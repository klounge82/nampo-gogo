import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class PersonalizationProvider extends ChangeNotifier {
  final Dio _dio;

  PersonalizationProvider({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://10.0.2.2:18080'));

  bool _usePersonalization = true;
  bool _preferNewPlaces = true;
  bool _preferRewards = true;
  List<String> _dislikedCategories = [];
  bool _isLoading = false;

  bool get usePersonalization => _usePersonalization;
  bool get preferNewPlaces => _preferNewPlaces;
  bool get preferRewards => _preferRewards;
  List<String> get dislikedCategories => _dislikedCategories;
  bool get isLoading => _isLoading;

  // Toggle flag locally & sync with server if logged in
  Future<void> togglePersonalization({required bool value, String? token}) async {
    _usePersonalization = value;
    notifyListeners();
    if (token != null && token.isNotEmpty) {
      await updatePreferences(token: token, usePersonalization: value);
    }
  }

  Future<void> toggleExcludeVisited({required bool value, String? token}) async {
    _preferNewPlaces = value;
    notifyListeners();
    if (token != null && token.isNotEmpty) {
      await updatePreferences(token: token, preferNewPlaces: value);
    }
  }

  Future<void> togglePreferRewards({required bool value, String? token}) async {
    _preferRewards = value;
    notifyListeners();
    if (token != null && token.isNotEmpty) {
      await updatePreferences(token: token, preferRewards: value);
    }
  }

  // GET /recommendations/preferences
  Future<void> loadPreferences({required String token}) async {
    if (token.isEmpty) return;
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _dio.get(
        '/recommendations/preferences',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data;
      _usePersonalization = data['use_personalization'] ?? true;
      _preferNewPlaces = data['prefer_new_places'] ?? true;
      _preferRewards = data['prefer_rewards'] ?? true;
      _dislikedCategories = List<String>.from(data['disliked_categories'] ?? []);
    } catch (e) {
      debugPrint('PersonalizationProvider: loadPreferences failed -> $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // PATCH /recommendations/preferences
  Future<void> updatePreferences({
    required String token,
    bool? usePersonalization,
    bool? preferNewPlaces,
    bool? preferRewards,
    List<String>? dislikedCategories,
  }) async {
    if (token.isEmpty) return;
    try {
      final res = await _dio.patch(
        '/recommendations/preferences',
        data: {
          if (usePersonalization != null) 'use_personalization': usePersonalization,
          if (preferNewPlaces != null) 'prefer_new_places': preferNewPlaces,
          if (preferRewards != null) 'prefer_rewards': preferRewards,
          if (dislikedCategories != null) 'disliked_categories': dislikedCategories,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      final data = res.data;
      _usePersonalization = data['use_personalization'] ?? _usePersonalization;
      _preferNewPlaces = data['prefer_new_places'] ?? _preferNewPlaces;
      _preferRewards = data['prefer_rewards'] ?? _preferRewards;
      _dislikedCategories = List<String>.from(data['disliked_categories'] ?? _dislikedCategories);
      notifyListeners();
    } catch (e) {
      debugPrint('PersonalizationProvider: updatePreferences failed -> $e');
    }
  }

  // POST /recommendations/feedback
  Future<bool> sendFeedback({
    required String token,
    required String targetType,
    required String targetId,
    required String feedbackType,
  }) async {
    if (token.isEmpty) return false;
    try {
      await _dio.post(
        '/recommendations/feedback',
        data: {
          'target_type': targetType,
          'target_id': targetId,
          'feedback_type': feedbackType,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return true;
    } catch (e) {
      debugPrint('PersonalizationProvider: sendFeedback failed -> $e');
      return false;
    }
  }
}
