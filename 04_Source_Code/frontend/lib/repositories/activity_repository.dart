import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class ActivityRepository {
  final Dio _dio;

  ActivityRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  // GET /activity
  Future<List<dynamic>> getActivities({
    String? type,
    int page = 1,
    int size = 20,
    required String token,
  }) async {
    try {
      final res = await _dio.get(
        '/activity',
        queryParameters: {
          if (type != null) 'type': type,
          'page': page,
          'size': size,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityRepository: getActivities failed. Error: $e');
      }
      rethrow;
    }
  }

  // GET /activity/today
  Future<List<dynamic>> getTodayActivities({required String token}) async {
    try {
      final res = await _dio.get(
        '/activity/today',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('ActivityRepository: getTodayActivities failed. Error: $e');
      }
      rethrow;
    }
  }
}
