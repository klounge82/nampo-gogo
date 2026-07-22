import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class AuthService {
  final FlutterSecureStorage _storage;

  AuthService({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  // Keys for storage
  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';

  // Helper to get Dio client config from ApiService
  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // Signup API Call
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {'email': email, 'password': password, 'nickname': nickname},
      );

      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('회원가입 실패: 서버 응답 오류');
    } catch (e) {
      rethrow;
    }
  }

  // Login API Call & Store Tokens
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {'email': email, 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Save tokens securely
        await _storage.write(
          key: _keyAccessToken,
          value: data['access_token'] as String,
        );
        await _storage.write(
          key: _keyRefreshToken,
          value: data['refresh_token'] as String,
        );

        return data;
      }
      throw Exception('로그인 실패: 잘못된 응답');
    } catch (e) {
      rethrow;
    }
  }

  // Refresh Token Request
  Future<Map<String, dynamic>> refreshTokens(String refreshToken) async {
    try {
      // Pass token as query parameter or field according to router configuration
      final response = await _dio.post(
        '/auth/refresh',
        queryParameters: {'ref_token': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // Save new tokens
        await _storage.write(
          key: _keyAccessToken,
          value: data['access_token'] as String,
        );
        await _storage.write(
          key: _keyRefreshToken,
          value: data['refresh_token'] as String,
        );

        return data;
      }
      throw Exception('토큰 갱신 실패');
    } catch (e) {
      rethrow;
    }
  }

  // Auto Login (checks tokens and validates via refresh api)
  Future<Map<String, dynamic>?> checkStoredSession() async {
    try {
      final refreshToken = await _storage.read(key: _keyRefreshToken);
      if (refreshToken == null) {
        return null; // No session stored
      }

      // Attempt to refresh & validate session
      final sessionData = await refreshTokens(refreshToken);
      return sessionData;
    } catch (e) {
      // Secure storage data might be invalid or network is offline
      // Handled in repository fallback
      rethrow;
    }
  }

  // Clear Secure Session
  Future<void> clearSession() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
  }

  static const String _keyGuestId = 'guest_id';

  // Persistent Guest ID in secure storage
  Future<String> getOrCreateGuestId() async {
    String? guestId = await _storage.read(key: _keyGuestId);
    if (guestId == null || guestId.isEmpty) {
      guestId =
          'guest_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
      await _storage.write(key: _keyGuestId, value: guestId);
    }
    return guestId;
  }

  // Read stored tokens if exists (read-only helper)
  Future<String?> getAccessToken() async =>
      await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: _keyRefreshToken);
}
