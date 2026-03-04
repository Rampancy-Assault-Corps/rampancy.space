import 'dart:convert';

import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/config/account_linking_config.dart';
import 'package:rampancy_assault_corps_server/main.dart';
import 'package:rampancy_assault_corps_server/service/account_link_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class PublicLinkAPI implements Routing {
  final AccountLinkingConfig config;
  final OAuthSecurityService? security;
  final AccountLinkService links;

  PublicLinkAPI({
    required this.config,
    required this.security,
    required this.links,
  });

  @override
  String get prefix => '/api/public/link';

  @override
  Router get router => Router()..get('/status', _status);

  Future<Response> _status(Request request) async {
    if (!config.enabled) {
      return _jsonResponse(<String, dynamic>{
        'featureEnabled': false,
        'authenticated': false,
        'discordConnected': false,
        'bungieConnected': false,
        'discord': null,
        'bungie': <String, dynamic>{
          'membershipCount': 0,
          'memberships': <dynamic>[],
        },
      });
    }

    final OAuthSecurityService? currentSecurity = security;
    if (currentSecurity == null) {
      return Response.internalServerError();
    }

    final String? token = _cookieValue(request, 'rac_session');
    if (token == null || token.isEmpty) {
      return _jsonResponse(_unauthenticated());
    }

    final SessionPayload? session = await currentSecurity.verifySessionToken(
      token,
    );
    if (session == null) {
      return _jsonResponse(_unauthenticated());
    }

    final AccountLinkStatus status = await links.getStatus(session.discordId);
    final AccountLink? link = status.link;

    final String discordId = link?.discordId ?? session.discordId;
    final String discordUsername =
        link?.discordUsername ?? session.discordUsername;
    final String? discordGlobalName =
        link?.discordGlobalName ?? session.discordGlobalName;
    final String? discordAvatarHash =
        link?.discordAvatarHash ?? session.discordAvatarHash;

    final List<Map<String, dynamic>> memberships = status.memberships
        .map(
          (BungieMembership membership) => <String, dynamic>{
            'membershipId': membership.membershipId,
            'membershipType': membership.membershipType,
            'displayName': membership.displayName,
            'iconPath': membership.iconPath,
            'crossSaveOverride': membership.crossSaveOverride,
            'isPrimary': membership.isPrimary,
          },
        )
        .toList();

    final bool bungieConnected =
        (link?.bungieConnected ?? false) && memberships.isNotEmpty;

    final Map<String, dynamic> payload = <String, dynamic>{
      'featureEnabled': true,
      'authenticated': true,
      'discordConnected': true,
      'bungieConnected': bungieConnected,
      'discord': <String, dynamic>{
        'id': discordId,
        'username': discordUsername,
        'globalName': discordGlobalName,
        'avatarUrl': _avatarUrl(discordId, discordAvatarHash),
      },
      'bungie': <String, dynamic>{
        'membershipCount': memberships.length,
        'memberships': memberships,
      },
    };

    return _jsonResponse(payload);
  }

  String? _cookieValue(Request request, String key) {
    final String? cookieHeader = request.headers['cookie'];
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }

    final List<String> segments = cookieHeader.split(';');
    for (final String rawSegment in segments) {
      final String segment = rawSegment.trim();
      final int idx = segment.indexOf('=');
      if (idx <= 0) {
        continue;
      }

      final String name = segment.substring(0, idx).trim();
      if (name != key) {
        continue;
      }

      return segment.substring(idx + 1).trim();
    }

    return null;
  }

  String? _avatarUrl(String discordId, String? avatarHash) {
    if (avatarHash == null || avatarHash.isEmpty) {
      return null;
    }

    return 'https://cdn.discordapp.com/avatars/$discordId/$avatarHash.png';
  }

  Map<String, dynamic> _unauthenticated() {
    return <String, dynamic>{
      'featureEnabled': true,
      'authenticated': false,
      'discordConnected': false,
      'bungieConnected': false,
      'discord': null,
      'bungie': <String, dynamic>{
        'membershipCount': 0,
        'memberships': <dynamic>[],
      },
    };
  }

  Response _jsonResponse(Map<String, dynamic> payload) {
    return Response.ok(
      jsonEncode(payload),
      headers: <String, String>{'Content-Type': 'application/json'},
    );
  }
}
