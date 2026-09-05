import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/more_screen.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:frontend/screens/point_history_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:frontend/providers/locale_provider.dart';

class MockAuthProvider extends ChangeNotifier implements AuthProvider {
  User? _mockUser;
  bool _mockIsLoggedIn = false;

  void setTestUser(User? user) {
    _mockUser = user;
    _mockIsLoggedIn = user != null;
    notifyListeners();
  }

  @override
  bool get isLoggedIn => _mockIsLoggedIn;

  @override
  User? get currentUser => _mockUser;

  @override
  bool get isLoading => false;

  @override
  String? get accessToken => 'mock_token';

  @override
  String? get refreshToken => 'mock_refresh';

  @override
  Future<void> autoLogin() async {}

  @override
  void handleSessionExpired() {}

  @override
  Future<bool> login({required String email, required String password}) async => true;

  @override
  Future<void> logout() async {
    _mockUser = null;
    _mockIsLoggedIn = false;
    notifyListeners();
  }

  @override
  Future<void> refreshUser() async {}

  @override
  Future<User> signUp({required String email, required String password, required String nickname}) async {
    throw UnimplementedError();
  }

  @override
  Future<User> signUpBusiness({
    required String email,
    required String password,
    required String nickname,
    required String businessName,
    required String businessRegistrationNumber,
    required String representativeName,
    required String phone,
    String? requestedStoreId,
  }) async {
    throw UnimplementedError();
  }

  @override
  void updatePoints(int newPoints, {int? newLifetimeEarnedPoints}) {}

  @override
  void updateUser(User user) {
    _mockUser = user;
    notifyListeners();
  }
}

void main() {
  group('MORE / ACCOUNT ARCHITECTURE UNIFICATION TESTS', () {
    final regularUser = User(
      id: 'usr_reg_001',
      nickname: '남포테스터',
      email: 'tester@nampogogo.local',
      role: 'CUSTOMER',
      status: 'ACTIVE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currentPoints: 500,
      lifetimeEarnedPoints: 1200,
      roles: const ['CUSTOMER'],
    );

    final adminUser = User(
      id: 'usr_admin_001',
      nickname: '남포관리자',
      email: 'admin@nampogogo.local',
      role: 'ADMIN',
      status: 'ACTIVE',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      currentPoints: 10000,
      lifetimeEarnedPoints: 25000,
      roles: const ['CUSTOMER', 'BUSINESS', 'ADMIN'],
    );

    testWidgets('MoreScreen renders full canonical service hub', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = MockAuthProvider();
      authProvider.setTestUser(regularUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MoreScreen(),
          ),
        ),
      );
      await tester.pump();

      // Top Header
      expect(find.text('남포테스터'), findsOneWidget);
      expect(find.text('tester@nampogogo.local'), findsOneWidget);

      // Section Headers
      expect(find.text('나의 활동 및 혜택'), findsNothing);
      expect(find.text('나의 활동'), findsOneWidget);
      expect(find.text('혜택'), findsOneWidget);
      expect(find.text('지원'), findsOneWidget);
      expect(find.text('모드 전환'), findsOneWidget);
      expect(find.text('서비스 설정'), findsOneWidget);

      // Activities
      expect(find.text('내 예약 내역'), findsOneWidget);
      expect(find.text('내가 작성한 리뷰'), findsOneWidget);
      expect(find.text('내 활동 기록'), findsOneWidget);
      expect(find.text('결제 및 이용 이력'), findsOneWidget);

      // Benefits
      expect(find.text('포인트 이용 내역'), findsOneWidget);
      expect(find.text('보유 쿠폰'), findsOneWidget);
      expect(find.text('즐겨찾기'), findsOneWidget);

      // Support & Policies
      expect(find.text('내 피드백 & 문의'), findsOneWidget);
      expect(find.text('고객지원센터'), findsOneWidget);
      expect(find.text('예약 및 취소 운영정책'), findsOneWidget);

      // Regular user does NOT see admin mode
      expect(find.text('관리자 모드로 전환'), findsNothing);
    });

    testWidgets('MoreScreen displays Admin Mode switch only for admin users', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = MockAuthProvider();
      authProvider.setTestUser(adminUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: MoreScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('관리자 모드로 전환'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders ONLY account management with zero service duplication', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = MockAuthProvider();
      authProvider.setTestUser(regularUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pump();

      // Account Header
      expect(find.text('남포테스터'), findsOneWidget);
      expect(find.text('te****@nampogogo.local'), findsOneWidget);
      expect(find.text('일반 회원'), findsOneWidget);

      // Account Management entries
      expect(find.text('프로필 수정'), findsOneWidget);
      expect(find.text('비밀번호 변경'), findsOneWidget);
      expect(find.text('로그아웃'), findsOneWidget);
      expect(find.text('회원탈퇴'), findsOneWidget);

      // Zero duplicate service hub entries in Account screen
      expect(find.text('내 예약 내역'), findsNothing);
      expect(find.text('내가 작성한 리뷰'), findsNothing);
      expect(find.text('내 활동 기록'), findsNothing);
      expect(find.text('결제 및 이용 이력'), findsNothing);
      expect(find.text('포인트 교환소'), findsNothing);
      expect(find.text('보유 포인트'), findsNothing);
      expect(find.text('즐겨찾기 보관함'), findsNothing);
      expect(find.text('사업자 모드로 전환'), findsNothing);
    });

    testWidgets('PointHistoryScreen contains Point Store exchange button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = MockAuthProvider();
      authProvider.setTestUser(regularUser);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: PointHistoryScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Point Store button present under points dashboard
      expect(find.text('포인트 교환소'), findsOneWidget);
    });
  });
}
