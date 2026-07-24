import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class FavoriteRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _localFavKey = 'nampo_gogo_local_favorites_json';

  FavoriteRepository({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  // POST /favorites (Add)
  Future<Map<String, dynamic>> addFavorite(
    String targetType,
    String targetId, {
    String? token,
  }) async {
    try {
      final res = await _dio.post(
        '/favorites',
        data: {'target_type': targetType, 'target_id': targetId},
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: addFavorite failed. Error: $e');
      }
      rethrow;
    }
  }

  // DELETE /favorites/{target_type}/{target_id} (Remove)
  Future<Map<String, dynamic>> removeFavorite(
    String targetType,
    String targetId, {
    String? token,
  }) async {
    try {
      final res = await _dio.delete(
        '/favorites/$targetType/$targetId',
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: removeFavorite failed. Error: $e');
      }
      rethrow;
    }
  }

  // GET /favorites (List)
  Future<List<dynamic>> getFavorites(String lang, {String? token}) async {
    try {
      final res = await _dio.get(
        '/favorites',
        queryParameters: {'lang': lang},
        options: token != null
            ? Options(headers: {'Authorization': 'Bearer $token'})
            : null,
      );
      return res.data as List<dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: getFavorites failed. Error: $e');
      }
      rethrow;
    }
  }

  // POST /favorites/merge (Merge)
  Future<Map<String, dynamic>> mergeFavorites(
    List<Map<String, String>> localItems,
    String token,
  ) async {
    try {
      final res = await _dio.post(
        '/favorites/merge',
        data: {'local_items': localItems},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: mergeFavorites failed. Error: $e');
      }
      rethrow;
    }
  }

  // --- LOCAL SECURE STORAGE FOR GUESTS ---

  Future<List<Map<String, String>>> getLocalFavorites() async {
    try {
      final raw = await _storage.read(key: _localFavKey);
      if (raw == null) return [];
      final List<dynamic> parsed = jsonDecode(raw);
      return parsed.map((e) {
        final map = e as Map<String, dynamic>;
        return {
          'target_type': map['target_type'].toString(),
          'target_id': map['target_id'].toString(),
        };
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: getLocalFavorites failed. Error: $e');
      }
      return [];
    }
  }

  Future<void> saveLocalFavorite(String targetType, String targetId) async {
    try {
      final list = await getLocalFavorites();
      // Duplication check
      final exists = list.any(
        (item) =>
            item['target_id'] == targetId && item['target_type'] == targetType,
      );
      if (!exists) {
        list.add({'target_type': targetType, 'target_id': targetId});
        await _storage.write(key: _localFavKey, value: jsonEncode(list));
      }
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: saveLocalFavorite failed. Error: $e');
      }
    }
  }

  Future<void> removeLocalFavorite(String targetType, String targetId) async {
    try {
      final list = await getLocalFavorites();
      list.removeWhere(
        (item) =>
            item['target_id'] == targetId && item['target_type'] == targetType,
      );
      await _storage.write(key: _localFavKey, value: jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: removeLocalFavorite failed. Error: $e');
      }
    }
  }

  Future<void> clearLocalFavorites() async {
    try {
      await _storage.delete(key: _localFavKey);
    } catch (e) {
      if (kDebugMode) {
        print('FavoriteRepository: clearLocalFavorites failed. Error: $e');
      }
    }
  }
}
