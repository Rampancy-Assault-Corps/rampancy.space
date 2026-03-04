import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:rampancy_assault_corps_server/config/account_linking_config.dart';

class DiscordProfile {
  final String id;
  final String username;
  final String? globalName;
  final String? avatarHash;

  const DiscordProfile({
    required this.id,
    required this.username,
    required this.globalName,
    required this.avatarHash,
  });
}

class BungieMembershipData {
  final String membershipId;
  final int membershipType;
  final String? displayName;
  final String? iconPath;
  final int? crossSaveOverride;
  final bool isPrimary;

  const BungieMembershipData({
    required this.membershipId,
    required this.membershipType,
    required this.displayName,
    required this.iconPath,
    required this.crossSaveOverride,
    required this.isPrimary,
  });
}

class BungieOAuthResult {
  final String refreshToken;
  final int? refreshExpiresAt;
  final List<BungieMembershipData> memberships;

  const BungieOAuthResult({
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.memberships,
  });
}

class OAuthProviderService {
  final AccountLinkingConfig _config;
  final http.Client _http;

  OAuthProviderService(this._config, {http.Client? client})
    : _http = client ?? http.Client();

  Uri buildDiscordAuthorizeUri({required String state}) {
    return Uri.https('discord.com', '/oauth2/authorize', <String, String>{
      'response_type': 'code',
      'client_id': _config.discordClientId,
      'scope': 'identify',
      'redirect_uri': _config.discordRedirectUri,
      'state': state,
      'prompt': 'consent',
    });
  }

  Uri buildBungieAuthorizeUri({required String state}) {
    return Uri.https('www.bungie.net', '/en/OAuth/Authorize', <String, String>{
      'client_id': _config.bungieClientId,
      'response_type': 'code',
      'state': state,
    });
  }

  Future<DiscordProfile> exchangeDiscordCodeForProfile({
    required String code,
  }) async {
    final Uri tokenUri = Uri.https('discord.com', '/api/oauth2/token');

    final http.Response tokenResponse = await _http.post(
      tokenUri,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: <String, String>{
        'client_id': _config.discordClientId,
        'client_secret': _config.discordClientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _config.discordRedirectUri,
      },
    );

    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      throw StateError(
        'Discord token exchange failed: ${tokenResponse.statusCode}',
      );
    }

    final Map<String, dynamic> tokenMap = _decodeMap(
      tokenResponse.body,
      'Discord token response',
    );
    final String accessToken = (tokenMap['access_token'] as String?) ?? '';

    if (accessToken.isEmpty) {
      throw StateError('Discord token exchange returned no access token.');
    }

    final Uri profileUri = Uri.https('discord.com', '/api/users/@me');
    final http.Response profileResponse = await _http.get(
      profileUri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    if (profileResponse.statusCode < 200 || profileResponse.statusCode >= 300) {
      throw StateError(
        'Discord profile request failed: ${profileResponse.statusCode}',
      );
    }

    final Map<String, dynamic> profileMap = _decodeMap(
      profileResponse.body,
      'Discord profile response',
    );

    final String id = (profileMap['id'] as String?) ?? '';
    final String username = (profileMap['username'] as String?) ?? '';

    if (id.isEmpty || username.isEmpty) {
      throw StateError('Discord profile missing required id/username fields.');
    }

    return DiscordProfile(
      id: id,
      username: username,
      globalName: profileMap['global_name'] as String?,
      avatarHash: profileMap['avatar'] as String?,
    );
  }

  Future<BungieOAuthResult> exchangeBungieCode({required String code}) async {
    final Uri tokenUri = Uri.parse(
      'https://www.bungie.net/platform/app/oauth/token/',
    );

    final String basicToken = base64Encode(
      utf8.encode('${_config.bungieClientId}:${_config.bungieClientSecret}'),
    );

    final http.Response tokenResponse = await _http.post(
      tokenUri,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $basicToken',
        'X-API-Key': _config.bungieApiKey,
      },
      body: <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _config.bungieClientId,
        'redirect_uri': _config.bungieRedirectUri,
      },
    );

    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      throw StateError(
        'Bungie token exchange failed: ${tokenResponse.statusCode}',
      );
    }

    final Map<String, dynamic> tokenMap = _decodeMap(
      tokenResponse.body,
      'Bungie token response',
    );

    final String accessToken = (tokenMap['access_token'] as String?) ?? '';
    final String refreshToken = (tokenMap['refresh_token'] as String?) ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Bungie token response missing required tokens.');
    }

    final int? refreshExpiresIn = _asInt(tokenMap['refresh_expires_in']);
    int? refreshExpiresAt;
    if (refreshExpiresIn != null) {
      refreshExpiresAt =
          DateTime.now().millisecondsSinceEpoch + (refreshExpiresIn * 1000);
    }

    final List<BungieMembershipData> memberships =
        await _fetchBungieMemberships(accessToken);

    return BungieOAuthResult(
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiresAt,
      memberships: memberships,
    );
  }

  Future<List<BungieMembershipData>> _fetchBungieMemberships(
    String accessToken,
  ) async {
    final Uri membershipsUri = Uri.parse(
      'https://www.bungie.net/Platform/User/GetMembershipsForCurrentUser/',
    );

    final http.Response membershipsResponse = await _http.get(
      membershipsUri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'X-API-Key': _config.bungieApiKey,
      },
    );

    if (membershipsResponse.statusCode < 200 ||
        membershipsResponse.statusCode >= 300) {
      throw StateError(
        'Bungie memberships request failed: ${membershipsResponse.statusCode}',
      );
    }

    final Map<String, dynamic> membershipsMap = _decodeMap(
      membershipsResponse.body,
      'Bungie memberships response',
    );

    final dynamic responseValue = membershipsMap['Response'];
    if (responseValue is! Map<String, dynamic>) {
      return <BungieMembershipData>[];
    }

    final Map<String, dynamic> responseMap = responseValue;
    final int? primaryMembershipType = _asInt(responseMap['crossSaveOverride']);
    final String? primaryMembershipId =
        responseMap['primaryMembershipId'] as String?;

    final dynamic rawMemberships = responseMap['destinyMemberships'];
    if (rawMemberships is! List<dynamic>) {
      return <BungieMembershipData>[];
    }

    final List<BungieMembershipData> memberships = <BungieMembershipData>[];

    for (final dynamic entry in rawMemberships) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      final String membershipId = (entry['membershipId'] as String?) ?? '';
      final int membershipType = _asInt(entry['membershipType']) ?? 0;
      if (membershipId.isEmpty || membershipType == 0) {
        continue;
      }

      final int? entryCrossSaveOverride = _asInt(entry['crossSaveOverride']);
      final bool isPrimaryById =
          primaryMembershipId != null && primaryMembershipId == membershipId;
      final bool isPrimaryByType =
          primaryMembershipType != null &&
          primaryMembershipType == membershipType;
      final bool isPrimary = isPrimaryById || isPrimaryByType;

      memberships.add(
        BungieMembershipData(
          membershipId: membershipId,
          membershipType: membershipType,
          displayName:
              (entry['displayName'] as String?) ??
              (entry['LastSeenDisplayName'] as String?),
          iconPath: entry['iconPath'] as String?,
          crossSaveOverride: entryCrossSaveOverride,
          isPrimary: isPrimary,
        ),
      );
    }

    return memberships;
  }

  int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is String) {
      return int.tryParse(value);
    }
    if (value is num) {
      return value.toInt();
    }
    return null;
  }

  Map<String, dynamic> _decodeMap(String body, String name) {
    final dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('$name must be a JSON object.');
    }
    return decoded;
  }
}
