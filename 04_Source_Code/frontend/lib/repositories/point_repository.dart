import 'package:flutter/foundation.dart';
import '../models/point_history.dart';
import '../services/point_service.dart';

class PointRepository {
  final PointService _pointService;

  // Local state cache for offline simulation fallback
  static int _mockBalance = 1250;
  static final List<PointHistory> _mockHistories = [
    PointHistory(
      id: 'mock_ph_1',
      userId: 'usr_mock_999',
      points: 150,
      activity: '씨앗호떡 맛보기 인증 미션 완료 보상',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    PointHistory(
      id: 'mock_ph_2',
      userId: 'usr_mock_999',
      points: 200,
      activity: '부산타워 전망대 방문 미션 완료 보상',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    PointHistory(
      id: 'mock_ph_3',
      userId: 'usr_mock_999',
      points: -100,
      activity: '남포동 카페 아메리카노 할인 쿠폰 교환',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    PointHistory(
      id: 'mock_ph_4',
      userId: 'usr_mock_999',
      points: 1000,
      activity: '신규 가입 웰컴 축하 포인트',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  PointRepository({PointService? pointService})
      : _pointService = pointService ?? PointService();

  // Get user points
  Future<int> getUserPoints({String? userId}) async {
    try {
      final res = await _pointService.fetchUserPoints(userId: userId);
      final currentPoints = res['current_points'] as int? ?? 0;
      _mockBalance = currentPoints; // update local cache
      return currentPoints;
    } catch (e) {
      if (kDebugMode) {
        print('PointRepository: Failed to fetch points. Falling back to local cache: $_mockBalance. Error: $e');
      }
      return _mockBalance;
    }
  }

  // Get point history
  Future<List<PointHistory>> getPointHistory({String? userId}) async {
    try {
      final list = await _pointService.fetchPointHistory(userId: userId);
      final result = list.map((json) => PointHistory.fromJson(json as Map<String, dynamic>)).toList();
      // Sync local cache histories
      _mockHistories.clear();
      _mockHistories.addAll(result);
      return result;
    } catch (e) {
      if (kDebugMode) {
        print('PointRepository: Failed to fetch history. Falling back to local mock list. Error: $e');
      }
      return List.from(_mockHistories);
    }
  }

  // Earn points
  Future<int> earnPoints(int points, String activity, {String? userId}) async {
    try {
      final res = await _pointService.earnPoints(points, activity, userId: userId);
      final currentPoints = res['current_points'] as int? ?? 0;
      _mockBalance = currentPoints;
      return currentPoints;
    } catch (e) {
      if (kDebugMode) {
        print('PointRepository: Failed to earn points API. Falling back locally. Error: $e');
      }
      _mockBalance += points;
      _mockHistories.insert(
        0,
        PointHistory(
          id: 'mock_ph_earn_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId ?? 'usr_mock_999',
          points: points,
          activity: '$activity (오프라인)',
          createdAt: DateTime.now(),
        ),
      );
      return _mockBalance;
    }
  }

  // Spend points
  Future<int> spendPoints(int points, String activity, {String? userId}) async {
    try {
      final res = await _pointService.spendPoints(points, activity, userId: userId);
      final currentPoints = res['current_points'] as int? ?? 0;
      _mockBalance = currentPoints;
      return currentPoints;
    } catch (e) {
      if (kDebugMode) {
        print('PointRepository: Failed to spend points API. Falling back locally. Error: $e');
      }
      if (_mockBalance < points) {
        throw Exception('보유 포인트가 부족합니다. (오프라인 모드)');
      }
      _mockBalance -= points;
      _mockHistories.insert(
        0,
        PointHistory(
          id: 'mock_ph_spend_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId ?? 'usr_mock_999',
          points: -points,
          activity: '$activity (오프라인)',
          createdAt: DateTime.now(),
        ),
      );
      return _mockBalance;
    }
  }
}
