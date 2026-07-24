import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../data/mock_data.dart';
import '../widgets/search_bar.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/mission_card.dart';
import '../repositories/system_repository.dart';
import 'place_detail_screen.dart';
import 'mission_detail_screen.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'notification_history_screen.dart';
import 'auth_screen.dart';
import '../config/production_config.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24.0),

                // Welcome Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '${AppStrings.homeWelcomeTitle} 👋',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          AppStrings.homeWelcomeSubtitle,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Consumer2<AuthProvider, NotificationProvider>(
                      builder: (context, auth, notif, _) {
                        final isLoggedIn = auth.isLoggedIn;
                        final count = notif.unreadCount;

                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              onPressed: () {
                                if (isLoggedIn) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const NotificationHistoryScreen(),
                                    ),
                                  );
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const AuthScreen(),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(
                                Icons.notifications_none,
                                size: 28.0,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (isLoggedIn && count > 0)
                              Positioned(
                                right: 4,
                                top: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '$count',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 12.0),

                // Server Status Badge
                FutureBuilder<String>(
                  future: SystemRepository().getSystemStatus(),
                  builder: (context, snapshot) {
                    final statusText = snapshot.data ?? '서버 상태 확인 중...';
                    final isOnline =
                        snapshot.hasData && !statusText.contains('오프라인');

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: isOnline
                            ? AppColors.success.withAlpha(20)
                            : AppColors.error.withAlpha(20),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: isOnline
                              ? AppColors.success.withAlpha(40)
                              : AppColors.error.withAlpha(40),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isOnline
                                    ? '🟢 API 연결됨'
                                    : (ProductionConfig.isProduction
                                          ? '🔴 서버 연결 실패 (네트워크를 확인해 주세요)'
                                          : '🔴 오프라인 모드 (Mock 데이터 사용)'),
                                style: TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.bold,
                                  color: isOnline
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                          if (isOnline) ...[
                            const SizedBox(height: 4.0),
                            Text(
                              statusText,
                              style: const TextStyle(
                                fontSize: 12.0,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16.0),

                // Search Bar
                NampoSearchBar(onTap: () {}, onChanged: (value) {}),

                const SizedBox(height: 28.0),

                // AI Recommendation Header
                _buildSectionHeader(
                  context,
                  title: AppStrings.homeRecommendTitle,
                  onMorePressed: () =>
                      _showComingSoon(context, AppStrings.homeRecommendTitle),
                ),

                const SizedBox(height: 12.0),

                // AI Recommendation List (Horizontal)
                SizedBox(
                  height: 290.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: MockData.recommendations.length,
                    itemBuilder: (context, index) {
                      final recommendation = MockData.recommendations[index];
                      return RecommendationCard(
                        recommendation: recommendation,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  PlaceDetailScreen(placeId: recommendation.id),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 28.0),

                // Today's Mission Header
                _buildSectionHeader(
                  context,
                  title: AppStrings.homeMissionTitle,
                  onMorePressed: () =>
                      _showComingSoon(context, AppStrings.homeMissionTitle),
                ),

                const SizedBox(height: 12.0),

                // Today's Mission List (Vertical)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: MockData.missions.length,
                  itemBuilder: (context, index) {
                    final mission = MockData.missions[index];
                    return MissionCard(
                      mission: mission,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MissionDetailScreen(missionId: mission.id),
                          ),
                        );
                      },
                      onActionButtonTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                MissionDetailScreen(missionId: mission.id),
                          ),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required VoidCallback onMorePressed,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        TextButton(
          onPressed: onMorePressed,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            AppStrings.homeMore,
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[$featureName] 기능은 MVP 정식 버전에서 연결될 예정입니다!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
