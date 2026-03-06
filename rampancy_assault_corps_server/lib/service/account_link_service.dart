import 'package:fast_log/fast_log.dart';
import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/service/oauth_provider_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';

class AccountLinkRecord {
  final String accountLinkId;
  final AccountLink link;

  const AccountLinkRecord({required this.accountLinkId, required this.link});
}

class AccountLinkStatus {
  final bool discordConnected;
  final bool bungieConnected;
  final AccountLink? link;
  final List<BungieMembership> memberships;

  const AccountLinkStatus({
    required this.discordConnected,
    required this.bungieConnected,
    required this.link,
    required this.memberships,
  });
}

class AccountLinkService {
  Future<AccountLinkRecord> upsertDiscordLink({
    required DiscordProfile profile,
    required String? accountLinkId,
  }) async {
    info(
      'account_link_discord_upsert_begin accountLinkId=$accountLinkId discordId=${profile.id}',
    );
    int now = DateTime.now().millisecondsSinceEpoch;
    AccountLink? target = await _loadByAccountLinkId(accountLinkId);
    AccountLink? existingForDiscord = await _findByDiscordId(profile.id);
    verbose(
      'account_link_discord_upsert_lookup targetFound=${target != null} existingForDiscord=${existingForDiscord != null}',
    );

    if (target == null || !target.bungieConnected) {
      throw StateError(
        'Bungie must be linked before Discord can be connected.',
      );
    }

    if (existingForDiscord != null &&
        target.accountLinkId != existingForDiscord.accountLinkId) {
      warn(
        'account_link_discord_upsert_conflict target=${target.accountLinkId} existing=${existingForDiscord.accountLinkId}',
      );
      AccountLink detached = existingForDiscord.copyWith(
        discordId: null,
        deleteDiscordId: true,
        discordUsername: null,
        deleteDiscordUsername: true,
        discordGlobalName: null,
        deleteDiscordGlobalName: true,
        discordAvatarHash: null,
        deleteDiscordAvatarHash: true,
        discordLinkedAt: null,
        deleteDiscordLinkedAt: true,
        updatedAt: now,
      );
      await $crud.setAccountLink(existingForDiscord.accountLinkId, detached);
      existingForDiscord = null;
    }

    String currentId = target.accountLinkId;
    AccountLink next = target.copyWith(
      discordId: profile.id,
      discordUsername: profile.username,
      discordGlobalName: profile.globalName,
      deleteDiscordGlobalName: profile.globalName == null,
      discordAvatarHash: profile.avatarHash,
      deleteDiscordAvatarHash: profile.avatarHash == null,
      discordLinkedAt: now,
      updatedAt: now,
    );

    await $crud.setAccountLink(currentId, next);
    info('account_link_discord_upsert_updated accountLinkId=$currentId');
    return AccountLinkRecord(accountLinkId: currentId, link: next);
  }

  Future<AccountLinkRecord> upsertBungieLink({
    required String? accountLinkId,
    required EncryptedToken encryptedRefreshToken,
    required int? refreshExpiresAt,
    required List<BungieMembershipData> memberships,
  }) async {
    info(
      'account_link_bungie_upsert_begin accountLinkId=$accountLinkId memberships=${memberships.length}',
    );
    int now = DateTime.now().millisecondsSinceEpoch;
    BungieMembershipData? primaryMembership = _primaryMembership(memberships);
    String? primaryMembershipId = primaryMembership?.membershipId;
    int? primaryMembershipType = primaryMembership?.membershipType;
    String? primaryMembershipKey = _primaryMembershipKey(primaryMembership);

    if (primaryMembershipId == null || primaryMembershipId.isEmpty) {
      throw StateError('Bungie returned no primary membership id.');
    }

    String targetAccountLinkId = primaryMembershipId;
    AccountLink? sessionLink = await _loadByAccountLinkId(accountLinkId);
    AccountLink? existingAtTargetId = await _loadByAccountLinkId(
      targetAccountLinkId,
    );
    AccountLink? existingForPrimaryKey;
    if (primaryMembershipKey != null) {
      existingForPrimaryKey = await _findByBungiePrimaryMembershipKey(
        primaryMembershipKey,
      );
    }
    verbose(
      'account_link_bungie_upsert_lookup sessionFound=${sessionLink != null} targetFound=${existingAtTargetId != null} primaryFound=${existingForPrimaryKey != null} targetAccountLinkId=$targetAccountLinkId primaryMembershipKey=$primaryMembershipKey',
    );

    Map<String, AccountLink> existingLinks = <String, AccountLink>{};
    _storeExistingLink(existingLinks, sessionLink);
    _storeExistingLink(existingLinks, existingAtTargetId);
    _storeExistingLink(existingLinks, existingForPrimaryKey);

    AccountLink next = AccountLink(
      discordId: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordId,
        sessionLink?.discordId,
        existingForPrimaryKey?.discordId,
      ]),
      discordUsername: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordUsername,
        sessionLink?.discordUsername,
        existingForPrimaryKey?.discordUsername,
      ]),
      discordGlobalName: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordGlobalName,
        sessionLink?.discordGlobalName,
        existingForPrimaryKey?.discordGlobalName,
      ]),
      discordAvatarHash: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordAvatarHash,
        sessionLink?.discordAvatarHash,
        existingForPrimaryKey?.discordAvatarHash,
      ]),
      discordLinkedAt: _firstNonNullInt(<int?>[
        existingAtTargetId?.discordLinkedAt,
        sessionLink?.discordLinkedAt,
        existingForPrimaryKey?.discordLinkedAt,
      ]),
      bungieConnected: true,
      bungiePrimaryMembershipKey: primaryMembershipKey,
      bungiePrimaryMembershipId: primaryMembershipId,
      bungiePrimaryMembershipType: primaryMembershipType,
      bungieLinkedAt: now,
      bungieRefreshCiphertext: encryptedRefreshToken.ciphertext,
      bungieRefreshNonce: encryptedRefreshToken.nonce,
      bungieRefreshExpiresAt: refreshExpiresAt,
      updatedAt: now,
    );

    await $crud.setAccountLink(targetAccountLinkId, next);
    await _syncMemberships(
      accountLinkId: targetAccountLinkId,
      memberships: memberships,
      now: now,
    );

    for (MapEntry<String, AccountLink> entry in existingLinks.entries) {
      if (entry.key == targetAccountLinkId) {
        continue;
      }
      await deleteAccountLink(entry.key);
    }

    info('account_link_bungie_upsert_saved accountLinkId=$targetAccountLinkId');
    return AccountLinkRecord(accountLinkId: targetAccountLinkId, link: next);
  }

  Future<AccountLinkStatus> getStatus(String accountLinkId) async {
    verbose('account_link_status_begin accountLinkId=$accountLinkId');
    if (accountLinkId.isEmpty) {
      return const AccountLinkStatus(
        discordConnected: false,
        bungieConnected: false,
        link: null,
        memberships: <BungieMembership>[],
      );
    }

    AccountLink? link = await $crud.getAccountLink(accountLinkId);
    if (link == null) {
      return const AccountLinkStatus(
        discordConnected: false,
        bungieConnected: false,
        link: null,
        memberships: <BungieMembership>[],
      );
    }

    AccountLink model = $crud.accountLinkModel(accountLinkId);
    List<BungieMembership> memberships = await model.getBungieMemberships();
    verbose(
      'account_link_status_resolved accountLinkId=$accountLinkId discordConnected=${_isDiscordConnected(link)} bungieConnected=${link.bungieConnected} memberships=${memberships.length}',
    );

    return AccountLinkStatus(
      discordConnected: _isDiscordConnected(link),
      bungieConnected: link.bungieConnected,
      link: link,
      memberships: memberships,
    );
  }

  Future<void> deleteAccountLink(String accountLinkId) async {
    if (accountLinkId.isEmpty) {
      return;
    }

    AccountLink? link = await $crud.getAccountLink(accountLinkId);
    if (link == null) {
      verbose('account_link_delete_missing accountLinkId=$accountLinkId');
      return;
    }

    List<BungieMembership> memberships = await $crud
        .accountLinkModel(accountLinkId)
        .getBungieMemberships();
    for (BungieMembership membership in memberships) {
      await $crud
          .accountLinkModel(accountLinkId)
          .deleteBungieMembership(membership.bungieMembershipId);
    }
    await $crud.deleteAccountLink(accountLinkId);
    info(
      'account_link_delete_done accountLinkId=$accountLinkId memberships=${memberships.length}',
    );
  }

  Future<AccountLink?> _loadByAccountLinkId(String? accountLinkId) async {
    if (accountLinkId == null || accountLinkId.isEmpty) {
      return null;
    }
    return $crud.getAccountLink(accountLinkId);
  }

  Future<AccountLink?> _findByDiscordId(String discordId) async {
    if (discordId.isEmpty) {
      return null;
    }
    List<AccountLink> matches = await $crud.getAccountLinks(
      (ref) => ref.whereEqual('discordId', discordId).limit(1),
    );
    if (matches.isEmpty) {
      verbose('account_link_find_by_discord none discordId=$discordId');
      return null;
    }
    verbose(
      'account_link_find_by_discord hit discordId=$discordId accountLinkId=${matches.first.accountLinkId}',
    );
    return matches.first;
  }

  Future<AccountLink?> _findByBungiePrimaryMembershipKey(String key) async {
    if (key.isEmpty) {
      return null;
    }
    List<AccountLink> matches = await $crud.getAccountLinks(
      (ref) => ref.whereEqual('bungiePrimaryMembershipKey', key).limit(1),
    );
    if (matches.isEmpty) {
      verbose('account_link_find_by_bungie_key none key=$key');
      return null;
    }
    verbose(
      'account_link_find_by_bungie_key hit key=$key accountLinkId=${matches.first.accountLinkId}',
    );
    return matches.first;
  }

  void _storeExistingLink(
    Map<String, AccountLink> existingLinks,
    AccountLink? link,
  ) {
    if (link == null) {
      return;
    }
    existingLinks[link.accountLinkId] = link;
  }

  Future<void> _syncMemberships({
    required String accountLinkId,
    required List<BungieMembershipData> memberships,
    required int now,
  }) async {
    AccountLink parent = $crud.accountLinkModel(accountLinkId);
    List<BungieMembership> existingMemberships = await parent
        .getBungieMemberships();
    Set<String> keepIds = <String>{};
    verbose(
      'account_link_sync_memberships_begin accountLinkId=$accountLinkId incoming=${memberships.length} existing=${existingMemberships.length}',
    );

    for (BungieMembershipData membership in memberships) {
      String membershipDocId = _membershipDocumentId(
        membership.membershipType,
        membership.membershipId,
      );
      keepIds.add(membershipDocId);
      BungieMembership next = BungieMembership(
        membershipId: membership.membershipId,
        membershipType: membership.membershipType,
        displayName: membership.displayName,
        iconPath: membership.iconPath,
        crossSaveOverride: membership.crossSaveOverride,
        isPrimary: membership.isPrimary,
        updatedAt: now,
      );
      await parent.setBungieMembership(membershipDocId, next);
    }

    for (BungieMembership existingMembership in existingMemberships) {
      String existingId = existingMembership.bungieMembershipId;
      if (!keepIds.contains(existingId)) {
        await parent.deleteBungieMembership(existingId);
      }
    }
    verbose(
      'account_link_sync_memberships_done accountLinkId=$accountLinkId kept=${keepIds.length}',
    );
  }

  BungieMembershipData? _primaryMembership(
    List<BungieMembershipData> memberships,
  ) {
    for (BungieMembershipData membership in memberships) {
      if (membership.isPrimary) {
        return membership;
      }
    }
    if (memberships.isEmpty) {
      return null;
    }
    return memberships.first;
  }

  String? _primaryMembershipKey(BungieMembershipData? membership) {
    if (membership == null) {
      return null;
    }
    return _membershipDocumentId(
      membership.membershipType,
      membership.membershipId,
    );
  }

  bool _isDiscordConnected(AccountLink link) {
    String? discordId = link.discordId;
    return discordId != null && discordId.isNotEmpty;
  }

  String? _firstNonEmptyString(List<String?> values) {
    for (String? value in values) {
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  int? _firstNonNullInt(List<int?> values) {
    for (int? value in values) {
      if (value != null) {
        return value;
      }
    }
    return null;
  }

  String _membershipDocumentId(int membershipType, String membershipId) {
    return '${membershipType}_$membershipId';
  }
}
