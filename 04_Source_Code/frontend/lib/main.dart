import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'constants/colors.dart';
import 'constants/strings.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/search_provider.dart';
import 'providers/favorite_provider.dart';
import 'providers/activity_provider.dart';
import 'providers/personalization_provider.dart';
import 'providers/analytics_provider.dart';
import 'services/notification_service.dart';
import 'providers/app_mode_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/business_app_shell.dart';
import 'theme/customer_theme.dart';
import 'theme/business_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Safe notification initialization
  final notifService = NotificationService();
  await notifService.initialize();
  await notifService.requestPermissions();

  // Load language settings on boot
  final localeProvider = LocaleProvider();
  await localeProvider.initLocale();

  final appModeProvider = AppModeProvider();

  runApp(
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
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider.value(value: appModeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final modeProvider = context.watch<AppModeProvider>();

    final activeTheme = modeProvider.isBusinessMode
        ? BusinessTheme.themeData
        : CustomerTheme.themeData;

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      locale: localeProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('zh'),
        Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ],
      theme: activeTheme,
      home: const RootNavigationSelector(),
    );
  }
}

class RootNavigationSelector extends StatelessWidget {
  const RootNavigationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<AppModeProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Initialize mode if needed
    modeProvider.syncUser(authProvider.currentUser);

    if (modeProvider.isBusinessMode) {
      return const BusinessAppShell();
    }
    return const MainNavigationScreen();
  }
}
