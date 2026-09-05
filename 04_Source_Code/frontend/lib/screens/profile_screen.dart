import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../config/production_config.dart';
import '../utils/l10n_mappers.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import 'profile_edit_screen.dart';
import 'change_password_screen.dart';
import 'account_delete_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // 1. Profile Card Header (Dedicated Account Information)
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(
                vertical: 28.0,
                horizontal: 20.0,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 36.0,
                    backgroundColor: isLoggedIn
                        ? AppColors.primary.withAlpha(26)
                        : Colors.grey.withAlpha(26),
                    backgroundImage:
                        (isLoggedIn && user?.profileImageUrl != null)
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
                              isLoggedIn ? (user?.nickname ?? '') : l10n.guestModeNotice,
                              style: const TextStyle(
                                fontSize: 18.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isLoggedIn) ...[
                              const SizedBox(width: 8.0),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(38),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withAlpha(76)),
                                ),
                                child: Text(
                                  L10nMappers.mapUserTier(
                                    l10n,
                                    user?.lifetimeEarnedPoints ?? 0,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          isLoggedIn
                              ? (user?.email != null ? _maskEmail(user!.email) : '')
                              : l10n.guestModeNotice,
                          style: const TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (isLoggedIn) ...[
                          const SizedBox(height: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              user?.isAdmin == true
                                  ? l10n.profileAdminMember
                                  : (user?.isApprovedBusiness == true
                                      ? l10n.profileBusinessMember
                                      : l10n.profileGeneralMember),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // 2. Account Management Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLoggedIn) ...[
                    // Section 1: 계정 정보 (Account Info)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, top: 8.0),
                      child: Text(
                        l10n.profileTitle,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _buildMenuCard([
                      _buildMenuItem(
                        context,
                        icon: Icons.edit_outlined,
                        title: l10n.profileEdit,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProfileEditScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 16.0),

                    // Section 2: 보안 및 계정 (Security & Account)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        l10n.profileSecuritySection,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _buildMenuCard([
                      _buildMenuItem(
                        context,
                        icon: Icons.lock_reset_outlined,
                        title: l10n.changePassword,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 16.0),

                    // Section 3: 계정 관리 (Account Management)
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                      child: Text(
                        l10n.profileAccountManagement,
                        style: const TextStyle(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    _buildMenuCard([
                      _buildMenuItem(
                        context,
                        icon: Icons.logout,
                        title: l10n.profileLogout,
                        onTap: () async {
                          await authProvider.logout();
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                      _buildMenuItem(
                        context,
                        icon: Icons.no_accounts_outlined,
                        title: l10n.deleteAccount,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AccountDeleteScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                  ] else ...[
                    _buildMenuCard([
                      _buildMenuItem(
                        context,
                        icon: Icons.login,
                        title: l10n.loginTitle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(),
                            ),
                          );
                        },
                      ),
                    ]),
                  ],

                  const SizedBox(height: 24.0),
                  const Center(
                    child: Text(
                      ProductionConfig.currentBuildMarker,
                      style: TextStyle(
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28.0),
                ],
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
          style: const TextStyle(fontSize: 14.0, color: AppColors.textPrimary),
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

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;
    final username = parts[0];
    final domain = parts[1];
    if (username.length <= 2) {
      return '${username[0]}*@$domain';
    }
    return '${username.substring(0, 2)}${'*' * (username.length - 2)}@$domain';
  }
}
