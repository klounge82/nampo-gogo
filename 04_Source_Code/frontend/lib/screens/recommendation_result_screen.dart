import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/recommendation_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/recommendation_feedback_widget.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
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

    final l10n = AppLocalizations.of(context);
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
        locale: l10n?.localeName ?? 'ko',
      );
      setState(() {
        _recommendation = course;
      });
    } catch (e) {
      setState(() {
        _errorMessage = l10n?.courseFetchErrorMsg ?? '추천 코스를 가져오지 못했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveCourse() async {
    if (_recommendation == null || _isSaving) return;

    final bool targetState = !_recommendation!.isSaved;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);

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
              targetState
                  ? (l10n?.courseSavedMsg ?? '📂 추천 코스가 보관함에 저장되었습니다.')
                  : (l10n?.courseUnsavedMsg ?? '코스 저장이 해제되었습니다.'),
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
          SnackBar(
            content: Text(
              l10n?.courseSaveErrorMsg ??
                  '코스를 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.',
            ),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.recommendResultTitle ?? '추천 코스 결과',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  Text(
                    '${l10n?.courseFetchErrorMsg ?? '추천 코스 생성을 실패하였습니다'}: $_errorMessage',
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _fetchCourse,
                    child: Text(l10n?.regenerateRecommendationAction ?? '다시 추천받기'),
                  ),
                ],
              ),
            )
          : _recommendation == null || _recommendation!.items.isEmpty
          ? Center(
              child: Text(
                l10n?.noMatchingCourseMsg ?? '조건에 부합하는 코스를 찾을 수 없습니다.',
              ),
            )
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
    final l10n = AppLocalizations.of(context);
    final String companionStr = l10n != null
        ? L10nMappers.mapCompanion(l10n, widget.travelType)
        : (widget.travelType == "SOLO" ? "나홀로" : widget.travelType == "COUPLE" ? "커플" : "가족/친구");
    final String transportStr = l10n != null
        ? L10nMappers.mapTransport(l10n, widget.transportMode)
        : (widget.transportMode == 'WALK' ? '도보 코스' : '차량/대중교통');
    final String personalizedTitle = l10n?.recommendOptPersonalized ?? '개인화 맞춤 코스 반영';

    final String courseTitleStr = l10n != null
        ? l10n.recommendCourseFormat(companionStr)
        : '$companionStr 남포동 나들이';
    final String metricsStr = l10n != null
        ? l10n.recommendMetricsFormat(
            itemsCount.toString(),
            totalDist.toStringAsFixed(1),
            totalTimeMin.toString(),
          )
        : '총 이동거리: ${totalDist.toStringAsFixed(1)} km  |  예상 소요시간: 약 $totalTimeMin분 ($itemsCount개 매장)';

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
                    personalizedTitle,
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
              Expanded(
                child: Text(
                  courseTitleStr,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
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
                  transportStr,
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
            metricsStr,
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
    final l10n = AppLocalizations.of(context);
    final localeCode = l10n?.localeName ?? 'ko';
    final placeName = L10nMappers.mapPlaceName(item.store, localeCode);
    final placeAddress = L10nMappers.mapPlaceAddress(item.store, localeCode);
    final placeDesc = L10nMappers.mapPlaceDescription(item.store, localeCode);
    final categoryStr = l10n != null
        ? L10nMappers.mapCategory(l10n, item.store.category)
        : item.store.category;
    final reasonStr = l10n != null
        ? L10nMappers.mapRecommendReason(l10n, item.recommendReasonCode)
        : '남포동 명소 추천 조건에 만족하는 인기 장소입니다.';

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
                            Expanded(
                              child: Text(
                                placeName,
                                style: const TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              categoryStr,
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          placeAddress,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          placeDesc,
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
                                reasonStr,
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
    final l10n = AppLocalizations.of(context);
    final bool isSaved = _recommendation?.isSaved ?? false;
    final String labelStr = isSaved
        ? (l10n?.savedCourseBadge ?? '보관함 저장됨')
        : (l10n?.saveCourseAction ?? '이 코스 보관함 저장');

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
                    labelStr,
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
