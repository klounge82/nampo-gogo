import 'package:dio/dio.dart';
import '../config/api_config.dart';

class CouponService {
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

  // GET /coupons
  Future<List<dynamic>> fetchCoupons() async {
    try {
      final response = await _dio.get('/coupons');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('쿠폰 상품 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /coupons/{coupon_id}/exchange
  Future<Map<String, dynamic>> exchangeCoupon(
    String couponId, {
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/coupons/$couponId/exchange',
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('쿠폰 교환 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /users/coupons
  Future<List<dynamic>> fetchUserCoupons({
    String? userId,
    String? status,
  }) async {
    try {
      final response = await _dio.get(
        '/users/coupons',
        queryParameters: {
          if (userId != null) 'user_id': userId,
          if (status != null) 'status': status,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('보유 쿠폰 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /users/coupons/{user_coupon_id}/use
  Future<Map<String, dynamic>> useUserCoupon(
    String userCouponId, {
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/users/coupons/$userCouponId/use',
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('쿠폰 사용 실패');
    } catch (e) {
      rethrow;
    }
  }
}
