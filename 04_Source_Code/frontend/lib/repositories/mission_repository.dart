import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../data/mock_data.dart';

class MissionRepository {
  final MissionService _missionService;

  MissionRepository({MissionService? missionService})
    : _missionService = missionService ?? MissionService();

  // Helper to map and localize Mission model
  Mission _mapMockToMission(dynamic mock, {String? locale}) {
    String authType = mock.category == '사진인증'
        ? 'PHOTO'
        : mock.category == 'GPS인증'
            ? 'GPS'
            : mock.category == 'QR인증'
                ? 'QR'
                : (mock.authType ?? 'PHOTO');

    final base = Mission(
      id: mock.id,
      storeId: mock.storeId,
      title: mock.title,
      description: mock.description,
      reward: mock.reward ?? '',
      points: mock.points,
      authType: authType,
      category: mock.category ?? '일반',
      createdAt: DateTime.now(),
    );

    return _localizeMission(base, locale);
  }

  /// Returns localized mock missions when API is unreachable or offline
  List<Mission> getMockMissions({String? locale}) {
    return MockData.missions
        .map((mock) => _mapMockToMission(mock, locale: locale))
        .toList();
  }

  Mission _localizeMission(Mission m, String? locale) {
    final loc = locale?.toLowerCase() ?? 'ko';
    if (loc == 'ko') return m;

    String title = m.title;
    String description = m.description;
    String reward = m.reward;

    final titleUpper = m.title.toUpperCase();
    final isMis1 = m.id == 'mis_01' ||
        m.id == 'msn_001' ||
        m.id == '1' ||
        m.title.contains('BIFF') ||
        m.title.contains('호떡') ||
        titleUpper.contains('HOTTEOK') ||
        titleUpper.contains('糖饼') ||
        titleUpper.contains('ホットク');

    final isMis2 = m.id == 'mis_02' ||
        m.id == 'msn_002' ||
        m.id == '2' ||
        m.title.contains('용두산') ||
        m.title.contains('타워') ||
        titleUpper.contains('YONGDUSAN') ||
        titleUpper.contains('BUSAN TOWER') ||
        titleUpper.contains('TOWER') ||
        m.title.contains('龙头山') ||
        m.title.contains('釜山塔') ||
        m.title.contains('龍頭山');

    final isMis3 = m.id == 'mis_03' ||
        m.id == 'msn_003' ||
        m.id == '3' ||
        m.title.contains('자갈치') ||
        m.title.contains('시장') ||
        titleUpper.contains('JAGALCHI') ||
        titleUpper.contains('MARKET') ||
        m.title.contains('札嘎其') ||
        m.title.contains('チャガルチ');

    if (loc.contains('zh')) {
      if (isMis1) {
        title = 'BIFF广场糖饼认证！';
        description = '购买BIFF广场坚果糖饼并拍照认证打卡。';
        reward = '坚果糖饼9折优惠券';
      } else if (isMis2) {
        title = '龙头山公园釜山塔登顶';
        description = '到达龙头山公园釜山塔附近并进行GPS位置认证。';
        reward = '展望台门票立减1,000韩元';
      } else if (isMis3) {
        title = '打卡札嘎其市场美食店';
        description = '在札嘎其市场合作店铺用餐并扫描商家二维码认证。';
        reward = '合作店铺免费饮料券';
      }
    } else if (loc.contains('en')) {
      if (isMis1) {
        title = 'BIFF Square Ssiat Hotteok Verification!';
        description = 'Buy Ssiat Hotteok at BIFF Square and upload a photo to verify.';
        reward = '10% Off Hotteok Coupon';
      } else if (isMis2) {
        title = 'Yongdusan Park Busan Tower Conquest';
        description = 'Reach Yongdusan Park Busan Tower and verify your GPS location.';
        reward = '1,000 KRW Observatory Discount';
      } else if (isMis3) {
        title = 'Visit Jagalchi Market Gourmet Place';
        description = 'Dine at Jagalchi Market partner shop and scan the merchant QR code.';
        reward = 'Free Beverage Coupon';
      }
    } else if (loc.contains('ja')) {
      if (isMis1) {
        title = 'BIFF広場ホットク認証！';
        description = 'BIFF広場でシアホットクを購入し写真を撮影して認証してください。';
        reward = 'ホットク10%割引クーポン';
      } else if (isMis2) {
        title = '龍頭山公園釜山タワー制覇';
        description = '龍頭山公園釜山タワー付近に到着しGPS位置を認証してください。';
        reward = '展望台入場1,000ウォン割引券';
      } else if (isMis3) {
        title = 'チャガルチ市場グルメ訪問';
        description = 'チャガルチ市場の提携店舗で食事をしてQRコード를 スキャンしてください。';
        reward = '提携店舗無料ドリンク券';
      }
    }

    return Mission(
      id: m.id,
      storeId: m.storeId,
      title: title,
      description: description,
      reward: reward,
      points: m.points,
      authType: m.authType,
      category: m.category,
      isCompleted: m.isCompleted,
      createdAt: m.createdAt,
    );
  }

  // Get all missions, option filter by storeId
  Future<List<Mission>> getMissions({String? storeId, String? locale}) async {
    try {
      final data = await _missionService.fetchMissions(storeId: storeId, locale: locale);
      return data
          .map((json) => _localizeMission(Mission.fromJson(json as Map<String, dynamic>), locale))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'MissionRepository: Failed to load missions from API. Falling back to Mock. Error: $e',
        );
      }
      // Fallback local Mock mapping
      var list = MockData.missions
          .map((mock) => _mapMockToMission(mock, locale: locale))
          .toList();
      if (storeId != null) {
        list = list.where((m) => m.storeId == storeId).toList();
      }
      return list;
    }
  }

  // Get specific mission detail
  Future<Mission> getMissionDetail(String id, {String? locale}) async {
    try {
      final json = await _missionService.fetchMissionDetail(id, locale: locale);
      return _localizeMission(Mission.fromJson(json), locale);
    } catch (e) {
      if (kDebugMode) {
        print(
          'MissionRepository: Detail fetch failed. Falling back. Error: $e',
        );
      }
      // Fallback local Mock detail
      try {
        final mockMission = MockData.missions.firstWhere((m) => m.id == id);
        return _mapMockToMission(mockMission, locale: locale);
      } catch (_) {
        throw Exception('해당 미션의 정보를 찾을 수 없습니다.');
      }
    }
  }

  // Get missions by Store ID
  Future<List<Mission>> getStoreMissions(String storeId) async {
    try {
      final data = await _missionService.fetchStoreMissions(storeId);
      return data
          .map((json) => Mission.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'MissionRepository: Store missions fetch failed. Falling back. Error: $e',
        );
      }
      // Fallback local Mock filtering
      return MockData.missions
          .where((m) => m.storeId == storeId)
          .map((mock) => _mapMockToMission(mock))
          .toList();
    }
  }

  // Verify mission (QR / Auth verify API call)
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
      final res = await _missionService.verifyMission(
        id,
        qrCode,
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        imageBase64: imageBase64,
        authToken: authToken,
      );
      return {
        'success': res['success'] as bool,
        'message': res['message'] as String,
        'points_awarded': res['points_awarded'] as int,
      };
    } catch (e) {
      if (kDebugMode) {
        print(
          'MissionRepository: Verification API failed. Error: $e',
        );
      }
      rethrow;
    }
  }
}
