import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/mission.dart';
import '../repositories/mission_repository.dart';
import '../providers/auth_provider.dart';
import 'mission_detail_screen.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final MissionRepository _missionRepository = MissionRepository();

  List<Mission> _missions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMissions();
  }

  Future<void> _loadMissions() async {
    setState(() => _isLoading = true);
    try {
      final list = await _missionRepository.getMissions();
      setState(() {
        _missions = list;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.watch<AuthProvider>().isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.missionTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMissions,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point Dashboard Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(76), // 0.3 opacity
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '나의 획득 포인트',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoggedIn ? '2,300 P' : '0 P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 36.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12.0),
                      Container(height: 1.0, color: Colors.white24),
                      const SizedBox(height: 12.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoggedIn ? '완료한 미션: 2개' : '완료한 미션: 0개',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                            ),
                          ),
                          Text(
                            isLoggedIn ? '상위 15% 관광객' : '오프라인/게스트',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28.0),

                // Section Header
                const Text(
                  '전체 미션 목록',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Mission List
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _missions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            '진행 가능한 미션이 없습니다.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _missions.length,
                        itemBuilder: (context, index) {
                          final mission = _missions[index];
                          return _buildMissionItemCard(context, mission);
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMissionItemCard(BuildContext context, Mission mission) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => MissionDetailScreen(missionId: mission.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Icon/Badge
                Container(
                  width: 48.0,
                  height: 48.0,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_outlined,
                      color: AppColors.primary,
                      size: 26.0,
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondary.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              '${mission.points} P',
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _getAuthTypeText(mission.authType),
                            style: const TextStyle(
                              fontSize: 10.0,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getAuthTypeText(String authType) {
    switch (authType) {
      case 'GPS':
        return '📍 위치 인증';
      case 'QR':
        return '🔍 QR 스캔';
      case 'PHOTO':
        return '📸 사진 등록';
      default:
        return '✏️ 일반 인증';
    }
  }
}
