import 'package:fast_log/fast_log.dart';
import 'package:fire_api/fire_api.dart';
import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/service/link_sync_state_service.dart';
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

class AccountLinkIdResolution {
  final String requestedAccountLinkId;
  final String canonicalAccountLinkId;
  final bool aliased;

  const AccountLinkIdResolution({
    required this.requestedAccountLinkId,
    required this.canonicalAccountLinkId,
    required this.aliased,
  });
}

class _CachedAccountLinkStatus {
  final AccountLinkStatus status;
  final int expiresAt;

  const _CachedAccountLinkStatus({
    required this.status,
    required this.expiresAt,
  });
}

class AccountLinkService {
  static const Duration _statusCacheTtl = Duration(seconds: 20);
  static const String _aliasCollectionPath = 'account_link_aliases';

  final LinkSyncStateService syncState;
  final Map<String, _CachedAccountLinkStatus> _statusCache;

  AccountLinkService({LinkSyncStateService? syncState})
    : syncState = syncState ?? LinkSyncStateService(),
      _statusCache = <String, _CachedAccountLinkStatus>{};

  Future<AccountLinkRecord> upsertDiscordLink({
    required DiscordProfile profile,
    required String? accountLinkId,
  }) async {
    info(
      'account_link_discord_upsert_begin accountLinkId=$accountLinkId discordId=${profile.id}',
    );
    int now = DateTime.now().millisecondsSinceEpoch;
    AccountLinkIdResolution? resolution = await resolveAccountLinkId(
      accountLinkId,
    );
    String? canonicalAccountLinkId = resolution?.canonicalAccountLinkId;
    AccountLink? target = await _loadDirectByAccountLinkId(
      canonicalAccountLinkId,
    );
    AccountLink? existingForDiscord = await _findByDiscordId(profile.id);
    verbose(
      'account_link_discord_upsert_lookup targetFound=${target != null} existingForDiscord=${existingForDiscord != null} canonicalAccountLinkId=$canonicalAccountLinkId',
    );

    if (target == null || !target.bungieConnected) {
      throw StateError(
        'Bungie must be linked before Discord can be connected.',
      );
    }

    AccountLink previousState = target;
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
      _invalidateStatuses(<String>[existingForDiscord.accountLinkId]);
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
    _invalidateStatuses(<String>[currentId]);
    await _recordStateChange(
      accountLinkId: currentId,
      previous: previousState,
      next: next,
    );
    info('account_link_discord_upsert_updated accountLinkId=$currentId');
    return AccountLinkRecord(accountLinkId: currentId, link: next);
  }

  Future<AccountLinkRecord> upsertBungieLink({
    required String? accountLinkId,
    required EncryptedToken encryptedRefreshToken,
    required int? refreshExpiresAt,
    required BungieOAuthResult result,
    bool emitSyncEvent = true,
  }) async {
    info(
      'account_link_bungie_upsert_begin accountLinkId=$accountLinkId bungieAccountId=${result.accountId} marathonMembershipId=${result.marathonMembershipId} memberships=${result.memberships.length}',
    );
    String targetAccountLinkId = result.accountId.trim();
    if (targetAccountLinkId.isEmpty) {
      throw const BungieIdentityMissingException(
        'Bungie returned no Bungie account id.',
      );
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    AccountLinkIdResolution? resolution = await resolveAccountLinkId(
      accountLinkId,
    );
    String? canonicalSessionAccountLinkId = resolution?.canonicalAccountLinkId;
    AccountLink? sessionLink = await _loadDirectByAccountLinkId(
      canonicalSessionAccountLinkId,
    );
    AccountLink? existingAtTargetId = await _loadDirectByAccountLinkId(
      targetAccountLinkId,
    );
    verbose(
      'account_link_bungie_upsert_lookup sessionFound=${sessionLink != null} targetFound=${existingAtTargetId != null} canonicalSessionAccountLinkId=$canonicalSessionAccountLinkId targetAccountLinkId=$targetAccountLinkId',
    );

    Map<String, AccountLink> existingLinks = <String, AccountLink>{};
    _storeExistingLink(existingLinks, sessionLink);
    _storeExistingLink(existingLinks, existingAtTargetId);
    AccountLink? previousState = _mergedLinkState(
      links: <AccountLink?>[sessionLink, existingAtTargetId],
      now: now,
    );

    AccountLink next = AccountLink(
      discordId: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordId,
        sessionLink?.discordId,
      ]),
      discordUsername: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordUsername,
        sessionLink?.discordUsername,
      ]),
      discordGlobalName: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordGlobalName,
        sessionLink?.discordGlobalName,
      ]),
      discordAvatarHash: _firstNonEmptyString(<String?>[
        existingAtTargetId?.discordAvatarHash,
        sessionLink?.discordAvatarHash,
      ]),
      discordLinkedAt: _firstNonNullInt(<int?>[
        existingAtTargetId?.discordLinkedAt,
        sessionLink?.discordLinkedAt,
      ]),
      bungieConnected: true,
      bungieAccountId: targetAccountLinkId,
      bungieDisplayName: _firstNonEmptyString(<String?>[
        result.displayName,
        existingAtTargetId?.bungieDisplayName,
        sessionLink?.bungieDisplayName,
      ]),
      bungieAvatarPath: _firstNonEmptyString(<String?>[
        result.avatarPath,
        existingAtTargetId?.bungieAvatarPath,
        sessionLink?.bungieAvatarPath,
      ]),
      bungieMarathonMembershipId: _firstNonEmptyString(<String?>[
        result.marathonMembershipId,
        existingAtTargetId?.bungieMarathonMembershipId,
        sessionLink?.bungieMarathonMembershipId,
      ]),
      bungieLinkedAt: now,
      bungieRefreshCiphertext: encryptedRefreshToken.ciphertext,
      bungieRefreshNonce: encryptedRefreshToken.nonce,
      bungieRefreshExpiresAt: refreshExpiresAt,
      updatedAt: now,
    );

    await $crud.setAccountLink(targetAccountLinkId, next);
    await _syncMemberships(
      accountLinkId: targetAccountLinkId,
      memberships: result.memberships,
      now: now,
    );

    List<String> migratedIds = <String>[];
    for (MapEntry<String, AccountLink> entry in existingLinks.entries) {
      String existingId = entry.key;
      if (existingId == targetAccountLinkId) {
        continue;
      }
      migratedIds.add(existingId);
      await _repointAliases(
        fromCanonicalAccountLinkId: existingId,
        toCanonicalAccountLinkId: targetAccountLinkId,
      );
      await _createAlias(existingId, targetAccountLinkId);
      await _deleteAccountLinkDirect(existingId);
    }

    _invalidateStatuses(<String>[
      targetAccountLinkId,
      ...existingLinks.keys,
      ...(resolution == null
          ? <String>[]
          : <String>[resolution.requestedAccountLinkId]),
    ]);
    if (emitSyncEvent) {
      await _recordStateChange(
        accountLinkId: targetAccountLinkId,
        previous: previousState,
        next: next,
      );
    }
    info(
      'account_link_bungie_upsert_saved accountLinkId=$targetAccountLinkId migratedIds=${migratedIds.join(',')}',
    );
    return AccountLinkRecord(accountLinkId: targetAccountLinkId, link: next);
  }

  Future<AccountLinkStatus> getStatus(String accountLinkId) async {
    verbose('account_link_status_begin accountLinkId=$accountLinkId');
    if (accountLinkId.isEmpty) {
      return _emptyStatus();
    }

    AccountLinkIdResolution? resolution = await resolveAccountLinkId(
      accountLinkId,
    );
    if (resolution == null) {
      return _emptyStatus();
    }

    String canonicalAccountLinkId = resolution.canonicalAccountLinkId;
    int now = DateTime.now().millisecondsSinceEpoch;
    _pruneStatusCache(now);
    _CachedAccountLinkStatus? cached = _statusCache[canonicalAccountLinkId];
    if (cached != null && cached.expiresAt > now) {
      if (resolution.aliased) {
        _statusCache[resolution.requestedAccountLinkId] = cached;
      }
      verbose(
        'account_link_status_cache_hit accountLinkId=$accountLinkId canonicalAccountLinkId=$canonicalAccountLinkId',
      );
      return cached.status;
    }

    AccountLink? link = await _loadDirectByAccountLinkId(
      canonicalAccountLinkId,
    );
    if (link == null) {
      AccountLinkStatus emptyStatus = _emptyStatus();
      _statusCache[canonicalAccountLinkId] = _CachedAccountLinkStatus(
        status: emptyStatus,
        expiresAt: now + _statusCacheTtl.inMilliseconds,
      );
      if (resolution.aliased) {
        _statusCache[resolution.requestedAccountLinkId] =
            _CachedAccountLinkStatus(
              status: emptyStatus,
              expiresAt: now + _statusCacheTtl.inMilliseconds,
            );
      }
      return emptyStatus;
    }

    AccountLink model = $crud.accountLinkModel(canonicalAccountLinkId);
    List<BungieMembership> memberships = await model.getBungieMemberships();
    verbose(
      'account_link_status_resolved requestedAccountLinkId=$accountLinkId canonicalAccountLinkId=$canonicalAccountLinkId discordConnected=${_isDiscordConnected(link)} bungieConnected=${link.bungieConnected} memberships=${memberships.length}',
    );

    AccountLinkStatus status = AccountLinkStatus(
      discordConnected: _isDiscordConnected(link),
      bungieConnected: link.bungieConnected,
      link: link,
      memberships: memberships,
    );
    _CachedAccountLinkStatus cachedStatus = _CachedAccountLinkStatus(
      status: status,
      expiresAt: now + _statusCacheTtl.inMilliseconds,
    );
    _statusCache[canonicalAccountLinkId] = cachedStatus;
    if (resolution.aliased) {
      _statusCache[resolution.requestedAccountLinkId] = cachedStatus;
    }
    return status;
  }

  Future<AccountLinkIdResolution?> resolveAccountLinkId(
    String? accountLinkId,
  ) async {
    if (accountLinkId == null || accountLinkId.isEmpty) {
      return null;
    }

    String requestedAccountLinkId = accountLinkId;
    String currentAccountLinkId = requestedAccountLinkId;
    bool aliased = false;
    for (int depth = 0; depth < 6; depth++) {
      AccountLink? directLink = await _loadDirectByAccountLinkId(
        currentAccountLinkId,
      );
      if (directLink != null) {
        return AccountLinkIdResolution(
          requestedAccountLinkId: requestedAccountLinkId,
          canonicalAccountLinkId: currentAccountLinkId,
          aliased: aliased,
        );
      }

      DocumentSnapshot aliasSnapshot = await _aliasDocument(
        currentAccountLinkId,
      ).get();
      Map<String, dynamic>? aliasData = aliasSnapshot.data;
      String? nextAccountLinkId = _asNonEmptyString(
        aliasData?['canonicalAccountLinkId'],
      );
      if (nextAccountLinkId == null ||
          nextAccountLinkId == currentAccountLinkId) {
        return AccountLinkIdResolution(
          requestedAccountLinkId: requestedAccountLinkId,
          canonicalAccountLinkId: currentAccountLinkId,
          aliased: aliased,
        );
      }

      aliased = true;
      currentAccountLinkId = nextAccountLinkId;
    }

    warn(
      'account_link_alias_resolution_depth_exceeded requestedAccountLinkId=$requestedAccountLinkId currentAccountLinkId=$currentAccountLinkId',
    );
    return AccountLinkIdResolution(
      requestedAccountLinkId: requestedAccountLinkId,
      canonicalAccountLinkId: currentAccountLinkId,
      aliased: aliased,
    );
  }

  Future<void> deleteAccountLink(
    String accountLinkId, {
    bool emitSyncEvent = true,
  }) async {
    if (accountLinkId.isEmpty) {
      return;
    }

    AccountLinkIdResolution? resolution = await resolveAccountLinkId(
      accountLinkId,
    );
    if (resolution == null) {
      return;
    }

    String canonicalAccountLinkId = resolution.canonicalAccountLinkId;
    AccountLink? link = await _loadDirectByAccountLinkId(
      canonicalAccountLinkId,
    );
    if (link == null) {
      verbose(
        'account_link_delete_missing requestedAccountLinkId=$accountLinkId canonicalAccountLinkId=$canonicalAccountLinkId',
      );
      await _deleteAliasDocument(resolution.requestedAccountLinkId);
      return;
    }

    List<BungieMembership> memberships = await $crud
        .accountLinkModel(canonicalAccountLinkId)
        .getBungieMemberships();
    for (BungieMembership membership in memberships) {
      await $crud
          .accountLinkModel(canonicalAccountLinkId)
          .deleteBungieMembership(membership.bungieMembershipId);
    }
    await $crud.deleteAccountLink(canonicalAccountLinkId);
    await _deleteAliasDocument(canonicalAccountLinkId);
    await _deleteAliasDocument(resolution.requestedAccountLinkId);
    await _deleteAliasesForCanonicalId(canonicalAccountLinkId);
    _invalidateStatuses(<String>[
      canonicalAccountLinkId,
      resolution.requestedAccountLinkId,
    ]);
    if (emitSyncEvent) {
      await _recordStateChange(
        accountLinkId: canonicalAccountLinkId,
        previous: link,
        next: null,
      );
    }
    info(
      'account_link_delete_done accountLinkId=$canonicalAccountLinkId memberships=${memberships.length}',
    );
  }

  Future<AccountLink?> _loadDirectByAccountLinkId(String? accountLinkId) async {
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
      (CollectionReference ref) =>
          ref.whereEqual('discordId', discordId).limit(1),
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

  AccountLinkStatus _emptyStatus() {
    return const AccountLinkStatus(
      discordConnected: false,
      bungieConnected: false,
      link: null,
      memberships: <BungieMembership>[],
    );
  }

  void _invalidateStatuses(List<String> accountLinkIds) {
    int now = DateTime.now().millisecondsSinceEpoch;
    _pruneStatusCache(now);
    for (String accountLinkId in accountLinkIds) {
      if (accountLinkId.isEmpty) {
        continue;
      }
      _statusCache.remove(accountLinkId);
    }
  }

  void _pruneStatusCache(int now) {
    _statusCache.removeWhere(
      (String _, _CachedAccountLinkStatus entry) => entry.expiresAt <= now,
    );
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

  Future<void> _recordStateChange({
    required String accountLinkId,
    required AccountLink? previous,
    required AccountLink? next,
  }) async {
    try {
      await syncState.recordAccountLinkStateChange(
        accountLinkId: accountLinkId,
        previous: previous,
        next: next,
      );
    } on Object catch (caughtError, stackTrace) {
      error(
        'account_link_sync_state_record_failed accountLinkId=$accountLinkId err=$caughtError',
      );
      error(stackTrace.toString());
    }
  }

  Future<void> _deleteAccountLinkDirect(String accountLinkId) async {
    if (accountLinkId.isEmpty) {
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
  }

  Future<void> _createAlias(
    String legacyAccountLinkId,
    String canonicalAccountLinkId,
  ) async {
    if (legacyAccountLinkId.isEmpty ||
        canonicalAccountLinkId.isEmpty ||
        legacyAccountLinkId == canonicalAccountLinkId) {
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    await _aliasDocument(legacyAccountLinkId).set(<String, dynamic>{
      'canonicalAccountLinkId': canonicalAccountLinkId,
      'updatedAt': now,
    });
    verbose(
      'account_link_alias_created legacyAccountLinkId=$legacyAccountLinkId canonicalAccountLinkId=$canonicalAccountLinkId',
    );
  }

  Future<void> _repointAliases({
    required String fromCanonicalAccountLinkId,
    required String toCanonicalAccountLinkId,
  }) async {
    if (fromCanonicalAccountLinkId.isEmpty ||
        toCanonicalAccountLinkId.isEmpty ||
        fromCanonicalAccountLinkId == toCanonicalAccountLinkId) {
      return;
    }

    int now = DateTime.now().millisecondsSinceEpoch;
    List<DocumentSnapshot> aliasSnapshots = await _aliasCollection()
        .whereEqual('canonicalAccountLinkId', fromCanonicalAccountLinkId)
        .get();
    for (DocumentSnapshot aliasSnapshot in aliasSnapshots) {
      await aliasSnapshot.reference.set(<String, dynamic>{
        'canonicalAccountLinkId': toCanonicalAccountLinkId,
        'updatedAt': now,
      });
    }
    if (aliasSnapshots.isNotEmpty) {
      verbose(
        'account_link_aliases_repointed fromCanonicalAccountLinkId=$fromCanonicalAccountLinkId toCanonicalAccountLinkId=$toCanonicalAccountLinkId count=${aliasSnapshots.length}',
      );
    }
  }

  Future<void> _deleteAliasesForCanonicalId(
    String canonicalAccountLinkId,
  ) async {
    if (canonicalAccountLinkId.isEmpty) {
      return;
    }

    List<DocumentSnapshot> aliasSnapshots = await _aliasCollection()
        .whereEqual('canonicalAccountLinkId', canonicalAccountLinkId)
        .get();
    for (DocumentSnapshot aliasSnapshot in aliasSnapshots) {
      await aliasSnapshot.reference.delete();
    }
  }

  Future<void> _deleteAliasDocument(String accountLinkId) async {
    if (accountLinkId.isEmpty) {
      return;
    }

    DocumentSnapshot aliasSnapshot = await _aliasDocument(accountLinkId).get();
    if (!aliasSnapshot.exists) {
      return;
    }
    await aliasSnapshot.reference.delete();
  }

  CollectionReference _aliasCollection() {
    return FirestoreDatabase.instance.collection(_aliasCollectionPath);
  }

  DocumentReference _aliasDocument(String accountLinkId) {
    return _aliasCollection().doc(accountLinkId);
  }

  AccountLink? _mergedLinkState({
    required List<AccountLink?> links,
    required int now,
  }) {
    bool hasLink = false;
    for (AccountLink? link in links) {
      if (link != null) {
        hasLink = true;
        break;
      }
    }
    if (!hasLink) {
      return null;
    }

    return AccountLink(
      discordId: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.discordId).toList(),
      ),
      discordUsername: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.discordUsername).toList(),
      ),
      discordGlobalName: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.discordGlobalName).toList(),
      ),
      discordAvatarHash: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.discordAvatarHash).toList(),
      ),
      discordLinkedAt: _firstNonNullInt(
        links.map((AccountLink? link) => link?.discordLinkedAt).toList(),
      ),
      bungieConnected: links.any(
        (AccountLink? link) => link?.bungieConnected ?? false,
      ),
      bungieAccountId: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.bungieAccountId).toList(),
      ),
      bungieDisplayName: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.bungieDisplayName).toList(),
      ),
      bungieAvatarPath: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.bungieAvatarPath).toList(),
      ),
      bungieMarathonMembershipId: _firstNonEmptyString(
        links
            .map((AccountLink? link) => link?.bungieMarathonMembershipId)
            .toList(),
      ),
      bungieLinkedAt: _firstNonNullInt(
        links.map((AccountLink? link) => link?.bungieLinkedAt).toList(),
      ),
      bungieRefreshCiphertext: _firstNonEmptyString(
        links
            .map((AccountLink? link) => link?.bungieRefreshCiphertext)
            .toList(),
      ),
      bungieRefreshNonce: _firstNonEmptyString(
        links.map((AccountLink? link) => link?.bungieRefreshNonce).toList(),
      ),
      bungieRefreshExpiresAt: _firstNonNullInt(
        links.map((AccountLink? link) => link?.bungieRefreshExpiresAt).toList(),
      ),
      updatedAt: now,
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

  String? _asNonEmptyString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String _membershipDocumentId(int membershipType, String membershipId) {
    return '${membershipType}_$membershipId';
  }
}
