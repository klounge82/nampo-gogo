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
  Place _mapMockToPlace(dynamic rec, {String? locale}) {
    String name = rec.name;
    String description = rec.description;
    String address = rec.address;
    String category = rec.category;

    final loc = locale?.toLowerCase() ?? 'ko';
    if (loc.contains('zh')) {
      if (rec.id == 'rec_01') {
        name = 'BIFF广场坚果糖饼';
        category = 'FOOD';
        address = '釜山中区九德路 58-1';
        description = '南浦洞必吃打卡！外酥里嫩的糖饼包裹着满满的坚果，香甜可口。';
      } else if (rec.id == 'rec_02') {
        name = '龙头山公园釜山塔';
        category = 'ATTRACTION';
        address = '釜山中区龙头山路 37-55';
        description = '耸立在南浦洞中心的釜山地标。从展望台俯瞰釜山港与影岛大桥夜景绝美。';
      } else if (rec.id == 'rec_03') {
        name = '札嘎其市场新鲜刺身店';
        category = 'FOOD';
        address = '釜山中区札嘎其海岸路 52';
        description = '在釜山最大的海鲜市场札嘎其市场享用现抓新鲜刺身与辣鱼汤。';
      } else if (rec.id == 'rec_04') {
        name = '国际市场 Ggotbunine';
        category = 'ATTRACTION';
        address = '釜山中区新昌洞4街 国际市场内';
        description = '电影《国际市场》真实拍摄地，怀旧文创商品与拍照打卡区一应俱全。';
      }
    } else if (loc.contains('en')) {
      if (rec.id == 'rec_01') {
        name = 'BIFF Square Ssiat Hotteok';
        category = 'FOOD';
        address = '58-1 Gudeok-ro, Jung-gu, Busan';
        description = 'A must-try in Nampo-dong! Crispy hotteok packed with sweet nuts.';
      } else if (rec.id == 'rec_02') {
        name = 'Yongdusan Park Busan Tower';
        category = 'ATTRACTION';
        address = '37-55 Yongdusan-gil, Jung-gu, Busan';
        description = 'Landmark of Busan towering in central Nampo-dong with stunning views.';
      } else if (rec.id == 'rec_03') {
        name = 'Jagalchi Market Fresh Fish Restaurant';
        category = 'FOOD';
        address = '52 Jagalchihaean-ro, Jung-gu, Busan';
        description = 'Enjoy fresh sashimi and spicy fish soup at Busan largest seafood market.';
      } else if (rec.id == 'rec_04') {
        name = 'Gukje Market Ggotbunine';
        category = 'ATTRACTION';
        address = 'Gukje Market, Sinchang-dong 4-ga, Jung-gu, Busan';
        description = 'Real filming location of the movie "Ode to My Father".';
      }
    } else if (loc.contains('ja')) {
      if (rec.id == 'rec_01') {
        name = 'BIFF広場シアホットク';
        category = 'FOOD';
        address = '釜山中区九徳路 58-1';
        description = '南浦洞の必須コース！サクサクのホットクにナッツがぎっしり。';
      } else if (rec.id == 'rec_02') {
        name = '龍頭山公園釜山タワー';
        category = 'ATTRACTION';
        address = '釜山中区龍頭山路 37-55';
        description = '南浦洞の中心にそびえ立つ釜山のシンボル。夜景が美しい展望台。';
      } else if (rec.id == 'rec_03') {
        name = 'チャガルチ市場刺身店';
        category = 'FOOD';
        address = '釜山中区チャガルチ海岸路 52';
        description = '釜山最大の魚市場で新鮮な刺身とメウンタンを満喫。';
      } else if (rec.id == 'rec_04') {
        name = '国際市場コッブニネ';
        category = 'ATTRACTION';
        address = '釜山中区新昌洞4街 国際市場内';
        description = '映画『国際市場で逢いましょう』のロケ地。レトロな記念フォトゾーン。';
      }
    }

    return Place(
      id: rec.id,
      name: name,
      category: category,
      rating: rec.rating,
      address: address,
      description: description,
      createdAt: DateTime.now(),
    );
  }

  // Fetch all places, filter by category locally on fallback
  Future<List<Place>> getPlaces({String? category, String? locale}) async {
    try {
      final data = await _placeService.fetchPlaces(category: category, locale: locale);
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
          .map((rec) => _mapMockToPlace(rec, locale: locale))
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
  Future<List<Place>> searchPlaces(String query, {String? locale}) async {
    try {
      final data = await _placeService.searchPlaces(query, locale: locale);
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
          .map((rec) => _mapMockToPlace(rec, locale: locale))
          .where(
            (place) =>
                place.name.toLowerCase().contains(cleanQuery) ||
                place.description.toLowerCase().contains(cleanQuery),
          )
          .toList();
    }
  }

  // Fetch detail by ID
  Future<Place> getPlaceDetail(String id, {String? locale}) async {
    try {
      final json = await _placeService.fetchPlaceDetail(id, locale: locale);
      return Place.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('PlaceRepository: Detail fetch failed. Falling back. Error: $e');
      }
      // Fallback 1: try finding in full places list
      try {
        final list = await getPlaces(locale: locale);
        return list.firstWhere((p) => p.id == id);
      } catch (_) {}

      // Fallback 2: mock detail matching
      try {
        final mockRec = MockData.recommendations.firstWhere(
          (rec) => rec.id == id || rec.id == id.replaceAll('store_mock_', 'rec_'),
        );
        return _mapMockToPlace(mockRec, locale: locale);
      } catch (_) {
        throw Exception('PLACE_NOT_FOUND');
      }
    }
  }
}
