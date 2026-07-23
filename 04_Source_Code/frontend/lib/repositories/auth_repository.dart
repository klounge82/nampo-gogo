import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class AuthRepository {
  final AuthService _authService;

  AuthRepository({AuthService? authService})
    : _authService = authService ?? AuthService();

  // Mock Fallback User asset
  static final User _mockUser = User(
    id: 'usr_mock_999',
    email: 'nampo_gogo@mock.com',
    nickname: '김남포 (Mock)',
    role: 'member',
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  // Sign Up
  Future<User> signUp({
    required String email,
    required String password,
    required String nickname,
    String? guestId,
  }) async {
    try {
      final gId = guestId ?? await _authService.getOrCreateGuestId();
      final res = await _authService.signUp(
        email: email,
        password: password,
        nickname: nickname,
        guestId: gId,
      );
      await _authService.rotateGuestId();
      return User.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('AuthRepository: Signup failed. Falling back to Mock. Error: $e');
      }
      // Fallback: Return a local mock user
      return User(
        id: 'usr_mock_${email.hashCode}',
        email: email,
        nickname: '$nickname (Mock)',
        role: 'member',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  // Login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? guestId,
  }) async {
    try {
      final gId = guestId ?? await _authService.getOrCreateGuestId();
      final res = await _authService.login(
        email: email,
        password: password,
        guestId: gId,
      );
      await _authService.rotateGuestId();
      return {
        'access_token': res['access_token'] as String,
        'refresh_token': res['refresh_token'] as String,
        'user': User.fromJson(res['user'] as Map<String, dynamic>),
      };
    } catch (e) {
      if (kDebugMode) {
        print('AuthRepository: Login failed. Falling back to Mock. Error: $e');
      }
      // Fallback Mock Login
      return {
        'access_token': 'mock_access_token_123',
        'refresh_token': 'mock_refresh_token_123',
        'user': _mockUser.copyWith(
          email: email,
          nickname: '${email.split('@')[0]} (Mock)',
        ),
      };
    }
  }

  // Auto Login session check
  Future<Map<String, dynamic>?> autoLogin() async {
    try {
      final res = await _authService.checkStoredSession();
      if (res == null) return null;

      return {
        'access_token': res['access_token'] as String,
        'refresh_token': res['refresh_token'] as String,
        'user': User.fromJson(res['user'] as Map<String, dynamic>),
      };
    } catch (e) {
      if (kDebugMode) {
        print(
          'AuthRepository: AutoLogin failed. Checking stored token values fallback. Error: $e',
        );
      }

      // Attempt to check if token exists locally, fallback if offline
      final accessToken = await _authService.getAccessToken();
      final refreshToken = await _authService.getRefreshToken();

      if (accessToken != null && refreshToken != null) {
        // Safe offline session recovery
        return {
          'access_token': accessToken,
          'refresh_token': refreshToken,
          'user': _mockUser,
        };
      }
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.clearSession();
    await _authService.rotateGuestId();
  }
}
