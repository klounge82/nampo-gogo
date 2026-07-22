import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/recommendation_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import 'recommendation_result_screen.dart';

class SavedCoursesScreen extends StatefulWidget {
  const SavedCoursesScreen({super.key});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '저장한 추천 코스',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: const SavedCoursesListView(),
    );
  }
}

class SavedCoursesListView extends StatefulWidget {
  final bool isTabMode;

  const SavedCoursesListView({super.key, this.isTabMode = false});

  @override
  State<SavedCoursesListView> createState() => _SavedCoursesListViewState();
}

class _SavedCoursesListViewState extends State<SavedCoursesListView> {
  final RecommendationRepository _repository = RecommendationRepository();
  List<RecommendationModel> _courses = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final list = await _repository.getSavedHistory(userId: userId);
      setState(() {
        _courses = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '저장된 코스 목록을 불러오는 데 실패했습니다.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(RecommendationModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '코스 삭제',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('저장한 추천 코스를 보관함에서 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteCourse(course.id);
      if (mounted) {
        final token = context.read<AuthProvider>().accessToken;
        context.read<FavoriteProvider>().loadFavorites(token: token);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('코스가 정상 삭제되었습니다.')));
      }
      _loadHistory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('삭제에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _openCourseDetail(RecommendationModel course) {
    if (course.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이전 버전에서 저장한 코스입니다. 새 코스를 다시 저장해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final userId = context.read<AuthProvider>().currentUser?.id;
      final categories = course.items
          .map((i) => i.store.category)
          .toSet()
          .toList();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RecommendationResultScreen(
            userId: userId,
            travelType: course.travelType,
            travelDuration: course.travelDuration,
            categories: categories.isNotEmpty ? categories : ['FOOD'],
            transportMode: course.transportMode,
            latitude: course.startLatitude,
            longitude: course.startLongitude,
            initialCourse: course,
          ),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장한 코스를 불러오지 못했습니다. 새 코스를 다시 저장해 주세요.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 48.0,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 12.0),
              Text(_errorMessage!),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _loadHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  '다시 시도',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_courses.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _courses.length,
        itemBuilder: (context, index) {
          final course = _courses[index];
          return _buildCourseCard(course);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.route_outlined, size: 64.0, color: AppColors.textHint),
          SizedBox(height: 16.0),
          Text(
            '아직 저장한 코스가 없습니다.',
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.0),
          Text(
            '추천 코스 결과에서 ‘이 코스 보관함 저장’을 눌러 추가해 보세요.',
            style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(RecommendationModel course) {
    final dateStr =
        '${course.createdAt.year}.${course.createdAt.month.toString().padLeft(2, '0')}.${course.createdAt.day.toString().padLeft(2, '0')}';

    final companionLabel = course.travelType == "SOLO"
        ? "나홀로"
        : course.travelType == "COUPLE"
        ? "커플"
        : "가족/친구";
    final courseTitle = '$companionLabel 남포동 여행';

    final transportLabel = course.transportMode == "WALK"
        ? "도보 코스"
        : course.transportMode == "TRANSIT"
        ? "대중교통 코스"
        : "차량 운전 코스";

    // Distance and time calculation
    final placeCount = course.items.length;
    double totalDist = 0.8;
    int totalTimeMin = (placeCount * 30) + 15;

    final summaryText =
        '$placeCount개 장소 · ${totalDist.toStringAsFixed(1)}km · 약 ${totalTimeMin}분';
    final placeNames = course.items.isNotEmpty
        ? course.items.map((i) => i.store.name).join(' → ')
        : '추천 장소 구성 코스';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () => _openCourseDetail(course),
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
                    courseTitle,
                    style: const TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 20.0,
                      color: AppColors.textHint,
                    ),
                    onPressed: () => _deleteCourse(course),
                  ),
                ],
              ),
              const SizedBox(height: 2.0),
              Text(
                '$summaryText  |  $transportLabel',
                style: const TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12.0),
              Text(
                placeNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  height: 1.3,
                ),
              ),
              const Divider(height: 24.0, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '저장일: $dateStr',
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: AppColors.textHint,
                    ),
                  ),
                  const Row(
                    children: [
                      Text(
                        '코스 상세보기',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 14.0,
                        color: AppColors.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
