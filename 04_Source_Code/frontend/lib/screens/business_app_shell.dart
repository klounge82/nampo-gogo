import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../theme/business_theme.dart';
import 'business_dashboard_screen.dart';
import 'business_store_screen.dart';
import 'business_products_screen.dart';
import 'business_reviews_screen.dart';

class BusinessAppShell extends StatefulWidget {
  const BusinessAppShell({super.key});

  @override
  State<BusinessAppShell> createState() => _BusinessAppShellState();
}

class _BusinessAppShellState extends State<BusinessAppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BusinessDashboardScreen(),
    BusinessStoreScreen(),
    BusinessProductsScreen(),
    BusinessReviewsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);

    // Sync mode with user
    modeProvider.syncUser(authProvider.currentUser);

    return Theme(
      data: BusinessTheme.themeData,
      child: Scaffold(
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: BusinessTheme.primaryTeal,
          unselectedItemColor: const Color(0xFF64748B),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: '대시보드',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: '매장 정보',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu),
              label: '상품 관리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review),
              label: '손님 리뷰',
            ),
          ],
        ),
      ),
    );
  }
}
