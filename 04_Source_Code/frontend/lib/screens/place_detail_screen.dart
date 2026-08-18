import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

import '../constants/colors.dart';
import '../models/place.dart';
import '../repositories/place_repository.dart';
import '../repositories/reservation_repository.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import '../widgets/favorite_button.dart';
import 'auth_screen.dart';
import '../models/review.dart' as model_review;
import 'review_write_screen.dart';
import 'my_reviews_screen.dart';
import 'qr_scanner_screen.dart';
import '../services/map_service.dart';
import '../services/auth_service.dart';
import '../services/reservation_service.dart';

import '../services/review_translation_service.dart';
import '../widgets/review_card_widget.dart';

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
  final ReviewTranslationService _translationService = ReviewTranslationService();

  final Set<String> _translatedReviewIds = {};
  final Map<String, String> _translatedTexts = {};
  final Set<String> _translatingReviewIds = {};
  final Set<String> _failedReviewIds = {};

  Future<void> _toggleReviewTranslation(
    model_review.Review rev,
    AppLocalizations l10n,
    String currentLocaleCode,
  ) async {
    final reviewId = rev.id;
    if (_translatedReviewIds.contains(reviewId)) {
      setState(() {
        _translatedReviewIds.remove(reviewId);
        _failedReviewIds.remove(reviewId);
      });
      return;
    }

    if (_translatedTexts.containsKey(reviewId)) {
      setState(() {
        _translatedReviewIds.add(reviewId);
        _failedReviewIds.remove(reviewId);
      });
      return;
    }

    setState(() {
      _translatingReviewIds.add(reviewId);
      _failedReviewIds.remove(reviewId);
    });

    try {
      final result = await _translationService.translateReview(
        reviewId: reviewId,
        content: rev.content,
        targetLocale: currentLocaleCode,
      );
      if (mounted) {
        setState(() {
          _translatedTexts[reviewId] = result;
          _translatedReviewIds.add(reviewId);
          _translatingReviewIds.remove(reviewId);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _translatingReviewIds.remove(reviewId);
          _failedReviewIds.add(reviewId);
        });
      }
    }
  }

  Place? _place;
  List<model_review.Review> _reviews = [];
  model_review.Review? _myReview;
  model_review.MyReviewResult? _myReviewResult;
  String? _currentUserId;
  String _currentGuestId = '';
  bool _isLoading = true;
  bool _isReviewsLoading = true;
  bool _reviewsError = false;
  String? _errorMessage;
  bool _reservationsEnabled = false;
  int _maxAdvanceDays = 30;
  String? _lastLocaleCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLoc = context.watch<LocaleProvider>().currentLocaleCode;
    if (_lastLocaleCode != currentLoc) {
      _lastLocaleCode = currentLoc;
      _loadPlaceDetail();
      _loadReviews();
    }
  }

  Future<void> _loadPlaceDetail() async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    setState(() => _isLoading = true);
    try {
      final place = await _placeRepository.getPlaceDetail(widget.placeId, locale: localeCode);
      bool resEnabled = false;
      int maxAdvDays = 30;
      try {
        final options = await ReservationService().getPublicReservationOptions(
          widget.placeId,
        );
        resEnabled = options['reservations_enabled'] as bool? ?? false;
        maxAdvDays = (options['maximum_advance_days'] as num?)?.toInt() ?? 30;
      } catch (_) {}

      setState(() {
        _place = place;
        _reservationsEnabled = resEnabled;
        _maxAdvanceDays = maxAdvDays;
        _errorMessage = null;
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
    setState(() {
      _isReviewsLoading = true;
      _reviewsError = false;
    });
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.currentUser?.id;
      final guestId = await AuthService().getOrCreateGuestId();
      _currentUserId = userId;
      _currentGuestId = guestId;

      final list = await _reviewRepository.getStoreReviews(
        widget.placeId,
        userId: userId,
        guestId: userId == null ? guestId : null,
      );
      final myResult = await _reviewRepository.getMyStoreReview(
        storeId: widget.placeId,
        userId: userId,
        guestId: userId == null ? guestId : null,
        includeDeleted: true,
      );

      _myReviewResult = myResult;
      _myReview = myResult.review;

      if (_myReview != null && !_myReview!.isDeleted) {
        list.removeWhere((r) => r.id == _myReview!.id);
        list.insert(0, _myReview!);
      }

      setState(() {
        _reviews = list;
        _isReviewsLoading = false;
        _reviewsError = false;
      });
    } catch (_) {
      setState(() {
        _isReviewsLoading = false;
        _reviewsError = true;
      });
    }
  }

  Future<void> _navigateToEdit(model_review.Review rev) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewWriteScreen(
          storeId: _place!.id,
          storeName: _place!.name,
          editReviewId: rev.id,
          initialRating: rev.rating,
          initialContent: rev.content,
          guestId: _currentUserId == null ? _currentGuestId : null,
          reviewVerificationType: _place!.reviewVerificationType,
        ),
      ),
    );
    if (result == true) {
      _loadPlaceDetail();
      _loadReviews();
    }
  }

  void _confirmDeleteReview(model_review.Review rev) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.deleteReviewConfirmTitle ?? '리뷰를 삭제하시겠습니까?',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        content: Text(
          l10n?.deleteReviewConfirmContent ?? '삭제한 리뷰는 다른 사용자에게 표시되지 않습니다.',
          style: const TextStyle(fontSize: 13.0, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l10n?.confirmCancel ?? '취소',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReview(rev.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n?.delete ?? '삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReview(String reviewId) async {
    try {
      await _reviewRepository.deleteReview(
        reviewId,
        userId: _currentUserId,
        guestId: _currentUserId == null ? _currentGuestId : null,
      );
      _loadPlaceDetail();
      _loadReviews();

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.reviewDeletedMsg ?? '리뷰가 삭제되었습니다.'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: l10n?.undoAction ?? '실행 취소',
              textColor: Colors.amber,
              onPressed: () => _restoreMyReview(reviewId),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showWarningDialog('삭제 실패', '리뷰를 삭제하지 못했습니다. 잠시 후 다시 시도해 주세요.');
      }
    }
  }

  Future<void> _restoreMyReview(String reviewId) async {
    try {
      await _reviewRepository.restoreReview(
        reviewId,
        userId: _currentUserId,
        guestId: _currentUserId == null ? _currentGuestId : null,
      );
      _loadPlaceDetail();
      _loadReviews();

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('리뷰가 복구되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showWarningDialog('복구 실패', '리뷰를 복구하지 못했습니다. 잠시 후 다시 시도해 주세요.');
      }
    }
  }

  Future<void> _navigateToRewrite(model_review.Review rev) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReviewWriteScreen(
          storeId: _place!.id,
          storeName: _place!.name,
          rewriteReviewId: rev.id,
          guestId: _currentUserId == null ? _currentGuestId : null,
          reviewVerificationType: _place!.reviewVerificationType,
        ),
      ),
    );
    if (result == true) {
      _loadPlaceDetail();
      _loadReviews();
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _place?.name ?? l10n?.mapViewDetail ?? '장소 상세',
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
                      l10n?.mapLoadFail ?? '장소 정보를 불러올 수 없습니다.',
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadPlaceDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        l10n?.mapRetry ?? '다시 시도',
                        style: const TextStyle(color: Colors.white),
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
    final l10n = AppLocalizations.of(context);
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
                    Row(
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
                            L10nMappers.mapCategory(
                              AppLocalizations.of(context)!,
                              place.category,
                            ),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                        if (place.isTestData) ...[
                          const SizedBox(width: 6.0),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade800,
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: const Text(
                              '테스트용',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ],
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
                Text(
                  l10n?.placeDescriptionTitle ?? '장소 소개',
                  style: const TextStyle(
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
                Text(
                  l10n?.locationInfoTitle ?? '위치 정보',
                  style: const TextStyle(
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
                              ? '${l10n?.locationInfoTitle ?? "위치 정보"}: (${place.latitude}, ${place.longitude})'
                              : (l10n?.noLocationCoordinates ?? '위치 좌표 없음'),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11.0,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          l10n?.detailedMapFeatureNotice ?? '상세 지도 및 로드뷰는 향후 활성화됩니다.',
                          style: const TextStyle(
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
                          label: Text(
                            l10n?.routeWalkBtn ?? '도보 길찾기',
                            style: const TextStyle(fontSize: 11.5),
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
                          label: Text(
                            l10n?.routeNaverBtn ?? '네이버 지도',
                            style: const TextStyle(
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
                      l10n?.visitorReviewsCount(_reviews.length) ??
                          '${l10n?.visitorReviewsTitle ?? "방문자 후기"} (${_reviews.length}${l10n?.countUnit ?? "개"})',
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
                          onPressed: () => _handleReviewGate(context, place),
                          child: Text(
                            l10n?.writeReviewBtn ?? '후기 남기기',
                            style: const TextStyle(
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
                if (_myReview != null && _myReview!.isDeleted)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                              size: 18.0,
                            ),
                            SizedBox(width: 6.0),
                            Text(
                              '삭제한 내 후기가 있습니다.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        const Text(
                          '다른 사용자에게는 표시되지 않습니다. QR 인증이나 대기 없이 복구하거나 다시 작성할 수 있습니다.',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => _restoreMyReview(_myReview!.id),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(
                                  color: AppColors.primary,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                              ),
                              child: const Text('복구'),
                            ),
                            const SizedBox(width: 8.0),
                            ElevatedButton(
                              onPressed: () => _navigateToRewrite(_myReview!),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                              ),
                              child: const Text('다시 작성'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                _isReviewsLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _reviewsError
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              '방문자 후기를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.',
                              style: TextStyle(
                                fontSize: 13.0,
                                color: Colors.red,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10.0),
                            OutlinedButton.icon(
                              onPressed: _loadReviews,
                              icon: const Icon(Icons.refresh, size: 16.0),
                              label: const Text('새로고침'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                              ),
                            ),
                          ],
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
                        child: Center(
                          child: Text(
                            '${l10n?.noReviewsYet ?? "작성된 후기가 없습니다."}\n${l10n?.beFirstReviewer ?? "첫 번째 후기를 남겨보세요!"}',
                            style: const TextStyle(
                              fontSize: 12.0,
                              color: AppColors.textHint,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : Column(
                        children: _reviews.map((rev) {
                          final activeUserId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? _currentUserId;
                          final isMyReview =
                              rev.isOwner ||
                              (_myReview != null && rev.id == _myReview!.id) ||
                              (activeUserId != null && rev.userId != null && rev.userId == activeUserId) ||
                              (activeUserId == null &&
                                  _currentGuestId.isNotEmpty &&
                                  rev.guestId == _currentGuestId &&
                                  rev.userId == null);

                          return ReviewCardWidget(
                            key: ValueKey('review_card_${rev.id}'),
                            review: rev,
                            isMyReview: isMyReview,
                            onEdit: isMyReview ? () => _navigateToEdit(rev) : null,
                            onDelete: isMyReview ? () => _confirmDeleteReview(rev) : null,
                            onRestore: (_myReview != null && rev.id == _myReview!.id && _myReview!.isDeleted)
                                ? () => _restoreMyReview(rev.id)
                                : null,
                          );
                        }).toList(),
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
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      isScrollControlled: true,
      builder: (bctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            final bottomPadding =
                MediaQuery.of(modalContext).viewInsets.bottom +
                MediaQuery.of(modalContext).padding.bottom +
                20.0;

            return SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  top: 24.0,
                  bottom: bottomPadding,
                ),
                child: SingleChildScrollView(
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
                                onPressed: (!isSubmitting && partySize > 1)
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
                                onPressed: (!isSubmitting && partySize < 8)
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
                        enabled: !isSubmitting,
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
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final picked = await showDatePicker(
                                  context: modalContext,
                                  initialDate: selectedDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(
                                    Duration(days: _maxAdvanceDays),
                                  ),
                                );

                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                      ),
                      const Divider(),

                      // Time Picker
                      ListTile(
                        enabled: !isSubmitting,
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
                        onTap: isSubmitting
                            ? null
                            : () async {
                                final picked = await showTimePicker(
                                  context: modalContext,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                      ),
                      const SizedBox(height: 24.0),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48.0,
                        child: ElevatedButton(
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  setModalState(() => isSubmitting = true);
                                  await _handleReservationSubmit(
                                    context: context,
                                    modalContext: modalContext,
                                    partySize: partySize,
                                    date: selectedDate,
                                    time: selectedTime,
                                    setModalState: setModalState,
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  '예약 신청하기',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.0,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleReservationSubmit({
    required BuildContext context,
    required BuildContext modalContext,
    required int partySize,
    required DateTime date,
    required TimeOfDay time,
    required StateSetter setModalState,
  }) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final finalTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    try {
      final repo = ReservationRepository();
      await repo.createReservation(
        storeId: _place!.id,
        reservationTime: finalTime,
        partySize: partySize,
        userId: userId,
      );

      // Pop bottom sheet safely
      if (Navigator.canPop(modalContext)) {
        Navigator.of(modalContext).pop();
      }

      // Show Korean success dialog
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) {
            final screenWidth = MediaQuery.of(ctx).size.width;
            final dialogWidth = screenWidth * 0.85;
            final storeName = _place?.name ?? '매장';

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Container(
                width: dialogWidth < 360 ? dialogWidth : 360,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 24.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉 예약 신청 접수 완료',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      '$storeName 매장에\n예약 신청이 접수되었습니다.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15.0,
                        height: 1.4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    const Text(
                      '매장에서 확인한 후 예약 상태가 변경됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13.0,
                        color: Colors.grey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 24.0),
                    SizedBox(
                      width: double.infinity,
                      height: 46.0,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      setModalState(() {});
      String cleanError = _formatReservationErrorMessage(e);
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              '예약 신청 안내',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            content: Text(cleanError),
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
  }

  String _formatReservationErrorMessage(dynamic error) {
    final raw = error.toString();
    if (raw.contains('최소')) return '최소 사전 예약 시간을 확인해 주세요.';
    if (raw.contains('피크타임') || raw.contains('바빠'))
      return '선택하신 시간은 매장 사정으로 예약을 받지 않습니다.';
    if (raw.contains('마감')) return '선택하신 시간대의 예약이 마감되었습니다.';
    if (raw.contains('중복')) return '이미 신청된 예약이 있습니다.';
    if (raw.contains('기능이 꺼져')) return '현재 해당 매장의 예약 기능이 준비 중입니다.';

    String cleaned = raw
        .replaceAll('Exception:', '')
        .replaceAll('DioException', '')
        .replaceAll('[bad response]:', '')
        .trim();
    if (cleaned.contains('http') ||
        cleaned.contains('Status code') ||
        cleaned.isEmpty) {
      return '예약 신청 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.';
    }
    return cleaned;
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
    final l10n = AppLocalizations.of(context);
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
                onPressed: () => _showActionFeedback(l10n?.findRouteBtn ?? '길찾기'),
                icon: const Icon(Icons.navigation_outlined, size: 18.0),
                label: Text(l10n?.findRouteBtn ?? '길찾기', style: const TextStyle(fontSize: 12.0)),
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
            if (_reservationsEnabled) ...[
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showReservationBottomSheet(context),
                  icon: const Icon(Icons.calendar_today, size: 18.0),
                  label: Text(l10n?.reservationAction ?? '예약하기', style: const TextStyle(fontSize: 12.0)),
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
            ],

            const SizedBox(width: 8.0),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showActionFeedback(l10n?.missionStartAction ?? '미션 도전'),
                icon: const Icon(Icons.stars, size: 18.0),
                label: Text(l10n?.missionStartAction ?? '미션 도전', style: const TextStyle(fontSize: 12.0)),
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

  Future<void> _handleReviewGate(BuildContext context, Place place) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    final guestId = await AuthService().getOrCreateGuestId();

    if (_myReview != null) {
      if (!_myReview!.isDeleted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              '이미 작성한 리뷰가 있습니다.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            content: const Text(
              '이 매장에는 이미 작성한 후기가 있습니다.\n작성한 후기를 직접 수정하시겠습니까?',
              style: TextStyle(fontSize: 13.0, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  '확인',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _navigateToEdit(_myReview!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('내 리뷰 수정'),
              ),
            ],
          ),
        );
        return;
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text(
              '삭제한 리뷰가 있습니다.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
            ),
            content: const Text(
              '이전에 작성했다가 삭제한 후기가 있습니다.\nQR 코드를 다시 스캔하지 않고 복구하거나 다시 작성할 수 있습니다.',
              style: TextStyle(fontSize: 13.0, height: 1.4),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  '나중에',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _restoreMyReview(_myReview!.id);
                },
                child: const Text(
                  '복구',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _navigateToRewrite(_myReview!);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('다시 작성'),
              ),
            ],
          ),
        );
        return;
      }
    }

    try {
      final activeV = await _reviewRepository.getActiveVerification(
        storeId: place.id,
        userId: userId,
        guestId: userId == null ? guestId : null,
      );

      if (activeV != null && mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewWriteScreen(
              storeId: place.id,
              storeName: place.name,
              verificationId: activeV['id'] as String?,
              guestId: userId == null ? guestId : null,
              reviewVerificationType: place.reviewVerificationType,
            ),
          ),
        );
        if (result == true) {
          _loadPlaceDetail();
          _loadReviews();
        }
        return;
      }

      final vType = place.reviewVerificationType;

      if (vType == 'BUSINESS_QR') {
        _showBusinessQRGateDialog(context, place, userId, guestId);
      } else if (vType == 'ATTRACTION_LOCATION') {
        _showAttractionGateDialog(context, place, userId, guestId);
      } else {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewWriteScreen(
              storeId: place.id,
              storeName: place.name,
              guestId: userId == null ? guestId : null,
              reviewVerificationType: place.reviewVerificationType,
            ),
          ),
        );
        if (result == true) {
          _loadPlaceDetail();
          _loadReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        final rawStr = e.toString();
        if (rawStr.contains('REVIEW_ALREADY_SUBMITTED')) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                '이미 리뷰를 작성했습니다.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              content: const Text(
                '이 매장에는 최근 72시간 이내에 리뷰를 작성했습니다.\n기존 리뷰는 내 정보에서 수정할 수 있습니다.',
                style: TextStyle(fontSize: 13.0, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => MyReviewsScreen()),
                    );
                  },
                  child: const Text(
                    '내 리뷰 보기',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    '확인',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          );
        } else if (rawStr.contains('DELETED_REVIEW_RESTORABLE')) {
          final parts = rawStr.split(':');
          String? delId;
          if (parts.length >= 3) {
            delId = parts[1].trim();
          }
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                '삭제한 리뷰가 있습니다.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              content: const Text(
                '삭제한 리뷰를 바로 다시 작성할 수 있습니다.\nQR 코드를 다시 인증하거나 기다릴 필요가 없습니다.',
                style: TextStyle(fontSize: 13.0, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    '나중에',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    if (delId != null && delId.isNotEmpty) {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewWriteScreen(
                            storeId: place.id,
                            storeName: place.name,
                            rewriteReviewId: delId,
                            guestId: userId == null ? guestId : null,
                            reviewVerificationType:
                                place.reviewVerificationType,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadPlaceDetail();
                        _loadReviews();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('다시 작성'),
                ),
              ],
            ),
          );
        } else if (rawStr.contains('DELETED_REVIEW_OPTION')) {
          final parts = rawStr.split(':');
          String? delId;
          if (parts.length >= 3) {
            delId = parts[1].trim();
          }
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text(
                '작성 방법을 선택해 주세요.',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
              ),
              content: const Text(
                '삭제한 기존 리뷰를 다시 작성하거나,\n새로운 방문 인증 후 새 리뷰를 작성할 수 있습니다.',
                style: TextStyle(fontSize: 13.0, height: 1.4),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    if (delId != null && delId.isNotEmpty) {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewWriteScreen(
                            storeId: place.id,
                            storeName: place.name,
                            rewriteReviewId: delId,
                            guestId: userId == null ? guestId : null,
                            reviewVerificationType:
                                place.reviewVerificationType,
                          ),
                        ),
                      );
                      if (result == true) {
                        _loadPlaceDetail();
                        _loadReviews();
                      }
                    }
                  },
                  child: const Text(
                    '삭제 리뷰 다시 작성',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showBusinessQRGateDialog(context, place, userId, guestId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('새 방문 리뷰 작성'),
                ),
              ],
            ),
          );
        } else {
          final is409 = rawStr.contains('409') || rawStr.contains('이미');
          if (is409) {
            _showWarningDialog(
              '이미 리뷰를 작성했습니다.',
              '이 매장에는 최근 72시간 이내에 리뷰를 작성했습니다.\n기존 리뷰는 내 정보에서 수정할 수 있습니다.',
            );
          } else {
            _showWarningDialog('안내', '인증 상태를 확인하지 못했습니다. 잠시 후 다시 시도해 주세요.');
          }
        }
      }
    }
  }

  void _showBusinessQRGateDialog(
    BuildContext context,
    Place place,
    String? userId,
    String guestId,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'QR 방문 인증이 필요합니다.',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        content: const Text(
          '실제 방문 고객의 신뢰할 수 있는 리뷰를 위해 매장 QR 인증 후 리뷰를 작성할 수 있습니다.',
          style: TextStyle(fontSize: 13.0, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '나중에',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final qrValue = await Navigator.of(context).push<String>(
                MaterialPageRoute(builder: (_) => const QrScannerScreen()),
              );
              if (qrValue != null && qrValue.isNotEmpty && mounted) {
                _verifyAndNavigateQR(place, qrValue, userId, guestId);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('QR 인증하기'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyAndNavigateQR(
    Place place,
    String qrToken,
    String? userId,
    String guestId,
  ) async {
    try {
      final vRes = await _reviewRepository.verifyStoreQR(
        storeId: place.id,
        qrToken: qrToken,
        userId: userId,
        guestId: userId == null ? guestId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('방문 인증이 완료되었습니다. 이제 리뷰를 작성할 수 있습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewWriteScreen(
              storeId: place.id,
              storeName: place.name,
              verificationId: vRes['id'] as String?,
              guestId: userId == null ? guestId : null,
              reviewVerificationType: place.reviewVerificationType,
            ),
          ),
        );
        if (result == true) {
          _loadPlaceDetail();
          _loadReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        final rawStr = e.toString();
        final is409 = rawStr.contains('409') || rawStr.contains('이미');
        final title = is409 ? '이미 리뷰를 작성했습니다.' : 'QR 인증 실패';
        final message = is409
            ? '이 매장의 현재 방문 인증으로 이미 리뷰를 작성했습니다.\n새로운 방문 리뷰는 72시간이 지난 뒤 다시 인증해 작성할 수 있습니다.'
            : rawStr
                  .replaceAll('Exception:', '')
                  .replaceAll('DioException', '')
                  .trim();
        _showWarningDialog(
          title,
          message.isEmpty ? '유효하지 않은 QR 코드입니다.' : message,
        );
      }
    }
  }

  void _showAttractionGateDialog(
    BuildContext context,
    Place place,
    String? userId,
    String guestId,
  ) {
    final hasCoords =
        place.latitude != null &&
        place.longitude != null &&
        (place.latitude != 0.0 || place.longitude != 0.0);
    final manualAllowed = place.manualVisitAllowed ?? true;

    if (!hasCoords) {
      if (manualAllowed) {
        _pickManualVisitDate(place, userId, guestId);
      } else {
        _showWarningDialog(
          '위치 정보 준비 중',
          '위치 정보 준비 중입니다. 위치 또는 방문일자 인증이 활성화되면 리뷰를 작성할 수 있습니다.',
        );
      }
      return;
    }

    if (!manualAllowed) {
      _verifyLocationGPS(place, userId, guestId);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '방문을 어떻게 인증하시겠습니까?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        content: const Text(
          '관광지 방문을 현재 위치(GPS) 또는 방문 날짜 직접 입력으로 인증할 수 있습니다.',
          style: TextStyle(fontSize: 13.0, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              '나중에',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _verifyLocationGPS(place, userId, guestId);
            },
            child: const Text(
              '현재 위치로 인증',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _pickManualVisitDate(place, userId, guestId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('방문일자로 인증'),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyLocationGPS(
    Place place,
    String? userId,
    String guestId,
  ) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          _showWarningDialog('현재 위치를 확인하지 못했습니다.', '위치 권한과 GPS 설정을 확인해 주세요.');
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final vRes = await _reviewRepository.verifyAttractionLocation(
        storeId: place.id,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        userId: userId,
        guestId: userId == null ? guestId : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('GPS 위치 방문 확인이 완료되었습니다. 이제 후기를 작성할 수 있습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReviewWriteScreen(
              storeId: place.id,
              storeName: place.name,
              verificationId: vRes['id'] as String?,
              guestId: userId == null ? guestId : null,
            ),
          ),
        );
        if (result == true) {
          _loadPlaceDetail();
          _loadReviews();
        }
      }
    } catch (e) {
      if (mounted) {
        _showWarningDialog('위치 확인 실패', _getCleanUserErrorMessage(e));
      }
    }
  }

  Future<void> _pickManualVisitDate(
    Place place,
    String? userId,
    String guestId,
  ) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 90)),
      lastDate: now,
      helpText: '방문 날짜 선택',
      cancelText: '취소',
      confirmText: '확인',
    );

    if (pickedDate != null && mounted) {
      try {
        final vRes = await _reviewRepository.verifyAttractionManualVisit(
          storeId: place.id,
          visitDate: pickedDate,
          userId: userId,
          guestId: userId == null ? guestId : null,
        );

        if (mounted) {
          final result = await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReviewWriteScreen(
                storeId: place.id,
                storeName: place.name,
                verificationId: vRes['id'] as String?,
                guestId: userId == null ? guestId : null,
              ),
            ),
          );
          if (result == true) {
            _loadPlaceDetail();
            _loadReviews();
          }
        }
      } catch (e) {
        if (mounted) {
          _showWarningDialog('방문 확인 실패', _getCleanUserErrorMessage(e));
        }
      }
    }
  }

  String _getCleanUserErrorMessage(dynamic error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      final dynamic detail = error.response?.data is Map
          ? error.response?.data['detail']
          : null;

      if (status == 400) {
        if (detail != null && detail is String) {
          if (detail.contains('미래') ||
              detail.contains('90일') ||
              detail.contains('날짜')) {
            return '방문일자를 확인해 주세요.\n오늘부터 최근 90일 이내의 날짜만 선택할 수 있습니다.';
          }
          if (detail.contains('사업장') || detail.contains('허용되지')) {
            return '이 관광지에서는 해당 인증 방식을 이용할 수 없습니다.';
          }
        }
        return '방문일자를 확인해 주세요.\n오늘부터 최근 90일 이내의 날짜만 선택할 수 있습니다.';
      }

      if (status == 409) {
        return '이미 이 관광지의 방문 인증 또는 후기가 있습니다.';
      }

      if (status == 401) {
        return '로그인 상태를 확인한 후 다시 시도해 주세요.';
      }

      if (status == 403) {
        return '이 관광지에서는 해당 인증 방식을 이용할 수 없습니다.';
      }

      if (status == 404) {
        return '관광지 정보를 찾지 못했습니다. 앱을 새로고침해 주세요.';
      }

      return '방문 확인을 처리하지 못했습니다.\n잠시 후 다시 시도해 주세요.';
    }

    final errStr = error.toString();
    if (errStr.contains('409') || errStr.contains('이미')) {
      return '이미 이 관광지의 방문 인증 또는 후기가 있습니다.';
    }
    if (errStr.contains('미래') ||
        errStr.contains('90일') ||
        errStr.contains('날짜')) {
      return '방문일자를 확인해 주세요.\n오늘부터 최근 90일 이내의 날짜만 선택할 수 있습니다.';
    }
    if (errStr.contains('401') || errStr.contains('로그인')) {
      return '로그인 상태를 확인한 후 다시 시도해 주세요.';
    }

    return '방문 확인을 처리하지 못했습니다.\n잠시 후 다시 시도해 주세요.';
  }

  void _showWarningDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13.0, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}
