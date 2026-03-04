import 'dart:convert';

import 'package:http/http.dart' as http;

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
  final bool discordConnected;
  final bool bungieConnected;
  final LinkStatusDiscord? discord;
  final List<LinkStatusMembership> memberships;

  const LinkStatus({
    required this.featureEnabled,
    required this.authenticated,
    required this.discordConnected,
    required this.bungieConnected,
    required this.discord,
    required this.memberships,
  });

  factory LinkStatus.fromMap(Map<String, dynamic> map) {
    final dynamic discordRaw = map['discord'];
    final dynamic bungieRaw = map['bungie'];

    LinkStatusDiscord? discord;
    if (discordRaw is Map<String, dynamic>) {
      discord = LinkStatusDiscord.fromMap(discordRaw);
    }

    final List<LinkStatusMembership> memberships = <LinkStatusMembership>[];
    if (bungieRaw is Map<String, dynamic>) {
      final dynamic rawMemberships = bungieRaw['memberships'];
      if (rawMemberships is List<dynamic>) {
        for (final dynamic raw in rawMemberships) {
          if (raw is Map<String, dynamic>) {
            memberships.add(LinkStatusMembership.fromMap(raw));
          }
        }
      }
    }

    return LinkStatus(
      featureEnabled: (map['featureEnabled'] as bool?) ?? true,
      authenticated: (map['authenticated'] as bool?) ?? false,
      discordConnected: (map['discordConnected'] as bool?) ?? false,
      bungieConnected: (map['bungieConnected'] as bool?) ?? false,
      discord: discord,
      memberships: memberships,
    );
  }
}

class LinkStatusService {
  static Future<LinkStatus> fetchStatus() async {
    final Uri uri = Uri.parse('/api/public/link/status');
    final http.Response response = await http.get(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Status endpoint failed: ${response.statusCode}');
    }

    final dynamic decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Status endpoint returned invalid JSON object.');
    }

    return LinkStatus.fromMap(decoded);
  }

  static Future<void> logout() async {
    final Uri uri = Uri.parse('/auth/logout');
    final http.Response response = await http.post(
      uri,
      headers: <String, String>{'Accept': 'application/json'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Logout failed: ${response.statusCode}');
    }
  }
}
