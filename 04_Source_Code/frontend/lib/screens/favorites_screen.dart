import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../widgets/favorite_button.dart';
import 'place_detail_screen.dart';
import 'recommendation_result_screen.dart'; // Deep links to recommendation course details

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshList() {
    final token = context.read<AuthProvider>().accessToken;
    final lang = context.read<LocaleProvider>().locale.languageCode;
    context.read<FavoriteProvider>().loadFavorites(token: token, lang: lang);
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteProvider>();

    // Divide items by type
    final places = favProvider.favoriteItems.where((item) => item['target_type'] == 'PLACE').toList();
    final recs = favProvider.favoriteItems.where((item) => item['target_type'] == 'RECOMMENDATION').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('즐겨찾기 보관함', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '저장한 장소'),
            Tab(text: '저장한 코스'),
          ],
        ),
      ),
      body: favProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildListView(places, 'PLACE'),
                _buildListView(recs, 'RECOMMENDATION'),
              ],
            ),
    );
  }

  Widget _buildListView(List<dynamic> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type == 'PLACE' ? Icons.store_mall_directory : Icons.route,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              '저장된 항목이 없습니다.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            const Text(
              '관심 있는 장소나 코스를 하트 아이콘으로 추가해 보세요.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        final String targetId = item['target_id'] as String;
        final String title = item['title'] as String;
        final String subtitle = item['subtitle'] as String? ?? '';
        final String? imgUrl = item['image_url'] as String?;
        final String? cat = item['category'] as String?;
        final double rating = (item['rating'] as num?)?.toDouble() ?? 0.0;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 48,
                height: 48,
                color: Colors.blueAccent.withOpacity(0.08),
                child: imgUrl != null && imgUrl.isNotEmpty
                    ? Image.network(imgUrl, fit: BoxFit.cover)
                    : Icon(
                        type == 'PLACE' ? Icons.place : Icons.route,
                        color: Colors.blueAccent,
                      ),
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
                    style: const TextStyle(fontSize: 11),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (cat != null && cat.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(cat, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      ),
                    if (rating > 0.0) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.star, color: Colors.amber, size: 12),
                      Text(' $rating', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ],
            ),
            trailing: FavoriteButton(
              targetType: type,
              targetId: targetId,
            ),
            onTap: () {
              if (type == 'PLACE') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: targetId)),
                );
              }
            },
          ),
        );
      },
    );
  }
}
