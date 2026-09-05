import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_mode_provider.dart';
import '../../utils/l10n_mappers.dart';
import '../../main.dart';
import '../../themes/admin_theme.dart';
import 'admin_dashboard_screen.dart';
import 'admin_business_approval_screen.dart';
import 'admin_member_manage_screen.dart';
import '../admin_store_manage_screen.dart';
import 'admin_point_gift_monitor_screen.dart';

class AdminAppShell extends StatefulWidget {
  const AdminAppShell({super.key});

  @override
  State<AdminAppShell> createState() => _AdminAppShellState();
}

class _AdminAppShellState extends State<AdminAppShell> {
  int _selectedIndex = 0;
  String _approvalFilter = 'ALL';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AdminTheme.themeData,
      child: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          final user = auth.currentUser;
          final isNotAdmin =
              !auth.isLoggedIn ||
              user == null ||
              (!user.roles.contains('ADMIN') && user.role != 'admin');
          if (isNotAdmin) {
            return const AdminAccessDeniedScreen();
          }

          final switchText = L10nMappers.mapSwitchToCustomerMode(
            Localizations.localeOf(context).languageCode,
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;

              if (isMobile) {
                return PopScope(
                  canPop: false,
                  onPopInvokedWithResult: (didPop, result) async {
                    if (didPop) return;
                    if (_selectedIndex != 0) {
                      setState(() {
                        _selectedIndex = 0;
                      });
                    } else {
                      final modeProvider = Provider.of<AppModeProvider>(
                        context,
                        listen: false,
                      );
                      modeProvider.setCustomerInitialTab(4);
                      await modeProvider.switchMode(
                        AppMode.customer,
                        auth.currentUser,
                      );
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const RootNavigationSelector(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: AdminTheme.darkBg,
                    appBar: AppBar(
                      backgroundColor: AdminTheme.sidebarBg,
                      elevation: 0.5,
                      leading: _selectedIndex != 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back, color: AdminTheme.textPrimary),
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 0;
                                });
                              },
                            )
                          : null,
                      title: const Text(
                        '남포동 고고 총관리자',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      actions: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final modeProvider = Provider.of<AppModeProvider>(
                              context,
                              listen: false,
                            );
                            modeProvider.setCustomerInitialTab(4);
                            await modeProvider.switchMode(
                              AppMode.customer,
                              auth.currentUser,
                            );
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => const RootNavigationSelector(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.swap_horiz,
                            size: 14,
                            color: AdminTheme.primaryBlue,
                          ),
                          label: Text(
                            switchText,
                            style: const TextStyle(
                              color: AdminTheme.primaryBlue,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AdminTheme.primaryBlue),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    drawer: Drawer(
                      backgroundColor: AdminTheme.sidebarBg,
                      child: _buildSidebar(auth, isMobile: true),
                    ),
                    body: _buildBody(),
                  ),
                );
              }

              return Scaffold(
                backgroundColor: AdminTheme.darkBg,
                body: Row(
                  children: [
                    // PC Sidebar Navigation
                    _buildSidebar(auth, isMobile: false),

                    // Main Content Body
                    Expanded(
                      child: Column(
                        children: [
                          // Header Bar
                          _buildHeader(auth),

                          // Screen View
                          Expanded(child: _buildBody()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSidebar(AuthProvider auth, {bool isMobile = false}) {
    final switchText = L10nMappers.mapSwitchToCustomerMode(Localizations.localeOf(context).languageCode);

    return Container(
      width: 240,
      color: AdminTheme.sidebarBg,
      child: Column(
        children: [
          // Logo Header
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AdminTheme.primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '남포동 고고',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AdminTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '총관리자 콘솔',
                      style: TextStyle(
                        fontSize: 11,
                        color: AdminTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Color(0xFF334155), height: 1),

          const SizedBox(height: 12),

          // Menu Items
          _buildNavItem(0, Icons.dashboard, '대시보드', active: true, isMobile: isMobile),
          _buildNavItem(1, Icons.verified_user, '사업자 승인', active: true, isMobile: isMobile),
          _buildNavItem(2, Icons.people, '회원 관리', active: true, isMobile: isMobile),
          _buildNavItem(3, Icons.store, '매장 관리', active: true, isMobile: isMobile),
          _buildNavItem(4, Icons.card_giftcard, '포인트 / 선물 관리', active: true, isMobile: isMobile),
          _buildNavItem(5, Icons.rate_review, '리뷰·신고', active: false, isMobile: isMobile),
          _buildNavItem(6, Icons.settings, '시스템 설정', active: false, isMobile: isMobile),

          const Spacer(),

          // Footer User Profile & Switch to Customer Mode Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () async {
                    final modeProvider = Provider.of<AppModeProvider>(context, listen: false);
                    modeProvider.setCustomerInitialTab(4);
                    await modeProvider.switchMode(AppMode.customer, auth.currentUser);
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const RootNavigationSelector(),
                        ),
                        (route) => false,
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: AdminTheme.primaryBlue.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AdminTheme.primaryBlue.withAlpha(100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swap_horiz, size: 16, color: AdminTheme.primaryBlue),
                        const SizedBox(width: 6),
                        Text(
                          switchText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: AdminTheme.primaryBlue,
                        radius: 16,
                        child: Icon(Icons.person, size: 18, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.currentUser?.nickname ?? '관리자',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AdminTheme.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Text(
                              '총관리자 (ADMIN)',
                              style: TextStyle(
                                fontSize: 10,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String title, {
    required bool active,
    bool isMobile = false,
  }) {
    final isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected
            ? AdminTheme.primaryBlue
            : (active ? AdminTheme.textSecondary : Colors.grey[600]),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected
              ? AdminTheme.primaryBlue
              : (active ? AdminTheme.textPrimary : Colors.grey[600]),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
      trailing: active
          ? null
          : const Icon(Icons.lock_outline, size: 14, color: Colors.grey),
      selected: isSelected,
      onTap: () {
        if (isMobile) {
          if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
            _scaffoldKey.currentState?.closeDrawer();
          }
        }
        if (!active) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text(title),
              content: const Text('준비 중인 기능입니다.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('확인'),
                ),
              ],
            ),
          );
          return;
        }
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }

  Widget _buildHeader(AuthProvider auth) {
    final switchText = L10nMappers.mapSwitchToCustomerMode(Localizations.localeOf(context).languageCode);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: AdminTheme.sidebarBg,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PC 관리자 모드',
            style: TextStyle(fontSize: 14, color: AdminTheme.textSecondary),
          ),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () async {
                  final modeProvider = Provider.of<AppModeProvider>(context, listen: false);
                  modeProvider.setCustomerInitialTab(4);
                  await modeProvider.switchMode(AppMode.customer, auth.currentUser);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const RootNavigationSelector(),
                      ),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(
                  Icons.swap_horiz,
                  size: 16,
                  color: AdminTheme.primaryBlue,
                ),
                label: Text(
                  switchText,
                  style: const TextStyle(
                    color: AdminTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AdminTheme.primaryBlue),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 12),
              TextButton.icon(
                onPressed: () async {
                  await auth.logout();
                },
                icon: const Icon(
                  Icons.logout,
                  size: 16,
                  color: AdminTheme.errorRose,
                ),
                label: const Text(
                  '로그아웃',
                  style: TextStyle(color: AdminTheme.errorRose),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return AdminDashboardScreen(
          onSelectFilter: (filter) {
            setState(() {
              _approvalFilter = filter;
              _selectedIndex = 1;
            });
          },
        );
      case 1:
        return AdminBusinessApprovalScreen(
          initialStatusFilter: _approvalFilter,
        );
      case 2:
        return const AdminMemberManageScreen();
      case 3:
        return const AdminStoreManageScreen();
      case 4:
        return const AdminPointGiftMonitorScreen();
      default:
        return const Center(child: Text('준비 중인 기능입니다.'));
    }
  }
}

class AdminAccessDeniedScreen extends StatelessWidget {
  const AdminAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.darkBg,
      body: Center(
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AdminTheme.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.errorRose.withOpacity(0.4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.gpp_maybe,
                size: 64,
                color: AdminTheme.errorRose,
              ),
              const SizedBox(height: 16),
              const Text(
                '접근 권한 제한 (HTTP 403)',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '관리자(ADMIN) 권한이 없는 계정입니다.\n관리자 콘솔은 권한을 보유한 계정으로 로그인 후 이용해 주세요.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AdminTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.primaryBlue,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('메인 화면으로 돌아가기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
