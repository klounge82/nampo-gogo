import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/search_repository.dart';

class SearchProvider extends ChangeNotifier {
  final SearchRepository _searchRepository;

  SearchProvider({SearchRepository? searchRepository})
    : _searchRepository = searchRepository ?? SearchRepository();

  // Search Results States
  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _totalCount = 0;

  // History & Autocomplete States
  List<String> _recentSearches = [];
  List<String> _popularSearches = [];
  List<String> _suggestions = [];

  // Filter States
  String _selectedType =
      'all'; // 'all', 'place', 'mission', 'coupon', 'recommendation'
  String _selectedSort = 'relevance'; // 'relevance', 'distance', 'rating'

  // Getters
  List<dynamic> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  int get totalCount => _totalCount;
  List<String> get recentSearches => _recentSearches;
  List<String> get popularSearches => _popularSearches;
  List<String> get suggestions => _suggestions;
  String get selectedType => _selectedType;
  String get selectedSort => _selectedSort;

  Timer? _debounceTimer;

  // Load Initial History
  Future<void> initSearchData({String lang = 'ko'}) async {
    await loadRecentSearches();
    await loadPopularSearches(lang: lang);
  }

  Future<void> loadRecentSearches() async {
    _recentSearches = await _searchRepository.getRecentSearches();
    notifyListeners();
  }

  Future<void> loadPopularSearches({String lang = 'ko'}) async {
    _popularSearches = await _searchRepository.getPopularSearches(lang: lang);
    notifyListeners();
  }

  // Set Search Filters & Sorts
  void setFilterType(String type) {
    _selectedType = type;
    notifyListeners();
  }

  void setSortOption(String sort) {
    _selectedSort = sort;
    notifyListeners();
  }

  // Trigger Integrated Search API
  Future<void> triggerSearch({
    required String query,
    String lang = 'ko',
    double? latitude,
    double? longitude,
  }) async {
    if (query.trim().isEmpty) return;

    _isLoading = true;
    _errorMessage = '';
    _suggestions = []; // Clear autocomplete suggestions on search submit
    notifyListeners();

    try {
      // Save query locally to history
      await _searchRepository.saveRecentSearch(query);
      await loadRecentSearches();

      final res = await _searchRepository.search(
        q: query,
        type: _selectedType,
        lang: lang,
        latitude: latitude,
        longitude: longitude,
        sort: _selectedSort,
      );

      _searchResults = res['items'] as List<dynamic>;
      _totalCount = res['total'] as int? ?? 0;
    } catch (e) {
      _errorMessage = '검색 결과를 가져오는 데 실패했습니다: $e';
      _searchResults = [];
      _totalCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Input listener with Debounce for Autocomplete suggestions
  void onSearchTextChanged(String text, {String lang = 'ko'}) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (text.trim().isEmpty) {
      _suggestions = [];
      notifyListeners();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 350), () async {
      _suggestions = await _searchRepository.getSuggestions(text, lang: lang);
      notifyListeners();
    });
  }

  // Local History Clear Helpers
  Future<void> deleteHistoryItem(String query) async {
    await _searchRepository.deleteRecentSearch(query);
    await loadRecentSearches();
  }

  Future<void> clearAllHistory() async {
    await _searchRepository.clearRecentSearches();
    await loadRecentSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}
