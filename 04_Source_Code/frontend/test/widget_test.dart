import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/constants/strings.dart';

void main() {
  testWidgets('Nampo GoGo App Navigation Smoke Test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build Nampo GoGo app and trigger a frame.
      await tester.pumpWidget(const MyApp());
      await tester.pump();

      // Verify that Nampo GoGo welcome text is present
      expect(find.text('${AppStrings.homeWelcomeTitle} 👋'), findsOneWidget);
      
      // Verify that we have a bottom navigation bar
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
