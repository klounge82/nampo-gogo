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

  // Load User Activities (with Mock Fallback on failure)
  Future<void> loadActivities({required String? token, String? type, int page = 1}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    if (token == null || token.isEmpty) {
      _activities = _getMockActivities();
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
      // API Fallback: Load Mock Data
      _activities = _getMockActivities();
      _errorMessage = '서버 통신에 실패하여 로컬 타임라인을 불러왔습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Generate standard Mock activities as requested in HISTORY-001 Mock Fallback
  List<dynamic> _getMockActivities() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final lastWeek = now.subtract(const Duration(days: 4));

    return [
      {
        'id': 'mock-act-1',
        'user_id': 'mock-usr-1',
        'activity_type': 'MISSION',
        'title': '씨앗호떡 미션 완료',
        'description': 'BIFF 광장 씨앗호떡 미션 완료 보상으로 150P가 적립되었습니다.',
        'target_type': 'MISSION',
        'target_id': 'mock-mission-1',
        'icon': 'emoji_events',
        'color': 'green',
        'created_at': now.toIso8601String(),
      },
      {
        'id': 'mock-act-2',
        'user_id': 'mock-usr-1',
        'activity_type': 'COUPON_EXCHANGE',
        'title': '쿠폰 교환',
        'description': '씨앗호떡 1개 교환 쿠폰 구매로 500P가 소모되었습니다.',
        'target_type': 'COUPON',
        'target_id': 'mock-coupon-1',
        'icon': 'redeem',
        'color': 'orange',
        'created_at': now.subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'mock-act-3',
        'user_id': 'mock-usr-1',
        'activity_type': 'REVIEW',
        'title': '리뷰 작성',
        'description': 'BIFF 광장 씨앗호떡 매장에 평점 5.0점 리뷰를 작성했습니다.',
        'target_type': 'PLACE',
        'target_id': 'mock-store-1',
        'icon': 'star',
        'color': 'purple',
        'created_at': now.subtract(const Duration(hours: 4)).toIso8601String(),
      },
      {
        'id': 'mock-act-4',
        'user_id': 'mock-usr-1',
        'activity_type': 'AI_RECOMMEND',
        'title': 'AI 추천 코스 생성',
        'description': '나홀로 여행 - 반나절 코스 추천 코스를 생성받았습니다.',
        'target_type': 'RECOMMENDATION',
        'target_id': 'mock-rec-1',
        'icon': 'auto_awesome',
        'color': 'deeporange',
        'created_at': yesterday.toIso8601String(),
      },
      {
        'id': 'mock-act-5',
        'user_id': 'mock-usr-1',
        'activity_type': 'RESERVATION_CREATE',
        'title': '예약 완료',
        'description': 'BIFF 광장 씨앗호떡 매장에 07월 20일 14:00 예약을 확정했습니다.',
        'target_type': 'RESERVATION',
        'target_id': 'mock-res-1',
        'icon': 'calendar_today',
        'color': 'blue',
        'created_at': lastWeek.toIso8601String(),
      },
    ];
  }

  void clearState() {
    _activities = [];
    _errorMessage = '';
    notifyListeners();
  }
}
