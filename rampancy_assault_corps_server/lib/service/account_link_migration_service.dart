import 'package:fast_log/fast_log.dart';
import 'package:fire_api/fire_api.dart';
import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/service/account_link_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_provider_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';

class AccountLinkMigrationService {
  static const String _migrationStatePath =
      'account_link_migrations/bungie_account_identity_v1';
  static const int _migrationVersion = 1;
  static const int _leaseDurationMs = 15 * 60 * 1000;

  final AccountLinkService links;
  final OAuthProviderService provider;
  final OAuthSecurityService security;

  const AccountLinkMigrationService({
    required this.links,
    required this.provider,
    required this.security,
  });

  Future<void> migrateIfNeeded() async {
    bool acquired = await _tryAcquireLease();
    if (!acquired) {
      return;
    }

    int scanned = 0;
    int migrated = 0;
    int skipped = 0;
    int failed = 0;
    info('account_link_migration_begin version=$_migrationVersion');

    try {
      List<AccountLink> accountLinks = await $crud.getAccountLinks();
      for (AccountLink link in accountLinks) {
        scanned++;
        if (!link.bungieConnected) {
          skipped++;
          continue;
        }

        if (_isCanonical(link)) {
          skipped++;
          continue;
        }

        String? ciphertext = link.bungieRefreshCiphertext;
        String? nonce = link.bungieRefreshNonce;
        if (ciphertext == null ||
            ciphertext.isEmpty ||
            nonce == null ||
            nonce.isEmpty) {
          failed++;
          warn(
            'account_link_migration_missing_refresh_token accountLinkId=${link.accountLinkId}',
          );
          continue;
        }

        try {
          String refreshToken = await security.decryptToken(
            EncryptedToken(ciphertext: ciphertext, nonce: nonce),
          );
          BungieOAuthResult result = await provider.refreshBungieLink(
            refreshToken: refreshToken,
          );
          EncryptedToken encryptedRefreshToken = await security.encryptToken(
            result.refreshToken,
          );
          await links.upsertBungieLink(
            accountLinkId: link.accountLinkId,
            encryptedRefreshToken: encryptedRefreshToken,
            refreshExpiresAt: result.refreshExpiresAt,
            result: result,
            emitSyncEvent: false,
          );
          migrated++;
          info(
            'account_link_migration_item_done legacyAccountLinkId=${link.accountLinkId} canonicalAccountLinkId=${result.accountId}',
          );
        } on Object catch (caughtError, stackTrace) {
          failed++;
          error(
            'account_link_migration_item_failed accountLinkId=${link.accountLinkId} err=$caughtError',
          );
          error(stackTrace.toString());
        }
      }

      await _setState(<String, dynamic>{
        'status': 'completed',
        'version': _migrationVersion,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'scanned': scanned,
        'migrated': migrated,
        'skipped': skipped,
        'failed': failed,
      });
      info(
        'account_link_migration_complete scanned=$scanned migrated=$migrated skipped=$skipped failed=$failed',
      );
    } on Object catch (caughtError, stackTrace) {
      await _setState(<String, dynamic>{
        'status': 'failed',
        'version': _migrationVersion,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        'failedAt': DateTime.now().millisecondsSinceEpoch,
        'scanned': scanned,
        'migrated': migrated,
        'skipped': skipped,
        'failed': failed,
        'error': caughtError.toString(),
      });
      error('account_link_migration_failed err=$caughtError');
      error(stackTrace.toString());
    }
  }

  bool _isCanonical(AccountLink link) {
    String? bungieAccountId = link.bungieAccountId;
    return bungieAccountId != null &&
        bungieAccountId.isNotEmpty &&
        bungieAccountId == link.accountLinkId;
  }

  Future<bool> _tryAcquireLease() async {
    DocumentReference stateDocument = _stateDocument();
    int now = DateTime.now().millisecondsSinceEpoch;
    bool acquired = false;
    await stateDocument.setAtomic((Map<String, dynamic>? data) {
      Map<String, dynamic> existing = data ?? <String, dynamic>{};
      int? version = _asInt(existing['version']);
      String? status = _asString(existing['status']);
      int? updatedAt = _asInt(existing['updatedAt']);
      bool alreadyComplete =
          version == _migrationVersion && status == 'completed';
      bool leaseActive =
          status == 'running' &&
          updatedAt != null &&
          (now - updatedAt) < _leaseDurationMs;
      if (alreadyComplete || leaseActive) {
        return existing;
      }

      acquired = true;
      return <String, dynamic>{
        'status': 'running',
        'version': _migrationVersion,
        'updatedAt': now,
        'startedAt': now,
      };
    });
    if (!acquired) {
      verbose('account_link_migration_skip_lease_unavailable');
    }
    return acquired;
  }

  Future<void> _setState(Map<String, dynamic> state) async {
    await _stateDocument().set(state);
  }

  DocumentReference _stateDocument() {
    return FirestoreDatabase.instance.document(_migrationStatePath);
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  String? _asString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }
}
