import 'package:flutter/foundation.dart';

enum AppEnvironment { development, staging, production }

class ProductionConfig {
  ProductionConfig._();

  // APP_ENV: 'development', 'staging', 'production'
  static const String _rawEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );

  static AppEnvironment get environment {
    switch (_rawEnv) {
      case 'production':
        return AppEnvironment.production;
      case 'staging':
        return AppEnvironment.staging;
      default:
        return AppEnvironment.development;
    }
  }

  static bool get isProduction => environment == AppEnvironment.production;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isDevelopment => environment == AppEnvironment.development;

  // API Base URL
  static const String _rawApiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://backend-production-b07b.up.railway.app',
  );

  static String get apiBaseUrl {
    final url = _rawApiUrl.trim();
    if (isProduction) {
      if (url.isEmpty) {
        throw StateError(
          'CONFIG_API_URL_MISSING: Production API Base URL cannot be empty!',
        );
      }
      if (url.contains('localhost') ||
          url.contains('127.0.0.1') ||
          url.contains('10.0.2.2') ||
          url.contains('192.168.')) {
        throw StateError(
          'CONFIG_API_URL_INVALID: Production API cannot refer to local address!',
        );
      }
      if (url.startsWith('http://')) {
        throw StateError(
          'CONFIG_API_URL_INVALID: Production API must use secure HTTPS protocol!',
        );
      }
      if (!url.startsWith('https://')) {
        throw StateError('CONFIG_API_URL_INVALID: Invalid URL format!');
      }
    }
    return url;
  }

  // Payment Mode: 'mock', 'live'
  static const String _rawPaymentMode = String.fromEnvironment(
    'PAYMENT_MODE',
    defaultValue: 'mock',
  );

  static String get paymentMode {
    if (isProduction) {
      // Prohibit live payments in production on client side until approved
      return 'mock';
    }
    return _rawPaymentMode;
  }

  // Production Guards Flags
  static bool get enableMockData {
    if (isProduction) return false;
    return const bool.fromEnvironment('ENABLE_MOCK_DATA', defaultValue: true);
  }

  static bool get enableDebugMenu {
    if (isProduction) return false;
    return const bool.fromEnvironment('ENABLE_DEBUG_MENU', defaultValue: true);
  }

  static bool get enableTestLogin {
    if (isProduction) return false;
    return const bool.fromEnvironment('ENABLE_TEST_LOGIN', defaultValue: true);
  }

  static bool get enableVerboseLog {
    if (isProduction) return false;
    return const bool.fromEnvironment('ENABLE_VERBOSE_LOG', defaultValue: true);
  }

  static bool get enableQrMock {
    if (isProduction) return false;
    if (!isDevelopment) return false;
    return const bool.fromEnvironment('ENABLE_QR_MOCK', defaultValue: false);
  }

  // 5대 운영 URL 및 고객지원 설정 (기본값으로 Netlify 확정 주소 적용)
  // TODO: 정식 출시 전 실제 개인정보처리자·사업자 정보 및 도메인으로 교체
  static const String _rawPublicSiteUrl = String.fromEnvironment(
    'PUBLIC_SITE_URL',
    defaultValue: 'https://nampo-gogo.netlify.app',
  );
  static const String _rawPrivacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue: 'https://nampo-gogo.netlify.app/privacy/',
  );
  static const String _rawTermsOfServiceUrl = String.fromEnvironment(
    'TERMS_OF_SERVICE_URL',
    defaultValue: 'https://nampo-gogo.netlify.app/terms/',
  );
  static const String _rawAccountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue: 'https://nampo-gogo.netlify.app/delete-account/',
  );
  static const String _rawSupportUrl = String.fromEnvironment(
    'SUPPORT_URL',
    defaultValue: 'https://nampo-gogo.netlify.app/support/',
  );

  // 베타 단계 임시 주소이며 정식 출시 시 운영 계정으로 전환 예정
  static const String _rawSupportEmail = String.fromEnvironment(
    'SUPPORT_EMAIL',
    defaultValue: 'klounge@kakao.com',
  );

  static String _validateSecureUrl(String key, String rawVal) {
    final val = rawVal.trim();
    if (val.isEmpty) {
      throw StateError(
        'CONFIG_${key}_MISSING: URL value for $key cannot be empty!',
      );
    }
    if (!val.startsWith('https://')) {
      throw StateError(
        'CONFIG_${key}_INVALID: URL for $key must use secure HTTPS protocol! ($val)',
      );
    }
    if (val.contains('localhost') ||
        val.contains('127.0.0.1') ||
        val.contains('10.0.2.2') ||
        val.contains('example.com')) {
      throw StateError(
        'CONFIG_${key}_INVALID: URL for $key cannot refer to local or dummy address!',
      );
    }
    return val;
  }

  static String get publicSiteUrl =>
      _validateSecureUrl('PUBLIC_SITE_URL', _rawPublicSiteUrl);
  static String get privacyPolicyUrl =>
      _validateSecureUrl('PRIVACY_POLICY_URL', _rawPrivacyPolicyUrl);
  static String get termsOfServiceUrl =>
      _validateSecureUrl('TERMS_OF_SERVICE_URL', _rawTermsOfServiceUrl);
  static String get accountDeletionUrl =>
      _validateSecureUrl('ACCOUNT_DELETION_URL', _rawAccountDeletionUrl);
  static String get supportUrl =>
      _validateSecureUrl('SUPPORT_URL', _rawSupportUrl);

  static String get supportEmail {
    final email = _rawSupportEmail.trim();
    if (email.isEmpty) {
      throw StateError(
        'CONFIG_SUPPORT_EMAIL_MISSING: Support Email cannot be empty!',
      );
    }
    if (!email.contains('@') || !email.contains('.')) {
      throw StateError(
        'CONFIG_SUPPORT_EMAIL_INVALID: Invalid email format! ($email)',
      );
    }
    return email;
  }

  static bool get isMockPayment => paymentMode == 'mock';
}
