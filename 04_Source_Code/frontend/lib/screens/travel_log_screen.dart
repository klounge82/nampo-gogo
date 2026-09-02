import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';
import '../widgets/activity_card.dart';
import '../l10n/app_localizations.dart';

class TravelLogScreen extends StatefulWidget {
  const TravelLogScreen({super.key});

  @override
  State<TravelLogScreen> createState() => _TravelLogScreenState();
}

class _TravelLogScreenState extends State<TravelLogScreen> {
  final List<String> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshActivities();
    });
  }

  void _refreshActivities() {
    final token = context.read<AuthProvider>().accessToken;
    if (token != null && token.isNotEmpty) {
      context.read<ActivityProvider>().loadActivities(token: token);
    }
  }

  void _addSamplePhoto() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('갤러리 사진 직접 선택'),
        content: const Text(
          '사용자가 직접 갤러리에서 선택한 사진만 여행로그에 추가됩니다.\n(휴대폰 전체 자동 검색 및 AI 사진 분류는 수행하지 않습니다)',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _showPermissionDeniedDialog();
            },
            child: const Text('권한 거부 테스트'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _selectedPhotos.add(
                  'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb',
                );
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('갤러리 사진 1장이 추가되었습니다.')),
              );
            },
            child: const Text('사진 선택 완료'),
          ),
        ],
      ),
    );
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('사진 접근 권한 필요'),
          ],
        ),
        content: const Text('사진 권한이 설정되어 있지 않습니다. 설정에서 사진 접근 권한을 허용해 주세요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('선택한 사진이 삭제되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final actProvider = context.watch<ActivityProvider>();
    final user = authProvider.currentUser;

    // Filter completed mission activities from actual activity stream
    final completedMissionActivities = actProvider.activities.where((act) {
      final actType = (act['activity_type'] as String? ?? '').toUpperCase();
      final targetType = (act['target_type'] as String? ?? '').toUpperCase();
      return actType == 'MISSION_COMPLETE' ||
          actType == 'MISSION_COMPLETED' ||
          targetType == 'MISSION';
    }).toList();

    final int completedCount = completedMissionActivities.length;
    final int currentPoints = user?.currentPoints ?? 0;
    final int lifetimePoints = user?.lifetimeEarnedPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.activityTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshActivities,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary card (Real-data driven)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Colors.blue.shade800],
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🗺️ ${user?.nickname ?? "이용자"} 님의 여행 요약',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '여행 요약',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    completedCount > 0
                        ? '총 $completedCount개의 미션을 완수하고 현재 ${currentPoints}P를 보유 중입니다.'
                        : (user != null
                              ? '현재 ${currentPoints}P를 보유 중입니다. 남포동의 다양한 미션에 도전해 보세요!'
                              : l10n.guestModeNotice),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Stat Summary Grid (Real-data driven)
            const Text(
              '📊 여행 완료 종합 통계',
              style: TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10.0,
              mainAxisSpacing: 10.0,
              childAspectRatio: 1.1,
              children: [
                _buildStatTile(
                  l10n.missionCompletedCount,
                  '$completedCount건',
                  Icons.emoji_events,
                  Colors.blue,
                ),
                _buildStatTile(
                  l10n.missionMyPoints,
                  '${currentPoints}P',
                  Icons.monetization_on,
                  Colors.green,
                ),
                _buildStatTile(
                  '누적 포인트',
                  '${lifetimePoints}P',
                  Icons.stars,
                  Colors.amber,
                ),
                _buildStatTile(
                  '선택 사진',
                  '${_selectedPhotos.length}장',
                  Icons.photo_library,
                  Colors.indigo,
                ),
                _buildStatTile(
                  '활동 기록',
                  '${actProvider.activities.length}건',
                  Icons.history,
                  Colors.teal,
                ),
                _buildStatTile(
                  '회원 등급',
                  user != null ? '정식회원' : '게스트',
                  Icons.verified_user,
                  Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Photo Selection Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📸 직접 선택한 여행 사진',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSamplePhoto,
                  icon: const Icon(Icons.add_a_photo, size: 16),
                  label: const Text('사진 추가'),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            _selectedPhotos.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('선택된 사진이 없습니다. 갤러리에서 직접 추가해 주세요.'),
                    ),
                  )
                : SizedBox(
                    height: 100.0,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedPhotos.length,
                      itemBuilder: (ctx, idx) {
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 12.0),
                              width: 100.0,
                              height: 100.0,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12.0),
                                image: DecorationImage(
                                  image: NetworkImage(_selectedPhotos[idx]),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 16,
                              child: GestureDetector(
                                onTap: () => _removePhoto(idx),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24.0),

            // Real Completed Missions Section (Authoritative)
            Text(
              '🎯 ${l10n.missionCompletedCount}',
              style: const TextStyle(
                fontSize: 15.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            completedMissionActivities.isEmpty
                ? Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Center(
                      child: Text(
                        l10n.emptyNoData,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: completedMissionActivities.map((act) {
                        return ActivityCard(activity: act);
                      }).toList(),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
