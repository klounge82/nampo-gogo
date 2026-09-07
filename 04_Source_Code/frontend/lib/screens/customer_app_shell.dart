import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../theme/customer_theme.dart';
import '../l10n/app_localizations.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'recommendation_input_screen.dart';
import 'favorites_screen.dart';
import 'profile_screen.dart';

class CustomerAppShell extends StatefulWidget {
  const CustomerAppShell({super.key});

  @override
  State<CustomerAppShell> createState() => _CustomerAppShellState();
}

class _CustomerAppShellState extends State<CustomerAppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    MapScreen(),
    RecommendationInputScreen(),
    FavoritesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);
    final l10n = AppLocalizations.of(context);

    // Sync mode status with user object
    modeProvider.syncUser(authProvider.currentUser);

    return Theme(
      data: CustomerTheme.themeData,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home_outlined),
              activeIcon: const Icon(Icons.home),
              label: l10n?.navHome ?? '홈',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore_outlined),
              activeIcon: const Icon(Icons.explore),
              label: l10n?.navExplore ?? '탐색',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.map_outlined),
              activeIcon: const Icon(Icons.map),
              label: l10n?.navCourses ?? '코스',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.bookmark_border),
              activeIcon: const Icon(Icons.bookmark),
              label: l10n?.navSaved ?? '저장',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: l10n?.navProfile ?? '내 정보',
            ),
          ],
        ),
      ),
    );
  }
}
