import 'dart:convert';

import 'package:fast_log/fast_log.dart';
import 'package:http/http.dart' as http;
import 'package:rampancy_assault_corps_web/utils/constants.dart';

class LinkStatusDiscord {
  final String id;
  final String username;
  final String? globalName;
  final String? avatarUrl;

  const LinkStatusDiscord({
    required this.id,
    required this.username,
    required this.globalName,
    required this.avatarUrl,
  });

  factory LinkStatusDiscord.fromMap(Map<String, dynamic> map) {
    return LinkStatusDiscord(
      id: (map['id'] as String?) ?? '',
      username: (map['username'] as String?) ?? '',
      globalName: map['globalName'] as String?,
      avatarUrl: map['avatarUrl'] as String?,
    );
  }
}

class LinkStatusMembership {
  final String membershipId;
  final int membershipType;
  final String? displayName;
  final String? iconPath;
  final int? crossSaveOverride;
  final bool isPrimary;

  const LinkStatusMembership({
    required this.membershipId,
    required this.membershipType,
    required this.displayName,
    required this.iconPath,
    required this.crossSaveOverride,
    required this.isPrimary,
  });

  factory LinkStatusMembership.fromMap(Map<String, dynamic> map) {
    return LinkStatusMembership(
      membershipId: (map['membershipId'] as String?) ?? '',
      membershipType: _asInt(map['membershipType']) ?? 0,
      displayName: map['displayName'] as String?,
      iconPath: map['iconPath'] as String?,
      crossSaveOverride: _asInt(map['crossSaveOverride']),
      isPrimary: (map['isPrimary'] as bool?) ?? false,
    );
  }

  static int? _asInt(dynamic value) {
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
}

class LinkStatus {
  final bool featureEnabled;
  final bool authenticated;
  final bool sessionAuthenticated;
  final bool discordConnected;
  final bool bungieConnected;
  final String? accountLinkId;
  final String? resumeToken;
  final String? bungieAccountId;
  final String? bungieAccountDisplayName;
  final String? bungieAccountAvatarUrl;
  final String? bungieMarathonMembershipId;
  final LinkStatusDiscord? discord;
  final List<LinkStatusMembership> memberships;

  const LinkStatus({
    required this.featureEnabled,
    required this.authenticated,
    required this.sessionAuthenticated,
    required this.discordConnected,
    required this.bungieConnected,
    required this.accountLinkId,
    required this.resumeToken,
    required this.bungieAccountId,
    required this.bungieAccountDisplayName,
    required this.bungieAccountAvatarUrl,
    required this.bungieMarathonMembershipId,
    required this.discord,
    required this.memberships,
  });

  static const LinkStatus fallback = LinkStatus(
    featureEnabled: true,
    authenticated: false,
    sessionAuthenticated: false,
    discordConnected: false,
    bungieConnected: false,
    accountLinkId: null,
    resumeToken: null,
    bungieAccountId: null,
    bungieAccountDisplayName: null,
    bungieAccountAvatarUrl: null,
    bungieMarathonMembershipId: null,
    discord: null,
    memberships: <LinkStatusMembership>[],
  );

  factory LinkStatus.fromMap(Map<String, dynamic> map) {
    dynamic discordRaw = map['discord'];
    dynamic bungieRaw = map['bungie'];

    LinkStatusDiscord? discord;
    if (discordRaw is Map<String, dynamic>) {
      discord = LinkStatusDiscord.fromMap(discordRaw);
    }

    List<LinkStatusMembership> memberships = <LinkStatusMembership>[];
    String? bungieAccountId;
    String? bungieAccountDisplayName;
    String? bungieAccountAvatarUrl;
    String? bungieMarathonMembershipId;
    if (bungieRaw is Map<String, dynamic>) {
      bungieAccountId = bungieRaw['accountId'] as String?;
      bungieAccountDisplayName = bungieRaw['displayName'] as String?;
      bungieAccountAvatarUrl = bungieRaw['avatarUrl'] as String?;
      bungieMarathonMembershipId = bungieRaw['marathonMembershipId'] as String?;
      dynamic rawMemberships = bungieRaw['memberships'];
      if (rawMemberships is List<dynamic>) {
        for (dynamic raw in rawMemberships) {
          if (raw is Map<String, dynamic>) {
            memberships.add(LinkStatusMembership.fromMap(raw));
          }
        }
      }
    }

    return LinkStatus(
      featureEnabled: (map['featureEnabled'] as bool?) ?? true,
      authenticated: (map['authenticated'] as bool?) ?? false,
      sessionAuthenticated: (map['sessionAuthenticated'] as bool?) ?? false,
      discordConnected: (map['discordConnected'] as bool?) ?? false,
      bungieConnected: (map['bungieConnected'] as bool?) ?? false,
      accountLinkId: map['accountLinkId'] as String?,
      resumeToken: map['resumeToken'] as String?,
      bungieAccountId: bungieAccountId,
      bungieAccountDisplayName: bungieAccountDisplayName,
      bungieAccountAvatarUrl: bungieAccountAvatarUrl,
      bungieMarathonMembershipId: bungieMarathonMembershipId,
      discord: discord,
      memberships: memberships,
    );
  }
}

class LinkStatusService {
  static const Duration _statusRequestTimeout = Duration(seconds: 2);

  static String authUrl(String path, {String? resumeToken}) =>
      _resolveUri(_pathWithResume(path, resumeToken)).toString();

  static Future<LinkStatus> fetchStatus({String? resumeToken}) async {
    try {
      Uri uri = _resolveUri('/api/public/link/status');
      network('link_status_fetch_begin uri=$uri');
      http.Response response = await http
          .get(uri, headers: _headers(resumeToken))
          .timeout(_statusRequestTimeout);
      network('link_status_fetch_response status=${response.statusCode}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        warn('link_status_fetch_non_success status=${response.statusCode}');
        return LinkStatus.fallback;
      }

      String body = response.body.trimLeft();
      if (body.startsWith('<')) {
        warn('link_status_fetch_html_response');
        return LinkStatus.fallback;
      }

      dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        warn('link_status_fetch_invalid_json_shape');
        return LinkStatus.fallback;
      }

      LinkStatus status = LinkStatus.fromMap(decoded);
      verbose(
        'link_status_fetch_done authenticated=${status.authenticated} bungieConnected=${status.bungieConnected} discordConnected=${status.discordConnected} accountLinkId=${status.accountLinkId}',
      );
      return status;
    } catch (e) {
      error('link_status_fetch_error err=$e');
      return LinkStatus.fallback;
    }
  }

  static Future<void> logout() async {
    Uri uri = _resolveUri('/auth/logout');
    network('link_logout_begin uri=$uri');
    http.Response response = await http.post(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );
    network('link_logout_response status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      error('link_logout_failed status=${response.statusCode}');
      throw StateError('Logout failed: ${response.statusCode}');
    }
    info('link_logout_success');
  }

  static Future<void> deleteAccount({String? resumeToken}) async {
    Uri uri = _resolveUri(_pathWithResume('/auth/account', resumeToken));
    network('link_delete_begin uri=$uri');
    http.Response response = await http.delete(
      uri,
      headers: _headers(resumeToken),
    );
    network('link_delete_response status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      error('link_delete_failed status=${response.statusCode}');
      throw StateError('Delete failed: ${response.statusCode}');
    }
    info('link_delete_success');
  }

  static Uri _resolveUri(String path) {
    String baseUrl = _serverBaseUrl();
    verbose(
      'link_resolve_uri path=$path base=${baseUrl.isEmpty ? 'same-origin' : baseUrl}',
    );
    if (baseUrl.isEmpty) {
      return Uri.parse(path);
    }
    return Uri.parse('$baseUrl$path');
  }

  static Map<String, String> _headers(String? resumeToken) {
    Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
    };
    if (resumeToken != null && resumeToken.isNotEmpty) {
      headers['x-rac-link-resume'] = resumeToken;
    }
    return headers;
  }

  static String _pathWithResume(String path, String? resumeToken) {
    if (resumeToken == null || resumeToken.isEmpty) {
      return path;
    }

    Uri uri = Uri.parse(path);
    Map<String, String> nextQuery = <String, String>{
      ...uri.queryParameters,
      'resume': resumeToken,
    };
    return uri.replace(queryParameters: nextQuery).toString();
  }

  static String _serverBaseUrl() {
    String configured = ApiConfig.serverApiUrl;
    if (configured.isNotEmpty) {
      return configured;
    }

    return '';
  }
}
