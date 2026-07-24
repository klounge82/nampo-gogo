import 'package:dio/dio.dart';
import '../config/api_config.dart';

class PlaceService {
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

  // GET /stores
  Future<List<dynamic>> fetchPlaces({String? category}) async {
    try {
      final response = await _dio.get(
        '/stores',
        queryParameters: category != null ? {'category': category} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('장소 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/categories
  Future<List<dynamic>> fetchCategories() async {
    try {
      final response = await _dio.get('/stores/categories');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('카테고리 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/search?q=...
  Future<List<dynamic>> searchPlaces(String query) async {
    try {
      final response = await _dio.get(
        '/stores/search',
        queryParameters: {'q': query},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('장소 검색 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/{store_id}
  Future<Map<String, dynamic>> fetchPlaceDetail(String id) async {
    try {
      final response = await _dio.get('/stores/$id');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('장소 상세 정보 조회 실패');
    } catch (e) {
      rethrow;
    }
  }
}
