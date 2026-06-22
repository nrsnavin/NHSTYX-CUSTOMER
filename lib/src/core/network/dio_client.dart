import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';

/// Configured [Dio] instance with bearer-token injection and a single
/// refresh-and-retry on 401 responses.
class DioClient {
  DioClient(this._ref) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.readAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final isUnauthorized = error.response?.statusCode == 401;
          final isAuthCall = error.requestOptions.path.contains('/auth/');
          final alreadyRetried = error.requestOptions.extra['retried'] == true;

          if (isUnauthorized && !isAuthCall && !alreadyRetried) {
            final refreshed = await _refreshToken();
            if (refreshed) {
              final newToken = await _storage.readAccessToken();
              final request = error.requestOptions
                ..extra['retried'] = true
                ..headers['Authorization'] = 'Bearer $newToken';
              try {
                final response = await _dio.fetch<dynamic>(request);
                return handler.resolve(response);
              } on DioException catch (e) {
                return handler.next(e);
              }
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  final Ref _ref;
  late final Dio _dio;

  TokenStorage get _storage => _ref.read(tokenStorageProvider);

  Dio get dio => _dio;

  /// Attempts to exchange the stored refresh token for a new token pair.
  /// Uses a bare Dio so it never re-enters this interceptor.
  Future<bool> _refreshToken() async {
    final refreshToken = await _storage.readRefreshToken();
    if (refreshToken == null) return false;

    try {
      final bare = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await bare.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = response.data?['data'] as Map<String, dynamic>?;
      if (data == null) return false;
      await _storage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );
      return true;
    } on DioException {
      await _storage.clear();
      return false;
    }
  }
}

final dioProvider = Provider<Dio>((ref) {
  return DioClient(ref).dio;
});
