import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../config/production_config.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'profile_screen.dart';
import 'recommendation_input_screen.dart';
import 'saved_courses_screen.dart';
import 'favorites_screen.dart';
import 'point_history_screen.dart';
import 'user_coupon_screen.dart';
import 'my_reservations_screen.dart';
import 'my_reviews_screen.dart';
import 'activity_screen.dart';
import 'payment_history_screen.dart';
import 'business_application_screen.dart';
import 'business_dashboard_screen.dart';
import 'notification_settings_screen.dart';
import 'language_settings_screen.dart';
import 'policy_viewer_screen.dart';
import 'auth_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.currentUser;
    final appModeProvider = context.watch<AppModeProvider>();
    final isBusinessMode = appModeProvider.isBusinessMode;
    final loc = context.watch<LocaleProvider>().currentLocaleCode;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.more,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // 1. Top Profile Header Card -> Navigates to Dedicated Account Screen
          _buildProfileHeaderCard(context, isLoggedIn, user, l10n),
          const SizedBox(height: 24.0),

          // 2. [나의 활동] Section
          _buildSectionHeader(l10n.moreMyActivitySection),
          const SizedBox(height: 8.0),
          _buildMenuTile(
            icon: Icons.calendar_month_outlined,
            title: l10n.profileMyReservations,
            color: Colors.blueAccent,
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
          _buildMenuTile(
            icon: Icons.rate_review_outlined,
            title: l10n.profileMyReviews,
            color: Colors.deepPurple,
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
          _buildMenuTile(
            icon: Icons.history,
            title: l10n.profileActivityLog,
            color: Colors.indigo,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ActivityScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.payment_outlined,
            title: l10n.profilePaymentHistory,
            color: Colors.green,
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
          _buildMenuTile(
            icon: Icons.bookmark_outline,
            title: l10n.mySavedCourses,
            subtitle: l10n.moreSavedCoursesDesc,
            color: AppColors.secondary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedCoursesScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.auto_awesome,
            title: l10n.recommendTitle,
            subtitle: l10n.moreAiCourseDesc,
            color: AppColors.primary,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RecommendationInputScreen()),
              );
            },
          ),
          const SizedBox(height: 24.0),

          // 3. [혜택] Section
          _buildSectionHeader(l10n.moreBenefitsSection),
          const SizedBox(height: 8.0),
          _buildMenuTile(
            icon: Icons.monetization_on_outlined,
            title: l10n.pointHistoryTitle,
            subtitle: l10n.morePointHistoryDesc,
            color: Colors.amber.shade800,
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
          _buildMenuTile(
            icon: Icons.confirmation_number_outlined,
            title: l10n.profileCouponsLabel,
            subtitle: l10n.moreCouponListDesc,
            color: Colors.teal,
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
          _buildMenuTile(
            icon: Icons.favorite_outline,
            title: l10n.moreFavoritesTitle,
            subtitle: l10n.moreFavoritesDesc,
            color: Colors.pink,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FavoritesScreen()),
              );
            },
          ),
          const SizedBox(height: 24.0),

          // 4. [지원] Section
          _buildSectionHeader(l10n.moreSupportSection),
          const SizedBox(height: 8.0),
          _buildMenuTile(
            icon: Icons.feedback_outlined,
            title: l10n.profileFeedback,
            color: Colors.blueGrey,
            onTap: () => _launchURL(context, ProductionConfig.supportUrl),
          ),
          _buildMenuTile(
            icon: Icons.support_agent_outlined,
            title: l10n.customerSupportCenter,
            color: Colors.blueGrey,
            onTap: () => _launchURL(context, ProductionConfig.supportUrl),
          ),
          _buildMenuTile(
            icon: Icons.event_note_outlined,
            title: l10n.policyRefundTitle,
            color: Colors.blueGrey,
            onTap: () {
              PolicyViewerScreen.show(
                context,
                title: l10n.policyRefundTitle,
                content: PolicyTexts.getReservationPolicy(loc),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.location_on_outlined,
            title: l10n.locationInfoTitle,
            color: Colors.blueGrey,
            onTap: () {
              PolicyViewerScreen.show(
                context,
                title: l10n.locationInfoTitle,
                content: PolicyTexts.getLocationCameraGuide(loc),
              );
            },
          ),
          const SizedBox(height: 24.0),

          // 5. [모드 전환] Section
          if (isLoggedIn) ...[
            _buildSectionHeader(l10n.moreModeSwitchSection),
            const SizedBox(height: 8.0),
            if (user?.isApprovedBusiness == true || user?.isAdmin == true)
              _buildMenuTile(
                icon: Icons.storefront_outlined,
                title: isBusinessMode ? l10n.moreSwitchToCustomer : l10n.moreSwitchToBusiness,
                subtitle: isBusinessMode ? l10n.moreSwitchToCustomerDesc : l10n.moreSwitchToBusinessDesc,
                color: Colors.deepOrange,
                onTap: () async {
                  final targetMode = isBusinessMode ? AppMode.customer : AppMode.business;
                  await appModeProvider.switchMode(targetMode, user);
                  if (targetMode == AppMode.business && context.mounted) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BusinessDashboardScreen()),
                    );
                  }
                },
              )
            else
              _buildMenuTile(
                icon: Icons.storefront_outlined,
                title: l10n.profileBusinessApply,
                color: Colors.deepOrange,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const BusinessApplicationScreen()),
                  );
                },
              ),
            if (user?.isAdmin == true)
              _buildMenuTile(
                icon: Icons.admin_panel_settings_outlined,
                title: l10n.moreAdminSwitch,
                color: Colors.redAccent,
                onTap: () async {
                  await appModeProvider.switchMode(AppMode.admin, user);
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const RootNavigationSelector(),
                      ),
                      (route) => false,
                    );
                  }
                },
              ),
            const SizedBox(height: 24.0),
          ],

          // 6. [서비스 설정] Section
          _buildSectionHeader(l10n.profileServiceSettings),
          const SizedBox(height: 8.0),
          _buildMenuTile(
            icon: Icons.language,
            title: l10n.languageSetting,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.notifications_none,
            title: l10n.notificationSetting,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationSettingsScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: l10n.profileTerms,
            color: Colors.blueGrey,
            onTap: () {
              PolicyViewerScreen.show(
                context,
                title: l10n.profileTerms,
                content: PolicyTexts.getTermsOfService(loc),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.shield_outlined,
            title: l10n.profilePrivacyPolicy,
            color: Colors.blueGrey,
            onTap: () {
              PolicyViewerScreen.show(
                context,
                title: l10n.profilePrivacyPolicy,
                content: PolicyTexts.getPrivacyPolicy(loc),
              );
            },
          ),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildProfileHeaderCard(
    BuildContext context,
    bool isLoggedIn,
    dynamic user,
    AppLocalizations l10n,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isLoggedIn) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
              );
            }
          },
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withAlpha(30),
                  backgroundImage: (isLoggedIn && user?.profileImageUrl != null)
                      ? NetworkImage(user!.profileImageUrl!)
                      : null,
                  child: (isLoggedIn && user?.profileImageUrl != null)
                      ? null
                      : const Icon(Icons.person, size: 32, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoggedIn ? (user?.nickname ?? '') : l10n.guestModeNotice,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isLoggedIn ? (user?.email ?? '') : l10n.moreLoginPromptDesc,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (!isLoggedIn)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text(l10n.loginTitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          leading: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 20.0),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11.0, color: AppColors.textSecondary),
                )
              : null,
          trailing: const Icon(Icons.chevron_right, size: 18.0, color: AppColors.textSecondary),
        ),
      ),
    );
  }

  Future<void> _launchURL(BuildContext context, String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        _showErrorSnackBar(context);
      }
    } catch (_) {
      if (!context.mounted) return;
      _showErrorSnackBar(context);
    }
  }

  void _showErrorSnackBar(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n?.errorNetwork ?? 'Network error. Please try again later.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
