import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../repositories/place_repository.dart';
import '../repositories/reservation_repository.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../widgets/favorite_button.dart';
import 'auth_screen.dart';
import '../models/review.dart' as model_review;
import 'review_write_screen.dart';
import '../services/map_service.dart';

class PlaceDetailScreen extends StatefulWidget {
  final String placeId;

  const PlaceDetailScreen({super.key, required this.placeId});

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();
  final ReviewRepository _reviewRepository = ReviewRepository();
  final MapService _mapService = MapService();

  Place? _place;
  List<model_review.Review> _reviews = [];
  bool _isLoading = true;
  bool _isReviewsLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPlaceDetail();
    _loadReviews();
  }

  Future<void> _loadPlaceDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final place = await _placeRepository.getPlaceDetail(widget.placeId);
      setState(() {
        _place = place;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadReviews() async {
    setState(() => _isReviewsLoading = true);
    try {
      final list = await _reviewRepository.getStoreReviews(widget.placeId);
      setState(() {
        _reviews = list;
        _isReviewsLoading = false;
      });
    } catch (_) {
      setState(() => _isReviewsLoading = false);
    }
  }

  void _showActionFeedback(String actionName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('[$actionName] 기능은 MVP 1차 릴리즈 이후 제공될 예정입니다.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.textPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _place?.name ?? '장소 상세',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (_place != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: FavoriteButton(
                targetType: 'PLACE',
                targetId: _place!.id,
                size: 26.0,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48.0,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadPlaceDetail,
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
            )
          : _buildContent(context, _place!),
      bottomNavigationBar:
          (_isLoading || _errorMessage != null || _place == null)
          ? null
          : _buildBottomActionBar(context),
    );
  }

  Widget _buildContent(BuildContext context, Place place) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Large Header Image
          Container(
            height: 220.0,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withAlpha(220),
                  AppColors.secondary.withAlpha(220),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    _getCategoryIcon(place.category),
                    color: Colors.white.withAlpha(77),
                    size: 110.0,
                  ),
                ),
                Positioned(
                  bottom: 16.0,
                  left: 16.0,
                  right: 16.0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(102),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      place.address,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Body info
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Tag & Rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(26),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                      child: Text(
                        place.category,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.secondary,
                          size: 18.0,
                        ),
                        const SizedBox(width: 4.0),
                        Text(
                          place.rating.toString(),
                          style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),

                // Name
                Text(
                  place.name,
                  style: const TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16.0),

                // Description Card
                const Text(
                  '장소 소개',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  place.description,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24.0),

                // Simulated Map Widget
                const Text(
                  '위치 정보',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Container(
                  height: 140.0,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.map_outlined,
                          size: 38.0,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          place.latitude != null && place.longitude != null
                              ? '위경도: (${place.latitude}, ${place.longitude})'
                              : '위치 좌표 없음',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        const Text(
                          '상세 지도 및 로드뷰는 향후 활성화됩니다.',
                          style: TextStyle(
                            color: AppColors.textHint,
                            fontSize: 10.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (place.latitude != null && place.longitude != null) ...[
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            _mapService.launchGoogleMapRoute(
                              destLat: place.latitude!,
                              destLng: place.longitude!,
                              destName: place.name,
                              mode: 'w',
                            );
                          },
                          icon: const Icon(Icons.directions_walk, size: 14.0),
                          label: const Text(
                            '도보 길찾기',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _mapService.launchNaverMapRoute(
                              destLat: place.latitude!,
                              destLng: place.longitude!,
                              destName: place.name,
                            );
                          },
                          icon: const Icon(
                            Icons.map,
                            size: 14.0,
                            color: Colors.white,
                          ),
                          label: const Text(
                            '네이버 지도',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF03C75A,
                            ), // Naver Green
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24.0),

                // Reviews Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '방문자 후기 (${_reviews.length}개)',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '★ ${place.rating.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .push(
                                  MaterialPageRoute(
                                    builder: (_) => ReviewWriteScreen(
                                      storeId: place.id,
                                      storeName: place.name,
                                    ),
                                  ),
                                )
                                .then((value) {
                                  if (value == true) {
                                    _loadPlaceDetail();
                                    _loadReviews();
                                  }
                                });
                          },
                          child: const Text(
                            '후기 남기기',
                            style: TextStyle(
                              fontSize: 12.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 6.0),
                _isReviewsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _reviews.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(
                          child: Text(
                            '아직 작성된 후기가 없습니다.\n첫 번째 후기를 남겨보세요!',
                            style: TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: _reviews
                            .map(
                              (rev) => Container(
                                margin: const EdgeInsets.only(bottom: 12.0),
                                padding: const EdgeInsets.all(14.0),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12.0),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          rev.user.nickname,
                                          style: const TextStyle(
                                            fontSize: 12.0,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < rev.rating
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: index < rev.rating
                                                  ? Colors.amber
                                                  : Colors.grey.shade300,
                                              size: 13.0,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8.0),
                                    Text(
                                      rev.content,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationBottomSheet(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('예약을 위해 로그인이 필요합니다.')));
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AuthScreen()));
      return;
    }

    int partySize = 2;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 18, minute: 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      isScrollControlled: true,
      builder: (bctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0,
                right: 24.0,
                top: 24.0,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '매장 예약 신청',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16.0),

                  // Party Size Selection
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '예약 인원',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: partySize > 1
                                ? () => setModalState(() => partySize--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$partySize 명',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            onPressed: partySize < 8
                                ? () => setModalState(() => partySize++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Divider(),

                  // Date Picker
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_today,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      '예약 날짜',
                      style: TextStyle(fontSize: 13.0),
                    ),
                    subtitle: Text(
                      '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (picked != null) {
                        setModalState(() => selectedDate = picked);
                      }
                    },
                  ),
                  const Divider(),

                  // Time Picker
                  ListTile(
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      '예약 시간',
                      style: TextStyle(fontSize: 13.0),
                    ),
                    subtitle: Text(
                      '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setModalState(() => selectedTime = picked);
                      }
                    },
                  ),
                  const SizedBox(height: 24.0),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    height: 48.0,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(bctx).pop();
                        _submitReservation(
                          context,
                          partySize,
                          selectedDate,
                          selectedTime,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: const Text(
                        '예약 확정하기',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _submitReservation(
    BuildContext context,
    int partySize,
    DateTime date,
    TimeOfDay time,
  ) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final finalTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    // Show indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final repo = ReservationRepository();
      await repo.createReservation(
        storeId: _place!.id,
        reservationTime: finalTime,
        partySize: partySize,
        userId: userId,
      );
      Navigator.of(context).pop();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '🎉 예약 신청 완료',
            style: TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          content: Text(
            '${_place!.name} 매장에 예약이 정상적으로 신청되었습니다.\n내 예약 내역에서 승인 상태를 확인해 주세요.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.0),
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text('확인', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text(
            '예약 실패',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text(
                '확인',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ),
      );
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '먹거리':
        return Icons.restaurant;
      case '볼거리':
        return Icons.visibility;
      case '맛집':
        return Icons.local_dining;
      default:
        return Icons.place;
    }
  }

  Widget _buildBottomActionBar(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showActionFeedback('길찾기'),
                icon: const Icon(Icons.navigation_outlined, size: 18.0),
                label: const Text('길찾기', style: TextStyle(fontSize: 12.0)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showReservationBottomSheet(context),
                icon: const Icon(Icons.calendar_today, size: 18.0),
                label: const Text('예약하기', style: TextStyle(fontSize: 12.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showActionFeedback('미션 도전'),
                icon: const Icon(Icons.stars, size: 18.0),
                label: const Text('미션 도전', style: TextStyle(fontSize: 12.0)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
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
