import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/build_info.dart';
import 'package:frontend/screens/business_dashboard_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HOTFIX-013: Build Identity & Footer Forensic Tests', () {
    test(
      '1. BuildInfo unit test provides exact RELEASE-001-I3 and e0195a1 values',
      () {
        expect(BuildInfo.appBuildName, equals('RELEASE-001-I3'));
        expect(BuildInfo.commitHash, equals('e0195a1'));
        expect(BuildInfo.appBuildName, isNot(equals('HOTFIX-012')));
        expect(BuildInfo.commitHash, isNot(equals('f40d58a')));
      },
    );

    testWidgets(
      '2. BusinessDashboardScreen Footer displays RELEASE-001-I3 and e0195a1',
      (WidgetTester tester) async {
        final authProvider = AuthProvider();
        final appModeProvider = AppModeProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<AppModeProvider>.value(
                value: appModeProvider,
              ),
            ],
            child: const MaterialApp(
              home: Scaffold(body: BusinessDashboardScreen()),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 500));

        // Verify Footer contains RELEASE-001-I3 and e0195a1
        expect(find.textContaining('RELEASE-001-I3'), findsWidgets);
        expect(find.textContaining('e0195a1'), findsWidgets);

        // Verify legacy strings are strictly NOT present
        expect(find.textContaining('HOTFIX-012'), findsNothing);
        expect(find.textContaining('f40d58a'), findsNothing);
      },
    );
  });
}
