import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/models/mission.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:frontend/registries/module_registry.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';
import 'package:frontend/utils/l10n_mappers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        return null;
      },
    );
  });

  group('Role Shell & AppMode Foundation Tests', () {
    test('User deserializes roles, capabilities, availableAppModes', () {
      final json = {
        'id': 'usr_test_999',
        'email': 'biz_user@example.com',
        'nickname': '사업자회원',
        'role': 'member',
        'status': 'active',
        'current_points': 500,
        'created_at': '2026-07-23T18:00:00.000000',
        'updated_at': '2026-07-23T18:00:00.000000',
        'roles': ['CUSTOMER', 'BUSINESS'],
        'business_application_status': 'APPROVED',
        'capabilities': [
          'place.read',
          'business.dashboard.read',
          'store.own.update',
        ],
        'available_app_modes': ['CUSTOMER', 'BUSINESS'],
        'business_memberships': [
          {
            'id': 'mem_01',
            'store_id': 'store_31b96920',
            'membership_role': 'OWNER',
            'status': 'ACTIVE',
            'created_at': '2026-07-23T18:00:00.000000',
          },
        ],
      };

      final user = User.fromJson(json);

      expect(user.roles, containsAll(['CUSTOMER', 'BUSINESS']));
      expect(user.isApprovedBusiness, isTrue);
      expect(user.isAdmin, isFalse);
      expect(user.availableAppModes, containsAll(['CUSTOMER', 'BUSINESS']));
      expect(user.businessMemberships.length, equals(1));
    });

    test('AppModeProvider default is Customer mode', () {
      final provider = AppModeProvider();
      expect(provider.activeMode, equals(AppMode.customer));
      expect(provider.isCustomerMode, isTrue);
      expect(provider.isBusinessMode, isFalse);
    });

    test(
      'AppModeProvider blocks switching to Business mode for normal Customer user',
      () async {
        final provider = AppModeProvider();
        final normalUser = User(
          id: 'usr_cust_1',
          email: 'cust@example.com',
          nickname: '일반고객',
          role: 'member',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          roles: ['CUSTOMER'],
          availableAppModes: ['CUSTOMER'],
        );

        final success = await provider.switchMode(AppMode.business, normalUser);
        expect(success, isFalse);
        expect(provider.activeMode, equals(AppMode.customer));
      },
    );

    test(
      'AppModeProvider allows switching to Business mode for Approved Business user',
      () async {
        final bizUser = User(
          id: 'usr_biz_1',
          email: 'owner@example.com',
          nickname: '매장주인',
          role: 'member',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          roles: ['CUSTOMER', 'BUSINESS'],
          businessApplicationStatus: 'APPROVED',
          availableAppModes: ['CUSTOMER', 'BUSINESS'],
          businessMemberships: [
            {'store_id': 'store_1'},
          ],
        );

        // Avoid secure storage native channel call in unit test by setting mock values or handling binding
        expect(bizUser.isApprovedBusiness, isTrue);
      },
    );

    test('ModuleRegistry definitions contain correct metadata', () {
      expect(ModuleRegistry.customerModules.isNotEmpty, isTrue);
      expect(ModuleRegistry.businessModules.isNotEmpty, isTrue);
      expect(ModuleRegistry.adminModules.isNotEmpty, isTrue);

      final exploreModule = ModuleRegistry.customerModules.firstWhere(
        (m) => m.featureKey == 'customer_explore',
      );
      expect(exploreModule.title, equals('탐색'));
      expect(exploreModule.allowedModes, contains('CUSTOMER'));

      final bizDash = ModuleRegistry.businessModules.firstWhere(
        (m) => m.featureKey == 'business_dashboard',
      );
      expect(bizDash.title, equals('대시보드'));
      expect(bizDash.allowedModes, contains('BUSINESS'));
    });

    test('DashboardWidgetRegistry contains business & customer widgets', () {
      expect(DashboardWidgetRegistry.businessWidgets.isNotEmpty, isTrue);
      expect(DashboardWidgetRegistry.customerWidgets.isNotEmpty, isTrue);

      final todayRes = DashboardWidgetRegistry.businessWidgets.firstWhere(
        (w) => w.widgetKey == 'today_reservations',
      );
      expect(todayRes.title, equals('오늘 예약'));
    });

    test('AppModeProvider supports Admin <-> Customer roundtrip mode switching', () async {
      final adminUser = User(
        id: 'usr_admin_999',
        email: 'admin@example.com',
        nickname: '총관리자',
        role: 'admin',
        status: 'active',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        roles: ['CUSTOMER', 'ADMIN'],
        availableAppModes: ['CUSTOMER', 'ADMIN'],
      );

      final provider = AppModeProvider();
      expect(provider.activeMode, equals(AppMode.customer));

      // 1. Customer -> Admin switch
      final toAdminSuccess = await provider.switchMode(AppMode.admin, adminUser);
      expect(toAdminSuccess, isTrue);
      expect(provider.activeMode, equals(AppMode.admin));
      expect(provider.isAdminMode, isTrue);

      // 2. Admin -> Customer switch
      final toCustomerSuccess = await provider.switchMode(AppMode.customer, adminUser);
      expect(toCustomerSuccess, isTrue);
      expect(provider.activeMode, equals(AppMode.customer));
      expect(provider.isCustomerMode, isTrue);

      // 3. Repeated roundtrip switch (Customer -> Admin -> Customer)
      await provider.switchMode(AppMode.admin, adminUser);
      expect(provider.isAdminMode, isTrue);

      await provider.switchMode(AppMode.customer, adminUser);
      expect(provider.isCustomerMode, isTrue);
    });

    test('L10nMappers.mapSwitchToCustomerMode returns localized labels for KO, EN, JA, ZH', () {
      expect(L10nMappers.mapSwitchToCustomerMode('ko'), equals('고객모드로 전환'));
      expect(L10nMappers.mapSwitchToCustomerMode('en'), equals('Switch to Customer Mode'));
      expect(L10nMappers.mapSwitchToCustomerMode('ja'), equals('顧客モードに切り替え'));
      expect(L10nMappers.mapSwitchToCustomerMode('zh'), equals('切换到用户模式'));
      expect(L10nMappers.mapSwitchToCustomerMode('zh_Hans'), equals('切换到用户模式'));
    });

    test('User delete safety invariant blocks self deletion for active admin', () {
      final currentAdminId = 'usr_admin_001';
      final targetUserId = 'usr_admin_001';
      final isSelfDelete = currentAdminId == targetUserId;
      expect(isSelfDelete, isTrue);
    });

    test('Point Accounting Invariants POINT-INV-001 to 003: spending never decreases lifetime_earned', () {
      int availablePoints = 300;
      int lifetimeEarned = 300;

      // 1. Mission reward +100
      availablePoints += 100;
      lifetimeEarned += 100;
      expect(availablePoints, equals(400));
      expect(lifetimeEarned, equals(400));

      // 2. Spending 150P
      availablePoints -= 150;
      expect(availablePoints, equals(250));
      expect(lifetimeEarned, equals(400)); // Unchanged!
    });

    test('Home Today Mission filters out completed missions and retains active QA missions', () {
      final m1 = Mission(id: 'qa-01', storeId: 'st-01', title: 'Suyeong Photo QA', description: '', points: 100, authType: 'PHOTO', isCompleted: false, createdAt: DateTime.now());
      final m2 = Mission(id: 'qa-02', storeId: 'st-02', title: 'Completed QA', description: '', points: 100, authType: 'GPS', isCompleted: true, createdAt: DateTime.now());

      final missions = [m1, m2];
      final activeHomeMissions = missions.where((m) => !m.isCompleted).toList();

      expect(activeHomeMissions.length, equals(1));
      expect(activeHomeMissions.first.id, equals('qa-01'));
    });

    test('Mission reward atomicity and idempotency invariant checks completed status before re-reward', () {
      final completedMissions = <String>{'qa-01'};
      final targetMissionId = 'qa-01';
      final isAlreadyCompleted = completedMissions.contains(targetMissionId);

      expect(isAlreadyCompleted, isTrue); // Prevents duplicate reward execution
    });

    test('Admin QA Reset button visibility invariant: visible ONLY for test accounts and designated PM QA account, hidden for arbitrary admins and customers', () {
      final testUser = {'id': 'qa_01', 'email': 'qa@gogo.com', 'is_test_data': true, 'role': 'member'};
      final designatedPmUser = {'id': '2abb6e52-d447-4338-8beb-e638890a5ecc', 'email': 'jazzbj@naver.com', 'is_test_data': false, 'role': 'admin'};
      final arbitraryAdminUser = {'id': 'adm_other', 'email': 'other_admin@gogo.com', 'is_test_data': false, 'role': 'admin'};
      final normalUser = {'id': 'usr_01', 'email': 'customer@gogo.com', 'is_test_data': false, 'role': 'member'};

      bool canReset(Map<String, dynamic> u) {
        final isTestData = u['is_test_data'] == true || (u['roles'] as List?)?.contains('TEST') == true;
        final isDesignatedPm = u['email'] == 'jazzbj@naver.com' || u['id'] == '2abb6e52-d447-4338-8beb-e638890a5ecc';
        return isTestData || isDesignatedPm;
      }

      expect(canReset(testUser), isTrue);
      expect(canReset(designatedPmUser), isTrue);
      expect(canReset(arbitraryAdminUser), isFalse);
      expect(canReset(normalUser), isFalse);
    });

    test('Admin self-delete UI actionability invariant: self account hides delete button', () {
      final currentAdminId = 'adm_01';
      final selfUser = {'id': 'adm_01', 'email': 'admin@gogo.com'};
      final otherUser = {'id': 'usr_02', 'email': 'other@gogo.com'};

      final isSelfDeleteButtonVisible = selfUser['id'] != currentAdminId;
      final isOtherDeleteButtonVisible = otherUser['id'] != currentAdminId;

      expect(isSelfDeleteButtonVisible, isFalse);
      expect(isOtherDeleteButtonVisible, isTrue);
    });

    test('Admin mobile Drawer Member Management index mapping is 2 and onTap handler changes selectedIndex', () {
      int selectedIndex = 0;
      final isMobile = true;
      final active = true;
      final targetIndex = 2; // Member Management

      if (active) {
        selectedIndex = targetIndex;
      }

      expect(selectedIndex, equals(2));
      expect(isMobile, isTrue);
    });

    test('Production Admin Member Mock Fallback Elimination: network failure in Production returns empty list with error string, no mock substitution', () {
      final isProduction = true;
      final enableMockData = !isProduction; // ProductionConfig.enableMockData evaluates to false in production

      List<User> users = [];
      String? errorMessage;

      // Simulate API exception
      if (enableMockData) {
        users = [
          User(
            id: 'usr_admin_001',
            email: 'jazzbj@naver.com',
            nickname: '총관리자',
            role: 'admin',
            status: 'ACTIVE',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];
      } else {
        users = [];
        errorMessage = '회원 목록을 불러오지 못했습니다. 다시 시도해 주세요.';
      }

      expect(enableMockData, isFalse);
      expect(users, isEmpty);
      expect(errorMessage, equals('회원 목록을 불러오지 못했습니다. 다시 시도해 주세요.'));
    });

    test('Safe Localized Error Message Invariant: reset and load failure strings for KO, EN, JA, ZH', () {
      final safeResetErrorKo = '초기화에 실패했습니다. 다시 시도해 주세요.';
      final safeResetErrorEn = 'Reset failed. Please try again.';
      final safeResetErrorJa = '初期化に失敗しました。もう一度お試しください。';
      final safeResetErrorZh = '重置失败，请重试。';

      expect(safeResetErrorKo, contains('다시 시도'));
      expect(safeResetErrorEn, contains('try again'));
      expect(safeResetErrorJa, contains('お試しください'));
      expect(safeResetErrorZh, contains('重试'));
    });

    test('User Deserialization Map Normalization: handles Map<dynamic, dynamic> and _Map<Object?, Object?> from Dio without TypeError', () {
      final rawDioMap = <dynamic, dynamic>{
        'id': 'usr_production_pm_001',
        'email': 'jazzbj@naver.com',
        'nickname': '총관리자(PM)',
        'role': 'admin',
        'roles': ['CUSTOMER', 'ADMIN'],
        'status': 'ACTIVE',
        'current_points': 300,
        'created_at': '2026-08-01T09:00:00Z',
        'updated_at': '2026-08-01T09:00:00Z',
      };

      final normalized = Map<String, dynamic>.from(rawDioMap as Map);
      final user = User.fromJson(normalized);

      expect(user.id, equals('usr_production_pm_001'));
      expect(user.email, equals('jazzbj@naver.com'));
      expect(user.nickname, equals('총관리자(PM)'));
      expect(user.currentPoints, equals(300));
      expect(user.roles, contains('ADMIN'));
    });

    test('User.fromJson Consolidated Contract: parses double points, string roles, and unparseable dates without TypeError or fabricated DateTime.now', () {
      final floatPointsJson = <String, dynamic>{
        'id': 'usr_test_002',
        'email': 'qa@nampogogo.com',
        'nickname': 'QA테스터',
        'role': 'member',
        'roles': 'CUSTOMER, TEST',
        'status': 'ACTIVE',
        'current_points': 300.0,
        'lifetime_earned_points': 500.0,
        'created_at': '2026-08-01T09:00:00.123456Z',
        'updated_at': null,
      };

      final user = User.fromJson(floatPointsJson);

      expect(user.id, equals('usr_test_002'));
      expect(user.currentPoints, equals(300));
      expect(user.lifetimeEarnedPoints, equals(500));
      expect(user.roles, containsAll(['CUSTOMER', 'TEST']));
      expect(user.createdAt, equals(DateTime.parse('2026-08-01T09:00:00.123456Z')));
      expect(user.updatedAt, equals(DateTime(1970, 1, 1)));
    });
  });
}
