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
    final gId = guestId ?? await _authService.getOrCreateGuestId();
    final res = await _authService.signUp(
      email: email,
      password: password,
      nickname: nickname,
      guestId: gId,
    );
    await _authService.rotateGuestId();
    return User.fromJson(res);
  }

  // Business Sign Up
  Future<User> signUpBusiness({
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
    final gId = guestId ?? await _authService.getOrCreateGuestId();
    final res = await _authService.signUpBusiness(
      email: email,
      password: password,
      nickname: nickname,
      businessName: businessName,
      businessRegistrationNumber: businessRegistrationNumber,
      representativeName: representativeName,
      phone: phone,
      requestedStoreId: requestedStoreId,
      guestId: gId,
    );
    await _authService.rotateGuestId();
    return User.fromJson(res);
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
      await _authService.clearSession();
      rethrow;
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
      await _authService.clearSession();
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _authService.clearSession();
    await _authService.rotateGuestId();
  }
}
