import '../models/point_history.dart';
import '../services/point_service.dart';

class PointRepository {
  final PointService _pointService;

  PointRepository({PointService? pointService})
    : _pointService = pointService ?? PointService();

  // Get user points
  Future<int> getUserPoints({String? userId}) async {
    final res = await _pointService.fetchUserPoints(userId: userId);
    return res['current_points'] as int? ?? 0;
  }

  // Get user points map containing both current and lifetime earned points
  Future<Map<String, int>> getUserPointsData({String? userId}) async {
    final res = await _pointService.fetchUserPoints(userId: userId);
    final currentPoints = res['current_points'] as int? ?? 0;
    final lifetimePoints = res['lifetime_earned_points'] as int? ?? 0;
    return {
      'current_points': currentPoints,
      'lifetime_earned_points': lifetimePoints,
    };
  }

  // Get point history
  Future<List<PointHistory>> getPointHistory({String? userId}) async {
    final list = await _pointService.fetchPointHistory(userId: userId);
    return list
        .map((json) => PointHistory.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  // Earn points
  Future<int> earnPoints(int points, String activity, {String? userId}) async {
    final res = await _pointService.earnPoints(
      points,
      activity,
      userId: userId,
    );
    return res['current_points'] as int? ?? 0;
  }

  // Spend points
  Future<int> spendPoints(int points, String activity, {String? userId}) async {
    final res = await _pointService.spendPoints(
      points,
      activity,
      userId: userId,
    );
    return res['current_points'] as int? ?? 0;
  }
}
