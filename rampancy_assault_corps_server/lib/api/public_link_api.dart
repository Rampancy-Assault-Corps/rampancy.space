import 'dart:convert';

import 'package:fast_log/fast_log.dart';
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
    verbose('public_link_status_request path=${request.requestedUri.path}');
    if (!config.enabled) {
      warn('public_link_status_disabled');
      return _jsonResponse(<String, dynamic>{
        'featureEnabled': false,
        'authenticated': false,
        'discordConnected': false,
        'bungieConnected': false,
        'discord': null,
        'bungie': <String, dynamic>{
          'primaryMembershipId': null,
          'primaryMembershipType': null,
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
    final SessionPayload? session = token == null || token.isEmpty
        ? null
        : await currentSecurity.verifySessionToken(token);
    if (token != null && token.isNotEmpty && session == null) {
      warn('public_link_status_session_invalid');
    }

    final String? resumeToken = _resumeToken(request);
    final LinkResumePayload? resume =
        session == null && resumeToken != null && resumeToken.isNotEmpty
        ? await currentSecurity.verifyLinkResumeToken(resumeToken)
        : null;

    final String? accountLinkId =
        session?.accountLinkId ?? resume?.accountLinkId;
    if (accountLinkId == null || accountLinkId.isEmpty) {
      verbose('public_link_status_no_session');
      return _jsonResponse(_unauthenticated());
    }

    final AccountLinkStatus status = await links.getStatus(accountLinkId);
    final AccountLink? link = status.link;
    if (link == null) {
      warn(
        'public_link_status_missing_account_link accountLinkId=$accountLinkId',
      );
      return _jsonResponse(_unauthenticated());
    }

    final String? discordId = link.discordId ?? session?.discordId;
    final String? discordUsername =
        link.discordUsername ?? session?.discordUsername;
    final String? discordGlobalName =
        link.discordGlobalName ?? session?.discordGlobalName;
    final String? discordAvatarHash =
        link.discordAvatarHash ?? session?.discordAvatarHash;

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

    final bool discordConnected =
        discordId != null &&
        discordId.isNotEmpty &&
        discordUsername != null &&
        discordUsername.isNotEmpty;

    final bool bungieConnected = link.bungieConnected;

    final Map<String, dynamic> payload = <String, dynamic>{
      'featureEnabled': true,
      'authenticated': true,
      'sessionAuthenticated': session != null,
      'discordConnected': discordConnected,
      'bungieConnected': bungieConnected,
      'discord': discordConnected
          ? <String, dynamic>{
              'id': discordId,
              'username': discordUsername,
              'globalName': discordGlobalName,
              'avatarUrl': _avatarUrl(discordId, discordAvatarHash),
            }
          : null,
      'bungie': <String, dynamic>{
        'primaryMembershipId': link.bungiePrimaryMembershipId,
        'primaryMembershipType': link.bungiePrimaryMembershipType,
        'membershipCount': memberships.length,
        'memberships': memberships,
      },
    };
    info(
      'public_link_status_resolved accountLinkId=$accountLinkId discordConnected=$discordConnected bungieConnected=$bungieConnected memberships=${memberships.length} sessionAuthenticated=${session != null}',
    );

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

  String? _resumeToken(Request request) {
    String? headerToken = request.headers['x-rac-link-resume'];
    if (headerToken != null && headerToken.isNotEmpty) {
      return headerToken;
    }

    String? queryToken = request.requestedUri.queryParameters['resume'];
    if (queryToken != null && queryToken.isNotEmpty) {
      return queryToken;
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
      'sessionAuthenticated': false,
      'discordConnected': false,
      'bungieConnected': false,
      'discord': null,
      'bungie': <String, dynamic>{
        'primaryMembershipId': null,
        'primaryMembershipType': null,
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
