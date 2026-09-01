import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../widgets/language_selector_button.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import 'auth_screen.dart';
import 'main_navigation_screen.dart';

class AuthChoiceScreen extends StatelessWidget {
  final bool showSessionExpiredNotice;

  const AuthChoiceScreen({super.key, this.showSessionExpiredNotice = false});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sessionExpiredNoticeText = l10n.sessionExpiredMessage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              if (showSessionExpiredNotice)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: Text(
                    sessionExpiredNoticeText,
                    style: TextStyle(
                      color: Colors.amber.shade900,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              // Top Bar with Language Selector
              Align(
                alignment: Alignment.topRight,
                child: const LanguageSelectorButton(),
              ),
              const SizedBox(height: 24.0),

              // Brand Logo & Slogan Header
              Column(
                children: [
                  const SizedBox(
                    width: 110.0,
                    height: 110.0,
                    child: Icon(Icons.location_on, size: 80.0, color: AppColors.primary),
                  ),
                  const SizedBox(height: 14.0),
                  const Text(
                    'NAMPO GOGO',
                    style: TextStyle(
                      fontSize: 22.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    l10n.welcomeSlogan,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24.0),

              // Signup Action Cards
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Customer Signup Button
                  _buildRoleChoiceCard(
                    context: context,
                    title: l10n.signupCustomer,
                    subtitle: l10n.signupCustomerSubtitle,
                    icon: Icons.person_add_outlined,
                    primaryColor: AppColors.primary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(
                            initialMode: AuthViewMode.customerSignup,
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 16.0),

                  // 2. Business Signup Button
                  _buildRoleChoiceCard(
                    context: context,
                    title: l10n.signupBusiness,
                    subtitle: l10n.signupBusinessSubtitle,
                    icon: Icons.storefront_outlined,
                    primaryColor: AppColors.secondary,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AuthScreen(
                            initialMode: AuthViewMode.businessSignup,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24.0),

              // Bottom Section: Login & Guest Mode Links
              Column(
                children: [
                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AuthScreen(
                                initialMode: AuthViewMode.login,
                              ),
                            ),
                          );
                        },
                        child: Text(
                          l10n.loginTitle,
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),

                  // Guest Mode Button
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RootNavigationSelector(),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 12.0,
                      ),
                      side: BorderSide(
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                    child: Text(
                      l10n.guestMode,
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChoiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.08),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 28.0),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: primaryColor,
              size: 24.0,
            ),
          ],
        ),
      ),
    );
  }
}
