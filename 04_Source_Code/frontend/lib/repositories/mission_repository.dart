import 'package:flutter/foundation.dart';
import '../models/mission.dart';
import '../services/mission_service.dart';
import '../data/mock_data.dart';

class MissionRepository {
  final MissionService _missionService;

  MissionRepository({MissionService? missionService})
      : _missionService = missionService ?? MissionService();

  // Helper to map Mock Mission metadata to Mission model
  Mission _mapMockToMission(dynamic mock) {
    return Mission(
      id: mock.id,
      storeId: mock.storeId,
      title: mock.title,
      description: mock.description,
      points: mock.points,
      authType: mock.authType,
      createdAt: DateTime.now(),
    );
  }

  // Get all missions, option filter by storeId
  Future<List<Mission>> getMissions({String? storeId}) async {
    try {
      final data = await _missionService.fetchMissions(storeId: storeId);
      return data.map((json) => Mission.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('MissionRepository: Failed to load missions from API. Falling back to Mock. Error: $e');
      }
      // Fallback local Mock mapping
      var list = MockData.missions.map((mock) => _mapMockToMission(mock)).toList();
      if (storeId != null) {
        list = list.where((m) => m.storeId == storeId).toList();
      }
      return list;
    }
  }

  // Get specific mission detail
  Future<Mission> getMissionDetail(String id) async {
    try {
      final json = await _missionService.fetchMissionDetail(id);
      return Mission.fromJson(json);
    } catch (e) {
      if (kDebugMode) {
        print('MissionRepository: Detail fetch failed. Falling back. Error: $e');
      }
      // Fallback local Mock detail
      try {
        final mockMission = MockData.missions.firstWhere((m) => m.id == id);
        return _mapMockToMission(mockMission);
      } catch (_) {
        throw Exception('해당 미션의 정보를 찾을 수 없습니다.');
      }
    }
  }

  // Get missions by Store ID
  Future<List<Mission>> getStoreMissions(String storeId) async {
    try {
      final data = await _missionService.fetchStoreMissions(storeId);
      return data.map((json) => Mission.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('MissionRepository: Store missions fetch failed. Falling back. Error: $e');
      }
      // Fallback local Mock filtering
      return MockData.missions
          .where((m) => m.storeId == storeId)
          .map((mock) => _mapMockToMission(mock))
          .toList();
    }
  }

  // Verify mission (QR / Auth verify API call)
  Future<Map<String, dynamic>> verifyMission(String id, String qrCode, {String? userId}) async {
    try {
      final res = await _missionService.verifyMission(id, qrCode, userId: userId);
      return {
        'success': res['success'] as bool,
        'message': res['message'] as String,
        'points_awarded': res['points_awarded'] as int,
      };
    } catch (e) {
      if (kDebugMode) {
        print('MissionRepository: Verification API failed. Performing local Mock Fallback. Error: $e');
      }
      if (qrCode == 'QR_SUCCESS_TOKEN' || qrCode.startsWith('QR_')) {
        return {
          'success': true,
          'message': '오프라인 모드: 미션 완료!',
          'points_awarded': 100,
        };
      }
      throw Exception('유효하지 않은 QR 코드입니다. (오프라인 모드)');
    }
  }
}
