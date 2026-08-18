import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/locale_storage_service.dart';
import '../config/api_config.dart';

class LocaleProvider with ChangeNotifier {
  final LocaleStorageService _storage = LocaleStorageService();
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 5),
    ),
  );

  Locale _locale = const Locale('ko');

  Locale get locale => _locale;

  String get currentLocaleCode {
    if (_locale.languageCode == 'zh' && _locale.scriptCode == 'Hans') {
      return 'zh_Hans';
    }
    return _locale.languageCode;
  }

  Future<void> initLocale() async {
    // 1. Check local cache
    final cached = await _storage.getCachedLanguage();
    if (cached != null) {
      if (cached == 'zh_Hans' || cached == 'zh-Hans') {
        _locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      } else {
        _locale = Locale(cached);
      }
      notifyListeners();
      return;
    }

    // 2. Fallback to system language detection
    try {
      final String systemLang = Platform.localeName.split('_')[0].toLowerCase();
      if (systemLang == 'zh') {
        _locale = const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      } else if (['ko', 'en', 'ja'].contains(systemLang)) {
        _locale = Locale(systemLang);
      } else {
        _locale = const Locale('ko'); // Default fallback
      }
    } catch (_) {
      _locale = const Locale('ko');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale, {String? userId}) async {
    final langCode = newLocale.languageCode;
    if (!['ko', 'en', 'ja', 'zh'].contains(langCode)) return;

    _locale = newLocale;
    notifyListeners();

    final cacheCode = (langCode == 'zh' && newLocale.scriptCode == 'Hans')
        ? 'zh_Hans'
        : langCode;

    // Cache locally
    await _storage.cacheLanguage(cacheCode);

    // Sync to backend DB if logged in
    try {
      await _dio.patch(
        '/users/language',
        data: {'language_code': cacheCode},
        queryParameters: {if (userId != null) 'user_id': userId},
      );
    } catch (_) {
      // Offline fallback silent failure
    }
  }
}
