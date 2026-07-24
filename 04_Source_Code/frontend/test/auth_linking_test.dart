import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/repositories/auth_repository.dart';

class MockAuthRepository extends AuthRepository {
  bool signUpCalled = false;
  bool loginCalled = false;
  bool logoutCalled = false;
  String? lastGuestId;

  @override
  Future<User> signUp({
    required String email,
    required String password,
    required String nickname,
    String? guestId,
  }) async {
    signUpCalled = true;
    lastGuestId = guestId;
    return User(
      id: 'usr_linked_101',
      email: email,
      nickname: nickname,
      role: 'member',
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? guestId,
  }) async {
    loginCalled = true;
    lastGuestId = guestId;
    return {
      'access_token': 'mock_access_token_abc',
      'refresh_token': 'mock_refresh_token_xyz',
      'user': User(
        id: 'usr_linked_101',
        email: email,
        nickname: '연결회원',
        role: 'member',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    };
  }

  @override
  Future<void> logout() async {
    logoutCalled = true;
  }
}

void main() {
  group('Auth & Guest Account Linking Unit Tests', () {
    test('AuthProvider login sets user state and session tokens', () async {
      final mockRepo = MockAuthRepository();
      final authProvider = AuthProvider(authRepository: mockRepo);

      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);

      final success = await authProvider.login(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authProvider.isLoggedIn, isTrue);
      expect(authProvider.currentUser?.email, equals('test@example.com'));
      expect(authProvider.accessToken, equals('mock_access_token_abc'));
      expect(mockRepo.loginCalled, isTrue);
    });

    test('AuthProvider logout resets user state and tokens', () async {
      final mockRepo = MockAuthRepository();
      final authProvider = AuthProvider(authRepository: mockRepo);

      await authProvider.login(
        email: 'test@example.com',
        password: 'password123',
      );
      expect(authProvider.isLoggedIn, isTrue);

      await authProvider.logout();
      expect(authProvider.isLoggedIn, isFalse);
      expect(authProvider.currentUser, isNull);
      expect(authProvider.accessToken, isNull);
      expect(mockRepo.logoutCalled, isTrue);
    });
  });
}
