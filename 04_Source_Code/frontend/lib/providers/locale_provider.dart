import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../services/locale_storage_service.dart';

class LocaleProvider with ChangeNotifier {
  final LocaleStorageService _storage = LocaleStorageService();
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:18080',
    connectTimeout: const Duration(seconds: 5),
  ));

  Locale _locale = const Locale('ko');

  Locale get locale => _locale;

  Future<void> initLocale() async {
    // 1. Check local cache
    final cached = await _storage.getCachedLanguage();
    if (cached != null) {
      _locale = Locale(cached);
      notifyListeners();
      return;
    }

    // 2. Fallback to system language detection
    try {
      final String systemLang = Platform.localeName.split('_')[0].toLowerCase();
      if (['ko', 'en', 'ja', 'zh', 'zh-Hans'].contains(systemLang)) {
        _locale = Locale(systemLang);
      } else {
        _locale = const Locale('en'); // Default default fallback
      }
    } catch (_) {
      _locale = const Locale('en');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale newLocale, {String? userId}) async {
    if (!['ko', 'en', 'ja', 'zh', 'zh-Hans'].contains(newLocale.languageCode)) return;

    _locale = newLocale;
    notifyListeners();

    // Cache locally
    await _storage.cacheLanguage(newLocale.languageCode);

    // Sync to backend DB if logged in
    try {
      await _dio.patch('/users/language', data: {
        'language_code': newLocale.languageCode,
      }, queryParameters: {
        if (userId != null) 'user_id': userId,
      });
    } catch (_) {
      // Offline fallback silent failure
    }
  }
}
