import 'dart:convert';
import 'dart:io';

class AccountLinkingConfig {
  final bool enabled;
  final String discordClientId;
  final String discordClientSecret;
  final String discordRedirectUri;
  final String bungieClientId;
  final String bungieClientSecret;
  final String bungieRedirectUri;
  final String bungieApiKey;
  final String sessionSigningKeyBase64;
  final String oauthStateSigningKeyBase64;
  final String tokenEncryptionKeyBase64;
  final int sessionMaxAgeSeconds;
  final int oauthStateMaxAgeSeconds;

  const AccountLinkingConfig({
    required this.enabled,
    required this.discordClientId,
    required this.discordClientSecret,
    required this.discordRedirectUri,
    required this.bungieClientId,
    required this.bungieClientSecret,
    required this.bungieRedirectUri,
    required this.bungieApiKey,
    required this.sessionSigningKeyBase64,
    required this.oauthStateSigningKeyBase64,
    required this.tokenEncryptionKeyBase64,
    required this.sessionMaxAgeSeconds,
    required this.oauthStateMaxAgeSeconds,
  });

  factory AccountLinkingConfig.fromEnvironment() {
    final Map<String, String> env = Platform.environment;
    final bool enabled = _parseBool(env['ENABLE_ACCOUNT_LINKING']);

    if (!enabled) {
      return const AccountLinkingConfig(
        enabled: false,
        discordClientId: '',
        discordClientSecret: '',
        discordRedirectUri: '',
        bungieClientId: '',
        bungieClientSecret: '',
        bungieRedirectUri: '',
        bungieApiKey: '',
        sessionSigningKeyBase64: '',
        oauthStateSigningKeyBase64: '',
        tokenEncryptionKeyBase64: '',
        sessionMaxAgeSeconds: 86400,
        oauthStateMaxAgeSeconds: 600,
      );
    }

    final List<String> missing = <String>[];

    final String discordClientId = _required(env, 'DISCORD_CLIENT_ID', missing);
    final String discordClientSecret = _required(
      env,
      'DISCORD_CLIENT_SECRET',
      missing,
    );
    final String discordRedirectUri = _required(
      env,
      'DISCORD_REDIRECT_URI',
      missing,
    );
    final String bungieClientId = _required(env, 'BUNGIE_CLIENT_ID', missing);
    final String bungieClientSecret = _required(
      env,
      'BUNGIE_CLIENT_SECRET',
      missing,
    );
    final String bungieRedirectUri = _required(
      env,
      'BUNGIE_REDIRECT_URI',
      missing,
    );
    final String bungieApiKey = _required(env, 'BUNGIE_API_KEY', missing);
    final String sessionSigningKeyBase64 = _required(
      env,
      'SESSION_SIGNING_KEY_BASE64',
      missing,
    );
    final String tokenEncryptionKeyBase64 = _required(
      env,
      'TOKEN_ENCRYPTION_KEY_BASE64',
      missing,
    );
    final String oauthStateSigningKeyBase64 =
        env['OAUTH_STATE_SIGNING_KEY_BASE64'] ?? sessionSigningKeyBase64;

    if (missing.isNotEmpty) {
      throw StateError(
        'ENABLE_ACCOUNT_LINKING=true but missing required env vars: ${missing.join(', ')}',
      );
    }

    _requireKeyLength(sessionSigningKeyBase64, 'SESSION_SIGNING_KEY_BASE64');
    _requireKeyLength(
      oauthStateSigningKeyBase64,
      'OAUTH_STATE_SIGNING_KEY_BASE64',
    );
    _requireKeyLength(tokenEncryptionKeyBase64, 'TOKEN_ENCRYPTION_KEY_BASE64');

    final int sessionMaxAgeSeconds =
        int.tryParse(env['RAC_SESSION_MAX_AGE_SECONDS'] ?? '') ?? 86400;
    final int oauthStateMaxAgeSeconds =
        int.tryParse(env['RAC_OAUTH_STATE_MAX_AGE_SECONDS'] ?? '') ?? 600;

    return AccountLinkingConfig(
      enabled: true,
      discordClientId: discordClientId,
      discordClientSecret: discordClientSecret,
      discordRedirectUri: discordRedirectUri,
      bungieClientId: bungieClientId,
      bungieClientSecret: bungieClientSecret,
      bungieRedirectUri: bungieRedirectUri,
      bungieApiKey: bungieApiKey,
      sessionSigningKeyBase64: sessionSigningKeyBase64,
      oauthStateSigningKeyBase64: oauthStateSigningKeyBase64,
      tokenEncryptionKeyBase64: tokenEncryptionKeyBase64,
      sessionMaxAgeSeconds: sessionMaxAgeSeconds,
      oauthStateMaxAgeSeconds: oauthStateMaxAgeSeconds,
    );
  }

  static bool _parseBool(String? raw) {
    if (raw == null) {
      return false;
    }

    final String value = raw.trim().toLowerCase();
    return value == '1' || value == 'true' || value == 'yes' || value == 'on';
  }

  static String _required(
    Map<String, String> env,
    String key,
    List<String> missing,
  ) {
    final String? value = env[key];
    if (value == null || value.trim().isEmpty) {
      missing.add(key);
      return '';
    }

    return value.trim();
  }

  static void _requireKeyLength(String keyBase64, String keyName) {
    final List<int> bytes = base64Decode(keyBase64);
    if (bytes.length != 32) {
      throw StateError('$keyName must decode to exactly 32 bytes.');
    }
  }
}
