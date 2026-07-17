import 'package:dio/dio.dart';
import '../config/api_config.dart';

class PointService {
  Dio get _dio => Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

  // GET /users/points
  Future<Map<String, dynamic>> fetchUserPoints({String? userId}) async {
    try {
      final response = await _dio.get(
        '/users/points',
        queryParameters: userId != null ? {'user_id': userId} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('보유 포인트 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /users/points/history
  Future<List<dynamic>> fetchPointHistory({String? userId}) async {
    try {
      final response = await _dio.get(
        '/users/points/history',
        queryParameters: userId != null ? {'user_id': userId} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('포인트 내역 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /users/points/earn
  Future<Map<String, dynamic>> earnPoints(int points, String activity, {String? userId}) async {
    try {
      final response = await _dio.post(
        '/users/points/earn',
        data: {
          'points': points,
          'activity': activity,
          'user_id': userId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('포인트 적립 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /users/points/spend
  Future<Map<String, dynamic>> spendPoints(int points, String activity, {String? userId}) async {
    try {
      final response = await _dio.post(
        '/users/points/spend',
        data: {
          'points': points,
          'activity': activity,
          'user_id': userId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('포인트 사용 실패');
    } catch (e) {
      rethrow;
    }
  }
}
