import 'package:flutter/foundation.dart';
import '../models/place.dart';
import '../services/place_service.dart';
import '../data/mock_data.dart';
import '../config/production_config.dart';

class PlaceRepository {
  final PlaceService _placeService;

  PlaceRepository({PlaceService? placeService})
    : _placeService = placeService ?? PlaceService();

  // Helper to map Mock Recommendation to Place model
  Place _mapMockToPlace(dynamic rec) {
    return Place(
      id: rec.id,
      name: rec.name,
      category: rec.category,
      rating: rec.rating,
      address: rec.address,
      description: rec.description,
      createdAt: DateTime.now(),
    );
  }

  // Fetch all places, filter by category locally on fallback
  Future<List<Place>> getPlaces({String? category}) async {
    try {
      final data = await _placeService.fetchPlaces(category: category);
      return data
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
      if (kDebugMode) {
        print(
          'PlaceRepository: Failed to load places from API. Falling back to Mock. Error: $e',
        );
      }
      // Fallback local Mock mapping
      var list = MockData.recommendations
          .map((rec) => _mapMockToPlace(rec))
          .toList();
      if (category != null) {
        list = list.where((place) => place.category == category).toList();
      }
      return list;
    }
  }

  // Fetch unique categories
  Future<List<String>> getCategories() async {
    try {
      final data = await _placeService.fetchCategories();
      return data.map((cat) => cat as String).toList();
    } catch (e) {
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
      if (kDebugMode) {
        print(
          'PlaceRepository: Failed to load categories. Falling back. Error: $e',
        );
      }
      // Fallback local unique categories
      return ['먹거리', '볼거리', '맛집'];
    }
  }

  // Search places
  Future<List<Place>> searchPlaces(String query) async {
    try {
      final data = await _placeService.searchPlaces(query);
      return data
          .map((json) => Place.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
      if (kDebugMode) {
        print('PlaceRepository: Search failed. Falling back. Error: $e');
      }
      // Fallback local search filtering
      final cleanQuery = query.toLowerCase();
      return MockData.recommendations
          .map((rec) => _mapMockToPlace(rec))
          .where(
            (place) =>
                place.name.toLowerCase().contains(cleanQuery) ||
                place.description.toLowerCase().contains(cleanQuery),
          )
          .toList();
    }
  }

  // Fetch detail by ID
  Future<Place> getPlaceDetail(String id) async {
    try {
      final json = await _placeService.fetchPlaceDetail(id);
      return Place.fromJson(json);
    } catch (e) {
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
      if (kDebugMode) {
        print('PlaceRepository: Detail fetch failed. Falling back. Error: $e');
      }
      // Fallback mock detail matching
      try {
        final mockRec = MockData.recommendations.firstWhere(
          (rec) => rec.id == id,
        );
        return _mapMockToPlace(mockRec);
      } catch (_) {
        throw Exception('해당 장소의 정보를 찾을 수 없습니다.');
      }
    }
  }
}
