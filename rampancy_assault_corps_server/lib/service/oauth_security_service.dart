import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';
import 'package:rampancy_assault_corps_server/config/account_linking_config.dart';

class SessionPayload {
  final String accountLinkId;
  final String? discordId;
  final String? discordUsername;
  final String? discordGlobalName;
  final String? discordAvatarHash;
  final int issuedAt;
  final int expiresAt;

  const SessionPayload({
    required this.accountLinkId,
    required this.discordId,
    required this.discordUsername,
    required this.discordGlobalName,
    required this.discordAvatarHash,
    required this.issuedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'accountLinkId': accountLinkId,
    'discordId': discordId,
    'discordUsername': discordUsername,
    'discordGlobalName': discordGlobalName,
    'discordAvatarHash': discordAvatarHash,
    'issuedAt': issuedAt,
    'expiresAt': expiresAt,
  };

  factory SessionPayload.fromMap(Map<String, dynamic> map) {
    String? accountLinkId = map['accountLinkId'] as String?;
    int? issuedAt = _asInt(map['issuedAt']);
    int? expiresAt = _asInt(map['expiresAt']);
    if (accountLinkId == null ||
        accountLinkId.isEmpty ||
        issuedAt == null ||
        expiresAt == null) {
      throw StateError('Invalid session payload.');
    }

    return SessionPayload(
      accountLinkId: accountLinkId,
      discordId: _asNullableString(map['discordId']),
      discordUsername: _asNullableString(map['discordUsername']),
      discordGlobalName: _asNullableString(map['discordGlobalName']),
      discordAvatarHash: _asNullableString(map['discordAvatarHash']),
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }

  static String? _asNullableString(dynamic value) {
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return null;
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

class OAuthStatePayload {
  final String provider;
  final String nonce;
  final int issuedAt;
  final int expiresAt;
  final String? accountLinkId;

  const OAuthStatePayload({
    required this.provider,
    required this.nonce,
    required this.issuedAt,
    required this.expiresAt,
    required this.accountLinkId,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'provider': provider,
    'nonce': nonce,
    'issuedAt': issuedAt,
    'expiresAt': expiresAt,
    'accountLinkId': accountLinkId,
  };

  factory OAuthStatePayload.fromMap(Map<String, dynamic> map) {
    String? provider = map['provider'] as String?;
    String? nonce = map['nonce'] as String?;
    int? issuedAt = SessionPayload._asInt(map['issuedAt']);
    int? expiresAt = SessionPayload._asInt(map['expiresAt']);
    if (provider == null ||
        provider.isEmpty ||
        nonce == null ||
        nonce.isEmpty ||
        issuedAt == null ||
        expiresAt == null) {
      throw StateError('Invalid OAuth state payload.');
    }

    return OAuthStatePayload(
      provider: provider,
      nonce: nonce,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      accountLinkId: SessionPayload._asNullableString(map['accountLinkId']),
    );
  }
}

class LinkResumePayload {
  final String accountLinkId;
  final int issuedAt;
  final int expiresAt;

  const LinkResumePayload({
    required this.accountLinkId,
    required this.issuedAt,
    required this.expiresAt,
  });

  Map<String, dynamic> toMap() => <String, dynamic>{
    'accountLinkId': accountLinkId,
    'issuedAt': issuedAt,
    'expiresAt': expiresAt,
  };

  factory LinkResumePayload.fromMap(Map<String, dynamic> map) {
    String? accountLinkId = map['accountLinkId'] as String?;
    int? issuedAt = SessionPayload._asInt(map['issuedAt']);
    int? expiresAt = SessionPayload._asInt(map['expiresAt']);
    if (accountLinkId == null ||
        accountLinkId.isEmpty ||
        issuedAt == null ||
        expiresAt == null) {
      throw StateError('Invalid link resume payload.');
    }

    return LinkResumePayload(
      accountLinkId: accountLinkId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
    );
  }
}

class EncryptedToken {
  final String ciphertext;
  final String nonce;

  const EncryptedToken({required this.ciphertext, required this.nonce});
}

class OAuthSecurityService {
  final Hmac _hmac;
  final AesGcm _aesGcm;
  final SecretKey _sessionKey;
  final SecretKey _stateKey;
  final SecretKey _tokenKey;
  final Random _random;
  final int _sessionMaxAgeSeconds;
  final int _oauthStateMaxAgeSeconds;

  OAuthSecurityService(AccountLinkingConfig config)
    : _hmac = Hmac.sha256(),
      _aesGcm = AesGcm.with256bits(),
      _sessionKey = SecretKey(base64Decode(config.sessionSigningKeyBase64)),
      _stateKey = SecretKey(base64Decode(config.oauthStateSigningKeyBase64)),
      _tokenKey = SecretKey(base64Decode(config.tokenEncryptionKeyBase64)),
      _random = Random.secure(),
      _sessionMaxAgeSeconds = config.sessionMaxAgeSeconds,
      _oauthStateMaxAgeSeconds = config.oauthStateMaxAgeSeconds;

  int get sessionMaxAgeSeconds => _sessionMaxAgeSeconds;

  Future<String> createSessionToken({
    required String accountLinkId,
    required String? discordId,
    required String? discordUsername,
    required String? discordGlobalName,
    required String? discordAvatarHash,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int expiresAt = now + (_sessionMaxAgeSeconds * 1000);
    final SessionPayload payload = SessionPayload(
      accountLinkId: accountLinkId,
      discordId: discordId,
      discordUsername: discordUsername,
      discordGlobalName: discordGlobalName,
      discordAvatarHash: discordAvatarHash,
      issuedAt: now,
      expiresAt: expiresAt,
    );
    return _sign(payload.toMap(), _sessionKey);
  }

  Future<SessionPayload?> verifySessionToken(String token) async {
    final Map<String, dynamic>? map = await _verify(token, _sessionKey);
    if (map == null) {
      return null;
    }

    SessionPayload payload;
    try {
      payload = SessionPayload.fromMap(map);
    } catch (_) {
      return null;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (payload.expiresAt < now) {
      return null;
    }

    return payload;
  }

  Future<String> createOAuthState({
    required String provider,
    required String? accountLinkId,
  }) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int expiresAt = now + (_oauthStateMaxAgeSeconds * 1000);
    final OAuthStatePayload payload = OAuthStatePayload(
      provider: provider,
      nonce: _randomToken(20),
      issuedAt: now,
      expiresAt: expiresAt,
      accountLinkId: accountLinkId,
    );
    return _sign(payload.toMap(), _stateKey);
  }

  Future<OAuthStatePayload?> verifyOAuthState({
    required String token,
    required String provider,
  }) async {
    final Map<String, dynamic>? map = await _verify(token, _stateKey);
    if (map == null) {
      return null;
    }

    OAuthStatePayload payload;
    try {
      payload = OAuthStatePayload.fromMap(map);
    } catch (_) {
      return null;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (payload.provider != provider) {
      return null;
    }
    if (payload.expiresAt < now) {
      return null;
    }

    return payload;
  }

  Future<String> createLinkResumeToken({required String accountLinkId}) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int expiresAt = now + (_sessionMaxAgeSeconds * 1000);
    final LinkResumePayload payload = LinkResumePayload(
      accountLinkId: accountLinkId,
      issuedAt: now,
      expiresAt: expiresAt,
    );
    return _sign(payload.toMap(), _stateKey);
  }

  Future<LinkResumePayload?> verifyLinkResumeToken(String token) async {
    final Map<String, dynamic>? map = await _verify(token, _stateKey);
    if (map == null) {
      return null;
    }

    LinkResumePayload payload;
    try {
      payload = LinkResumePayload.fromMap(map);
    } catch (_) {
      return null;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (payload.expiresAt < now) {
      return null;
    }

    return payload;
  }

  Future<EncryptedToken> encryptToken(String plaintext) async {
    final List<int> nonce = _randomBytes(12);
    final SecretBox box = await _aesGcm.encrypt(
      utf8.encode(plaintext),
      secretKey: _tokenKey,
      nonce: nonce,
    );

    final List<int> packed = <int>[...box.cipherText, ...box.mac.bytes];

    return EncryptedToken(
      ciphertext: base64UrlEncode(packed),
      nonce: base64UrlEncode(nonce),
    );
  }

  Future<String> _sign(Map<String, dynamic> payload, SecretKey key) async {
    final String encodedPayload = base64UrlEncode(
      utf8.encode(jsonEncode(payload)),
    );
    final Mac mac = await _hmac.calculateMac(
      utf8.encode(encodedPayload),
      secretKey: key,
    );
    final String signature = base64UrlEncode(mac.bytes);
    return '$encodedPayload.$signature';
  }

  Future<Map<String, dynamic>?> _verify(String value, SecretKey key) async {
    final List<String> parts = value.split('.');
    if (parts.length != 2) {
      return null;
    }

    final String encodedPayload = parts[0];
    final String encodedSignature = parts[1];

    List<int> expectedBytes;
    try {
      expectedBytes = base64Url.decode(encodedSignature);
    } catch (_) {
      return null;
    }

    final Mac calculated = await _hmac.calculateMac(
      utf8.encode(encodedPayload),
      secretKey: key,
    );
    final bool valid = _constantTimeEquals(calculated.bytes, expectedBytes);

    if (!valid) {
      return null;
    }

    try {
      final String payloadRaw = utf8.decode(base64Url.decode(encodedPayload));
      final dynamic decoded = jsonDecode(payloadRaw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  String _randomToken(int length) {
    final List<int> bytes = _randomBytes(length);
    return base64UrlEncode(bytes);
  }

  List<int> _randomBytes(int length) {
    return List<int>.generate(length, (_) => _random.nextInt(256));
  }

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }

    int diff = 0;
    for (int i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
