import 'dart:convert';

import 'package:fast_log/fast_log.dart';
import 'package:rampancy_assault_corps_server/config/account_linking_config.dart';
import 'package:rampancy_assault_corps_server/main.dart';
import 'package:rampancy_assault_corps_server/service/account_link_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_provider_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class OAuthAPI implements Routing {
  final AccountLinkingConfig config;
  final OAuthProviderService provider;
  final OAuthSecurityService security;
  final AccountLinkService links;

  OAuthAPI({
    required this.config,
    required this.provider,
    required this.security,
    required this.links,
  });

  @override
  String get prefix => '/auth';

  @override
  Router get router => Router()
    ..get('/discord/start', _discordStart)
    ..get('/discord/callback', _discordCallback)
    ..get('/bungie/start', _bungieStart)
    ..get('/bungie/callback', _bungieCallback)
    ..post('/logout', _logout);

  Future<Response> _discordStart(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    final String state = await security.createOAuthState(
      provider: 'discord',
      discordId: null,
    );
    final Uri uri = provider.buildDiscordAuthorizeUri(state: state);
    return Response.found(uri.toString());
  }

  Future<Response> _discordCallback(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    final String? code = request.param('code');
    final String? state = request.param('state');

    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return _redirectWithError('discord_callback_invalid');
    }

    final OAuthStatePayload? decodedState = await security.verifyOAuthState(
      token: state,
      provider: 'discord',
    );

    if (decodedState == null) {
      return _redirectWithError('discord_state_invalid');
    }

    try {
      final DiscordProfile profile = await provider
          .exchangeDiscordCodeForProfile(code: code);
      await links.upsertDiscordLink(profile);

      final String session = await security.createSessionToken(
        discordId: profile.id,
        discordUsername: profile.username,
        discordGlobalName: profile.globalName,
        discordAvatarHash: profile.avatarHash,
      );

      final String cookie = _sessionCookie(
        session,
        request,
        security.sessionMaxAgeSeconds,
      );

      info('discord_link_success user=${profile.id}');
      return Response.found(
        '/?linked=discord',
        headers: <String, String>{'Set-Cookie': cookie},
      );
    } catch (e) {
      error('discord_link_failed err=$e');
      return _redirectWithError('discord_link_failed');
    }
  }

  Future<Response> _bungieStart(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    final SessionPayload? session = await _getSession(request);
    if (session == null) {
      return _redirectWithError('discord_required');
    }

    final String state = await security.createOAuthState(
      provider: 'bungie',
      discordId: session.discordId,
    );
    final Uri uri = provider.buildBungieAuthorizeUri(state: state);
    return Response.found(uri.toString());
  }

  Future<Response> _bungieCallback(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    final SessionPayload? session = await _getSession(request);
    if (session == null) {
      return _redirectWithError('discord_required');
    }

    final String? code = request.param('code');
    final String? state = request.param('state');

    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      return _redirectWithError('bungie_callback_invalid');
    }

    final OAuthStatePayload? decodedState = await security.verifyOAuthState(
      token: state,
      provider: 'bungie',
    );

    if (decodedState == null || decodedState.discordId != session.discordId) {
      return _redirectWithError('bungie_state_invalid');
    }

    try {
      final BungieOAuthResult result = await provider.exchangeBungieCode(
        code: code,
      );
      final EncryptedToken encrypted = await security.encryptToken(
        result.refreshToken,
      );

      await links.upsertBungieLink(
        discordId: session.discordId,
        encryptedRefreshToken: encrypted,
        refreshExpiresAt: result.refreshExpiresAt,
        memberships: result.memberships,
      );

      info('bungie_link_success user=${session.discordId}');
      return Response.found('/?linked=bungie');
    } catch (e) {
      error('bungie_link_failed user=${session.discordId} err=$e');
      return _redirectWithError('bungie_link_failed');
    }
  }

  Future<Response> _logout(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    final String cookie = _clearSessionCookie(request);
    final String body = jsonEncode(<String, dynamic>{'ok': true});
    return Response.ok(
      body,
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Set-Cookie': cookie,
      },
    );
  }

  Future<SessionPayload?> _getSession(Request request) async {
    final String? token = _cookieValue(request, 'rac_session');
    if (token == null || token.isEmpty) {
      return null;
    }

    return security.verifySessionToken(token);
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

  String _sessionCookie(String token, Request request, int maxAgeSeconds) {
    final bool secure = request.requestedUri.scheme == 'https';
    final String securePart = secure ? '; Secure' : '';
    return 'rac_session=$token; Path=/; HttpOnly; SameSite=Lax; Max-Age=$maxAgeSeconds$securePart';
  }

  String _clearSessionCookie(Request request) {
    final bool secure = request.requestedUri.scheme == 'https';
    final String securePart = secure ? '; Secure' : '';
    return 'rac_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0$securePart';
  }

  Response _redirectWithError(String code) {
    return Response.found('/?error=$code');
  }
}
