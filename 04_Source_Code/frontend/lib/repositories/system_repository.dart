import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class SystemRepository {
  final ApiService _apiService;

  SystemRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  // Fetches system status, falls back gracefully on connection errors
  Future<String> getSystemStatus() async {
    try {
      final message = await _apiService.fetchApiStatusMessage();
      return message;
    } catch (e) {
      if (kDebugMode) {
        print(
          'SystemRepository: API Connection failed, falling back. Error: $e',
        );
      }
      // Rule 6: fallback safely to mock offline message without crashing
      return 'Nampo GoGo API (오프라인 모드)';
    }
  }
}
