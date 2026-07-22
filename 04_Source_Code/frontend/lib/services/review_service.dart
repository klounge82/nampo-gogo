import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ReviewService {
  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // POST /stores/{store_id}/reviews
  Future<Map<String, dynamic>> createReview({
    required String storeId,
    required int rating,
    required String content,
    String? userId,
    String? guestId,
    String? verificationId,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/reviews',
        data: {
          'rating': rating,
          'content': content,
          if (userId != null) 'user_id': userId,
          if (guestId != null) 'guest_id': guestId,
          if (verificationId != null) 'verification_id': verificationId,
          if (imageUrls != null) 'image_urls': imageUrls,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('리뷰 등록 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /stores/{store_id}/verify-qr
  Future<Map<String, dynamic>> verifyStoreQR({
    required String storeId,
    required String qrToken,
    String? userId,
    String? guestId,
  }) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/verify-qr',
        data: {
          'qr_token': qrToken,
          if (userId != null) 'user_id': userId,
          if (guestId != null) 'guest_id': guestId,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('QR 방문 인증 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /stores/{store_id}/verify-location
  Future<Map<String, dynamic>> verifyAttractionLocation({
    required String storeId,
    required double latitude,
    required double longitude,
    String? userId,
    String? guestId,
  }) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/verify-location',
        data: {
          'latitude': latitude,
          'longitude': longitude,
          if (userId != null) 'user_id': userId,
          if (guestId != null) 'guest_id': guestId,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('위치 방문 확인 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /stores/{store_id}/verify-manual-visit
  Future<Map<String, dynamic>> verifyAttractionManualVisit({
    required String storeId,
    required DateTime visitDate,
    String? userId,
    String? guestId,
  }) async {
    try {
      final response = await _dio.post(
        '/stores/$storeId/verify-manual-visit',
        data: {
          'visit_date': visitDate.toIso8601String(),
          if (userId != null) 'user_id': userId,
          if (guestId != null) 'guest_id': guestId,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('방문 날짜 입력 확인 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/{store_id}/active-verification
  Future<Map<String, dynamic>?> getActiveVerification({
    required String storeId,
    String? userId,
    String? guestId,
  }) async {
    try {
      final response = await _dio.get(
        '/stores/$storeId/active-verification',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (guestId != null) 'guest_id': guestId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // GET /stores/{store_id}/reviews
  Future<List<dynamic>> fetchStoreReviews(
    String storeId, {
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/stores/$storeId/reviews',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('리뷰 목록 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /reviews/me
  Future<List<dynamic>> fetchMyReviews({
    String? userId,
    int skip = 0,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get(
        '/reviews/me',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          'skip': skip,
          'limit': limit,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('내 리뷰 목록 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /reviews/{review_id}
  Future<Map<String, dynamic>> updateReview(
    String reviewId, {
    int? rating,
    String? content,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await _dio.patch(
        '/reviews/$reviewId',
        data: {
          if (rating != null) 'rating': rating,
          if (content != null) 'content': content,
          if (imageUrls != null) 'image_urls': imageUrls,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('리뷰 수정 실패');
    } catch (e) {
      rethrow;
    }
  }

  // DELETE /reviews/{review_id}
  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final response = await _dio.delete('/reviews/$reviewId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('리뷰 삭제 실패');
    } catch (e) {
      rethrow;
    }
  }
}
