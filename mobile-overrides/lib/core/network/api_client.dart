import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../storage/local_cache.dart';

class Api {
  Api._();
  static final Api instance = Api._();

  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://darb-api-yapv.onrender.com/api/v1',
  );
  static const _storage = FlutterSecureStorage();

  String? _accessToken;
  Future<bool>? _refreshing;
  bool _sessionInvalidated = false;

  String? get accessToken => _accessToken;
  bool get sessionInvalidated => _sessionInvalidated;

  Future<void> restore() async {
    _sessionInvalidated = false;
    _accessToken = await _storage.read(key: 'accessToken');
    if (_accessToken == null) await _refreshAccessToken();
  }

  Future<void> saveTokens(Map<String, dynamic> tokens) async {
    final access = tokens['accessToken'] as String?;
    final refresh = tokens['refreshToken'] as String?;
    if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
      throw const ApiException('استجابة الجلسة غير مكتملة. أعد المحاولة دون تسجيل الخروج.');
    }
    _sessionInvalidated = false;
    // Persist the rotated refresh token first so an interrupted write cannot
    // leave the client holding a refresh token that the server already revoked.
    await _storage.write(key: 'refreshToken', value: refresh);
    await _storage.write(key: 'accessToken', value: access);
    _accessToken = access;
  }

  Future<void> clear() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await http
            .post(
              Uri.parse('$baseUrl/auth/logout'),
              headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: jsonEncode({'refreshToken': refreshToken}),
            )
            .timeout(const Duration(seconds: 8));
      } catch (_) {}
    }
    _accessToken = null;
    _sessionInvalidated = false;
    await _storage.delete(key: 'accessToken');
    await _storage.delete(key: 'refreshToken');
    await DarbLocalCache.instance.clearAll();
  }

  Future<dynamic> get(String path) => _request('GET', path, retryOnTransient: true);

  Future<({dynamic data, bool fromCache})> getWithCache(String path, String cacheKey) async {
    try {
      final data = await get(path);
      if (data != null) {
        await DarbLocalCache.instance.writeJson(cacheKey, data);
      }
      return (data: data, fromCache: false);
    } on ApiException catch (e) {
      if (e.isNetworkError) {
        final cached = await DarbLocalCache.instance.readJson(cacheKey);
        if (cached != null) return (data: cached, fromCache: true);
      }
      rethrow;
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) =>
      _request('POST', path, body: body);

  Future<dynamic> patch(String path, Map<String, dynamic> body) =>
      _request('PATCH', path, body: body);

  Future<dynamic> put(String path, Map<String, dynamic> body) =>
      _request('PUT', path, body: body);

  Future<dynamic> delete(String path, [Map<String, dynamic>? body]) =>
      _request('DELETE', path, body: body);

  Future<bool> _refreshAccessToken() async {
    if (_refreshing != null) return _refreshing!;
    _refreshing = _performRefresh();
    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  static const Duration _coldStartTimeout = Duration(seconds: 55);

  Future<bool> _performRefresh() async {
    final refreshToken = await _storage.read(key: 'refreshToken');
    if (refreshToken == null || refreshToken.isEmpty) {
      _sessionInvalidated = true;
      return false;
    }
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/refresh'),
            headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_coldStartTimeout);

      if (response.statusCode == 401 || response.statusCode == 403) {
        _sessionInvalidated = true;
        _accessToken = null;
        await _storage.delete(key: 'accessToken');
        await _storage.delete(key: 'refreshToken');
        return false;
      }
      if (response.statusCode < 200 || response.statusCode >= 300) return false;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      await saveTokens(decoded);
      return _accessToken != null;
    } catch (_) {
      return false;
    }
  }

  Future<http.Response> _send(String method, Uri uri, Map<String, dynamic>? body) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_accessToken != null) headers['Authorization'] = 'Bearer $_accessToken';
    final request = http.Request(method, uri)..headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final streamed = await request.send().timeout(_coldStartTimeout);
    return http.Response.fromStream(streamed).timeout(_coldStartTimeout);
  }

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool retryOnTransient = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    late http.Response response;
    final maxAttempts = retryOnTransient ? 3 : 1;

    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        response = await _send(method, uri, body);
        if (response.statusCode == 401 &&
            (path == '/auth/me' || !path.startsWith('/auth/'))) {
          if (await _refreshAccessToken()) {
            response = await _send(method, uri, body);
          }
        }
        if (retryOnTransient &&
            response.statusCode >= 500 &&
            attempt + 1 < maxAttempts) {
          await Future<void>.delayed(
            Duration(milliseconds: 1500 * (1 << attempt)),
          );
          continue;
        }
        break;
      } catch (_) {
        if (retryOnTransient && attempt + 1 < maxAttempts) {
          await Future<void>.delayed(
            Duration(milliseconds: 1500 * (1 << attempt)),
          );
          continue;
        }
        throw const ApiException(
          'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.',
          isNetworkError: true,
        );
      }
    }

    dynamic data;
    try {
      data = response.body.isEmpty ? null : jsonDecode(response.body);
    } catch (_) {
      data = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = data is Map
          ? (data['message'] is List
              ? (data['message'] as List).join('\n')
              : data['message'])
          : null;
      throw ApiException(
        message?.toString() ?? 'حدث خطأ (${response.statusCode})',
        statusCode: response.statusCode,
      );
    }
    return data;
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isNetworkError;

  const ApiException(
    this.message, {
    this.statusCode,
    this.isNetworkError = false,
  });

  @override
  String toString() => message;
}
