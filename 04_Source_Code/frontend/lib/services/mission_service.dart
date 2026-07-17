import 'package:dio/dio.dart';
import '../config/api_config.dart';

class MissionService {
  // Helper to build Dio client
  Dio get _dio => Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ));

  // GET /missions
  Future<List<dynamic>> fetchMissions({String? storeId}) async {
    try {
      final response = await _dio.get(
        '/missions',
        queryParameters: storeId != null ? {'store_id': storeId} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('미션 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /missions/{mission_id}
  Future<Map<String, dynamic>> fetchMissionDetail(String id) async {
    try {
      final response = await _dio.get('/missions/$id');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('미션 상세 정보 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/{store_id}/missions
  Future<List<dynamic>> fetchStoreMissions(String storeId) async {
    try {
      final response = await _dio.get('/stores/$storeId/missions');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('매장별 미션 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /missions/{mission_id}/verify
  Future<Map<String, dynamic>> verifyMission(String id, String qrCode, {String? userId}) async {
    try {
      final response = await _dio.post(
        '/missions/$id/verify',
        data: {
          'qr_code': qrCode,
          'user_id': userId,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('미션 인증 처리 중 오류 발생');
    } catch (e) {
      rethrow;
    }
  }
}
