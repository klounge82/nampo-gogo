import 'package:dio/dio.dart';
import '../config/api_config.dart';

class AnalyticsRepository {
  final Dio _dio;

  AnalyticsRepository({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConfig.baseUrl,
              connectTimeout: ApiConfig.connectTimeout,
              receiveTimeout: ApiConfig.receiveTimeout,
            ),
          );

  // GET /analytics/dashboard
  Future<Map<String, dynamic>> fetchDashboardSummary({
    required String token,
    String? storeId,
  }) async {
    try {
      final res = await _dio.get(
        '/analytics/dashboard',
        queryParameters: {if (storeId != null) 'store_id': storeId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('대시보드 요약 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /analytics/revenue
  Future<Map<String, dynamic>> fetchRevenueStats({
    required String token,
    String? storeId,
  }) async {
    try {
      final res = await _dio.get(
        '/analytics/revenue',
        queryParameters: {if (storeId != null) 'store_id': storeId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('매출 통계 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /analytics/reservation
  Future<Map<String, dynamic>> fetchReservationStats({
    required String token,
    String? storeId,
  }) async {
    try {
      final res = await _dio.get(
        '/analytics/reservation',
        queryParameters: {if (storeId != null) 'store_id': storeId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('예약 통계 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /analytics/ai
  Future<Map<String, dynamic>> fetchAIStats({
    required String token,
    String? storeId,
  }) async {
    try {
      final res = await _dio.get(
        '/analytics/ai',
        queryParameters: {if (storeId != null) 'store_id': storeId},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data != null) {
        return res.data as Map<String, dynamic>;
      }
      throw Exception('AI 통계 로드 실패');
    } catch (e) {
      rethrow;
    }
  }
}
