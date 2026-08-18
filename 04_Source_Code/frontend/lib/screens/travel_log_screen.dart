import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/activity_provider.dart';

class TravelLogScreen extends StatefulWidget {
  const TravelLogScreen({super.key});

  @override
  State<TravelLogScreen> createState() => _TravelLogScreenState();
}

class _TravelLogScreenState extends State<TravelLogScreen> {
  final List<String> _selectedPhotos = [
    'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e',
    'https://images.unsplash.com/photo-1541167760496-1628856ab772',
  ];

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '',
  );

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
        content: const Text(
          '사진 권한이 설정되어 있지 않습니다. 설정에서 사진 접근 권한을 허용해 주세요.',
        ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('선택한 사진이 삭제되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // Beta scenario steps completion status
    final scenarioSteps = [
      {'title': '1. 용두산공원 산책', 'desc': '용두산공원 위치 방문 및 스탬프', 'done': true},
      {'title': '2. 남포토스트 방문', 'desc': '스페셜 토스트 주문 & 사업자 추천 확인', 'done': true},
      {'title': '3. 남포돼지국밥/복국 식사', 'desc': '남포동 대표 맛집 가상결제/예약', 'done': true},
      {'title': '4. K-Lounge 힐링 마사지', 'desc': '추천받은 마사지 매장 이동', 'done': true},
      {'title': '5. 고유 QR 방문 인증', 'desc': '매장 QR 스캔으로 방문 검증 완료', 'done': true},
      {'title': '6. 리뷰 작성 & 포인트 적립', 'desc': '방문 리뷰 작성 및 500P 보너스', 'done': true},
      {'title': '7. 여행로그 자동 완성', 'desc': '나만의 남포동 여행 기록 완성', 'done': true},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '남포동 여행로그 완성',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header summary card
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
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '베타 자동요약',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    '오늘 남포동에서 총 5개 거점을 방문하고 1,800P를 적립하였습니다. 즐거운 여행의 기록을 확인해 보세요!',
                    style: TextStyle(fontSize: 12.5, color: Colors.white.withValues(alpha: 0.9), height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Stat Summary Grid
            const Text(
              '📊 여행 완료 종합 통계',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                _buildStatTile('방문 장소', '5곳', Icons.place, Colors.blue),
                _buildStatTile('예약 이용', '2건', Icons.event_available, Colors.teal),
                _buildStatTile('작성 리뷰', '2건', Icons.rate_review, Colors.amber),
                _buildStatTile('획득 포인트', '1,800P', Icons.add_circle, Colors.green),
                _buildStatTile('사용 포인트', '500P', Icons.remove_circle, Colors.orange),
                _buildStatTile('선택 사진', '${_selectedPhotos.length}장', Icons.photo_library, Colors.indigo),
              ],
            ),
            const SizedBox(height: 24.0),

            // Photo Selection Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📸 직접 선택한 여행 사진',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
                                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24.0),

            // Beta Scenario Stepper Section
            const Text(
              '🎯 확장 베타 테스트 시나리오 검증',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: scenarioSteps.map((step) {
                  final bool isDone = step['done'] as bool;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Icon(
                          isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                          color: isDone ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDone ? AppColors.textPrimary : AppColors.textHint,
                                ),
                              ),
                              Text(
                                step['desc'] as String,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDone ? Colors.green.shade300 : Colors.grey.shade300),
                          ),
                          child: Text(
                            isDone ? '완료' : '진행중',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: isDone ? Colors.green.shade800 : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color color) {
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
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
