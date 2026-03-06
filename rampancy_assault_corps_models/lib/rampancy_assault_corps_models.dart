library rampancy_assault_corps_models;

import 'dart:convert';
import 'dart:math';

import 'package:artifact/artifact.dart';
import 'package:crypto/crypto.dart';
import 'package:fire_crud/fire_crud.dart';
import 'package:rampancy_assault_corps_models/gen/artifacts.gen.dart';

export 'package:rampancy_assault_corps_models/gen/artifacts.gen.dart';
export 'package:rampancy_assault_corps_models/gen/crud.gen.dart';
export 'package:fire_crud/fire_crud.dart' show $crud;

void registerCrud() => $crud
  ..setupArtifact($artifactFromMap, $artifactToMap, $constructArtifact)
  ..registerModels([
    FireModel<User>.artifact("user"),
    FireModel<ServerCommand>.artifact("command"),
    FireModel<AccountLink>.artifact("account_links"),
  ]);

const model = Artifact(
  generateSchema: false,
  reflection: false,
  compression: true,
);

const Artifact server = Artifact(
  generateSchema: false,
  reflection: false,
  compression: true,
);

const reflect = Artifact(
  generateSchema: false,
  reflection: true,
  compression: true,
);

// ============================================================================
// User Model
// ============================================================================

@model
class User with ModelCrud {
  final String name;
  final String email;
  final String? profileHash;

  User({required this.name, required this.email, this.profileHash});

  @override
  List<FireModel<ModelCrud>> get childModels => [
    FireModel<UserSettings>.artifact("data", exclusiveDocumentId: "settings"),
  ];
}

@model
class UserSettings with ModelCrud {
  final ThemeMode themeMode;

  UserSettings({this.themeMode = ThemeMode.system});

  @override
  List<FireModel<ModelCrud>> get childModels => [];
}

enum ThemeMode { light, dark, system }

// ============================================================================
// Server Command & Response Models
// ============================================================================

@server
class ServerCommand with ModelCrud {
  final String user;

  ServerCommand({required this.user});

  @override
  List<FireModel<ModelCrud>> get childModels => [
    FireModel<ServerResponse>.artifact(
      "response",
      exclusiveDocumentId: "response",
    ),
  ];
}

@server
class ServerResponse with ModelCrud {
  final String user;

  ServerResponse({required this.user});

  @override
  List<FireModel<ModelCrud>> get childModels => [];
}

@server
class ResponseOK extends ServerResponse {
  ResponseOK({required super.user});
}

@server
class ResponseError extends ServerResponse {
  final String message;

  ResponseError({required super.user, required this.message});
}

@model
class AccountLink with ModelCrud {
  final String? discordId;
  final String? discordUsername;
  final String? discordGlobalName;
  final String? discordAvatarHash;
  final int? discordLinkedAt;
  final bool bungieConnected;
  final String? bungiePrimaryMembershipKey;
  final String? bungiePrimaryMembershipId;
  final int? bungiePrimaryMembershipType;
  final int? bungieLinkedAt;
  final String? bungieRefreshCiphertext;
  final String? bungieRefreshNonce;
  final int? bungieRefreshExpiresAt;
  final int updatedAt;

  AccountLink({
    this.discordId,
    this.discordUsername,
    this.discordGlobalName,
    this.discordAvatarHash,
    this.discordLinkedAt,
    this.bungieConnected = false,
    this.bungiePrimaryMembershipKey,
    this.bungiePrimaryMembershipId,
    this.bungiePrimaryMembershipType,
    this.bungieLinkedAt,
    this.bungieRefreshCiphertext,
    this.bungieRefreshNonce,
    this.bungieRefreshExpiresAt,
    required this.updatedAt,
  });

  @override
  List<FireModel<ModelCrud>> get childModels => [
    FireModel<BungieMembership>.artifact("memberships"),
  ];
}

@model
class BungieMembership with ModelCrud {
  final String membershipId;
  final int membershipType;
  final String? displayName;
  final String? iconPath;
  final int? crossSaveOverride;
  final bool isPrimary;
  final int updatedAt;

  BungieMembership({
    required this.membershipId,
    required this.membershipType,
    this.displayName,
    this.iconPath,
    this.crossSaveOverride,
    this.isPrimary = false,
    required this.updatedAt,
  });

  @override
  List<FireModel<ModelCrud>> get childModels => [];
}

// ============================================================================
// Server Signature (for authentication)
// ============================================================================

@model
class RampancyAssaultCorpsServerSignature {
  final String signature;
  final String session;
  final int time;

  RampancyAssaultCorpsServerSignature({
    required this.signature,
    required this.session,
    required this.time,
  });

  static String? _sessionId;
  static String get sessionId {
    if (_sessionId == null) {
      Random r = Random();
      _sessionId = base64Encode(
        List.generate(128, (i) => r.nextInt(256)).toList(),
      );
    }

    return _sessionId!;
  }

  String get hash =>
      sha256.convert(utf8.encode("$signature:$session@$time")).toString();

  static String get randomSignature {
    Random random = Random();
    return base64Encode(
      List.generate(128, (i) => random.nextInt(256)).toList(),
    );
  }

  static RampancyAssaultCorpsServerSignature newSignature() =>
      RampancyAssaultCorpsServerSignature(
        signature: randomSignature,
        session: sessionId,
        time: DateTime.timestamp().millisecondsSinceEpoch,
      );
}
