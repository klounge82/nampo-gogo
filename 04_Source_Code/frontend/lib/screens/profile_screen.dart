import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';
import 'point_history_screen.dart';
import 'coupon_list_screen.dart';
import 'user_coupon_screen.dart';
import 'my_reservations_screen.dart';
import 'my_reviews_screen.dart';
import 'admin_dashboard_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'payment_history_screen.dart';
import 'notification_settings_screen.dart';
import 'favorites_screen.dart';
import 'activity_screen.dart';
import 'saved_courses_screen.dart';
import 'language_settings_screen.dart';
import 'profile_edit_screen.dart';
import 'change_password_screen.dart';
import 'account_delete_screen.dart';
import '../l10n/app_localizations.dart';
import '../config/production_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.profileTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showComingSoon(context, '설정'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile Card Header (Conditional login UI)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36.0,
                    backgroundColor: isLoggedIn 
                        ? AppColors.primary.withAlpha(26) 
                        : Colors.grey.withAlpha(26),
                    backgroundImage: (isLoggedIn && user?.profileImageUrl != null)
                        ? NetworkImage(user!.profileImageUrl!)
                        : null,
                    child: (isLoggedIn && user?.profileImageUrl != null)
                        ? null
                        : Icon(
                            isLoggedIn ? Icons.person : Icons.lock_outline,
                            size: 40.0,
                            color: isLoggedIn ? AppColors.primary : Colors.grey,
                          ),
                  ),
                  const SizedBox(width: 20.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isLoggedIn ? '${user?.nickname}' : '게스트 사용자',
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isLoggedIn) ...[
                              const SizedBox(width: 8.0),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => const ProfileEditScreen()),
                                  );
                                },
                                child: const Icon(Icons.edit, size: 18, color: Colors.blueAccent),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          isLoggedIn 
                              ? '${user?.email}' 
                              : '로그인 후 더 많은 기능을 사용해 보세요.',
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  isLoggedIn
                      ? OutlinedButton(
                          onPressed: () => authProvider.logout(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('로그아웃', style: TextStyle(fontSize: 12.0)),
                        )
                      : ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: const Text('로그인', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
            ),
            
            // Assets Overview (Points, Coupons)
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildAssetColumn(
                    icon: Icons.monetization_on,
                    iconColor: AppColors.primary,
                    value: isLoggedIn ? '${user?.currentPoints ?? 0} P' : '0 P',
                    label: '보유 포인트',
                    onTap: () {
                      if (isLoggedIn) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const PointHistoryScreen()),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    },
                  ),
                  Container(
                    width: 1.0,
                    height: 40.0,
                    color: AppColors.border,
                  ),
                  _buildAssetColumn(
                    icon: Icons.confirmation_number,
                    iconColor: AppColors.secondary,
                    value: isLoggedIn ? '확인하기' : '0 개',
                    label: '보유 쿠폰',
                    onTap: () {
                      if (isLoggedIn) {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const UserCouponScreen()),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Menu List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 12.0),
                    child: Text(
                      '서비스 설정',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _buildMenuCard([
                    if (isLoggedIn && authProvider.currentUser?.role == 'admin')
                      _buildMenuItem(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: '관리자 시스템 대시보드',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                          );
                        },
                      ),
                    if (isLoggedIn && (authProvider.currentUser?.role == 'owner' || authProvider.currentUser?.role == 'admin'))
                      _buildMenuItem(
                        context,
                        icon: Icons.analytics_outlined,
                        title: '비즈니스 통계 대시보드',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AnalyticsDashboardScreen()),
                          );
                        },
                      ),
                    _buildMenuItem(
                      context,
                      icon: Icons.storefront,
                      title: '포인트 교환소',
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const CouponListScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.calendar_month,
                      title: '내 예약 내역',
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.rate_review_outlined,
                      title: '내가 작성한 리뷰',
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.history,
                      title: '내 활동 기록',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ActivityScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.payment,
                      title: '결제 및 이용 이력',
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PaymentHistoryScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite_border,
                      title: '즐겨찾기 보관함',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                        );
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.feedback_outlined,
                      title: '내 피드백 & 문의',
                      onTap: () => _launchURL(context, ProductionConfig.supportUrl),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.notifications_active_outlined,
                      title: l10n.notificationSetting,
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.favorite_border,
                      title: l10n.mySavedCourses,
                      onTap: () {
                        if (isLoggedIn) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SavedCoursesScreen()),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.language_outlined,
                      title: l10n.languageSetting,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                        );
                      },
                    ),
                  ]),
                  
                  const Padding(
                    padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 20.0),
                    child: Text(
                      '정보 및 지원',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _buildMenuCard([
                    _buildMenuItem(
                      context,
                      icon: Icons.info_outline,
                      title: '서비스 소개',
                      onTap: () => _launchURL(context, ProductionConfig.publicSiteUrl),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.shield_outlined,
                      title: '개인정보 처리방침',
                      onTap: () => _launchURL(context, ProductionConfig.privacyPolicyUrl),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.description_outlined,
                      title: '이용약관',
                      onTap: () => _launchURL(context, ProductionConfig.termsOfServiceUrl),
                    ),
                    _buildMenuItem(
                      context,
                      icon: Icons.support_agent_outlined,
                      title: '고객지원 센터',
                      onTap: () => _launchURL(context, ProductionConfig.supportUrl),
                    ),
                  ]),
                  
                  if (isLoggedIn) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0, bottom: 8.0, top: 20.0),
                      child: Text(
                        '계정 관리',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _buildMenuCard([
                      _buildMenuItem(
                        context,
                        icon: Icons.lock_reset_outlined,
                        title: '비밀번호 변경',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.no_accounts_outlined,
                        title: '회원탈퇴',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const AccountDeleteScreen()),
                          );
                        },
                      ),
                    ]),
                  ],
                  const SizedBox(height: 28.0),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetColumn({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28.0),
            const SizedBox(height: 6.0),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.0,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Column(children: items),
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: AppColors.textPrimary, size: 22.0),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14.0,
            color: AppColors.textPrimary,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textSecondary,
          size: 18.0,
        ),
        onTap: onTap,
        dense: true,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String title) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[$title] 페이지는 MVP 1차 릴리즈 이후 공개됩니다.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(context);
      }
    } catch (_) {
      _showErrorSnackBar(context);
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('페이지를 열 수 없습니다. 잠시 후 다시 시도해 주세요.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
