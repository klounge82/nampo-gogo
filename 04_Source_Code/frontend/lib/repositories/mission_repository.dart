import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../data/mock_data.dart';
import '../config/production_config.dart';

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

    String title = m.title;
    String description = m.description;
    String reward = m.reward;

    final titleUpper = m.title.toUpperCase();
    final idLower = m.id.toLowerCase();

    final isMis1 = idLower == 'mis_01' ||
        idLower == 'msn_001' ||
        idLower == '1' ||
        m.title.contains('BIFF') ||
        m.title.contains('호떡') ||
        titleUpper.contains('HOTTEOK') ||
        titleUpper.contains('糖饼') ||
        titleUpper.contains('ホットク');

    final isMis2 = idLower == 'mis_02' ||
        idLower == 'msn_002' ||
        idLower == '2' ||
        m.title.contains('용두산') ||
        m.title.contains('타워') ||
        titleUpper.contains('YONGDUSAN') ||
        titleUpper.contains('BUSAN TOWER') ||
        titleUpper.contains('TOWER') ||
        m.title.contains('龙头山') ||
        m.title.contains('釜山塔') ||
        m.title.contains('龍頭山');

    final isMis3 = idLower == 'mis_03' ||
        idLower == 'msn_003' ||
        idLower == '3' ||
        m.title.contains('자갈치') ||
        m.title.contains('시장') ||
        titleUpper.contains('JAGALCHI') ||
        titleUpper.contains('MARKET') ||
        m.title.contains('札嘎其') ||
        m.title.contains('チャガルチ');

    final isMisSuyeong = m.title.contains('수영강') ||
        m.description.contains('수영강') ||
        idLower.contains('suyeong') ||
        idLower.contains('photo-004') ||
        idLower.contains('photo-gps-005');

    final isMisGwangalli = m.title.contains('광안리') ||
        m.description.contains('광안리') ||
        idLower.contains('gwangalli');

    final isMisGampo = m.title.contains('감포') ||
        m.description.contains('감포') ||
        idLower.contains('gampo');

    String? tZh = m.titleZh;
    String? dZh = m.descriptionZh;
    String? tEn = m.titleEn;
    String? dEn = m.descriptionEn;
    String? tJa = m.titleJa;
    String? dJa = m.descriptionJa;

    if (loc.contains('zh')) {
      if (tZh != null && tZh.trim().isNotEmpty) {
        title = tZh;
      } else if (isMis1) {
        title = 'BIFF广场糖饼认证！';
        description = '购买BIFF广场坚果糖饼并拍照认证打卡。';
        reward = '坚果糖饼9折优惠券';
      } else if (isMis2) {
        title = '[QA] 龙头山公园 GPS 访问任务';
        description = '在龙头山公园 100m 范围内验证 GPS 位置。';
        reward = '100P';
      } else if (isMis3) {
        title = '[QA] 札嘎其市场 QR 访问任务';
        description = '在札嘎其市场合作店铺用餐并扫描商家二维码认证。';
        reward = '合作店铺免费饮料券';
      } else if (isMisSuyeong) {
        title = '[QA] 水营江边 现场照片 任务';
        description = '在水营江边散步路拍照上传验证。';
        reward = '100P';
      } else if (isMisGwangalli) {
        title = '[QA] 广安里海水浴场 GPS 访问任务';
        description = '在广安里海水浴场 100m 范围内验证 GPS 位置。';
        reward = '100P';
      } else if (isMisGampo) {
        title = '[QA] 甘浦路 GPS 测试点';
        description = '在甘浦路 100m 范围内验证 GPS 位置。';
        reward = '100P';
      }
      if (dZh != null && dZh.trim().isNotEmpty) {
        description = dZh;
      }
      tZh = title;
      dZh = description;
    } else if (loc.contains('en')) {
      if (tEn != null && tEn.trim().isNotEmpty) {
        title = tEn;
      } else if (isMis1) {
        title = 'BIFF Square Ssiat Hotteok Verification!';
        description = 'Buy Ssiat Hotteok at BIFF Square and upload a photo to verify.';
        reward = '10% Off Hotteok Coupon';
      } else if (isMis2) {
        title = '[QA] Yongdusan Park GPS Visit Mission';
        description = 'Verify your GPS location within 100m of Yongdusan Park.';
        reward = '100P';
      } else if (isMis3) {
        title = '[QA] Jagalchi Market QR Visit Mission';
        description = 'Dine at Jagalchi Market partner shop and scan the merchant QR code.';
        reward = 'Free Beverage Coupon';
      } else if (isMisSuyeong) {
        title = '[QA] Suyeong River Trail Photo Mission';
        description = 'Take and upload a photo on the Suyeong River walking trail.';
        reward = '100P';
      } else if (isMisGwangalli) {
        title = '[QA] Gwangalli Beach GPS Visit Mission';
        description = 'Verify your GPS location within 100m of Gwangalli Beach.';
        reward = '100P';
      } else if (isMisGampo) {
        title = '[QA] Gampo-ro GPS Test Point';
        description = 'Verify your GPS location within 100m of Gampo-ro.';
        reward = '100P';
      }
      if (dEn != null && dEn.trim().isNotEmpty) {
        description = dEn;
      }
      tEn = title;
      dEn = description;
    } else if (loc.contains('ja')) {
      if (tJa != null && tJa.trim().isNotEmpty) {
        title = tJa;
      } else if (isMis1) {
        title = 'BIFF広場ホットク認証！';
        description = 'BIFF広場でシアホットクを購入し写真を撮影して認証してください。';
        reward = 'ホットク10%割引クーポン';
      } else if (isMis2) {
        title = '[QA] 龍頭山公園 GPS 訪問ミッション';
        description = '龍頭山公園の 100m 以内で GPS 位置を検証します。';
        reward = '100P';
      } else if (isMis3) {
        title = '[QA] チャガルチ市場 QR 訪問ミッション';
        description = 'チャガルチ市場の提携店舗で食事をしてQRコードをスキャンしてください。';
        reward = '提携店舗無料ドリンク券';
      } else if (isMisSuyeong) {
        title = '[QA] 水営江辺 現場写真 ミッション';
        description = '水営江辺の散策路で写真を撮影してアップロードしてください。';
        reward = '100P';
      } else if (isMisGwangalli) {
        title = '[QA] 広安里海水浴場 GPS 訪問ミッション';
        description = '広安里海水浴場の 100m 以内で GPS 位置を検証します。';
        reward = '100P';
      } else if (isMisGampo) {
        title = '[QA] 甘浦路 GPS テストポイント';
        description = '甘浦路の 100m 以内で GPS 位置を検証します。';
        reward = '100P';
      }
      if (dJa != null && dJa.trim().isNotEmpty) {
        description = dJa;
      }
      tJa = title;
      dJa = description;
    }

    return Mission(
      id: m.id,
      storeId: m.storeId,
      title: title,
      description: description,
      titleEn: tEn ?? m.titleEn,
      titleJa: tJa ?? m.titleJa,
      titleZh: tZh ?? m.titleZh,
      descriptionEn: dEn ?? m.descriptionEn,
      descriptionJa: dJa ?? m.descriptionJa,
      descriptionZh: dZh ?? m.descriptionZh,
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
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
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
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
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
      if (!ProductionConfig.enableMockData) {
        rethrow;
      }
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
