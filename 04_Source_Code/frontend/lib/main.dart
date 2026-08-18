import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
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
import 'screens/admin/admin_app_shell.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/business_app_shell.dart';
import 'screens/business_pending_shell.dart';
import 'theme/customer_theme.dart';
import 'theme/business_theme.dart';
import 'screens/brand_splash_screen.dart';
import 'screens/auth_choice_screen.dart';

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

  // Initialize Auth session on boot before rendering UI
  final authProvider = AuthProvider();
  await authProvider.autoLogin();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
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
      child: const NampoGoGoApp(),
    ),
  );
}

class NampoGoGoApp extends StatelessWidget {
  const NampoGoGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.watch<AppModeProvider>().isBusinessMode
        ? BusinessTheme.themeData
        : CustomerTheme.themeData;
    final localeProvider = context.watch<LocaleProvider>();

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
        Locale('ru'),
        Locale('vi'),
      ],
      theme: activeTheme,
      home: const BrandSplashScreen(),
      routes: {'/admin': (context) => const AdminAppShell()},
    );
  }
}

class RootNavigationSelector extends StatelessWidget {
  const RootNavigationSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final modeProvider = context.watch<AppModeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Unauthenticated landing screen
    if (!authProvider.isLoggedIn || user == null) {
      return const AuthChoiceScreen();
    }

    // Initialize mode if needed
    modeProvider.syncUser(user);

    if (user.businessApplicationStatus == 'PENDING' &&
        modeProvider.isBusinessMode) {
      return const BusinessPendingShell();
    }

    if (modeProvider.isBusinessMode) {
      return const BusinessAppShell();
    }
    return const MainNavigationScreen();
  }
}
