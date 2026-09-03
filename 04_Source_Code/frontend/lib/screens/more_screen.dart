import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../l10n/app_localizations.dart';
import 'profile_screen.dart';
import 'recommendation_input_screen.dart';
import 'saved_courses_screen.dart';
import 'favorites_screen.dart';
import 'coupon_list_screen.dart';
import 'point_history_screen.dart';
import 'notification_settings_screen.dart';
import 'language_settings_screen.dart';
import 'policy_viewer_screen.dart';
import 'auth_screen.dart';
import 'business_dashboard_screen.dart';

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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // User / Profile Header Card
          _buildProfileHeaderCard(context, isLoggedIn, user, l10n),
          const SizedBox(height: 20.0),

          // Primary More Features
          _buildSectionHeader(l10n.aiRecommendTitle),
          const SizedBox(height: 8.0),
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
          const SizedBox(height: 20.0),

          // My Activities
          _buildSectionHeader(l10n.moreMyActivitySection),
          const SizedBox(height: 8.0),
          _buildMenuTile(
            icon: Icons.person_outline,
            title: l10n.profileTitle,
            subtitle: l10n.moreProfileDetailDesc,
            color: Colors.indigo,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.stars_outlined,
            title: l10n.pointHistoryTitle,
            subtitle: l10n.morePointHistoryDesc,
            color: Colors.amber.shade800,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PointHistoryScreen()),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.confirmation_number_outlined,
            title: l10n.profileCouponsLabel,
            subtitle: l10n.moreCouponListDesc,
            color: Colors.teal,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CouponListScreen()),
              );
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
          const SizedBox(height: 20.0),

          // Business mode if merchant
          if (isLoggedIn && (user?.isApprovedBusiness == true || user?.isAdmin == true)) ...[
            _buildSectionHeader(l10n.businessDashboardTitle),
            const SizedBox(height: 8.0),
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
            ),
            const SizedBox(height: 20.0),
          ],

          // App Settings & Info
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
            icon: Icons.policy_outlined,
            title: l10n.profileTerms,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PolicyViewerScreen(
                    title: l10n.profileTerms,
                    content: 'Nampo GoGo Terms of Service...',
                  ),
                ),
              );
            },
          ),
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.profilePrivacyPolicy,
            color: Colors.blueGrey,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PolicyViewerScreen(
                    title: l10n.profilePrivacyPolicy,
                    content: 'Nampo GoGo Privacy Policy...',
                  ),
                ),
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
      padding: const EdgeInsets.all(16.0),
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
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppColors.primary.withAlpha(30),
            child: const Icon(Icons.person, size: 32, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoggedIn ? (user?.nickname ?? user?.username ?? '') : l10n.guestModeNotice,
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
            IconButton(
              icon: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
            ),
        ],
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
    );
  }
}
