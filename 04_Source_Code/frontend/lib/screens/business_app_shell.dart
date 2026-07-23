import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../theme/business_theme.dart';
import 'business_dashboard_screen.dart';
import 'admin_reservation_manage_screen.dart';
import 'admin_review_manage_screen.dart';

class BusinessAppShell extends StatefulWidget {
  const BusinessAppShell({super.key});

  @override
  State<BusinessAppShell> createState() => _BusinessAppShellState();
}

class _BusinessAppShellState extends State<BusinessAppShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    BusinessDashboardScreen(),
    AdminReservationManageScreen(),
    _BusinessPlaceholderScreen(title: '매장 정보 관리'),
    AdminReviewManageScreen(),
    _BusinessPlaceholderScreen(title: '사업자 더보기 설정'),
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
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today),
              label: '예약',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.store_outlined),
              activeIcon: Icon(Icons.store),
              label: '매장 관리',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.rate_review_outlined),
              activeIcon: Icon(Icons.rate_review),
              label: '리뷰',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.more_horiz),
              activeIcon: Icon(Icons.more_horiz),
              label: '더보기',
            ),
          ],
        ),
      ),
    );
  }
}

class _BusinessPlaceholderScreen extends StatelessWidget {
  final String title;

  const _BusinessPlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.construction,
              size: 48,
              color: BusinessTheme.primaryTeal,
            ),
            const SizedBox(height: 16),
            Text(
              '$title 기능은 준비 중입니다.',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '다음 업데이트에서 세부 관리 도구가 제공됩니다.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
