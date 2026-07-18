import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/main.dart';
import 'package:frontend/constants/strings.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/notification_provider.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/providers/profile_provider.dart';
import 'package:frontend/providers/search_provider.dart';
import 'package:frontend/providers/favorite_provider.dart';
import 'package:frontend/providers/activity_provider.dart';
import 'package:frontend/providers/personalization_provider.dart';
import 'package:frontend/providers/analytics_provider.dart';

void main() {
  testWidgets('Nampo GoGo App Navigation Smoke Test', (WidgetTester tester) async {
    await tester.runAsync(() async {
      // Build Nampo GoGo app and trigger a frame with providers
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => NotificationProvider()),
            ChangeNotifierProvider(create: (_) => ProfileProvider()),
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => FavoriteProvider()),
            ChangeNotifierProvider(create: (_) => ActivityProvider()),
            ChangeNotifierProvider(create: (_) => PersonalizationProvider()),
            ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pump();

      // Verify that Nampo GoGo welcome text is present
      expect(find.text('${AppStrings.homeWelcomeTitle} 👋'), findsOneWidget);
      
      // Verify that we have a bottom navigation bar
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });
}
