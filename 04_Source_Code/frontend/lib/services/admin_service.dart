import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AdminService {
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

  // GET /admin/stats
  Future<Map<String, dynamic>> fetchAdminStats({String? adminId}) async {
    try {
      final response = await _dio.get(
        '/admin/stats',
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('대시보드 통계 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /admin/users
  Future<List<dynamic>> fetchAdminUsers({
    String? search,
    int skip = 0,
    int limit = 20,
    String? adminId,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/users',
        queryParameters: {
          if (search != null) 'search': search,
          'skip': skip,
          'limit': limit,
          if (adminId != null) 'admin_id': adminId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('회원 목록 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/users/{user_id}/status
  Future<Map<String, dynamic>> updateUserStatus(
    String userId,
    String status, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/users/$userId/status',
        data: {'status': status},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('회원 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /admin/stores
  Future<Map<String, dynamic>> createStore(
    Map<String, dynamic> storeData, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/stores',
        data: storeData,
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('매장 등록 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PUT /admin/stores/{store_id}
  Future<Map<String, dynamic>> updateStore(
    String storeId,
    Map<String, dynamic> storeData, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.put(
        '/admin/stores/$storeId',
        data: storeData,
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('매장 수정 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/stores/{store_id}/status
  Future<Map<String, dynamic>> updateStoreStatus(
    String storeId,
    String status, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/stores/$storeId/status',
        data: {'status': status},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('매장 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /admin/missions
  Future<Map<String, dynamic>> createMission(
    Map<String, dynamic> missionData, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/missions',
        data: missionData,
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('미션 등록 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/missions/{mission_id}/status
  Future<Map<String, dynamic>> updateMissionStatus(
    String missionId,
    String status, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/missions/$missionId/status',
        data: {'status': status},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('미션 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /admin/coupons
  Future<Map<String, dynamic>> createCoupon(
    Map<String, dynamic> couponData, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.post(
        '/admin/coupons',
        data: couponData,
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('쿠폰 상품 등록 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/coupons/{coupon_id}/status
  Future<Map<String, dynamic>> updateCouponStatus(
    String couponId,
    String status, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/coupons/$couponId/status',
        data: {'status': status},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('쿠폰 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /admin/reservations
  Future<List<dynamic>> fetchAdminReservations({
    String? adminId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/reservations',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (adminId != null) 'admin_id': adminId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('예약 내역 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/reservations/{reservation_id}/status
  Future<Map<String, dynamic>> updateReservationStatus(
    String reservationId,
    String status, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/reservations/$reservationId/status',
        data: {'status': status},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 상태 강제 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /admin/reviews
  Future<List<dynamic>> fetchAdminReviews({
    String? adminId,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/reviews',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (adminId != null) 'admin_id': adminId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('리뷰 목록 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /admin/reviews/{review_id}/hide
  Future<Map<String, dynamic>> hideReview(
    String reviewId,
    bool isHidden, {
    String? adminId,
  }) async {
    try {
      final response = await _dio.patch(
        '/admin/reviews/$reviewId/hide',
        data: {'is_hidden': isHidden},
        queryParameters: {if (adminId != null) 'admin_id': adminId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('리뷰 숨김 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /admin/audit-logs
  Future<List<dynamic>> fetchAdminAuditLogs({
    String? adminId,
    int skip = 0,
    int limit = 30,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/audit-logs',
        queryParameters: {
          'skip': skip,
          'limit': limit,
          if (adminId != null) 'admin_id': adminId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('감사 로그 로드 실패');
    } catch (e) {
      rethrow;
    }
  }
}
