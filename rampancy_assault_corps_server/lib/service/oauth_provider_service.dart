import 'dart:convert';

import 'package:fast_log/fast_log.dart';
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
    Uri uri = Uri.https('discord.com', '/oauth2/authorize', <String, String>{
      'response_type': 'code',
      'client_id': _config.discordClientId,
      'scope': 'identify',
      'redirect_uri': _config.discordRedirectUri,
      'state': state,
      'prompt': 'consent',
    });
    network(
      'oauth_discord_authorize_build redirectUri=${_config.discordRedirectUri} stateLength=${state.length}',
    );
    return uri;
  }

  Uri buildBungieAuthorizeUri({required String state}) {
    Uri uri =
        Uri.https('www.bungie.net', '/en/oauth/authorize', <String, String>{
          'client_id': _config.bungieClientId,
          'response_type': 'code',
          'redirect_uri': _config.bungieRedirectUri,
          'state': state,
        });
    network(
      'oauth_bungie_authorize_build redirectUri=${_config.bungieRedirectUri} stateLength=${state.length}',
    );
    return uri;
  }

  Future<DiscordProfile> exchangeDiscordCodeForProfile({
    required String code,
  }) async {
    Uri tokenUri = Uri.https('discord.com', '/api/oauth2/token');
    network('oauth_discord_exchange_begin codeLength=${code.length}');

    http.Response tokenResponse = await _http.post(
      tokenUri,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: <String, String>{
        'client_id': _config.discordClientId,
        'client_secret': _config.discordClientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _config.discordRedirectUri,
      },
    );
    network(
      'oauth_discord_exchange_token_response status=${tokenResponse.statusCode}',
    );

    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      String providerError = _extractProviderError(tokenResponse.body);
      throw StateError(
        'Discord token exchange failed: ${tokenResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> tokenMap = _decodeMap(
      tokenResponse.body,
      'Discord token response',
    );
    String accessToken = (tokenMap['access_token'] as String?) ?? '';

    if (accessToken.isEmpty) {
      throw StateError('Discord token exchange returned no access token.');
    }

    Uri profileUri = Uri.https('discord.com', '/api/users/@me');
    http.Response profileResponse = await _http.get(
      profileUri,
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    network(
      'oauth_discord_profile_response status=${profileResponse.statusCode}',
    );

    if (profileResponse.statusCode < 200 || profileResponse.statusCode >= 300) {
      String providerError = _extractProviderError(profileResponse.body);
      throw StateError(
        'Discord profile request failed: ${profileResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> profileMap = _decodeMap(
      profileResponse.body,
      'Discord profile response',
    );

    String id = (profileMap['id'] as String?) ?? '';
    String username = (profileMap['username'] as String?) ?? '';

    if (id.isEmpty || username.isEmpty) {
      throw StateError('Discord profile missing required id/username fields.');
    }
    info('oauth_discord_profile_resolved discordId=$id username=$username');

    return DiscordProfile(
      id: id,
      username: username,
      globalName: profileMap['global_name'] as String?,
      avatarHash: profileMap['avatar'] as String?,
    );
  }

  Future<BungieOAuthResult> exchangeBungieCode({required String code}) async {
    Uri tokenUri = Uri.https('www.bungie.net', '/platform/app/oauth/token/');
    network('oauth_bungie_exchange_begin codeLength=${code.length}');

    String basicToken = base64Encode(
      utf8.encode('${_config.bungieClientId}:${_config.bungieClientSecret}'),
    );

    http.Response tokenResponse = await _http.post(
      tokenUri,
      headers: <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
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
    network(
      'oauth_bungie_exchange_token_response status=${tokenResponse.statusCode}',
    );

    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      String providerError = _extractProviderError(tokenResponse.body);
      throw StateError(
        'Bungie token exchange failed: ${tokenResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> tokenMap = _decodeMap(
      tokenResponse.body,
      'Bungie token response',
    );

    String accessToken = (tokenMap['access_token'] as String?) ?? '';
    String refreshToken = (tokenMap['refresh_token'] as String?) ?? '';

    if (accessToken.isEmpty || refreshToken.isEmpty) {
      throw StateError('Bungie token response missing required tokens.');
    }

    int? refreshExpiresIn = _asInt(tokenMap['refresh_expires_in']);
    int? refreshExpiresAt;
    if (refreshExpiresIn != null) {
      refreshExpiresAt =
          DateTime.now().millisecondsSinceEpoch + (refreshExpiresIn * 1000);
    }
    info('oauth_bungie_tokens_resolved refreshExpiry=$refreshExpiresAt');

    List<BungieMembershipData> memberships = await _fetchBungieMemberships(
      accessToken,
    );
    info('oauth_bungie_memberships_resolved count=${memberships.length}');

    return BungieOAuthResult(
      refreshToken: refreshToken,
      refreshExpiresAt: refreshExpiresAt,
      memberships: memberships,
    );
  }

  Future<List<BungieMembershipData>> _fetchBungieMemberships(
    String accessToken,
  ) async {
    Uri membershipsUri = Uri.https(
      'www.bungie.net',
      '/Platform/User/GetMembershipsForCurrentUser/',
    );
    network('oauth_bungie_memberships_begin');

    http.Response membershipsResponse = await _http.get(
      membershipsUri,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'X-API-Key': _config.bungieApiKey,
      },
    );
    network(
      'oauth_bungie_memberships_response status=${membershipsResponse.statusCode}',
    );

    if (membershipsResponse.statusCode < 200 ||
        membershipsResponse.statusCode >= 300) {
      String providerError = _extractProviderError(membershipsResponse.body);
      throw StateError(
        'Bungie memberships request failed: ${membershipsResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> membershipsMap = _decodeMap(
      membershipsResponse.body,
      'Bungie memberships response',
    );

    dynamic responseValue = membershipsMap['Response'];
    if (responseValue is! Map<String, dynamic>) {
      warn('oauth_bungie_memberships_missing_response_object');
      return <BungieMembershipData>[];
    }

    Map<String, dynamic> responseMap = responseValue;
    int? primaryMembershipType = _asInt(responseMap['crossSaveOverride']);
    String? primaryMembershipId = responseMap['primaryMembershipId'] as String?;

    dynamic rawMemberships = responseMap['destinyMemberships'];
    if (rawMemberships is! List<dynamic>) {
      warn('oauth_bungie_memberships_missing_destiny_memberships');
      return <BungieMembershipData>[];
    }

    List<BungieMembershipData> memberships = <BungieMembershipData>[];

    for (dynamic entry in rawMemberships) {
      if (entry is! Map<String, dynamic>) {
        continue;
      }

      String membershipId = (entry['membershipId'] as String?) ?? '';
      int membershipType = _asInt(entry['membershipType']) ?? 0;
      if (membershipId.isEmpty || membershipType == 0) {
        continue;
      }

      int? entryCrossSaveOverride = _asInt(entry['crossSaveOverride']);
      bool isPrimaryById =
          primaryMembershipId != null && primaryMembershipId == membershipId;
      bool isPrimaryByType =
          primaryMembershipType != null &&
          primaryMembershipType == membershipType;
      bool isPrimary = isPrimaryById || isPrimaryByType;

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
    dynamic decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('$name must be a JSON object.');
    }
    return decoded;
  }

  String _extractProviderError(String body) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      String compactBody = body.trim().replaceAll('\n', ' ');
      if (compactBody.length > 220) {
        return compactBody.substring(0, 220);
      }
      return compactBody;
    }

    if (decoded is! Map<String, dynamic>) {
      return decoded.toString();
    }

    String? errorCode = decoded['error'] as String?;
    String? message =
        decoded['error_description'] as String? ??
        decoded['Message'] as String? ??
        decoded['message'] as String?;
    if (errorCode != null && errorCode.isNotEmpty && message != null) {
      return '$errorCode: $message';
    }
    if (errorCode != null && errorCode.isNotEmpty) {
      return errorCode;
    }
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return decoded.toString();
  }
}
