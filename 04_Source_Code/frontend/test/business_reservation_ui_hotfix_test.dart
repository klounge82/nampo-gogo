import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/build_info.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';
import 'package:frontend/screens/business_reservations_screen.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('RELEASE-001-I2: Reservation End-to-End & Build Metadata Tests', () {


    test(
      '1. Dashboard widget registry marks all 4 reservation cards available',
      () {
        final todayWidget = DashboardWidgetRegistry.businessWidgets.firstWhere(
          (w) => w.widgetKey == 'today_reservations',
        );
        final pendingWidget = DashboardWidgetRegistry.businessWidgets
            .firstWhere((w) => w.widgetKey == 'pending_reservations');
        final completedWidget = DashboardWidgetRegistry.businessWidgets
            .firstWhere((w) => w.widgetKey == 'completed_reservations');
        final settingsWidget = DashboardWidgetRegistry.businessWidgets
            .firstWhere((w) => w.widgetKey == 'reservation_settings');

        expect(todayWidget.available, isTrue);
        expect(pendingWidget.available, isTrue);
        expect(completedWidget.available, isTrue);
        expect(settingsWidget.available, isTrue);
      },
    );

    test(
      '2. BusinessReservationsScreen instantiates safely with null-safe defaults',
      () {
        const screen = BusinessReservationsScreen(
          initialTabIndex: 0,
          initialFilter: 'PENDING',
        );

        expect(screen.initialTabIndex, equals(0));
        expect(screen.initialFilter, equals('PENDING'));
      },
    );

    test(
      '3. AppModeProvider 3-roundtrip mode switching retains session state',
      () async {
        final modeProvider = AppModeProvider();
        final testUser = User(
          id: 'e1d38954-ba8c-4c85-bc0e-39fec0886360',
          email: 'jazzbj@naver.com',
          nickname: 'jazzbj',
          role: 'admin',
          status: 'active',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          roles: const ['CUSTOMER', 'ADMIN', 'BUSINESS'],
          availableAppModes: const ['CUSTOMER', 'BUSINESS', 'ADMIN'],
        );

        // Roundtrip 1
        await modeProvider.switchMode(AppMode.business, testUser);
        expect(modeProvider.isBusinessMode, isTrue);
        await modeProvider.switchMode(AppMode.customer, testUser);
        expect(modeProvider.isCustomerMode, isTrue);

        // Roundtrip 2
        await modeProvider.switchMode(AppMode.business, testUser);
        expect(modeProvider.isBusinessMode, isTrue);
        await modeProvider.switchMode(AppMode.customer, testUser);
        expect(modeProvider.isCustomerMode, isTrue);

        // Roundtrip 3
        await modeProvider.switchMode(AppMode.business, testUser);
        expect(modeProvider.isBusinessMode, isTrue);
        await modeProvider.switchMode(AppMode.customer, testUser);
        expect(modeProvider.isCustomerMode, isTrue);

        expect(testUser.hasRole('CUSTOMER'), isTrue);
        expect(testUser.hasRole('BUSINESS'), isTrue);
      },
    );

    test(
      '4. BuildInfo metadata provides dynamic app build name, commit hash, and build time',
      () {
        expect(BuildInfo.appBuildName, equals('RELEASE-001-I2'));
        expect(BuildInfo.commitHash, isNotEmpty);
        expect(BuildInfo.buildTime, isNotEmpty);
      },
    );
  });
}
