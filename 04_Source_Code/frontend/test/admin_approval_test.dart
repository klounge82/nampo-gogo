import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/themes/admin_theme.dart';
import 'package:frontend/screens/admin/admin_app_shell.dart';
import 'package:frontend/screens/business_pending_shell.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/app_mode_provider.dart';

void main() {
  group('Admin Business Approval & Access Guard Frontend Unit Tests', () {
    test('AdminTheme produces dark palette correctly', () {
      final theme = AdminTheme.themeData;
      expect(theme.scaffoldBackgroundColor, AdminTheme.darkBg);
      expect(theme.primaryColor, AdminTheme.primaryBlue);
    });

    testWidgets('AdminAppShell shows Access Denied for unauthenticated user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
          ],
          child: const MaterialApp(home: AdminAppShell()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(AdminAccessDeniedScreen), findsOneWidget);
      expect(find.textContaining('접근 권한 제한'), findsOneWidget);
    });

    testWidgets('BusinessPendingShell renders PENDING status correctly', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => AppModeProvider()),
          ],
          child: const MaterialApp(home: BusinessPendingShell()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('사업자 승인 대기'), findsWidgets);
      expect(find.textContaining('Customer'), findsOneWidget);
    });
  });
}
