import 'package:flutter/material.dart';
import '../repositories/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repository = AnalyticsRepository();

  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueData;
  Map<String, dynamic>? _reservationData;
  Map<String, dynamic>? _aiData;

  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  Map<String, dynamic>? get revenueData => _revenueData;
  Map<String, dynamic>? get reservationData => _reservationData;
  Map<String, dynamic>? get aiData => _aiData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAllStats({required String token, String? storeId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.fetchDashboardSummary(token: token, storeId: storeId),
        _repository.fetchRevenueStats(token: token, storeId: storeId),
        _repository.fetchReservationStats(token: token, storeId: storeId),
        _repository.fetchAIStats(token: token, storeId: storeId),
      ]);

      _dashboardData = results[0];
      _revenueData = results[1];
      _reservationData = results[2];
      _aiData = results[3];
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
