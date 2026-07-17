import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/search_provider.dart';
import '../providers/locale_provider.dart';
import 'place_detail_screen.dart';
import 'mission_detail_screen.dart';
import 'user_coupon_screen.dart'; // Deep links to Coupon overview or similar screen

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    final lang = context.read<LocaleProvider>().locale.languageCode;
    context.read<SearchProvider>().initSearchData(lang: lang);
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _executeSearch(String query) {
    if (query.trim().isEmpty) return;
    _searchController.text = query;
    _focusNode.unfocus();
    setState(() => _hasSearched = true);

    final lang = context.read<LocaleProvider>().locale.languageCode;
    context.read<SearchProvider>().triggerSearch(
          query: query,
          lang: lang,
        );
  }

  void _clearSearch() {
    _searchController.clear();
    _focusNode.requestFocus();
    setState(() => _hasSearched = false);
    context.read<SearchProvider>().onSearchTextChanged('');
  }

  @override
  Widget build(BuildContext context) {
    final searchProvider = context.watch<SearchProvider>();
    final lang = context.read<LocaleProvider>().locale.languageCode;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12.0),
                  child: Icon(Icons.search, color: Colors.grey),
                ),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    onChanged: (text) => searchProvider.onSearchTextChanged(text, lang: lang),
                    onSubmitted: _executeSearch,
                    decoration: const InputDecoration(
                      hintText: '장소, 미션, 쿠폰 검색...',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: _clearSearch,
                  ),
              ],
            ),
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // If suggestion list is visible (user is typing and suggestions are loaded)
          if (!_hasSearched && searchProvider.suggestions.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: searchProvider.suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = searchProvider.suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.search, color: Colors.grey, size: 18),
                    title: Text(suggestion),
                    onTap: () => _executeSearch(suggestion),
                  );
                },
              ),
            )
          // If search results are showing
          else if (_hasSearched)
            Expanded(
              child: Column(
                children: [
                  // Filter Tab headers (All, Place, Mission, Coupon, Recommendation)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    child: Row(
                      children: [
                        _buildTabChip('all', '전체', searchProvider),
                        _buildTabChip('place', '장소', searchProvider),
                        _buildTabChip('mission', '미션', searchProvider),
                        _buildTabChip('coupon', '쿠폰', searchProvider),
                        _buildTabChip('recommendation', 'AI 코스', searchProvider),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // List content
                  Expanded(
                    child: searchProvider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : searchProvider.searchResults.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                itemCount: searchProvider.searchResults.length,
                                itemBuilder: (context, index) {
                                  final item = searchProvider.searchResults[index];
                                  return _buildResultCard(item);
                                },
                              ),
                  ),
                ],
              ),
            )
          // Default pre-search screen (Recent queries and popular queries)
          else
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recent searches
                    if (searchProvider.recentSearches.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            '최근 검색어',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          TextButton(
                            onPressed: () => searchProvider.clearAllHistory(),
                            child: const Text('전체 삭제', style: TextStyle(color: Colors.grey, fontSize: 13)),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: searchProvider.recentSearches.map((query) {
                          return InputChip(
                            label: Text(query),
                            onPressed: () => _executeSearch(query),
                            onDeleted: () => searchProvider.deleteHistoryItem(query),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 30),
                    ],

                    // Popular Searches
                    if (searchProvider.popularSearches.isNotEmpty) ...[
                      const Text(
                        '인기 검색어',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 8.0,
                        children: searchProvider.popularSearches.map((pop) {
                          return ActionChip(
                            label: Text(pop),
                            onPressed: () => _executeSearch(pop),
                            backgroundColor: Colors.blueAccent.withOpacity(0.06),
                            side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabChip(String value, String label, SearchProvider provider) {
    final isSelected = provider.selectedType == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            provider.setFilterType(value);
            if (_searchController.text.isNotEmpty) {
              _executeSearch(_searchController.text);
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '검색 결과가 없습니다.',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          SizedBox(height: 8),
          Text(
            '검색어를 확인하거나 필터를 변경해 보세요.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic item) {
    final String type = item['result_type'] as String;
    final String title = item['title'] as String;
    final String subtitle = item['subtitle'] as String? ?? '';
    final String? imgUrl = item['image_url'] as String?;
    final String? cat = item['category'] as String?;
    final double rating = (item['rating'] as num?)?.toDouble() ?? 0.0;
    final int? dist = item['distance_meters'] as int?;

    IconData typeIcon = Icons.place;
    Color typeColor = Colors.blueAccent;

    if (type == 'MISSION') {
      typeIcon = Icons.golf_course;
      typeColor = Colors.green;
    } else if (type == 'COUPON') {
      typeIcon = Icons.confirmation_number;
      typeColor = Colors.amber;
    } else if (type == 'RECOMMENDATION') {
      typeIcon = Icons.route;
      typeColor = Colors.purple;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 48,
            height: 48,
            color: typeColor.withOpacity(0.1),
            child: imgUrl != null
                ? Image.network(imgUrl, fit: BoxFit.cover)
                : Icon(typeIcon, color: typeColor),
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: typeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    type,
                    style: TextStyle(fontSize: 9, color: typeColor, fontWeight: FontWeight.bold),
                  ),
                ),
                if (cat != null && cat.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(cat, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
                if (rating > 0.0) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.star, color: Colors.amber, size: 12),
                  Text(' $rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
                if (dist != null) ...[
                  const SizedBox(width: 8),
                  Text('${dist}m', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          final String id = item['id'] as String;
          if (type == 'PLACE') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: id)),
            );
          } else if (type == 'MISSION') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => MissionDetailScreen(missionId: id)),
            );
          } else if (type == 'COUPON') {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UserCouponScreen()),
            );
          }
        },
      ),
    );
  }
}
