import 'package:flutter/foundation.dart';
import 'production_config.dart';

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    // 1. If in production, strictly resolve through validated environment config
    if (ProductionConfig.isProduction) {
      return ProductionConfig.apiBaseUrl;
    }

    // 2. If staging, prioritize apiBaseUrl env value
    if (ProductionConfig.isStaging && ProductionConfig.apiBaseUrl.isNotEmpty) {
      return ProductionConfig.apiBaseUrl;
    }

    // 3. Prioritize raw env override if specified
    if (ProductionConfig.apiBaseUrl.isNotEmpty) {
      return ProductionConfig.apiBaseUrl;
    }

    if (kIsWeb) {
      return 'http://localhost:18080';
    }

    // Android Emulator uses 10.0.2.2 to access host loopback
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:18080';
    }

    // iOS Simulator, desktop apps, etc. use localhost
    return 'http://localhost:18080';
  }

  static const Duration connectTimeout = Duration(seconds: 5);
  static const Duration receiveTimeout = Duration(seconds: 3);
}
