import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    Place place;
    try {
      if (json['store'] is Map<String, dynamic>) {
        place = Place.fromJson(json['store'] as Map<String, dynamic>);
      } else {
        place = Place(
          id: json['store_id'] as String? ?? 'store_unknown',
          name: '저장된 장소',
          category: '기타',
          rating: 4.5,
          address: '부산 중구',
          description: '저장된 상세 장소 정보입니다.',
          createdAt: DateTime.now(),
        );
      }
    } catch (_) {
      place = Place(
        id: json['store_id'] as String? ?? 'store_unknown',
        name: '저장된 장소',
        category: '기타',
        rating: 4.5,
        address: '부산 중구',
        description: '저장된 상세 장소 정보입니다.',
        createdAt: DateTime.now(),
      );
    }

    return CourseItemModel(
      storeId: json['store_id'] as String? ?? place.id,
      visitOrder: json['visit_order'] as int? ?? 1,
      recommendReasonCode:
          json['recommend_reason_code'] as String? ?? 'REASON_CLOSE',
      store: place,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'store_id': storeId,
      'visit_order': visitOrder,
      'recommend_reason_code': recommendReasonCode,
      'store': store.toJson(),
    };
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
    List<CourseItemModel> courseItems = [];
    try {
      var list = json['items'] as List<dynamic>? ?? [];
      for (var i in list) {
        if (i is Map<String, dynamic>) {
          courseItems.add(CourseItemModel.fromJson(i));
        }
      }
    } catch (_) {
      courseItems = [];
    }

    DateTime parsedDate;
    try {
      parsedDate = json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return RecommendationModel(
      id:
          json['id'] as String? ??
          'rec_dummy_${DateTime.now().millisecondsSinceEpoch}',
      travelType:
          json['travel_type'] as String? ??
          json['companion_type'] as String? ??
          'SOLO',
      travelDuration:
          json['travel_duration'] as String? ??
          json['duration_type'] as String? ??
          'HALF_DAY',
      transportMode: json['transport_mode'] as String? ?? 'WALK',
      startLatitude: (json['start_latitude'] as num? ?? 35.1152).toDouble(),
      startLongitude: (json['start_longitude'] as num? ?? 129.0422).toDouble(),
      isSaved: json['is_saved'] as bool? ?? true,
      createdAt: parsedDate,
      items: courseItems,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'travel_type': travelType,
      'travel_duration': travelDuration,
      'transport_mode': transportMode,
      'start_latitude': startLatitude,
      'start_longitude': startLongitude,
      'is_saved': isSaved,
      'created_at': createdAt.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  RecommendationModel copyWith({bool? isSaved}) {
    return RecommendationModel(
      id: id,
      travelType: travelType,
      travelDuration: travelDuration,
      transportMode: transportMode,
      startLatitude: startLatitude,
      startLongitude: startLongitude,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt,
      items: items,
    );
  }
}

class RecommendationRepository {
  final RecommendationService _recommendationService;
  final FlutterSecureStorage _storage;
  static const String _guestCoursesKey = 'guest_saved_courses_list';

  RecommendationRepository({
    RecommendationService? recommendationService,
    FlutterSecureStorage? storage,
  }) : _recommendationService =
           recommendationService ?? RecommendationService(),
       _storage = storage ?? const FlutterSecureStorage();

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
        print(
          'RecommendationRepository: Failed course generate. Simulating offline fallback: $e',
        );
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

  Future<List<RecommendationModel>> getLocalCourses() async {
    try {
      final raw = await _storage.read(key: _guestCoursesKey);
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> parsed = jsonDecode(raw);
      return parsed
          .map((e) => RecommendationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationRepository: getLocalCourses failed: $e');
      }
      return [];
    }
  }

  Future<void> saveLocalCourse(RecommendationModel course) async {
    try {
      final list = await getLocalCourses();
      final index = list.indexWhere((item) => item.id == course.id);
      final updatedCourse = course.copyWith(isSaved: true);
      if (index >= 0) {
        list[index] = updatedCourse;
      } else {
        list.insert(0, updatedCourse);
      }
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.write(key: _guestCoursesKey, value: raw);
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationRepository: saveLocalCourse failed: $e');
      }
    }
  }

  Future<void> removeLocalCourse(String id) async {
    try {
      final list = await getLocalCourses();
      list.removeWhere((item) => item.id == id);
      final raw = jsonEncode(list.map((e) => e.toJson()).toList());
      await _storage.write(key: _guestCoursesKey, value: raw);
    } catch (e) {
      if (kDebugMode) {
        print('RecommendationRepository: removeLocalCourse failed: $e');
      }
    }
  }

  Future<List<RecommendationModel>> getSavedHistory({String? userId}) async {
    final localCourses = await getLocalCourses();
    if (userId == null || userId.isEmpty) {
      return localCourses;
    }

    try {
      final list = await _recommendationService.fetchSavedHistory(
        userId: userId,
      );
      final serverCourses = list
          .map(
            (json) =>
                RecommendationModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();

      final Map<String, RecommendationModel> mergedMap = {};
      for (var c in serverCourses) {
        mergedMap[c.id] = c;
      }
      for (var c in localCourses) {
        if (!mergedMap.containsKey(c.id)) {
          mergedMap[c.id] = c;
        }
      }
      return mergedMap.values.toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'RecommendationRepository: Failed fetch history. Fallback to local courses: $e',
        );
      }
      return localCourses;
    }
  }

  Future<RecommendationModel> saveCourse(
    RecommendationModel course, {
    required bool isSaved,
    String? userId,
  }) async {
    final bool isGuestOrDummy =
        userId == null || userId.isEmpty || course.id.startsWith('rec_dummy_');

    if (isGuestOrDummy) {
      if (isSaved) {
        await saveLocalCourse(course);
      } else {
        await removeLocalCourse(course.id);
      }
      return course.copyWith(isSaved: isSaved);
    }

    try {
      final res = await _recommendationService.toggleSaveStatus(
        course.id,
        isSaved: isSaved,
      );
      final updated = RecommendationModel.fromJson(res);
      if (isSaved) {
        await saveLocalCourse(updated);
      } else {
        await removeLocalCourse(updated.id);
      }
      return updated;
    } catch (e) {
      if (kDebugMode) {
        print(
          'RecommendationRepository: saveCourse server call failed. Falling back to local storage: $e',
        );
      }
      if (isSaved) {
        await saveLocalCourse(course);
      } else {
        await removeLocalCourse(course.id);
      }
      return course.copyWith(isSaved: isSaved);
    }
  }

  Future<void> deleteCourse(String id) async {
    await removeLocalCourse(id);
    if (!id.startsWith('rec_dummy_')) {
      try {
        await _recommendationService.deleteCourse(id);
      } catch (e) {
        if (kDebugMode) {
          print('RecommendationRepository: deleteCourse server failed: $e');
        }
      }
    }
  }
}
