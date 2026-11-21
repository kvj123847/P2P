import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  const ApiConfig({
    required this.coreApiBaseUrl,
    required this.sessionEngineBaseUrl,
  });

  static const development = ApiConfig(
    coreApiBaseUrl: String.fromEnvironment(
      'CORE_API_BASE_URL',
      defaultValue: 'http://10.0.2.2:3000/api/v1',
    ),
    sessionEngineBaseUrl: String.fromEnvironment(
      'SESSION_ENGINE_BASE_URL',
      defaultValue: 'http://10.0.2.2:8001',
    ),
  );
  static const agoraAppId = String.fromEnvironment('AGORA_APP_ID');

  static ApiConfig get current {
    const isProduction = bool.fromEnvironment('PRODUCTION', defaultValue: false);
    if (!isProduction) return development;

    const coreUrl = String.fromEnvironment('CORE_API_BASE_URL');
    const sessionUrl = String.fromEnvironment('SESSION_ENGINE_BASE_URL');
    if (coreUrl.isEmpty || sessionUrl.isEmpty) {
      throw StateError(
        'Production builds require CORE_API_BASE_URL and '
        'SESSION_ENGINE_BASE_URL via --dart-define.',
      );
    }
    final coreUri = Uri.tryParse(coreUrl);
    final sessionUri = Uri.tryParse(sessionUrl);
    if (coreUri == null ||
        !coreUri.isAbsolute ||
        coreUri.scheme != 'https' ||
        sessionUri == null ||
        !sessionUri.isAbsolute ||
        sessionUri.scheme != 'https') {
      throw const FormatException(
        'Production API URLs must be absolute HTTPS URLs.',
      );
    }
    return ApiConfig(
      coreApiBaseUrl: coreUrl,
      sessionEngineBaseUrl: sessionUrl,
    );
  }

  final String coreApiBaseUrl;
  final String sessionEngineBaseUrl;
}

class ApiException implements Exception {
  const ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  ApiClient({
    ApiConfig? config,
    FlutterSecureStorage? storage,
    http.Client? client,
  })  : _config = config ?? ApiConfig.current,
        _storage = storage ?? const FlutterSecureStorage(),
        _client = client ?? http.Client();

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  final ApiConfig _config;
  final FlutterSecureStorage _storage;
  final http.Client _client;

  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  Future<void> clearAccessToken() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
  }

  Future<Map<String, dynamic>> getCore(String path,
          {Map<String, String>? query}) =>
      _request('GET', _uri(_config.coreApiBaseUrl, path, query));

  Future<Map<String, dynamic>> postCore(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('POST', _uri(_config.coreApiBaseUrl, path), body: body);

  Future<Map<String, dynamic>> putCore(String path,
          {Map<String, dynamic>? body}) =>
      _request('PUT', _uri(_config.coreApiBaseUrl, path), body: body);

  Future<Map<String, dynamic>> patchCore(String path,
          {Map<String, dynamic>? body}) =>
      _request('PATCH', _uri(_config.coreApiBaseUrl, path), body: body);

  Future<Map<String, dynamic>> deleteCore(String path,
          {Map<String, dynamic>? body}) =>
      _request('DELETE', _uri(_config.coreApiBaseUrl, path), body: body);

  Future<Map<String, dynamic>> postSession(
    String path, {
    Map<String, dynamic>? body,
  }) =>
      _request('POST', _uri(_config.sessionEngineBaseUrl, path), body: body);

  Future<Map<String, dynamic>> getSession(String path) =>
      _request('GET', _uri(_config.sessionEngineBaseUrl, path));

  Uri _uri(String base, String path, [Map<String, String>? query]) {
    final uri = Uri.parse('$base$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
    bool retry = true,
  }) async {
    final token = await _storage.read(key: _accessTokenKey);
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final request = http.Request(method, uri)
      ..headers.addAll(headers)
      ..body = body == null ? '' : jsonEncode(body);
    late final http.Response response;
    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 15));
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException(504, 'The server request timed out');
    } on SocketException {
      throw const ApiException(503, 'Unable to connect to the server');
    } on HttpException {
      throw const ApiException(502, 'The server connection failed');
    }
    if (response.statusCode == 401 && retry && uri.path.contains('/api/')) {
      final refreshed = await _refresh();
      if (refreshed) {
        return _request(method, uri, body: body, retry: false);
      }
    }
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final error = decoded is Map<String, dynamic> ? decoded['error'] : null;
      final message = error is Map<String, dynamic>
          ? error['message']?.toString()
          : error?.toString();
      throw ApiException(response.statusCode, message ?? 'Request failed');
    }
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{'data': decoded};
  }

  Future<bool> _refresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null || refreshToken.isEmpty) return false;
    final request = http.Request(
      'POST',
      _uri(_config.coreApiBaseUrl, Endpoints.refresh),
    )
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({'refreshToken': refreshToken});
    final response = await _client.send(request).timeout(const Duration(seconds: 15));
    final decoded = jsonDecode((await http.Response.fromStream(response)).body);
    if (decoded is! Map<String, dynamic> || decoded['data'] is! Map<String, dynamic>) {
      await clearAccessToken();
      return false;
    }
    final data = decoded['data'] as Map<String, dynamic>;
    final access = data['accessToken']?.toString();
    final refresh = data['refreshToken']?.toString();
    if (access == null || refresh == null) {
      await clearAccessToken();
      return false;
    }
    await saveAccessToken(access);
    await saveRefreshToken(refresh);
    return true;
  }
}

class Endpoints {
  static const login = '/auth/login';
  static const signup = '/auth/signup';
  static const refresh = '/auth/refresh';
  static const profile = '/users/me/profile';
  static const tutors = '/users/tutors/search';
  static const courses = '/courses';
  static const sessions = '/sessions';
  static String sessionToken(String id) => '/sessions/$id/video-token';
  static const chats = '/conversations';
  static const notifications = '/notifications';
  static const checkout = '/payments/checkout';
  static const earnings = '/payments/earnings';
}
