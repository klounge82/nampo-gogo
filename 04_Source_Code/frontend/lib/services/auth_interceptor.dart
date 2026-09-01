import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'auth_service.dart';

class AuthInterceptor extends Interceptor {
  final Dio dio;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static bool _isRefreshing = false;
  static Completer<String?>? _refreshCompleter;
  static void Function()? onSessionExpired;
  static bool _sessionExpiredEventEmitted = false;

  static void emitSessionExpired() {
    if (!_sessionExpiredEventEmitted) {
      _sessionExpiredEventEmitted = true;
      AuthService().clearSession();
      onSessionExpired?.call();
      // Reset event flag after brief delay for future sessions
      Future.delayed(const Duration(seconds: 3), () {
        _sessionExpiredEventEmitted = false;
      });
    }
  }

  AuthInterceptor(this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null &&
          token.isNotEmpty &&
          !options.headers.containsKey('Authorization')) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (_) {}
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only handle 401 Unauthorized for authenticated endpoints
    if (err.response?.statusCode == 401) {
      final path = err.requestOptions.path;
      // Do not attempt refresh on auth endpoints to prevent infinite loops
      if (path.contains('/auth/login') ||
          path.contains('/auth/register') ||
          path.contains('/auth/refresh')) {
        return handler.next(err);
      }

      if (_isRefreshing) {
        try {
          final newAccessToken = await _refreshCompleter?.future;
          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            final opts = err.requestOptions;
            opts.headers['Authorization'] = 'Bearer $newAccessToken';
            final cloneReq = await dio.fetch(opts);
            return handler.resolve(cloneReq);
          }
        } catch (_) {}
      } else {
        _isRefreshing = true;
        _refreshCompleter = Completer<String?>();

        try {
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null && refreshToken.isNotEmpty) {
            final sessionData = await AuthService().refreshTokens(refreshToken);
            final newAccess = sessionData['access_token'] as String?;

            _refreshCompleter?.complete(newAccess);
            _isRefreshing = false;

            if (newAccess != null && newAccess.isNotEmpty) {
              final opts = err.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccess';
              final cloneReq = await dio.fetch(opts);
              return handler.resolve(cloneReq);
            }
          } else {
            _refreshCompleter?.complete(null);
            _isRefreshing = false;
            emitSessionExpired();
          }
        } catch (refreshErr) {
          _refreshCompleter?.complete(null);
          _isRefreshing = false;
          emitSessionExpired();
        }
      }
    }

    // Preserve 403, 500, network, and unhandled errors without mutation
    return handler.next(err);
  }
}
