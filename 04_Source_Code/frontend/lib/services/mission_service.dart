import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class MissionService {
  // Helper to build Dio client
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

  // GET /missions
  Future<List<dynamic>> fetchMissions({String? storeId, String? locale}) async {
    try {
      final params = <String, dynamic>{};
      if (storeId != null) params['store_id'] = storeId;
      if (locale != null) params['locale'] = locale;

      final response = await _dio.get(
        '/missions',
        queryParameters: params.isNotEmpty ? params : null,
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
  Future<Map<String, dynamic>> fetchMissionDetail(String id, {String? locale}) async {
    try {
      final params = <String, dynamic>{};
      if (locale != null) params['locale'] = locale;

      final response = await _dio.get(
        '/missions/$id',
        queryParameters: params.isNotEmpty ? params : null,
      );
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

  // Helper to get Auth headers
  Future<Options> _getAuthOptions({String? authToken}) async {
    String? token = authToken;
    if (token == null || token.isEmpty) {
      try {
        const storage = FlutterSecureStorage();
        token = await storage.read(key: 'access_token');
      } catch (_) {}
    }
    if (token != null && token.isNotEmpty) {
      return Options(headers: {'Authorization': 'Bearer $token'});
    }
    return Options();
  }

  // POST /missions/{mission_id}/verify
  Future<Map<String, dynamic>> verifyMission(
    String id,
    String qrCode, {
    String? userId,
    double? latitude,
    double? longitude,
    String? imageBase64,
    String? authToken,
  }) async {
    try {
      final payload = <String, dynamic>{
        'qr_code': qrCode,
        'user_id': userId,
      };
      if (latitude != null) payload['latitude'] = latitude;
      if (longitude != null) payload['longitude'] = longitude;
      if (imageBase64 != null) payload['image_base64'] = imageBase64;

      final options = await _getAuthOptions(authToken: authToken);
      final response = await _dio.post(
        '/missions/$id/verify',
        data: payload,
        options: options,
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
