import 'package:flutter/material.dart';
import '../repositories/favorite_repository.dart';

class FavoriteProvider extends ChangeNotifier {
  final FavoriteRepository _repository;

  FavoriteProvider({FavoriteRepository? repository})
      : _repository = repository ?? FavoriteRepository();

  // Active Favorites Status IDs for fast lookup
  final Set<String> _favoriteIds = {};
  List<dynamic> _favoriteItems = [];
  bool _isLoading = false;
  String _errorMessage = '';

  Set<String> get favoriteIds => _favoriteIds;
  List<dynamic> get favoriteItems => _favoriteItems;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Load My Favorites (Server or Local)
  Future<void> loadFavorites({String? token, String lang = 'ko'}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty) {
        // Authenticated user: Load from backend
        final items = await _repository.getFavorites(lang, token: token);
        _favoriteItems = items;
        _favoriteIds.clear();
        for (var item in items) {
          _favoriteIds.add(item['target_id'] as String);
        }
      } else {
        // Guest user: Load from local storage
        final locals = await _repository.getLocalFavorites();
        _favoriteIds.clear();
        _favoriteItems = [];
        for (var item in locals) {
          final String targetId = item['target_id']!;
          final String targetType = item['target_type']!;
          _favoriteIds.add(targetId);
          // Insert minimal mock info for offline guest display
          _favoriteItems.add({
            'id': targetId,
            'target_type': targetType,
            'target_id': targetId,
            'title': targetType == 'PLACE' ? '저장된 장소' : '저장된 AI 코스',
            'subtitle': '로그인 시 정보가 완전히 연동됩니다.',
            'category': '',
            'rating': 0.0,
            'is_active': true
          });
        }
      }
    } catch (e) {
      _errorMessage = '즐겨찾기 목록을 가져오는 데 실패했습니다.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle Favorite Action (Optimistic Update)
  Future<void> toggleFavorite({
    required String targetType,
    required String targetId,
    String? token,
    String lang = 'ko',
    BuildContext? context,
  }) async {
    final bool wasActive = _favoriteIds.contains(targetId);

    // 1. Optimistic Update (Update UI instantly)
    if (wasActive) {
      _favoriteIds.remove(targetId);
      _favoriteItems.removeWhere((item) => item['target_id'] == targetId);
    } else {
      _favoriteIds.add(targetId);
      _favoriteItems.add({
        'id': targetId,
        'target_type': targetType,
        'target_id': targetId,
        'title': targetType == 'PLACE' ? '장소' : 'AI 코스',
        'subtitle': '',
        'category': '',
        'rating': 0.0,
        'is_active': true
      });
    }
    notifyListeners();

    try {
      if (token != null && token.isNotEmpty) {
        // Server Sync
        if (wasActive) {
          await _repository.removeFavorite(targetType, targetId, token: token);
        } else {
          await _repository.addFavorite(targetType, targetId, token: token);
        }
        // Silent reload to fetch complete server-computed metadata
        final items = await _repository.getFavorites(lang, token: token);
        _favoriteItems = items;
        _favoriteIds.clear();
        for (var item in items) {
          _favoriteIds.add(item['target_id'] as String);
        }
        notifyListeners();
      } else {
        // Local Disk Sync
        if (wasActive) {
          await _repository.removeLocalFavorite(targetType, targetId);
        } else {
          await _repository.saveLocalFavorite(targetType, targetId);
        }
        if (context != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 전에는 기기에 임시 저장됩니다.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      // 2. Rollback on failure
      if (wasActive) {
        _favoriteIds.add(targetId);
      } else {
        _favoriteIds.remove(targetId);
        _favoriteItems.removeWhere((item) => item['target_id'] == targetId);
      }
      notifyListeners();

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('통신 실패로 즐겨찾기 변경이 취소되었습니다.')),
        );
      }
    }
  }

  // Merge Local Cache to Account after login completes
  Future<void> mergeLocalCacheToAccount(String token, {String lang = 'ko'}) async {
    try {
      final locals = await _repository.getLocalFavorites();
      if (locals.isEmpty) return;

      await _repository.mergeFavorites(locals, token);
      await _repository.clearLocalFavorites();
      await loadFavorites(token: token, lang: lang);
    } catch (e) {
      // Fail silently or log
    }
  }

  // Reset favorites state on logout
  void clearState() {
    _favoriteIds.clear();
    _favoriteItems.clear();
    _errorMessage = '';
    notifyListeners();
  }
}
