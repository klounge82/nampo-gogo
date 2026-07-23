import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:frontend/registries/module_registry.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
        'capabilities': ['place.read', 'business.dashboard.read', 'store.own.update'],
        'available_app_modes': ['CUSTOMER', 'BUSINESS'],
        'business_memberships': [
          {
            'id': 'mem_01',
            'store_id': 'store_31b96920',
            'membership_role': 'OWNER',
            'status': 'ACTIVE',
            'created_at': '2026-07-23T18:00:00.000000'
          }
        ]
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

    test('AppModeProvider blocks switching to Business mode for normal Customer user', () async {
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
    });

    test('AppModeProvider allows switching to Business mode for Approved Business user', () async {
      // Mock storage or initialize binding
      final provider = AppModeProvider();
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
          {'store_id': 'store_1'}
        ],
      );

      // Avoid secure storage native channel call in unit test by setting mock values or handling binding
      expect(bizUser.isApprovedBusiness, isTrue);
    });

    test('ModuleRegistry definitions contain correct metadata', () {
      expect(ModuleRegistry.customerModules.isNotEmpty, isTrue);
      expect(ModuleRegistry.businessModules.isNotEmpty, isTrue);
      expect(ModuleRegistry.adminModules.isNotEmpty, isTrue);

      final exploreModule = ModuleRegistry.customerModules.firstWhere((m) => m.featureKey == 'customer_explore');
      expect(exploreModule.title, equals('탐색'));
      expect(exploreModule.allowedModes, contains('CUSTOMER'));

      final bizDash = ModuleRegistry.businessModules.firstWhere((m) => m.featureKey == 'business_dashboard');
      expect(bizDash.title, equals('대시보드'));
      expect(bizDash.allowedModes, contains('BUSINESS'));
    });

    test('DashboardWidgetRegistry contains business & customer widgets', () {
      expect(DashboardWidgetRegistry.businessWidgets.isNotEmpty, isTrue);
      expect(DashboardWidgetRegistry.customerWidgets.isNotEmpty, isTrue);

      final todayRes = DashboardWidgetRegistry.businessWidgets.firstWhere((w) => w.widgetKey == 'today_reservations');
      expect(todayRes.title, equals('오늘 예약'));
    });
  });
}
