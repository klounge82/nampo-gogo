import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';
import 'package:frontend/screens/business_reservations_screen.dart';

void main() {
  group('HOTFIX-008: Reservation Null-safe Parsing & UI Tests', () {
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
  });
}
