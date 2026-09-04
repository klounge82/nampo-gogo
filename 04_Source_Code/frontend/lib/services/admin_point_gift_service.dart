import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'auth_interceptor.dart';

class AdminPointGiftService {
  Dio get _dio {
    final dio = Dio(
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
    dio.interceptors.add(AuthInterceptor(dio));
    return dio;
  }

  /// GET /admin/points/users/{user_id}/summary
  Future<Map<String, dynamic>> getUserSummary(String userId) async {
    try {
      final response = await _dio.get('/admin/points/users/$userId/summary');
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('포인트 요약 로드 실패');
    } catch (e) {
      debugPrint('AdminPointGiftService.getUserSummary error: $e');
      rethrow;
    }
  }

  /// GET /admin/points/users/{user_id}/history
  Future<Map<String, dynamic>> getUserHistory(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _dio.get(
        '/admin/points/users/$userId/history',
        queryParameters: {'limit': limit, 'offset': offset},
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('포인트 원장 내역 로드 실패');
    } catch (e) {
      debugPrint('AdminPointGiftService.getUserHistory error: $e');
      rethrow;
    }
  }

  /// GET /admin/points/users/{user_id}/lots
  Future<Map<String, dynamic>> getUserLots(
    String userId, {
    int limit = 50,
    int offset = 0,
    String? statusFilter,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'ALL') {
        params['status_filter'] = statusFilter;
      }
      final response = await _dio.get(
        '/admin/points/users/$userId/lots',
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('포인트 Lot 목록 로드 실패');
    } catch (e) {
      debugPrint('AdminPointGiftService.getUserLots error: $e');
      rethrow;
    }
  }

  /// GET /admin/gifts
  Future<Map<String, dynamic>> listGifts({
    int limit = 20,
    int offset = 0,
    String? statusFilter,
    String? userId,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'ALL') {
        params['status_filter'] = statusFilter;
      }
      if (userId != null && userId.trim().isNotEmpty) {
        params['user_id'] = userId.trim();
      }
      final response = await _dio.get(
        '/admin/gifts',
        queryParameters: params,
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      throw Exception('선물 감사 목록 로드 실패');
    } catch (e) {
      debugPrint('AdminPointGiftService.listGifts error: $e');
      rethrow;
    }
  }
}
