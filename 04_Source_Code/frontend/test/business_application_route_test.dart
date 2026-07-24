import 'package:flutter_test/flutter_test.dart';
import '../lib/services/business_service.dart';
import '../lib/registries/module_registry.dart';
import '../lib/registries/dashboard_widget_registry.dart';

void main() {
  group('Business Application Route & Error Handling Unit Tests', () {
    test('Official Business Application Route metadata is consistent', () {
      final module = ModuleRegistry.businessModules
          .firstWhere((m) => m.featureKey == 'business_store_manage');
      expect(module.route, '/business/store');

      final widget = DashboardWidgetRegistry.businessWidgets
          .firstWhere((w) => w.widgetKey == 'store_status');
      expect(widget.targetRoute, '/business/store');
    });

    test('BusinessService instantiates without error', () {
      final service = BusinessService();
      expect(service, isNotNull);
    });
  });
}
