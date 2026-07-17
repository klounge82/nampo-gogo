import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocaleStorageService {
  static final LocaleStorageService _instance = LocaleStorageService._internal();
  factory LocaleStorageService() => _instance;
  LocaleStorageService._internal();

  final _storage = const FlutterSecureStorage();
  static const String _keyLanguage = 'selected_language';

  Future<String?> getCachedLanguage() async {
    try {
      return await _storage.read(key: _keyLanguage);
    } catch (_) {
      return null;
    }
  }

  Future<void> cacheLanguage(String languageCode) async {
    try {
      await _storage.write(key: _keyLanguage, value: languageCode);
    } catch (_) {}
  }
}
