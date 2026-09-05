import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/more_screen.dart';
import 'package:frontend/screens/profile_edit_screen.dart';
import 'package:frontend/screens/my_reviews_screen.dart';
import 'package:frontend/screens/main_navigation_screen.dart';
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
  group('FIELD UX CORRECTION BATCH 2 TESTS', () {
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

    test('AppModeProvider customerInitialTab defaults to 0 and updates correctly', () {
      final modeProvider = AppModeProvider();
      expect(modeProvider.customerInitialTab, 0);

      modeProvider.setCustomerInitialTab(4);
      expect(modeProvider.customerInitialTab, 4);

      modeProvider.switchMode(AppMode.customer, regularUser);
      // Should remain 4 when set
      expect(modeProvider.customerInitialTab, 4);
    });

    testWidgets('MainNavigationScreen starts at provided initialIndex', (WidgetTester tester) async {
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
            home: MainNavigationScreen(initialIndex: 4),
          ),
        ),
      );
      await tester.pump();

      // Should be on More screen directly
      expect(find.byType(MoreScreen), findsOneWidget);
      expect(find.text('남포테스터'), findsOneWidget);
    });

    testWidgets('MoreScreen localized section headers in EN and JA', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authProvider = MockAuthProvider();
      authProvider.setTestUser(regularUser);

      // Test English
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
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

      expect(find.text('My Activities'), findsOneWidget);
      expect(find.text('Benefits'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);

      // Test Japanese
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ja'),
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

      expect(find.text('マイ活動'), findsOneWidget);
      expect(find.text('特典'), findsOneWidget);
      expect(find.text('サポート'), findsOneWidget);
    });

    testWidgets('ProfileEditScreen has image picker bottom sheet with gallery/camera/default options', (WidgetTester tester) async {
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
            home: ProfileEditScreen(),
          ),
        ),
      );
      await tester.pump();

      // Tap on the avatar / camera button to open bottom sheet
      final editIconFinder = find.byIcon(Icons.camera_alt);
      expect(editIconFinder, findsOneWidget);
      await tester.tap(editIconFinder);
      await tester.pumpAndSettle();

      // Check modal bottom sheet options
      expect(find.text('사진 앨범에서 선택'), findsOneWidget);
      expect(find.text('카메라로 촬영'), findsOneWidget);
      expect(find.text('기본 이미지로 변경'), findsOneWidget);

      // Simulator mock gallery must NOT exist
      expect(find.text('시뮬레이터 갤러리 1'), findsNothing);
      expect(find.text('시뮬레이터 갤러리 2'), findsNothing);
    });

    testWidgets('MyReviewsScreen renders localized tabs in KO and EN', (WidgetTester tester) async {
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
            home: MyReviewsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('작성한 리뷰'), findsOneWidget);
      expect(find.textContaining('삭제된 리뷰'), findsOneWidget);
    });
  });
}
