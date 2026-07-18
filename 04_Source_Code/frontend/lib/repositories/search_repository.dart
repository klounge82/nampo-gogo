import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';

class SearchRepository {
  final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _recentSearchKey = 'nampo_gogo_recent_searches_json';

  SearchRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  // GET /search
  Future<Map<String, dynamic>> search({
    required String q,
    String type = 'all',
    int page = 1,
    int size = 20,
    String lang = 'ko',
    double? latitude,
    double? longitude,
    String sort = 'relevance',
  }) async {
    try {
      final res = await _dio.get(
        '/search',
        queryParameters: {
          'q': q,
          'type': type,
          'page': page,
          'size': size,
          'lang': lang,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
          'sort': sort,
        },
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: search failed. Error: $e');
      }
      rethrow;
    }
  }

  // GET /search/suggestions (Autocomplete)
  Future<List<String>> getSuggestions(String q, {String lang = 'ko'}) async {
    try {
      final res = await _dio.get(
        '/search/suggestions',
        queryParameters: {'q': q, 'lang': lang},
      );
      final list = res.data['suggestions'] as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: getSuggestions failed. Error: $e');
      }
      return [];
    }
  }

  // GET /search/popular
  Future<List<String>> getPopularSearches({String lang = 'ko'}) async {
    try {
      final res = await _dio.get(
        '/search/popular',
        queryParameters: {'lang': lang},
      );
      final list = res.data['suggestions'] as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: getPopularSearches failed. Error: $e');
      }
      return [];
    }
  }

  // --- RECENT SEARCH LOCAL SECURE STORAGE HELPERS ---

  Future<List<String>> getRecentSearches() async {
    try {
      final raw = await _storage.read(key: _recentSearchKey);
      if (raw == null) return [];
      final List<dynamic> parsed = jsonDecode(raw);
      return parsed.map((e) => e.toString()).toList();
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: getRecentSearches failed. Error: $e');
      }
      return [];
    }
  }

  Future<void> saveRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    try {
      final list = await getRecentSearches();

      // Remove duplicates and move to the front
      list.remove(trimmed);
      list.insert(0, trimmed);

      // Limit to maximum 10 items
      if (list.length > 10) {
        list.removeLast();
      }

      await _storage.write(key: _recentSearchKey, value: jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: saveRecentSearch failed. Error: $e');
      }
    }
  }

  Future<void> deleteRecentSearch(String query) async {
    try {
      final list = await getRecentSearches();
      list.remove(query);
      await _storage.write(key: _recentSearchKey, value: jsonEncode(list));
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: deleteRecentSearch failed. Error: $e');
      }
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      await _storage.delete(key: _recentSearchKey);
    } catch (e) {
      if (kDebugMode) {
        print('SearchRepository: clearRecentSearches failed. Error: $e');
      }
    }
  }
}
