import 'dart:async';
import 'dart:io';

import 'package:arcane_admin/arcane_admin.dart';
import 'package:fast_log/fast_log.dart';
import 'package:google_cloud/google_cloud.dart';
import 'package:rampancy_assault_corps_models/rampancy_assault_corps_models.dart';
import 'package:rampancy_assault_corps_server/api/oauth_api.dart';
import 'package:rampancy_assault_corps_server/api/public_link_api.dart';
import 'package:rampancy_assault_corps_server/api/user_api.dart';
import 'package:rampancy_assault_corps_server/api/settings_api.dart';
import 'package:rampancy_assault_corps_server/api/command_api.dart';
import 'package:rampancy_assault_corps_server/config/account_linking_config.dart';
import 'package:rampancy_assault_corps_server/service/account_link_service.dart';
import 'package:rampancy_assault_corps_server/service/user_service.dart';
import 'package:rampancy_assault_corps_server/service/command_service.dart';
import 'package:rampancy_assault_corps_server/service/link_sync_state_service.dart';
import 'package:rampancy_assault_corps_server/service/media_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_provider_service.dart';
import 'package:rampancy_assault_corps_server/service/oauth_security_service.dart';
import 'package:rampancy_assault_corps_server/util/request_authenticator.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

class RampancyAssaultCorpsServer implements Routing {
  static late final RampancyAssaultCorpsServer instance;
  late final HttpServer server;
  late final RequestAuthenticator authenticator;

  // Services
  static late AccountLinkingConfig config;
  static late UserService svcUser;
  static late CommandService svcCommand;
  static late MediaService svcMedia;
  static late LinkSyncStateService svcLinkSyncState;
  static late AccountLinkService svcAccountLink;
  static OAuthProviderService? svcOAuthProvider;
  static OAuthSecurityService? svcOAuthSecurity;

  // APIs
  static late UserAPI apiUser;
  static late SettingsAPI apiSettings;
  static late CommandAPI apiCommand;
  static late OAuthAPI apiOAuth;
  static late PublicLinkAPI apiPublicLink;

  Future<void> start() async {
    print('[startup] start');
    print('[startup] registerCrud');
    registerCrud();

    print('[startup] load_config');
    config = AccountLinkingConfig.fromEnvironment();

    print('[startup] arcane_admin_initialize_begin');
    await ArcaneAdmin.initialize();
    print('[startup] arcane_admin_initialize_done');

    instance = this;

    print('[startup] start_services_and_apis_begin');
    await Future.wait([_startServices(), _startAPIs()]);
    print('[startup] start_services_and_apis_done');

    FirestoreDatabase.instance.debugLogging = false;

    authenticator = RequestAuthenticator();

    // Start Server
    print('[startup] bind_port_begin port=${listenPort()}');
    verbose("STARTING rampancy_assault_corps_server");
    server = await serve(_pipeline, InternetAddress.anyIPv4, listenPort());
    verbose("Server listening on port ${server.port}");
    print('[startup] bind_port_done port=${server.port}');
  }

  Future<void> _startServices() async {
    svcUser = UserService();
    svcCommand = CommandService();
    svcMedia = MediaService();
    svcLinkSyncState = LinkSyncStateService();
    svcAccountLink = AccountLinkService(syncState: svcLinkSyncState);
    if (config.enabled) {
      svcOAuthProvider = OAuthProviderService(config);
      svcOAuthSecurity = OAuthSecurityService(config);
    }
    verbose("Services Online");
  }

  Future<void> _startAPIs() async {
    apiUser = UserAPI();
    apiSettings = SettingsAPI();
    apiCommand = CommandAPI();
    OAuthSecurityService? publicLinkSecurity = svcOAuthSecurity;
    apiOAuth = OAuthAPI(
      config: config,
      provider: svcOAuthProvider,
      security: svcOAuthSecurity,
      links: svcAccountLink,
    );
    if (config.enabled) {
      publicLinkSecurity = svcOAuthSecurity;
    }
    apiPublicLink = PublicLinkAPI(
      config: config,
      security: publicLinkSecurity,
      links: svcAccountLink,
    );
    verbose("APIs Initialized");
  }

  Future<Response> _onError(Object err, StackTrace stackTrace) async {
    error('Request Error: $err');
    error('Stack Trace: $stackTrace');
    return Response.internalServerError();
  }

  Future<Response?> _onRequest(Request request) =>
      authenticator.authenticateRequest(request);

  Future<Response> _onResponse(Response response) async {
    return response;
  }

  Handler get _pipeline => Pipeline()
      .addMiddleware(_corsMiddleware)
      .addMiddleware(_middleware)
      .addHandler(router.call);

  @override
  String get prefix => "/";

  Middleware get _middleware => createMiddleware(
    requestHandler: _onRequest,
    errorHandler: _onError,
    responseHandler: _onResponse,
  );

  Middleware get _corsMiddleware => corsHeaders(
    headers: {
      ACCESS_CONTROL_ALLOW_ORIGIN: "*",
      ACCESS_CONTROL_ALLOW_METHODS: "GET, POST, PUT, DELETE, OPTIONS",
      ACCESS_CONTROL_ALLOW_HEADERS: "*",
    },
  );

  @override
  Router get router {
    final Router r = Router();
    r.mount(apiOAuth.prefix, apiOAuth.router.call);
    r.mount(apiPublicLink.prefix, apiPublicLink.router.call);
    r.mount(apiUser.prefix, apiUser.router.call);
    r.mount(apiSettings.prefix, apiSettings.router.call);
    r.mount(apiCommand.prefix, apiCommand.router.call);
    r.get("/keepAlive", _requestGetKeepAlive);
    return r;
  }

  Future<Response> _requestGetKeepAlive(Request request) async =>
      Response.ok('{"ok": true}');
}

// Firebase Storage bucket name (update with your project ID)
const String bucket = "rampancy-space.firebasestorage.app";

abstract class Routing {
  Router get router;
  String get prefix;
}

extension XRequest on Request {
  String? param(String key) => url.queryParameters[key];
}

void main() => runZonedGuarded(
  () async {
    print('[startup] main_enter');
    await RampancyAssaultCorpsServer().start();
  },
  (Object errorValue, StackTrace stackTrace) {
    print('[startup] unhandled_error err=$errorValue');
    print('[startup] unhandled_error_stack $stackTrace');
    error('server_startup_unhandled err=$errorValue');
    error('server_startup_unhandled_stack stack=$stackTrace');
    exitCode = 1;
  },
);
