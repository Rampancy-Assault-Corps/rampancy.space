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
      return _jsonResponse(_unauthenticated(featureEnabled: false));
    }

    OAuthSecurityService? currentSecurity = security;
    if (currentSecurity == null) {
      return Response.internalServerError();
    }

    String? token = _cookieValue(request, 'rac_session');
    SessionPayload? session = token == null || token.isEmpty
        ? null
        : await currentSecurity.verifySessionToken(token);
    if (token != null && token.isNotEmpty && session == null) {
      warn('public_link_status_session_invalid');
    }

    String? resumeToken = _resumeToken(request);
    LinkResumePayload? resume =
        session == null && resumeToken != null && resumeToken.isNotEmpty
        ? await currentSecurity.verifyLinkResumeToken(resumeToken)
        : null;

    String? requestedAccountLinkId =
        session?.accountLinkId ?? resume?.accountLinkId;
    AccountLinkIdResolution? resolution = await links.resolveAccountLinkId(
      requestedAccountLinkId,
    );
    String? canonicalAccountLinkId = resolution?.canonicalAccountLinkId;
    if (canonicalAccountLinkId == null || canonicalAccountLinkId.isEmpty) {
      verbose('public_link_status_no_session');
      return _jsonResponse(_unauthenticated());
    }

    AccountLinkStatus status = await links.getStatus(canonicalAccountLinkId);
    AccountLink? link = status.link;
    if (link == null) {
      warn(
        'public_link_status_missing_account_link accountLinkId=$canonicalAccountLinkId',
      );
      return _jsonResponse(_unauthenticated());
    }

    String nextResumeToken = await currentSecurity.createLinkResumeToken(
      accountLinkId: canonicalAccountLinkId,
    );
    String? cookie = await _maybeRefreshSessionCookie(
      request: request,
      security: currentSecurity,
      session: session,
      resolution: resolution,
      link: link,
    );
    String? discordId = link.discordId ?? session?.discordId;
    String? discordUsername = link.discordUsername ?? session?.discordUsername;
    String? discordGlobalName =
        link.discordGlobalName ?? session?.discordGlobalName;
    String? discordAvatarHash =
        link.discordAvatarHash ?? session?.discordAvatarHash;

    List<Map<String, dynamic>> memberships = status.memberships
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

    bool discordConnected =
        discordId != null &&
        discordId.isNotEmpty &&
        discordUsername != null &&
        discordUsername.isNotEmpty;
    bool bungieConnected = link.bungieConnected;

    Map<String, dynamic> payload = <String, dynamic>{
      'featureEnabled': true,
      'authenticated': true,
      'sessionAuthenticated': session != null,
      'accountLinkId': canonicalAccountLinkId,
      'resumeToken': nextResumeToken,
      'discordConnected': discordConnected,
      'bungieConnected': bungieConnected,
      'discord': discordConnected
          ? <String, dynamic>{
              'id': discordId,
              'username': discordUsername,
              'globalName': discordGlobalName,
              'avatarUrl': _discordAvatarUrl(discordId, discordAvatarHash),
            }
          : null,
      'bungie': <String, dynamic>{
        'accountId': link.bungieAccountId,
        'displayName': link.bungieDisplayName,
        'avatarUrl': _bungieAvatarUrl(link.bungieAvatarPath),
        'marathonMembershipId': link.bungieMarathonMembershipId,
        'membershipCount': memberships.length,
        'memberships': memberships,
      },
    };
    info(
      'public_link_status_resolved requestedAccountLinkId=$requestedAccountLinkId canonicalAccountLinkId=$canonicalAccountLinkId discordConnected=$discordConnected bungieConnected=$bungieConnected memberships=${memberships.length} sessionAuthenticated=${session != null}',
    );

    return _jsonResponse(payload, cookie: cookie);
  }

  String? _cookieValue(Request request, String key) {
    String? cookieHeader = request.headers['cookie'];
    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }

    List<String> segments = cookieHeader.split(';');
    for (String rawSegment in segments) {
      String segment = rawSegment.trim();
      int idx = segment.indexOf('=');
      if (idx <= 0) {
        continue;
      }

      String name = segment.substring(0, idx).trim();
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

  Future<String?> _maybeRefreshSessionCookie({
    required Request request,
    required OAuthSecurityService security,
    required SessionPayload? session,
    required AccountLinkIdResolution? resolution,
    required AccountLink link,
  }) async {
    if (session == null || resolution == null || !resolution.aliased) {
      return null;
    }

    bool secure = request.requestedUri.scheme == 'https';
    String securePart = secure ? '; Secure' : '';
    String? discordId = link.discordId ?? session.discordId;
    String? discordUsername = link.discordUsername ?? session.discordUsername;
    String? discordGlobalName =
        link.discordGlobalName ?? session.discordGlobalName;
    String? discordAvatarHash =
        link.discordAvatarHash ?? session.discordAvatarHash;
    String token = await security.createSessionToken(
      accountLinkId: resolution.canonicalAccountLinkId,
      discordId: discordId,
      discordUsername: discordUsername,
      discordGlobalName: discordGlobalName,
      discordAvatarHash: discordAvatarHash,
    );
    return 'rac_session=$token; Path=/; HttpOnly; SameSite=Lax; Max-Age=${security.sessionMaxAgeSeconds}$securePart';
  }

  String? _discordAvatarUrl(String discordId, String? avatarHash) {
    if (avatarHash == null || avatarHash.isEmpty) {
      return null;
    }

    return 'https://cdn.discordapp.com/avatars/$discordId/$avatarHash.png';
  }

  String? _bungieAvatarUrl(String? avatarPath) {
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    if (avatarPath.startsWith('http')) {
      return avatarPath;
    }
    return 'https://www.bungie.net$avatarPath';
  }

  Map<String, dynamic> _unauthenticated({bool featureEnabled = true}) {
    return <String, dynamic>{
      'featureEnabled': featureEnabled,
      'authenticated': false,
      'sessionAuthenticated': false,
      'accountLinkId': null,
      'resumeToken': null,
      'discordConnected': false,
      'bungieConnected': false,
      'discord': null,
      'bungie': <String, dynamic>{
        'accountId': null,
        'displayName': null,
        'avatarUrl': null,
        'marathonMembershipId': null,
        'membershipCount': 0,
        'memberships': <dynamic>[],
      },
    };
  }

  Response _jsonResponse(Map<String, dynamic> payload, {String? cookie}) {
    Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (cookie != null && cookie.isNotEmpty) {
      headers['Set-Cookie'] = cookie;
    }

    return Response.ok(jsonEncode(payload), headers: headers);
  }
}
