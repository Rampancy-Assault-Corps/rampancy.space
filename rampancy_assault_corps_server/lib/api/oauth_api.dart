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
  final OAuthProviderService? provider;
  final OAuthSecurityService? security;
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
    ..delete('/account', _deleteAccount)
    ..post('/logout', _logout);

  Future<Response> _discordStart(Request request) async {
    if (!config.enabled) {
      return _redirectWithError('discord_not_configured');
    }

    final OAuthSecurityService? currentSecurity = security;
    final OAuthProviderService? currentProvider = provider;
    if (currentSecurity == null || currentProvider == null) {
      return _redirectWithError('discord_not_configured');
    }

    info('oauth_discord_start path=${request.requestedUri.path}');
    SessionPayload? session = await _getSession(request);
    verbose('oauth_discord_start hasSession=${session != null}');
    if (session == null) {
      warn('oauth_discord_start_missing_bungie_session');
      return _redirectWithError('discord_requires_bungie');
    }

    AccountLinkStatus status = await links.getStatus(session.accountLinkId);
    if (!status.bungieConnected || status.link == null) {
      warn(
        'oauth_discord_start_missing_bungie_link accountLinkId=${session.accountLinkId}',
      );
      return _redirectWithError('discord_requires_bungie');
    }

    final String state = await currentSecurity.createOAuthState(
      provider: 'discord',
      accountLinkId: session.accountLinkId,
    );
    final Uri uri = currentProvider.buildDiscordAuthorizeUri(state: state);
    network('oauth_discord_start_redirect host=${uri.host} path=${uri.path}');
    return Response.found(uri.toString());
  }

  Future<Response> _discordCallback(Request request) async {
    if (!config.enabled) {
      return _redirectWithError('discord_not_configured');
    }

    final OAuthSecurityService? currentSecurity = security;
    final OAuthProviderService? currentProvider = provider;
    if (currentSecurity == null || currentProvider == null) {
      return _redirectWithError('discord_not_configured');
    }

    final String? code = request.param('code');
    final String? state = request.param('state');
    final String? providerError = request.param('error');
    final String? providerErrorDescription = request.param('error_description');

    info('oauth_discord_callback path=${request.requestedUri.path}');
    verbose(
      'oauth_discord_callback hasCode=${code != null && code.isNotEmpty} hasState=${state != null && state.isNotEmpty} providerError=$providerError',
    );

    if (providerError != null && providerError.isNotEmpty) {
      warn(
        'oauth_discord_callback_provider_error error=$providerError description=$providerErrorDescription',
      );
      return _redirectWithError('discord_provider_error');
    }

    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      warn('oauth_discord_callback_invalid_query');
      return _redirectWithError('discord_callback_invalid');
    }

    final OAuthStatePayload? decodedState = await currentSecurity
        .verifyOAuthState(token: state, provider: 'discord');

    if (decodedState == null) {
      warn('oauth_discord_callback_state_invalid');
      return _redirectWithError('discord_state_invalid');
    }
    verbose(
      'oauth_discord_callback_state_valid accountLinkId=${decodedState.accountLinkId}',
    );

    String? accountLinkId = decodedState.accountLinkId;
    if (accountLinkId == null || accountLinkId.isEmpty) {
      warn('oauth_discord_callback_missing_bungie_account_link');
      return _redirectWithError('discord_requires_bungie');
    }

    AccountLinkStatus status = await links.getStatus(accountLinkId);
    if (!status.bungieConnected || status.link == null) {
      warn(
        'oauth_discord_callback_missing_bungie_link accountLinkId=$accountLinkId',
      );
      return _redirectWithError('discord_requires_bungie');
    }

    try {
      final DiscordProfile profile = await currentProvider
          .exchangeDiscordCodeForProfile(code: code);
      AccountLinkRecord link = await links.upsertDiscordLink(
        profile: profile,
        accountLinkId: accountLinkId,
      );

      final String session = await currentSecurity.createSessionToken(
        accountLinkId: link.accountLinkId,
        discordId: link.link.discordId,
        discordUsername: link.link.discordUsername,
        discordGlobalName: link.link.discordGlobalName,
        discordAvatarHash: link.link.discordAvatarHash,
      );

      final String cookie = _sessionCookie(
        session,
        request,
        currentSecurity.sessionMaxAgeSeconds,
      );
      verbose(
        'oauth_discord_callback_cookie_issued maxAge=${currentSecurity.sessionMaxAgeSeconds}',
      );

      info('discord_link_success accountLinkId=${link.accountLinkId}');
      return Response.found(
        '/link?linked=discord',
        headers: <String, String>{'Set-Cookie': cookie},
      );
    } catch (e) {
      error('discord_link_failed err=$e');
      return _redirectWithError('discord_link_failed');
    }
  }

  Future<Response> _bungieStart(Request request) async {
    if (!config.enabled) {
      return _redirectWithError('bungie_not_configured');
    }

    final OAuthSecurityService? currentSecurity = security;
    final OAuthProviderService? currentProvider = provider;
    if (currentSecurity == null || currentProvider == null) {
      return _redirectWithError('bungie_not_configured');
    }

    info('oauth_bungie_start path=${request.requestedUri.path}');
    final SessionPayload? session = await _getSession(request);
    verbose('oauth_bungie_start hasSession=${session != null}');
    final String state = await currentSecurity.createOAuthState(
      provider: 'bungie',
      accountLinkId: session?.accountLinkId,
    );
    final Uri uri = currentProvider.buildBungieAuthorizeUri(state: state);
    network('oauth_bungie_start_redirect host=${uri.host} path=${uri.path}');
    return Response.found(uri.toString());
  }

  Future<Response> _bungieCallback(Request request) async {
    if (!config.enabled) {
      return _redirectWithError('bungie_not_configured');
    }

    final OAuthSecurityService? currentSecurity = security;
    final OAuthProviderService? currentProvider = provider;
    if (currentSecurity == null || currentProvider == null) {
      return _redirectWithError('bungie_not_configured');
    }

    final String? code = request.param('code');
    final String? state = request.param('state');
    final String? providerError = request.param('error');
    final String? providerErrorDescription = request.param('error_description');

    info('oauth_bungie_callback path=${request.requestedUri.path}');
    verbose(
      'oauth_bungie_callback hasCode=${code != null && code.isNotEmpty} hasState=${state != null && state.isNotEmpty} providerError=$providerError',
    );

    if (providerError != null && providerError.isNotEmpty) {
      warn(
        'oauth_bungie_callback_provider_error error=$providerError description=$providerErrorDescription',
      );
      return _redirectWithError('bungie_provider_error');
    }

    if (code == null || code.isEmpty || state == null || state.isEmpty) {
      warn('oauth_bungie_callback_invalid_query');
      return _redirectWithError('bungie_callback_invalid');
    }

    final OAuthStatePayload? decodedState = await currentSecurity
        .verifyOAuthState(token: state, provider: 'bungie');

    if (decodedState == null) {
      warn('oauth_bungie_callback_state_invalid');
      return _redirectWithError('bungie_state_invalid');
    }
    verbose(
      'oauth_bungie_callback_state_valid accountLinkId=${decodedState.accountLinkId}',
    );

    SessionPayload? session = await _getSession(request);
    if (session != null &&
        decodedState.accountLinkId != null &&
        decodedState.accountLinkId != session.accountLinkId) {
      warn(
        'oauth_bungie_callback_state_mismatch session=${session.accountLinkId} state=${decodedState.accountLinkId}',
      );
      return _redirectWithError('bungie_state_invalid');
    }

    String? accountLinkId =
        decodedState.accountLinkId ?? session?.accountLinkId;

    try {
      final BungieOAuthResult result = await currentProvider.exchangeBungieCode(
        code: code,
      );
      final EncryptedToken encrypted = await currentSecurity.encryptToken(
        result.refreshToken,
      );

      AccountLinkRecord link = await links.upsertBungieLink(
        accountLinkId: accountLinkId,
        encryptedRefreshToken: encrypted,
        refreshExpiresAt: result.refreshExpiresAt,
        memberships: result.memberships,
      );

      String newSession = await currentSecurity.createSessionToken(
        accountLinkId: link.accountLinkId,
        discordId: link.link.discordId,
        discordUsername: link.link.discordUsername,
        discordGlobalName: link.link.discordGlobalName,
        discordAvatarHash: link.link.discordAvatarHash,
      );
      String cookie = _sessionCookie(
        newSession,
        request,
        currentSecurity.sessionMaxAgeSeconds,
      );
      verbose(
        'oauth_bungie_callback_cookie_issued maxAge=${currentSecurity.sessionMaxAgeSeconds}',
      );

      info('bungie_link_success accountLinkId=${link.accountLinkId}');
      return Response.found(
        '/link?linked=bungie',
        headers: <String, String>{'Set-Cookie': cookie},
      );
    } catch (e) {
      error('bungie_link_failed accountLinkId=$accountLinkId err=$e');
      return _redirectWithError('bungie_link_failed');
    }
  }

  Future<Response> _deleteAccount(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    info('oauth_delete_account path=${request.requestedUri.path}');
    SessionPayload? session = await _getSession(request);
    String cookie = _clearSessionCookie(request);
    if (session == null) {
      warn('oauth_delete_account_missing_session');
      return Response.forbidden(
        jsonEncode(<String, dynamic>{'ok': false, 'error': 'unauthorized'}),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Set-Cookie': cookie,
        },
      );
    }

    try {
      await links.deleteAccountLink(session.accountLinkId);
      info('oauth_delete_account_done accountLinkId=${session.accountLinkId}');
      return Response.ok(
        jsonEncode(<String, dynamic>{'ok': true}),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Set-Cookie': cookie,
        },
      );
    } catch (e) {
      error(
        'oauth_delete_account_failed accountLinkId=${session.accountLinkId} err=$e',
      );
      return Response.internalServerError(
        body: jsonEncode(<String, dynamic>{
          'ok': false,
          'error': 'delete_failed',
        }),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Set-Cookie': cookie,
        },
      );
    }
  }

  Future<Response> _logout(Request request) async {
    if (!config.enabled) {
      return Response.notFound('Not Found');
    }

    info('oauth_logout path=${request.requestedUri.path}');
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
    final OAuthSecurityService? currentSecurity = security;
    if (currentSecurity == null) {
      verbose('oauth_session_security_unavailable');
      return null;
    }

    final String? token = _cookieValue(request, 'rac_session');
    if (token == null || token.isEmpty) {
      verbose('oauth_session_missing_cookie');
      return null;
    }

    SessionPayload? session = await currentSecurity.verifySessionToken(token);
    verbose('oauth_session_verified=${session != null}');
    return session;
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
    return Response.found('/link?error=$code');
  }
}
