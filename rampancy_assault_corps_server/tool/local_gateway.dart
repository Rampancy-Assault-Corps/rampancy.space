import 'dart:io';

import 'package:fast_log/fast_log.dart';

class LocalGatewayConfig {
  final InternetAddress host;
  final int listenPort;
  final int frontendPort;
  final int backendPort;

  const LocalGatewayConfig({
    required this.host,
    required this.listenPort,
    required this.frontendPort,
    required this.backendPort,
  });

  factory LocalGatewayConfig.fromEnvironment() {
    String hostRaw = Platform.environment['RAC_GATEWAY_HOST'] ?? '127.0.0.1';
    String listenPortRaw = Platform.environment['RAC_GATEWAY_PORT'] ?? '8080';
    String frontendPortRaw =
        Platform.environment['RAC_FRONTEND_PORT'] ?? '8082';
    String backendPortRaw = Platform.environment['RAC_BACKEND_PORT'] ?? '8081';
    InternetAddress host = InternetAddress(hostRaw);
    int listenPort = int.parse(listenPortRaw);
    int frontendPort = int.parse(frontendPortRaw);
    int backendPort = int.parse(backendPortRaw);
    return LocalGatewayConfig(
      host: host,
      listenPort: listenPort,
      frontendPort: frontendPort,
      backendPort: backendPort,
    );
  }
}

class LocalGateway {
  final LocalGatewayConfig config;
  final HttpClient _client;

  const LocalGateway({required this.config, required HttpClient client})
    : _client = client;

  Future<void> start() async {
    HttpServer server = await HttpServer.bind(config.host, config.listenPort);
    info(
      'local_gateway_listening host=${config.host.address} port=${config.listenPort} frontend=${config.frontendPort} backend=${config.backendPort}',
    );
    await for (HttpRequest request in server) {
      _handleRequest(request);
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    Uri upstream = _buildUpstreamUri(request);
    network(
      'local_gateway_request method=${request.method} path=${request.uri.path} target=${upstream.host}:${upstream.port}',
    );

    try {
      HttpClientRequest upstreamRequest = await _client.openUrl(
        request.method,
        upstream,
      );
      upstreamRequest.followRedirects = false;
      _copyRequestHeaders(request, upstreamRequest);
      List<int> body = await _readBody(request);
      if (body.isNotEmpty) {
        upstreamRequest.add(body);
      }

      HttpClientResponse upstreamResponse = await upstreamRequest.close();
      await _writeResponse(request.response, upstreamResponse);
      info(
        'local_gateway_response status=${upstreamResponse.statusCode} path=${request.uri.path}',
      );
    } catch (e) {
      error('local_gateway_error path=${request.uri.path} err=$e');
      request.response.statusCode = HttpStatus.badGateway;
      request.response.headers.contentType = ContentType.text;
      request.response.write('Bad Gateway');
      await request.response.close();
    }
  }

  Uri _buildUpstreamUri(HttpRequest request) {
    int port = _targetPort(request.uri.path);
    return Uri(
      scheme: 'http',
      host: config.host.address,
      port: port,
      path: request.uri.path,
      query: request.uri.hasQuery ? request.uri.query : null,
    );
  }

  int _targetPort(String path) {
    if (path == '/keepAlive') {
      return config.backendPort;
    }
    if (path.startsWith('/auth/')) {
      return config.backendPort;
    }
    if (path.startsWith('/api/')) {
      return config.backendPort;
    }
    return config.frontendPort;
  }

  Future<List<int>> _readBody(HttpRequest request) async {
    List<int> body = <int>[];
    await for (List<int> chunk in request) {
      body.addAll(chunk);
    }
    return body;
  }

  void _copyRequestHeaders(HttpRequest source, HttpClientRequest target) {
    source.headers.forEach((String name, List<String> values) {
      String lowercaseName = name.toLowerCase();
      if (lowercaseName == 'host') {
        return;
      }
      if (lowercaseName == 'content-length') {
        return;
      }
      for (String value in values) {
        target.headers.add(name, value);
      }
    });
  }

  Future<void> _writeResponse(
    HttpResponse target,
    HttpClientResponse source,
  ) async {
    target.statusCode = source.statusCode;
    source.headers.forEach((String name, List<String> values) {
      String lowercaseName = name.toLowerCase();
      if (lowercaseName == 'transfer-encoding') {
        return;
      }
      if (lowercaseName == 'content-length') {
        return;
      }
      for (String value in values) {
        target.headers.add(name, value);
      }
    });

    await source.pipe(target);
  }
}

Future<void> main() async {
  LocalGatewayConfig config = LocalGatewayConfig.fromEnvironment();
  HttpClient client = HttpClient();
  LocalGateway gateway = LocalGateway(config: config, client: client);
  await gateway.start();
}
