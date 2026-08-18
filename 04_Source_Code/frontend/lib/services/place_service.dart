import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

class PlaceService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

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

  Future<Options?> _getAuthOptions() async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token != null && token.trim().isNotEmpty) {
        return Options(
          headers: {
            'Authorization': 'Bearer ${token.trim()}',
          },
        );
      }
    } catch (_) {}
    return null;
  }

  // GET /stores
  Future<List<dynamic>> fetchPlaces({String? category, String? locale}) async {
    try {
      final params = <String, dynamic>{};
      if (category != null) params['category'] = category;
      if (locale != null) params['locale'] = locale;

      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/stores',
        queryParameters: params.isNotEmpty ? params : null,
        options: options,
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
      final options = await _getAuthOptions();
      final response = await _dio.get('/stores/categories', options: options);
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('카테고리 목록 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/search?q=...
  Future<List<dynamic>> searchPlaces(String query, {String? locale}) async {
    try {
      final params = <String, dynamic>{'q': query};
      if (locale != null) params['locale'] = locale;

      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/stores/search',
        queryParameters: params,
        options: options,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('장소 검색 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/{id}
  Future<Map<String, dynamic>> fetchPlaceDetail(String id, {String? locale}) async {
    try {
      final params = <String, dynamic>{};
      if (locale != null) params['locale'] = locale;

      final options = await _getAuthOptions();
      final response = await _dio.get(
        '/stores/$id',
        queryParameters: params.isNotEmpty ? params : null,
        options: options,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('장소 상세 정보 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }
}
