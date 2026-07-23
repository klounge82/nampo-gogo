import 'package:flutter/foundation.dart';
import '../models/review.dart';
import '../models/user.dart';
import '../models/place.dart';
import '../services/review_service.dart';

class ReviewRepository {
  final ReviewService _reviewService;

  // Local state cache for offline simulation fallback
  static final List<Review> _mockReviews = [
    Review(
      id: 'rev_mock_1',
      userId: 'usr_mock_999',
      storeId: 'store_mock_1',
      rating: 5,
      content: '숯불 향이 가득 밴 갈비 맛이 일품입니다! 서비스도 대단히 만족스러워요.',
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      user: User(
        id: 'usr_mock_999',
        email: 'tester@gogo.com',
        nickname: '남포고고동이',
        role: 'member',
        status: 'active',
        currentPoints: 1200,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now().subtract(const Duration(days: 10)),
      ),
      store: Place(
        id: 'store_mock_1',
        name: '남포 숯불갈비',
        category: '한식',
        rating: 4.8,
        address: '부산 중구 남포길 12-1',
        description: '숯불로 구워내 더욱 풍미 깊은 양념갈비 맛집입니다.',
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ),
    Review(
      id: 'rev_mock_2',
      userId: 'usr_mock_777',
      storeId: 'store_mock_1',
      rating: 4,
      content: '기대 이상으로 고기가 부드럽고 밑반찬이 다양해서 아주 맛있게 잘 먹고 왔습니다.',
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      updatedAt: DateTime.now().subtract(const Duration(days: 4)),
      user: User(
        id: 'usr_mock_777',
        email: 'chulsoo@gogo.com',
        nickname: '중구철수',
        role: 'member',
        status: 'active',
        currentPoints: 800,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now().subtract(const Duration(days: 20)),
      ),
      store: Place(
        id: 'store_mock_1',
        name: '남포 숯불갈비',
        category: '한식',
        rating: 4.8,
        address: '부산 중구 남포길 12-1',
        description: '숯불로 구워내 더욱 풍미 깊은 양념갈비 맛집입니다.',
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ),
  ];

  ReviewRepository({ReviewService? reviewService})
    : _reviewService = reviewService ?? ReviewService();

  // Create Review
  Future<Review> createReview({
    required String storeId,
    required int rating,
    required String content,
    String? userId,
    String? guestId,
    String? verificationId,
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _reviewService.createReview(
        storeId: storeId,
        rating: rating,
        content: content,
        userId: userId,
        guestId: guestId,
        verificationId: verificationId,
        imageUrls: imageUrls,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReviewRepository: Failed to create review online. Simulating offline. Error: $e',
        );
      }

      final newId = 'rev_mock_${DateTime.now().millisecondsSinceEpoch}';
      final newRev = Review(
        id: newId,
        userId: userId,
        guestId: guestId,
        storeId: storeId,
        rating: rating,
        content: content,
        isDeleted: false,
        verificationId: verificationId,
        verificationBadge: verificationId != null ? 'QR 방문 인증' : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: User(
          id: userId ?? 'usr_mock_999',
          email: 'tester@gogo.com',
          nickname: userId != null ? '남포고고동이' : '게스트',
          role: 'member',
          status: 'active',
          currentPoints: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        store: Place(
          id: storeId,
          name: storeId.contains('jagal') ? '자갈치 신선 횟집' : 'K-Lounge',
          category: '음식점',
          rating: 4.5,
          address: '부산 중구 남포길 1',
          description: '남포 GoGo 협약 제공 매장입니다.',
          imageUrl: '',
          createdAt: DateTime.now(),
        ),
      );

      _mockReviews.insert(0, newRev);
      return newRev;
    }
  }

  // QR Verification
  Future<Map<String, dynamic>> verifyStoreQR({
    required String storeId,
    required String qrToken,
    String? userId,
    String? guestId,
  }) async {
    try {
      return await _reviewService.verifyStoreQR(
        storeId: storeId,
        qrToken: qrToken,
        userId: userId,
        guestId: guestId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: verifyStoreQR error: $e');
      }
      rethrow;
    }
  }

  // Attraction Location Verification
  Future<Map<String, dynamic>> verifyAttractionLocation({
    required String storeId,
    required double latitude,
    required double longitude,
    String? userId,
    String? guestId,
  }) async {
    try {
      return await _reviewService.verifyAttractionLocation(
        storeId: storeId,
        latitude: latitude,
        longitude: longitude,
        userId: userId,
        guestId: guestId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: verifyAttractionLocation error: $e');
      }
      rethrow;
    }
  }

  // Attraction Manual Visit Verification
  Future<Map<String, dynamic>> verifyAttractionManualVisit({
    required String storeId,
    required DateTime visitDate,
    String? userId,
    String? guestId,
  }) async {
    try {
      return await _reviewService.verifyAttractionManualVisit(
        storeId: storeId,
        visitDate: visitDate,
        userId: userId,
        guestId: guestId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: verifyAttractionManualVisit error: $e');
      }
      rethrow;
    }
  }

  // Active Verification Lookup
  Future<Map<String, dynamic>?> getActiveVerification({
    required String storeId,
    String? userId,
    String? guestId,
  }) async {
    return await _reviewService.getActiveVerification(
      storeId: storeId,
      userId: userId,
      guestId: guestId,
    );
  }

  // Fetch Store Reviews
  Future<List<Review>> getStoreReviews(
    String storeId, {
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final list = await _reviewService.fetchStoreReviews(
        storeId,
        skip: skip,
        limit: limit,
      );
      return list
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReviewRepository: Failed to load store reviews. Simulating offline. Error: $e',
        );
      }
      return _mockReviews
          .where((r) => r.storeId == storeId && !r.isDeleted)
          .toList();
    }
  }

  // Fetch My Reviews
  Future<List<Review>> getMyReviews({
    String? userId,
    String? guestId,
    bool includeDeleted = false,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final list = await _reviewService.fetchMyReviews(
        userId: userId,
        guestId: guestId,
        includeDeleted: includeDeleted,
        skip: skip,
        limit: limit,
      );
      return list
          .map((json) => Review.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReviewRepository: Failed to load my reviews. Simulating offline. Error: $e',
        );
      }
      final targetUid = userId ?? 'usr_mock_999';
      return _mockReviews
          .where(
            (r) =>
                r.userId == targetUid &&
                (!includeDeleted ? !r.isDeleted : true),
          )
          .toList();
    }
  }

  // Update Review
  Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? content,
    String? userId,
    String? guestId,
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _reviewService.updateReview(
        reviewId,
        rating: rating,
        content: content,
        userId: userId,
        guestId: guestId,
        imageUrls: imageUrls,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReviewRepository: Failed to update review. Simulating offline. Error: $e',
        );
      }

      final index = _mockReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        final current = _mockReviews[index];
        final updated = Review(
          id: current.id,
          userId: current.userId,
          storeId: current.storeId,
          rating: rating ?? current.rating,
          content: content ?? current.content,
          isDeleted: current.isDeleted,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          user: current.user,
          store: current.store,
        );
        _mockReviews[index] = updated;
        return updated;
      }
      throw Exception('리뷰를 찾을 수 없습니다.');
    }
  }

  // Delete Review
  Future<bool> deleteReview(
    String reviewId, {
    String? userId,
    String? guestId,
  }) async {
    try {
      final res = await _reviewService.deleteReview(
        reviewId,
        userId: userId,
        guestId: guestId,
      );
      return res['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReviewRepository: Failed to delete review. Simulating offline. Error: $e',
        );
      }

      final index = _mockReviews.indexWhere((r) => r.id == reviewId);
      if (index != -1) {
        final current = _mockReviews[index];
        _mockReviews[index] = Review(
          id: current.id,
          userId: current.userId,
          storeId: current.storeId,
          rating: current.rating,
          content: current.content,
          isDeleted: true,
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          user: current.user,
          store: current.store,
        );
        return true;
      }
      throw Exception('리뷰를 찾을 수 없습니다.');
    }
  }

  // Restore Review
  Future<Review> restoreReview(
    String reviewId, {
    String? userId,
    String? guestId,
  }) async {
    try {
      final res = await _reviewService.restoreReview(
        reviewId,
        userId: userId,
        guestId: guestId,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to restore review error: $e');
      }
      rethrow;
    }
  }

  // Rewrite Review
  Future<Review> rewriteReview(
    String reviewId, {
    int? rating,
    String? content,
    String? userId,
    String? guestId,
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _reviewService.rewriteReview(
        reviewId,
        rating: rating,
        content: content,
        userId: userId,
        guestId: guestId,
        imageUrls: imageUrls,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to rewrite review error: $e');
      }
      rethrow;
    }
  }
}
