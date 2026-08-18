import 'dart:async';
import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ReviewTranslationService {
  static final ReviewTranslationService _instance = ReviewTranslationService._internal();
  factory ReviewTranslationService() => _instance;
  ReviewTranslationService._internal();

  final Dio _dio = Dio(BaseOptions(
    baseUrl: ApiConfig.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  /// Cache keyed by `${reviewId}_${targetLocale}`
  final Map<String, String> _translationCache = {};

  /// Deduplication set for active requests
  final Set<String> _activeRequests = {};

  /// Clear cache for a modified or deleted review
  void invalidateCache(String reviewId) {
    _translationCache.removeWhere((key, _) => key.startsWith('${reviewId}_'));
  }

  /// Clear all cache
  void clearAllCache() {
    _translationCache.clear();
  }

  /// Translate review content via Backend Translation API
  Future<String> translateReview({
    required String reviewId,
    required String content,
    required String targetLocale,
  }) async {
    final cleanContent = content.trim();
    if (cleanContent.isEmpty) return content;

    final normalizedLocale = targetLocale.toLowerCase().contains('zh') ? 'zh_Hans' : targetLocale;
    final cacheKey = '${reviewId}_$normalizedLocale';

    // 1. Return cached result if available
    if (_translationCache.containsKey(cacheKey)) {
      return _translationCache[cacheKey]!;
    }

    // 2. Prevent duplicate concurrent requests
    if (_activeRequests.contains(cacheKey)) {
      while (_activeRequests.contains(cacheKey)) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_translationCache.containsKey(cacheKey)) {
        return _translationCache[cacheKey]!;
      }
    }

    _activeRequests.add(cacheKey);

    try {
      final response = await _dio.post(
        '/reviews/$reviewId/translate',
        data: {
          'target_locale': normalizedLocale,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final translatedText = response.data['translated_text'] as String;
        _translationCache[cacheKey] = translatedText;
        return translatedText;
      } else {
        throw Exception('Translation API returned error: ${response.statusCode}');
      }
    } catch (e) {
      // PROTOTYPE GENERIC FALLBACK REMOVED:
      // In production API mode, if API key is unconfigured or request fails,
      // rethrow Exception so UI displays clean failure notice without semantic distortion.
      rethrow;
    } finally {
      _activeRequests.remove(cacheKey);
    }
  }
}
