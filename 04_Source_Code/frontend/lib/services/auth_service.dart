import 'package:flutter/foundation.dart';
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
    String? guestId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
          if (guestId != null) 'guest_id': guestId,
        },
        options: Options(
          headers: {
            if (guestId != null && guestId.isNotEmpty) 'x-guest-id': guestId,
          },
        ),
      );

      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('회원가입 실패: 서버 응답 오류');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '회원가입 처리 중 오류가 발생했습니다.');
    } catch (e) {
      rethrow;
    }
  }

  // Business Signup API Call
  Future<Map<String, dynamic>> signUpBusiness({
    required String email,
    required String password,
    required String nickname,
    required String businessName,
    required String businessRegistrationNumber,
    required String representativeName,
    required String phone,
    String? requestedStoreId,
    String? guestId,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup/business',
        data: {
          'email': email,
          'password': password,
          'nickname': nickname,
          'business_name': businessName,
          'business_registration_number': businessRegistrationNumber,
          'representative_name': representativeName,
          'phone': phone,
          if (requestedStoreId != null) 'requested_store_id': requestedStoreId,
          if (guestId != null) 'guest_id': guestId,
        },
        options: Options(
          headers: {
            if (guestId != null && guestId.isNotEmpty) 'x-guest-id': guestId,
          },
        ),
      );

      if ((response.statusCode == 200 || response.statusCode == 201) &&
          response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('사업자 회원가입 실패: 서버 응답 오류');
    } on DioException catch (e) {
      final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
      throw Exception(msg?.toString() ?? '사업자 회원가입 처리 중 오류가 발생했습니다.');
    } catch (e) {
      rethrow;
    }
  }

  // Login API Call & Store Tokens
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? guestId,
  }) async {
    debugPrint('NG_LOGIN_DIAG REQUEST_START endpoint=/auth/login');
    try {
      final response = await _dio.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          if (guestId != null) 'guest_id': guestId,
        },
        options: Options(
          headers: {
            if (guestId != null && guestId.isNotEmpty) 'x-guest-id': guestId,
          },
        ),
      );

      debugPrint('NG_LOGIN_DIAG HTTP_STATUS=${response.statusCode}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        debugPrint('NG_LOGIN_DIAG RESPONSE_PARSED_OK');

        // Save tokens securely
        debugPrint('NG_LOGIN_DIAG ACCESS_TOKEN_SAVE_START');
        await _storage.write(
          key: _keyAccessToken,
          value: data['access_token'] as String,
        );
        debugPrint('NG_LOGIN_DIAG ACCESS_TOKEN_SAVE_OK');

        debugPrint('NG_LOGIN_DIAG REFRESH_TOKEN_SAVE_START');
        await _storage.write(
          key: _keyRefreshToken,
          value: data['refresh_token'] as String,
        );
        debugPrint('NG_LOGIN_DIAG REFRESH_TOKEN_SAVE_OK');

        return data;
      }
      debugPrint('NG_LOGIN_DIAG FAILURE_STAGE=AUTH_SERVICE_NON_200');
      throw Exception('이메일 또는 비밀번호가 올바르지 않습니다.');
    } on DioException catch (e) {
      debugPrint('NG_LOGIN_DIAG FAILURE_STAGE=AUTH_SERVICE_DIO_EXCEPTION');
      debugPrint('NG_LOGIN_DIAG EXCEPTION_TYPE=${e.runtimeType}');
      if (e.response?.statusCode != null) {
        debugPrint('NG_LOGIN_DIAG HTTP_STATUS=${e.response?.statusCode}');
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 400) {
        final msg = e.response?.data is Map ? e.response?.data['detail'] : null;
        throw Exception(msg?.toString() ?? '이메일 또는 비밀번호가 올바르지 않습니다.');
      }
      throw Exception('로그인 서비스에 연결할 수 없습니다. 잠시 후 다시 시도해 주세요.');
    } catch (e) {
      debugPrint('NG_LOGIN_DIAG FAILURE_STAGE=AUTH_SERVICE_GENERIC_EXCEPTION');
      debugPrint('NG_LOGIN_DIAG EXCEPTION_TYPE=${e.runtimeType}');
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

  // Auto Login (checks tokens and validates via /auth/me or refresh api)
  Future<Map<String, dynamic>?> checkStoredSession() async {
    try {
      final accessToken = await _storage.read(key: _keyAccessToken);
      final refreshToken = await _storage.read(key: _keyRefreshToken);

      if (accessToken == null && refreshToken == null) {
        return null; // No session stored
      }

      // 1. Try validating existing access_token with GET /auth/me
      if (accessToken != null && accessToken.isNotEmpty) {
        try {
          final response = await _dio.get(
            '/auth/me',
            options: Options(
              headers: {'Authorization': 'Bearer $accessToken'},
            ),
          );
          if (response.statusCode == 200 && response.data != null) {
            return {
              'access_token': accessToken,
              'refresh_token': refreshToken ?? '',
              'user': response.data as Map<String, dynamic>,
            };
          }
        } catch (_) {}
      }

      // 2. If access_token invalid/expired, try refresh_token
      if (refreshToken != null && refreshToken.isNotEmpty) {
        final sessionData = await refreshTokens(refreshToken);
        return sessionData;
      }
    } catch (e) {
      await clearSession();
    }
    return null;
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

  // Rotate guest ID after account linking or logout
  Future<String> rotateGuestId() async {
    final newGuestId =
        'guest_${DateTime.now().millisecondsSinceEpoch}_${(1000 + (DateTime.now().microsecondsSinceEpoch % 9000))}';
    await _storage.write(key: _keyGuestId, value: newGuestId);
    return newGuestId;
  }

  // Read stored tokens if exists (read-only helper)
  Future<String?> getAccessToken() async =>
      await _storage.read(key: _keyAccessToken);
  Future<String?> getRefreshToken() async =>
      await _storage.read(key: _keyRefreshToken);

  // Fetch current user details from GET /auth/me
  Future<Map<String, dynamic>?> getMe() async {
    try {
      final token = await _storage.read(key: _keyAccessToken);
      final response = await _dio.get(
        '/auth/me',
        options: Options(
          headers: {
            if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
          },
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}
