import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/auth_repository.dart';
import '../services/notification_service.dart';
import '../repositories/notification_repository.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthProvider({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  // Core Authentication States
  bool _isLoggedIn = false;
  bool _isLoading = false;
  User? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  // Getters
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;

  // Sign Up Flow
  Future<User> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    _setLoading(true);
    try {
      final user = await _authRepository.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      return user;
    } finally {
      _setLoading(false);
    }
  }

  // Login Flow
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final session = await _authRepository.login(
        email: email,
        password: password,
      );
      _accessToken = session['access_token'] as String;
      _refreshToken = session['refresh_token'] as String;
      _currentUser = session['user'] as User;
      _isLoggedIn = true;
      notifyListeners();

      // FCM Token registration (Async background binding)
      _registerFCM();

      return true;
    } catch (e) {
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Auto Login Session Verification (Boot time checks)
  Future<void> autoLogin() async {
    _setLoading(true);
    try {
      final session = await _authRepository.autoLogin();
      if (session != null) {
        _accessToken = session['access_token'] as String;
        _refreshToken = session['refresh_token'] as String;
        _currentUser = session['user'] as User;
        _isLoggedIn = true;
        notifyListeners();

        // FCM Token registration (Async background binding)
        _registerFCM();
      }
    } catch (_) {
      // Ignored for auto login
    } finally {
      _setLoading(false);
    }
  }

  // Logout Flow
  Future<void> logout() async {
    _setLoading(true);
    try {
      // Deregister FCM token before clearing user session
      await _deregisterFCM();

      await _authRepository.logout();
      _isLoggedIn = false;
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // FCM Token Helpers
  Future<void> _registerFCM() async {
    try {
      final token = await NotificationService().getFCMToken();
      if (token != null && _currentUser != null) {
        await NotificationRepository().registerToken(
          deviceId: 'dev_${_currentUser!.id.substring(0, 8)}',
          deviceType: 'android',
          fcmToken: token,
          userId: _currentUser!.id,
        );
      }
    } catch (_) {}
  }

  Future<void> _deregisterFCM() async {
    try {
      if (_currentUser != null) {
        await NotificationRepository().deregisterToken(
          deviceId: 'dev_${_currentUser!.id.substring(0, 8)}',
          userId: _currentUser!.id,
        );
      }
    } catch (_) {}
  }

  // Update local user points cache and notify UI listeners
  void updatePoints(int newPoints) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(currentPoints: newPoints);
      notifyListeners();
    }
  }

  // Update whole local user object and notify UI listeners
  void updateUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  // Helper State Mutator
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
