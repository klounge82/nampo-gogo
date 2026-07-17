import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/recommendation_repository.dart';
import '../providers/auth_provider.dart';
import 'recommendation_result_screen.dart';

class SavedCoursesScreen extends StatefulWidget {
  const SavedCoursesScreen({super.key});

  @override
  State<SavedCoursesScreen> createState() => _SavedCoursesScreenState();
}

class _SavedCoursesScreenState extends State<SavedCoursesScreen> {
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
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteCourse(RecommendationModel course) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('코스 삭제', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('저장한 추천 코스를 보관함에서 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _repository.deleteCourse(course.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('코스가 정상 삭제되었습니다.')),
      );
      _loadHistory();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('저장한 추천 코스', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(child: Text('기록 로드 실패: $_errorMessage'))
              : _courses.isEmpty
                  ? const Center(
                      child: Text('저장된 AI 추천 코스가 없습니다.', style: TextStyle(color: AppColors.textSecondary)),
                    )
                  : RefreshIndicator(
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
                    ),
    );
  }

  Widget _buildCourseCard(RecommendationModel course) {
    final dateStr = '${course.createdAt.year}.${course.createdAt.month.toString().padLeft(2, '0')}.${course.createdAt.day.toString().padLeft(2, '0')}';
    final durationLabel = course.travelDuration == 'TWO_HOURS'
        ? '2시간 코스'
        : course.travelDuration == 'HALF_DAY'
            ? '반나절 코스'
            : '풀데이 코스';
            
    final placeNames = course.items.map((i) => i.store.name).join(' → ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => RecommendationResultScreen(
                userId: course.user_id, // backend user_id mapped
                travelType: course.travelType,
                travelDuration: course.travelDuration,
                categories: const ['FOOD'], // Dummy list mapping to results
                transportMode: course.transportMode,
                latitude: course.startLatitude,
                longitude: course.startLongitude,
              ),
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
                    '${course.travelType == "SOLO" ? "나홀로" : course.travelType == "COUPLE" ? "커플" : "가족/친구"} 여행',
                    style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18.0, color: AppColors.textHint),
                    onPressed: () => _deleteCourse(course),
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                '시간: $durationLabel  |  이동: ${course.transportMode == "WALK" ? "도보" : "차량/대중교통"}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12.0),
              Text(
                placeNames,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const Divider(height: 24.0, color: AppColors.border),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '생성일: $dateStr',
                    style: const TextStyle(fontSize: 11.0, color: AppColors.textHint),
                  ),
                  const Row(
                    children: [
                      Text('상세보기', style: TextStyle(fontSize: 11.5, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                      Icon(Icons.chevron_right, size: 14.0, color: AppColors.secondary),
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

// Extends RecommendationModel to get user_id from json mapping helper
extension RecommendationModelUserId on RecommendationModel {
  String? get user_id => (this as dynamic).userId as String?;
}
