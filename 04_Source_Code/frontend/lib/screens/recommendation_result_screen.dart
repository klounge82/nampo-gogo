import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/recommendation_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/recommendation_feedback_widget.dart';
import 'place_detail_screen.dart';

class RecommendationResultScreen extends StatefulWidget {
  final String? userId;
  final String travelType;
  final String travelDuration;
  final List<String> categories;
  final String transportMode;
  final double? latitude;
  final double? longitude;
  final bool usePersonalization;
  final bool excludeVisited;
  final bool preferRewards;
  final RecommendationModel? initialCourse;

  const RecommendationResultScreen({
    super.key,
    this.userId,
    required this.travelType,
    required this.travelDuration,
    required this.categories,
    required this.transportMode,
    this.latitude,
    this.longitude,
    this.usePersonalization = false,
    this.excludeVisited = false,
    this.preferRewards = false,
    this.initialCourse,
  });

  @override
  State<RecommendationResultScreen> createState() =>
      _RecommendationResultScreenState();
}

class _RecommendationResultScreenState
    extends State<RecommendationResultScreen> {
  final RecommendationRepository _repository = RecommendationRepository();

  RecommendationModel? _recommendation;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialCourse != null) {
      _recommendation = widget.initialCourse;
      _isLoading = false;
    } else {
      _fetchCourse();
    }
  }

  Future<void> _fetchCourse() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final course = await _repository.getRecommendedCourse(
        userId: widget.userId,
        travelType: widget.travelType,
        travelDuration: widget.travelDuration,
        categories: widget.categories,
        transportMode: widget.transportMode,
        latitude: widget.latitude,
        longitude: widget.longitude,
        usePersonalization: widget.usePersonalization,
        excludeVisited: widget.excludeVisited,
        preferRewards: widget.preferRewards,
      );
      setState(() {
        _recommendation = course;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '추천 코스를 가져오지 못했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCourse() async {
    if (_recommendation == null || _isSaving) return;

    final bool targetState = !_recommendation!.isSaved;
    setState(() => _isSaving = true);

    try {
      final updated = await _repository.saveCourse(
        _recommendation!,
        isSaved: targetState,
        userId: widget.userId,
      );
      setState(() {
        _recommendation = updated;
      });

      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final token = authProvider.accessToken;
        Provider.of<FavoriteProvider>(context, listen: false).toggleFavorite(
          targetType: 'RECOMMENDATION',
          targetId: _recommendation!.id,
          token: token,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              targetState ? '📂 추천 코스가 보관함에 저장되었습니다.' : '코스 저장이 해제되었습니다.',
            ),
            backgroundColor: targetState ? Colors.green : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        if (e is DioException) {
          print(
            '[CourseSave Error] status: ${e.response?.statusCode}, method: ${e.requestOptions.method}, path: ${e.requestOptions.path}',
          );
        } else {
          print('[CourseSave Error] $e');
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('코스를 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String _translateReason(String code) {
    switch (code) {
      case 'REASON_CATEGORY':
        return '선택하신 관심 카테고리 테마에 잘 부합하는 장소입니다.';
      case 'REASON_CLOSE':
        return '현재 기준 위치에서 도보로 가깝게 접근할 수 있습니다.';
      case 'REASON_MISSION':
        return '보너스 포인트를 획득할 수 있는 액티브 미션이 있습니다.';
      case 'REASON_COUPON':
        return '혜택을 누릴 수 있는 제휴 쿠폰 상점이 마련되어 있습니다.';
      case 'REASON_MISSION_COUPON':
        return '참여 가능한 인증 미션과 교환 쿠폰이 모두 연계되어 있습니다.';
      case 'REASON_FAVORITE':
        return '즐겨찾기 목록에 보관하신 매장입니다.';
      case 'REASON_FAVORITE_CAT':
        return '즐겨찾기 취향과 유사한 스타일의 매장입니다.';
      case 'REASON_RECENT_SEARCH':
        return '최근 검색하시거나 관심을 보인 관심 테마입니다.';
      case 'REASON_REWARD':
        return '아직 도전하지 않은 보상 미션이 대기 중인 장소입니다.';
      case 'REASON_VISITED':
        return '이미 방문하셨으나 다시 들르기 매력적인 장소입니다.';
      default:
        return '남포동 명소 추천 조건에 만족하는 인기 장소입니다.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '추천 코스 결과',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('추천 코스 생성을 실패하였습니다: $_errorMessage'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _fetchCourse,
                    child: const Text('다시 추천받기'),
                  ),
                ],
              ),
            )
          : _recommendation == null || _recommendation!.items.isEmpty
          ? const Center(child: Text('조건에 부합하는 코스를 찾을 수 없습니다.'))
          : Column(
              children: [
                // Course overview Banner
                _buildOverviewBanner(),

                // Places timeline sequence
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      top: 16.0,
                      bottom: 24.0,
                    ),
                    itemCount: _recommendation!.items.length,
                    itemBuilder: (context, index) {
                      final item = _recommendation!.items[index];
                      return _buildTimelineItem(
                        item,
                        index == _recommendation!.items.length - 1,
                      );
                    },
                  ),
                ),

                // Actions footer
                _buildFooterActions(),
              ],
            ),
    );
  }

  Widget _buildOverviewBanner() {
    final int itemsCount = _recommendation!.items.length;
    // Walk mode average: approx. 80m/min. Drive mode: 350m/min.
    final double walkSpeed = widget.transportMode == 'WALK' ? 80.0 : 350.0;
    // Calculate simulated duration based on distance sequence
    double totalDist = 0.0;
    for (int i = 0; i < itemsCount - 1; i++) {
      final p1 = _recommendation!.items[i].store;
      final p2 = _recommendation!.items[i + 1].store;
      if (p1.latitude != null &&
          p1.longitude != null &&
          p2.latitude != null &&
          p2.longitude != null) {
        // Simple planar approximation
        final dy = (p2.latitude! - p1.latitude!) * 111.0;
        final dx = (p2.longitude! - p1.longitude!) * 88.0;
        totalDist += (dy * dy + dx * dx);
      }
    }
    totalDist = totalDist > 0 ? (totalDist * 10).clamp(0.4, 4.2) : 0.8;
    final int totalTimeMin =
        ((totalDist * 1000) / walkSpeed).round() +
        (itemsCount * 30); // 30 mins per place stay

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.usePersonalization) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8.0),
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 4.0,
              ),
              decoration: BoxDecoration(
                color: Colors.amber.shade700.withAlpha(30),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.amber.shade700, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 12.0,
                    color: Colors.amber.shade800,
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '개인화 맞춤 코스 반영',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${widget.travelType == "SOLO"
                    ? "나홀로"
                    : widget.travelType == "COUPLE"
                    ? "커플"
                    : "가족/친구"} 남포동 나들이',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Text(
                  widget.transportMode == 'WALK' ? '도보 코스' : '차량/대중교통',
                  style: const TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            '총 이동거리: ${totalDist.toStringAsFixed(1)} km  |  예상 소요시간: 약 $totalTimeMin분 ($itemsCount개 매장)',
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(CourseItemModel item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left timeline decorator
          Column(
            children: [
              Container(
                width: 24.0,
                height: 24.0,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${item.visitOrder}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    color: AppColors.primary.withAlpha(80),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16.0),

          // Right Content card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            PlaceDetailScreen(placeId: item.store.id),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.store.name,
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              item.store.category,
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          item.store.address,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          item.store.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const Divider(height: 20.0, color: AppColors.border),

                        // Recommendation reason
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.psychology_alt_outlined,
                              size: 14.0,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 6.0),
                            Expanded(
                              child: Text(
                                _translateReason(item.recommendReasonCode),
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        RecommendationFeedbackWidget(storeId: item.store.id),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions() {
    final bool isSaved = _recommendation?.isSaved ?? false;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 46.0,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveCourse,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18.0,
                          height: 18.0,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          isSaved ? Icons.bookmark : Icons.bookmark_border,
                          size: 18.0,
                        ),
                  label: Text(
                    isSaved ? '보관함 저장됨' : '이 코스 보관함 저장',
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isSaved
                        ? Colors.grey
                        : AppColors.secondary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
