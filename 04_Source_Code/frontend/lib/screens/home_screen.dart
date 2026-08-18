import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../data/mock_data.dart';
import '../models/place.dart';
import '../models/mission.dart';
import '../models/recommendation.dart';
import '../repositories/place_repository.dart';
import '../repositories/mission_repository.dart';
import '../repositories/system_repository.dart';
import '../providers/locale_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/search_bar.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/mission_card.dart';
import '../widgets/language_selector_button.dart';
import '../l10n/app_localizations.dart';
import 'place_detail_screen.dart';
import 'mission_detail_screen.dart';
import 'notification_history_screen.dart';
import 'auth_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();
  final MissionRepository _missionRepository = MissionRepository();

  List<Place> _places = [];
  List<Mission> _missions = [];
  String? _lastLocaleCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLoc = context.watch<LocaleProvider>().currentLocaleCode;
    if (_lastLocaleCode != currentLoc) {
      _lastLocaleCode = currentLoc;
      _loadDynamicData();
    }
  }

  Future<void> _loadDynamicData() async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    try {
      final places = await _placeRepository.getPlaces(locale: localeCode);
      final missions = await _missionRepository.getMissions(locale: localeCode);
      if (mounted) {
        setState(() {
          _places = places;
          _missions = missions;
        });
      }
    } catch (_) {
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Convert Place list to Recommendation list for UI rendering if places exist
    final recommendationsToDisplay = _places.isNotEmpty
        ? _places.map((p) => Recommendation(
            id: p.id,
            name: p.name,
            category: p.category,
            rating: p.rating,
            address: p.address,
            description: p.description,
            tags: const ['AI 추천', '남포동 명소'],
          )).toList()
        : MockData.recommendations;

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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isNarrow = screenWidth < 360;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${l10n.welcomeGreeting} ${l10n.welcomeTitle}',
                                    style: TextStyle(
                                      fontSize: isNarrow ? 18.0 : 22.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      height: 1.2,
                                    ),
                                    softWrap: true,
                                  ),
                                  const SizedBox(height: 4.0),
                                  Text(
                                    l10n.welcomeSlogan,
                                    style: TextStyle(
                                      fontSize: isNarrow ? 12.0 : 13.0,
                                      color: AppColors.textSecondary,
                                    ),
                                    softWrap: true,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LanguageSelectorButton(),
                                const SizedBox(width: 4.0),
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
                                            size: 26.0,
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
                          ],
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 12.0),

                // Server Status Badge
                FutureBuilder<String>(
                  future: SystemRepository().getSystemStatus(),
                  builder: (context, snapshot) {
                    final statusText = snapshot.data ?? l10n.apiChecking;
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
                                    ? l10n.apiConnected
                                    : l10n.apiDisconnected,
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
                              l10n.apiRunning,
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
                NampoSearchBar(
                  readOnly: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchScreen()),
                    );
                  },
                ),

                const SizedBox(height: 28.0),

                // AI Recommendation Header
                _buildSectionHeader(
                  context,
                  title: l10n.aiRecommendTitle,
                  onMorePressed: () =>
                      _showComingSoon(context, l10n.aiRecommendTitle),
                ),

                const SizedBox(height: 12.0),

                // AI Recommendation List (Horizontal)
                SizedBox(
                  height: 290.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: recommendationsToDisplay.length,
                    itemBuilder: (context, index) {
                      final recommendation = recommendationsToDisplay[index];
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
                  title: l10n.todaysMissionTitle,
                  onMorePressed: () =>
                      _showComingSoon(context, l10n.todaysMissionTitle),
                ),

                const SizedBox(height: 12.0),

                // Today's Mission List (Vertical)
                Builder(
                  builder: (context) {
                    final localeCode = context.watch<LocaleProvider>().currentLocaleCode;
                    final displayMissions = _missions.isNotEmpty
                        ? _missions
                        : _missionRepository.getMockMissions(locale: localeCode);

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: displayMissions.length,
                      itemBuilder: (context, index) {
                        final mission = displayMissions[index];
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
    final l10n = AppLocalizations.of(context)!;

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
          child: Text(
            l10n.more,
            style: const TextStyle(
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
