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
      '1. BuildInfo unit test provides non-empty appBuildName and commitHash',
      () {
        expect(BuildInfo.appBuildName, isNotEmpty);
        expect(BuildInfo.commitHash, isNotEmpty);
        expect(BuildInfo.appBuildName, isNot(equals('HOTFIX-012')));
        expect(BuildInfo.commitHash, isNot(equals('f40d58a')));
      },
    );

    testWidgets(
      '2. BusinessDashboardScreen Footer displays build info',
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

        expect(find.textContaining(BuildInfo.appBuildName), findsWidgets);
        expect(find.textContaining(BuildInfo.commitHash), findsWidgets);

        expect(find.textContaining('HOTFIX-012'), findsNothing);
        expect(find.textContaining('f40d58a'), findsNothing);
      },
    );

  });
}
