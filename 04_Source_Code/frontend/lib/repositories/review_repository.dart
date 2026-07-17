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
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _reviewService.createReview(
        storeId: storeId,
        rating: rating,
        content: content,
        userId: userId,
        imageUrls: imageUrls,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to create review online. Simulating offline. Error: $e');
      }

      final newId = 'rev_mock_${DateTime.now().millisecondsSinceEpoch}';
      final newRev = Review(
        id: newId,
        userId: userId ?? 'usr_mock_999',
        storeId: storeId,
        rating: rating,
        content: content,
        isDeleted: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: User(
          id: userId ?? 'usr_mock_999',
          email: 'tester@gogo.com',
          nickname: '나(오프라인)',
          role: 'member',
          status: 'active',
          currentPoints: 0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        store: Place(
          id: storeId,
          name: storeId.contains('jagal') ? '자갈치 신선 횟집' : '남포 숯불갈비',
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

  // Fetch Store Reviews
  Future<List<Review>> getStoreReviews(String storeId, {int skip = 0, int limit = 10}) async {
    try {
      final list = await _reviewService.fetchStoreReviews(storeId, skip: skip, limit: limit);
      return list.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to load store reviews. Simulating offline. Error: $e');
      }
      return _mockReviews.where((r) => r.storeId == storeId && !r.isDeleted).toList();
    }
  }

  // Fetch My Reviews
  Future<List<Review>> getMyReviews({String? userId, int skip = 0, int limit = 10}) async {
    try {
      final list = await _reviewService.fetchMyReviews(userId: userId, skip: skip, limit: limit);
      return list.map((json) => Review.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to load my reviews. Simulating offline. Error: $e');
      }
      final targetUid = userId ?? 'usr_mock_999';
      return _mockReviews.where((r) => r.userId == targetUid && !r.isDeleted).toList();
    }
  }

  // Update Review
  Future<Review> updateReview(
    String reviewId, {
    int? rating,
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      final res = await _reviewService.updateReview(
        reviewId,
        rating: rating,
        content: content,
        imageUrls: imageUrls,
      );
      return Review.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to update review. Simulating offline. Error: $e');
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
  Future<bool> deleteReview(String reviewId) async {
    try {
      final res = await _reviewService.deleteReview(reviewId);
      return res['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('ReviewRepository: Failed to delete review. Simulating offline. Error: $e');
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
}
