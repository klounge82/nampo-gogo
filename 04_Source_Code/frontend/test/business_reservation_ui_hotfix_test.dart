import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';
import 'package:frontend/screens/business_reservations_screen.dart';

void main() {
  group('HOTFIX-006: Business Reservation UI & Route Activation Tests', () {
    test('1. Dashboard widget registry marks reservation cards available', () {
      final todayWidget = DashboardWidgetRegistry.businessWidgets.firstWhere(
        (w) => w.widgetKey == 'today_reservations',
      );
      final pendingWidget = DashboardWidgetRegistry.businessWidgets.firstWhere(
        (w) => w.widgetKey == 'pending_reservations',
      );

      expect(todayWidget.available, isTrue);
      expect(todayWidget.targetRoute, equals('/business/reservations'));
      expect(pendingWidget.available, isTrue);
      expect(pendingWidget.targetRoute, equals('/business/reservations'));
    });

    test(
      '2. BusinessReservationsScreen instantiated with initialTabIndex & initialFilter',
      () {
        const screen = BusinessReservationsScreen(
          initialTabIndex: 1,
          initialFilter: 'PENDING',
        );

        expect(screen.initialTabIndex, equals(1));
        expect(screen.initialFilter, equals('PENDING'));
      },
    );
  });
}
