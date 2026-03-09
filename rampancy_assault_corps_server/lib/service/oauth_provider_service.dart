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
  final String accountId;
  final String? displayName;
  final String? avatarPath;
  final String? marathonMembershipId;
  final List<BungieMembershipData> memberships;

  const BungieOAuthResult({
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.accountId,
    required this.displayName,
    required this.avatarPath,
    required this.marathonMembershipId,
    required this.memberships,
  });
}

class BungieTokenExchangeException implements Exception {
  final String message;

  const BungieTokenExchangeException(this.message);

  @override
  String toString() => message;
}

class BungieIdentityMissingException implements Exception {
  final String message;

  const BungieIdentityMissingException(this.message);

  @override
  String toString() => message;
}

class _BungieTokenResult {
  final String accessToken;
  final String refreshToken;
  final int? refreshExpiresAt;
  final String? accountId;

  const _BungieTokenResult({
    required this.accessToken,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.accountId,
  });
}

class _BungieMembershipResponse {
  final String accountId;
  final String? displayName;
  final String? avatarPath;
  final String? marathonMembershipId;
  final List<BungieMembershipData> memberships;

  const _BungieMembershipResponse({
    required this.accountId,
    required this.displayName,
    required this.avatarPath,
    required this.marathonMembershipId,
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
    _BungieTokenResult tokenResult = await _exchangeBungieToken(
      body: <String, String>{
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': _config.bungieClientId,
        'redirect_uri': _config.bungieRedirectUri,
      },
      logLabel: 'oauth_bungie_exchange',
      codeLength: code.length,
    );
    _BungieMembershipResponse membershipResponse =
        await _fetchBungieMemberships(
          tokenResult.accessToken,
          tokenResult.accountId,
        );
    info(
      'oauth_bungie_exchange_resolved accountId=${membershipResponse.accountId} marathonMembershipPresent=${membershipResponse.marathonMembershipId != null && membershipResponse.marathonMembershipId!.isNotEmpty} memberships=${membershipResponse.memberships.length}',
    );

    return BungieOAuthResult(
      refreshToken: tokenResult.refreshToken,
      refreshExpiresAt: tokenResult.refreshExpiresAt,
      accountId: membershipResponse.accountId,
      displayName: membershipResponse.displayName,
      avatarPath: membershipResponse.avatarPath,
      marathonMembershipId: membershipResponse.marathonMembershipId,
      memberships: membershipResponse.memberships,
    );
  }

  Future<BungieOAuthResult> refreshBungieLink({
    required String refreshToken,
  }) async {
    _BungieTokenResult tokenResult = await _exchangeBungieToken(
      body: <String, String>{
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': _config.bungieClientId,
        'redirect_uri': _config.bungieRedirectUri,
      },
      logLabel: 'oauth_bungie_refresh',
      codeLength: refreshToken.length,
    );
    _BungieMembershipResponse membershipResponse =
        await _fetchBungieMemberships(
          tokenResult.accessToken,
          tokenResult.accountId,
        );
    info(
      'oauth_bungie_refresh_resolved accountId=${membershipResponse.accountId} marathonMembershipPresent=${membershipResponse.marathonMembershipId != null && membershipResponse.marathonMembershipId!.isNotEmpty} memberships=${membershipResponse.memberships.length}',
    );

    return BungieOAuthResult(
      refreshToken: tokenResult.refreshToken,
      refreshExpiresAt: tokenResult.refreshExpiresAt,
      accountId: membershipResponse.accountId,
      displayName: membershipResponse.displayName,
      avatarPath: membershipResponse.avatarPath,
      marathonMembershipId: membershipResponse.marathonMembershipId,
      memberships: membershipResponse.memberships,
    );
  }

  Future<_BungieTokenResult> _exchangeBungieToken({
    required Map<String, String> body,
    required String logLabel,
    required int codeLength,
  }) async {
    Uri tokenUri = Uri.https('www.bungie.net', '/platform/app/oauth/token/');
    network('$logLabel.begin codeLength=$codeLength');

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
      body: body,
    );
    network('$logLabel.token_response status=${tokenResponse.statusCode}');

    if (tokenResponse.statusCode < 200 || tokenResponse.statusCode >= 300) {
      String providerError = _extractProviderError(tokenResponse.body);
      throw BungieTokenExchangeException(
        'Bungie token exchange failed: ${tokenResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> tokenMap = _decodeMap(
      tokenResponse.body,
      'Bungie token response',
    );

    String accessToken = (tokenMap['access_token'] as String?) ?? '';
    String nextRefreshToken = (tokenMap['refresh_token'] as String?) ?? '';
    String? accountId = _asStringId(tokenMap['membership_id']);

    if (accessToken.isEmpty || nextRefreshToken.isEmpty) {
      throw BungieTokenExchangeException(
        'Bungie token response missing required tokens.',
      );
    }

    int? refreshExpiresIn = _asInt(tokenMap['refresh_expires_in']);
    int? refreshExpiresAt;
    if (refreshExpiresIn != null) {
      refreshExpiresAt =
          DateTime.now().millisecondsSinceEpoch + (refreshExpiresIn * 1000);
    }
    info(
      '$logLabel.tokens_resolved accountId=$accountId refreshExpiry=$refreshExpiresAt',
    );

    return _BungieTokenResult(
      accessToken: accessToken,
      refreshToken: nextRefreshToken,
      refreshExpiresAt: refreshExpiresAt,
      accountId: accountId,
    );
  }

  Future<_BungieMembershipResponse> _fetchBungieMemberships(
    String accessToken,
    String? tokenAccountId,
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
      throw BungieTokenExchangeException(
        'Bungie memberships request failed: ${membershipsResponse.statusCode} $providerError',
      );
    }

    Map<String, dynamic> membershipsMap = _decodeMap(
      membershipsResponse.body,
      'Bungie memberships response',
    );

    dynamic responseValue = membershipsMap['Response'];
    if (responseValue is! Map<String, dynamic>) {
      throw const BungieIdentityMissingException(
        'Bungie memberships response was missing the Response object.',
      );
    }

    Map<String, dynamic> responseMap = responseValue;
    Map<String, dynamic>? bungieNetUser = _mapOrNull(
      responseMap['bungieNetUser'],
    );
    String? accountId =
        tokenAccountId ?? _asStringId(bungieNetUser?['membershipId']);
    if (accountId == null || accountId.isEmpty) {
      throw const BungieIdentityMissingException(
        'Bungie returned no Bungie account id.',
      );
    }

    String? displayName = _firstNonEmptyString(<String?>[
      _asNullableString(bungieNetUser?['displayName']),
      _asNullableString(bungieNetUser?['uniqueName']),
      _asNullableString(bungieNetUser?['normalizedName']),
    ]);
    String? avatarPath = _asNullableString(
      bungieNetUser?['profilePicturePath'],
    );
    String? marathonMembershipId = _asStringId(
      responseMap['marathonMembershipId'],
    );
    int? primaryMembershipType = _asInt(responseMap['crossSaveOverride']);
    String? primaryMembershipId = _asStringId(
      responseMap['primaryMembershipId'],
    );
    List<BungieMembershipData> memberships = _parseDestinyMemberships(
      responseMap: responseMap,
      primaryMembershipId: primaryMembershipId,
      primaryMembershipType: primaryMembershipType,
    );

    info(
      'oauth_bungie_memberships_resolved accountId=$accountId marathonMembershipId=$marathonMembershipId memberships=${memberships.length}',
    );

    return _BungieMembershipResponse(
      accountId: accountId,
      displayName: displayName,
      avatarPath: avatarPath,
      marathonMembershipId: marathonMembershipId,
      memberships: memberships,
    );
  }

  List<BungieMembershipData> _parseDestinyMemberships({
    required Map<String, dynamic> responseMap,
    required String? primaryMembershipId,
    required int? primaryMembershipType,
  }) {
    dynamic rawMemberships = responseMap['destinyMemberships'];
    if (rawMemberships is! List<dynamic>) {
      warn('oauth_bungie_memberships_missing_destiny_memberships');
      return <BungieMembershipData>[];
    }

    List<BungieMembershipData> memberships = <BungieMembershipData>[];
    for (dynamic rawEntry in rawMemberships) {
      if (rawEntry is! Map<String, dynamic>) {
        continue;
      }

      String? membershipId = _asStringId(rawEntry['membershipId']);
      int? membershipType = _asInt(rawEntry['membershipType']);
      if (membershipId == null ||
          membershipId.isEmpty ||
          membershipType == null ||
          membershipType == 0) {
        continue;
      }

      int? entryCrossSaveOverride = _asInt(rawEntry['crossSaveOverride']);
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
          displayName: _firstNonEmptyString(<String?>[
            _asNullableString(rawEntry['displayName']),
            _asNullableString(rawEntry['LastSeenDisplayName']),
          ]),
          iconPath: _asNullableString(rawEntry['iconPath']),
          crossSaveOverride: entryCrossSaveOverride,
          isPrimary: isPrimary,
        ),
      );
    }

    return memberships;
  }

  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    return null;
  }

  String? _asStringId(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    if (value is int) {
      return value.toString();
    }
    if (value is num) {
      return value.toInt().toString();
    }
    return null;
  }

  String? _asNullableString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
  }

  String? _firstNonEmptyString(List<String?> values) {
    for (String? value in values) {
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    return null;
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
