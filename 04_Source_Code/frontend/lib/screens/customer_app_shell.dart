import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../theme/customer_theme.dart';
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
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: '탐색',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: '코스',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              activeIcon: Icon(Icons.bookmark),
              label: '저장',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '내 정보',
            ),
          ],
        ),
      ),
    );
  }
}
