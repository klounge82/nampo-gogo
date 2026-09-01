import 'package:flutter/material.dart';
import '../repositories/activity_repository.dart';

class ActivityProvider extends ChangeNotifier {
  final ActivityRepository _repository;

  ActivityProvider({ActivityRepository? repository})
    : _repository = repository ?? ActivityRepository();

  List<dynamic> _activities = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get activities => _activities;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load User Activities
  Future<void> loadActivities({
    required String? token,
    String? type,
    int page = 1,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (token == null || token.isEmpty) {
      _activities = [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final list = await _repository.getActivities(
        type: type,
        page: page,
        token: token,
      );
      _activities = list;
    } catch (e) {
      _activities = [];
      _errorMessage = '서버 통신에 실패하여 활동 내역을 불러오지 못했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearState() {
    _activities = [];
    _errorMessage = '';
    notifyListeners();
  }
}
