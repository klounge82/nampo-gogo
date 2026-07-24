import 'package:dio/dio.dart';
import '../config/api_config.dart';

class RecommendationService {
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

  // POST /recommendations/courses
  Future<Map<String, dynamic>> generateCourse({
    String? userId,
    required String travelType,
    required String travelDuration,
    required List<String> categories,
    required String transportMode,
    double? latitude,
    double? longitude,
    bool? usePersonalization,
    bool? excludeVisited,
    bool? preferRewards,
  }) async {
    try {
      final response = await _dio.post(
        '/recommendations/courses',
        data: {
          'user_id': userId,
          'travel_type': travelType,
          'travel_duration': travelDuration,
          'categories': categories,
          'transport_mode': transportMode,
          'latitude': latitude,
          'longitude': longitude,
          'use_personalization': usePersonalization ?? false,
          'exclude_visited': excludeVisited ?? false,
          'prefer_new_places': excludeVisited ?? false,
          'prefer_rewards': preferRewards ?? false,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('추천 코스 생성 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /recommendations/history
  Future<List<dynamic>> fetchSavedHistory({String? userId}) async {
    try {
      final response = await _dio.get(
        '/recommendations/history',
        queryParameters: {if (userId != null) 'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('저장된 코스 목록 로드 실패');
    } catch (e) {
      rethrow;
    }
  }

  // PATCH /recommendations/{id}/save
  Future<Map<String, dynamic>> toggleSaveStatus(
    String id, {
    required bool isSaved,
  }) async {
    try {
      final response = await _dio.patch(
        '/recommendations/$id/save',
        queryParameters: {'is_saved': isSaved},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('코스 저장 상태 변경 실패');
    } catch (e) {
      rethrow;
    }
  }

  // DELETE /recommendations/{id}
  Future<Map<String, dynamic>> deleteCourse(String id) async {
    try {
      final response = await _dio.delete('/recommendations/$id');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('코스 삭제 실패');
    } catch (e) {
      rethrow;
    }
  }
}
