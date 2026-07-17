import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/personalization_provider.dart';
import '../services/location_service.dart';
import 'recommendation_result_screen.dart';
import 'saved_courses_screen.dart';

class RecommendationInputScreen extends StatefulWidget {
  const RecommendationInputScreen({super.key});

  @override
  State<RecommendationInputScreen> createState() => _RecommendationInputScreenState();
}

class _RecommendationInputScreenState extends State<RecommendationInputScreen> {
  final LocationService _locationService = LocationService();

  String _selectedTravelType = 'COUPLE'; // SOLO, COUPLE, FAMILY, FRIENDS
  String _selectedDuration = 'HALF_DAY'; // TWO_HOURS, HALF_DAY, FULL_DAY
  String _selectedTransport = 'WALK';    // WALK, TRANSIT, DRIVE

  final List<String> _selectedCategories = ['FOOD', 'CAFE']; // FOOD, CAFE, TOURISM, SHOPPING, EXPERIENCE

  bool _isLocating = false;

  void _toggleCategory(String cat) {
    setState(() {
      if (_selectedCategories.contains(cat)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(cat);
        }
      } else {
        _selectedCategories.add(cat);
      }
    });
  }

  Future<void> _submitRequest() async {
    setState(() => _isLocating = true);

    // Get current position
    Position? position;
    try {
      position = await _locationService.getCurrentLocation();
    } catch (e) {
      // Geolocator error or permission denied -> fallback to Busan station
      position = null;
    }

    setState(() => _isLocating = false);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    final personalProvider = Provider.of<PersonalizationProvider>(context, listen: false);

    if (!mounted) return;

    // Navigate to Results Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationResultScreen(
          userId: userId,
          travelType: _selectedTravelType,
          travelDuration: _selectedDuration,
          categories: _selectedCategories,
          transportMode: _selectedTransport,
          latitude: position?.latitude,
          longitude: position?.longitude,
          usePersonalization: personalProvider.usePersonalization,
          excludeVisited: personalProvider.preferNewPlaces,
          preferRewards: personalProvider.preferRewards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI 코스 추천', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.bookmark_outline),
              tooltip: '저장한 코스',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedCoursesScreen()),
              ),
            ),
        ],
      ),
      body: _isLocating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppColors.primary),
                  SizedBox(height: 16.0),
                  Text('사용자 주변 매장 탐색 중...', style: TextStyle(fontSize: 13.0, color: AppColors.textSecondary)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '남포동 맞춤 여행 코스 빌더',
                    style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    '관심 카테고리와 시간을 선택하시면 최적의 추천 시퀀스를 도출합니다.',
                    style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24.0),

                  // 1. Travel Type
                  _buildSectionTitle('1. 누구와 함께 여행하시나요?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSelectableChip('혼자 (SOLO)', 'SOLO', _selectedTravelType, (val) => setState(() => _selectedTravelType = val)),
                      _buildSelectableChip('연인 (COUPLE)', 'COUPLE', _selectedTravelType, (val) => setState(() => _selectedTravelType = val)),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSelectableChip('가족 (FAMILY)', 'FAMILY', _selectedTravelType, (val) => setState(() => _selectedTravelType = val)),
                      _buildSelectableChip('친구 (FRIENDS)', 'FRIENDS', _selectedTravelType, (val) => setState(() => _selectedTravelType = val)),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // 2. Duration
                  _buildSectionTitle('2. 여행 예정 시간은 얼마인가요?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSelectableChip('2시간 (가볍게)', 'TWO_HOURS', _selectedDuration, (val) => setState(() => _selectedDuration = val)),
                      _buildSelectableChip('반나절 (실속형)', 'HALF_DAY', _selectedDuration, (val) => setState(() => _selectedDuration = val)),
                      _buildSelectableChip('하루 종일 (풀코스)', 'FULL_DAY', _selectedDuration, (val) => setState(() => _selectedDuration = val)),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // 3. Category selector (Multi-select)
                  _buildSectionTitle('3. 무엇을 하고 싶으신가요? (복수 선택 가능)'),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: [
                      _buildMultiSelectChip('🍕 맛있는 식사', 'FOOD'),
                      _buildMultiSelectChip('☕ 감성 카페', 'CAFE'),
                      _buildMultiSelectChip('📸 주요 볼거리', 'TOURISM'),
                      _buildMultiSelectChip('🛍️ 시장/쇼핑', 'SHOPPING'),
                      _buildMultiSelectChip('🎯 로컬 체험', 'EXPERIENCE'),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // 4. Transport Mode
                  _buildSectionTitle('4. 주요 이동 방식은 무엇인가요?'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSelectableChip('도보 걷기 (WALK)', 'WALK', _selectedTransport, (val) => setState(() => _selectedTransport = val)),
                      _buildSelectableChip('대중교통 (TRANSIT)', 'TRANSIT', _selectedTransport, (val) => setState(() => _selectedTransport = val)),
                      _buildSelectableChip('차량 운전 (DRIVE)', 'DRIVE', _selectedTransport, (val) => setState(() => _selectedTransport = val)),
                    ],
                  ),
                  const SizedBox(height: 24.0),

                  // 5. Personalization Options
                  _buildSectionTitle('5. 개인화 추천 옵션'),
                  Consumer<PersonalizationProvider>(
                    builder: (context, personal, child) {
                      return Column(
                        children: [
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('내 활동 및 즐겨찾기 반영', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
                            subtitle: const Text('최근 검색어, 즐겨찾기, 포인트 혜택을 기반으로 우선 추천합니다.', style: TextStyle(fontSize: 11.0, color: Colors.grey)),
                            value: personal.usePersonalization,
                            onChanged: (val) {
                              final token = context.read<AuthProvider>().accessToken;
                              personal.togglePersonalization(value: val, token: token);
                            },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('이미 방문한 곳 제외', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
                            subtitle: const Text('최근 예약하셨거나 리뷰 및 미션을 완료한 장소를 코스에서 제외합니다.', style: TextStyle(fontSize: 11.0, color: Colors.grey)),
                            value: personal.preferNewPlaces,
                            onChanged: (val) {
                              final token = context.read<AuthProvider>().accessToken;
                              personal.toggleExcludeVisited(value: val, token: token);
                            },
                          ),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('미션 완료 보상(포인트) 우선', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
                            subtitle: const Text('아직 완료하지 않은 보상 미션이 대기 중인 장소를 우선 배치합니다.', style: TextStyle(fontSize: 11.0, color: Colors.grey)),
                            value: personal.preferRewards,
                            onChanged: (val) {
                              final token = context.read<AuthProvider>().accessToken;
                              personal.togglePreferRewards(value: val, token: token);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 36.0),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton(
                      onPressed: _submitRequest,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      child: const Text('맞춤 AI 코스 생성하기', style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildSelectableChip(String label, String value, String currentSelected, ValueChanged<String> onSelected) {
    final bool isSel = value == currentSelected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withAlpha(20) : AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? AppColors.primary : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip(String label, String value) {
    final bool isSel = _selectedCategories.contains(value);
    return GestureDetector(
      onTap: () => _toggleCategory(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
