import 'package:flutter/foundation.dart';
import '../services/recommendation_service.dart';
import '../models/place.dart';

class CourseItemModel {
  final String storeId;
  final int visitOrder;
  final String recommendReasonCode;
  final Place store;

  CourseItemModel({
    required this.storeId,
    required this.visitOrder,
    required this.recommendReasonCode,
    required this.store,
  });

  factory CourseItemModel.fromJson(Map<String, dynamic> json) {
    return CourseItemModel(
      storeId: json['store_id'] as String? ?? '',
      visitOrder: json['visit_order'] as int? ?? 1,
      recommendReasonCode: json['recommend_reason_code'] as String? ?? 'REASON_CLOSE',
      store: Place.fromJson(json['store'] as Map<String, dynamic>),
    );
  }
}

class RecommendationModel {
  final String id;
  final String travelType;
  final String travelDuration;
  final String transportMode;
  final double startLatitude;
  final double startLongitude;
  final bool isSaved;
  final DateTime createdAt;
  final List<CourseItemModel> items;

  RecommendationModel({
    required this.id,
    required this.travelType,
    required this.travelDuration,
    required this.transportMode,
    required this.startLatitude,
    required this.startLongitude,
    required this.isSaved,
    required this.createdAt,
    required this.items,
  });

  factory RecommendationModel.fromJson(Map<String, dynamic> json) {
    var list = json['items'] as List<dynamic>? ?? [];
    List<CourseItemModel> courseItems = list.map((i) => CourseItemModel.fromJson(i as Map<String, dynamic>)).toList();
    
    return RecommendationModel(
      id: json['id'] as String? ?? '',
      travelType: json['travel_type'] as String? ?? 'SOLO',
      travelDuration: json['travel_duration'] as String? ?? 'HALF_DAY',
      transportMode: json['transport_mode'] as String? ?? 'WALK',
      startLatitude: (json['start_latitude'] as num? ?? 35.1152).toDouble(),
      startLongitude: (json['start_longitude'] as num? ?? 129.0422).toDouble(),
      isSaved: json['is_saved'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
      items: courseItems,
    );
  }
}

class RecommendationRepository {
  final RecommendationService _recommendationService;

  RecommendationRepository({RecommendationService? recommendationService})
      : _recommendationService = recommendationService ?? RecommendationService();

  Future<RecommendationModel> getRecommendedCourse({
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
      final res = await _recommendationService.generateCourse(
        userId: userId,
        travelType: travelType,
        travelDuration: travelDuration,
        categories: categories,
        transportMode: transportMode,
        latitude: latitude,
        longitude: longitude,
        usePersonalization: usePersonalization,
        excludeVisited: excludeVisited,
        preferRewards: preferRewards,
      );
      return RecommendationModel.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationRepository: Failed course generate. Simulating offline fallback: $e');
      }
      
      // Simulate default 3 stores course (HALF_DAY)
      final dummyItems = [
        CourseItemModel(
          storeId: 'store_biff_dummy',
          visitOrder: 1,
          recommendReasonCode: 'REASON_CATEGORY',
          store: Place(
            id: 'store_biff_dummy',
            name: 'BIFF 광장 씨앗호떡',
            category: '맛집',
            rating: 4.5,
            address: '부산 중구 구덕로 58-1',
            description: '호떡 속에 씨앗이 가득하여 씹는 맛이 있는 남포동 명물입니다.',
            latitude: 35.0987,
            longitude: 129.0289,
            createdAt: DateTime.now(),
          ),
        ),
        CourseItemModel(
          storeId: 'store_tower_dummy',
          visitOrder: 2,
          recommendReasonCode: 'REASON_CLOSE',
          store: Place(
            id: 'store_tower_dummy',
            name: '용두산공원 부산타워',
            category: '볼거리',
            rating: 4.6,
            address: '부산 중구 용두산길 37-55',
            description: '전망대에서 부산 시내 전경을 볼 수 있는 필수 관광 명소입니다.',
            latitude: 35.1008,
            longitude: 129.0326,
            createdAt: DateTime.now(),
          ),
        ),
        CourseItemModel(
          storeId: 'store_jagal_dummy',
          visitOrder: 3,
          recommendReasonCode: 'REASON_MISSION_COUPON',
          store: Place(
            id: 'store_jagal_dummy',
            name: '자갈치시장 신선한 횟집',
            category: '맛집',
            rating: 4.7,
            address: '부산 중구 자갈치해안로 52',
            description: '신선한 생선회와 맛있는 식사가 준비되어 있는 명소입니다.',
            latitude: 35.0967,
            longitude: 129.0305,
            createdAt: DateTime.now(),
          ),
        ),
      ];

      return RecommendationModel(
        id: 'rec_dummy_${DateTime.now().millisecondsSinceEpoch}',
        travelType: travelType,
        travelDuration: travelDuration,
        transportMode: transportMode,
        startLatitude: latitude ?? 35.1152,
        startLongitude: longitude ?? 129.0422,
        isSaved: false,
        createdAt: DateTime.now(),
        items: dummyItems,
      );
    }
  }

  Future<List<RecommendationModel>> getSavedHistory({String? userId}) async {
    try {
      final list = await _recommendationService.fetchSavedHistory(userId: userId);
      return list.map((json) => RecommendationModel.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationRepository: Failed fetch history. Returning empty list: $e');
      }
      return [];
    }
  }

  Future<RecommendationModel> saveCourse(String id, {required bool isSaved}) async {
    final res = await _recommendationService.toggleSaveStatus(id, isSaved: isSaved);
    return RecommendationModel.fromJson(res);
  }

  Future<void> deleteCourse(String id) async {
    await _recommendationService.deleteCourse(id);
  }
}
