import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/service/oauth_provider_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';

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
  Future<AccountLink> upsertDiscordLink(DiscordProfile profile) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final AccountLink? current = await $crud.getAccountLink(profile.id);

    final AccountLink next;
    if (current == null) {
      next = AccountLink(
        discordId: profile.id,
        discordUsername: profile.username,
        discordGlobalName: profile.globalName,
        discordAvatarHash: profile.avatarHash,
        discordLinkedAt: now,
        bungieConnected: false,
        updatedAt: now,
      );
    } else {
      next = current.copyWith(
        discordUsername: profile.username,
        discordGlobalName: profile.globalName,
        deleteDiscordGlobalName: profile.globalName == null,
        discordAvatarHash: profile.avatarHash,
        deleteDiscordAvatarHash: profile.avatarHash == null,
        updatedAt: now,
      );
    }

    await $crud.setAccountLink(profile.id, next);
    return next;
  }

  Future<AccountLink> upsertBungieLink({
    required String discordId,
    required EncryptedToken encryptedRefreshToken,
    required int? refreshExpiresAt,
    required List<BungieMembershipData> memberships,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final AccountLink? current = await $crud.getAccountLink(discordId);
    if (current == null) {
      throw StateError(
        'Account link does not exist for Discord ID $discordId.',
      );
    }

    final AccountLink updated = current.copyWith(
      bungieConnected: true,
      bungieLinkedAt: now,
      bungieRefreshCiphertext: encryptedRefreshToken.ciphertext,
      bungieRefreshNonce: encryptedRefreshToken.nonce,
      bungieRefreshExpiresAt: refreshExpiresAt,
      deleteBungieRefreshExpiresAt: refreshExpiresAt == null,
      updatedAt: now,
    );

    await $crud.setAccountLink(discordId, updated);

    final AccountLink parent = $crud.accountLinkModel(discordId);
    final List<BungieMembership> existing = await parent.getBungieMemberships();
    final Set<String> keepIds = <String>{};

    for (final BungieMembershipData membership in memberships) {
      final String id = _membershipDocumentId(
        membership.membershipType,
        membership.membershipId,
      );
      keepIds.add(id);
      final BungieMembership next = BungieMembership(
        membershipId: membership.membershipId,
        membershipType: membership.membershipType,
        displayName: membership.displayName,
        iconPath: membership.iconPath,
        crossSaveOverride: membership.crossSaveOverride,
        isPrimary: membership.isPrimary,
        updatedAt: now,
      );
      await parent.setBungieMembership(id, next);
    }

    for (final BungieMembership existingMembership in existing) {
      final String existingId = existingMembership.bungieMembershipId;
      if (!keepIds.contains(existingId)) {
        await parent.deleteBungieMembership(existingId);
      }
    }

    return updated;
  }

  Future<AccountLinkStatus> getStatus(String discordId) async {
    final AccountLink? link = await $crud.getAccountLink(discordId);
    if (link == null) {
      return const AccountLinkStatus(
        discordConnected: false,
        bungieConnected: false,
        link: null,
        memberships: <BungieMembership>[],
      );
    }

    final AccountLink model = $crud.accountLinkModel(discordId);
    final List<BungieMembership> memberships = await model
        .getBungieMemberships();

    return AccountLinkStatus(
      discordConnected: true,
      bungieConnected: link.bungieConnected,
      link: link,
      memberships: memberships,
    );
  }

  String _membershipDocumentId(int membershipType, String membershipId) {
    return '${membershipType}_$membershipId';
  }
}
