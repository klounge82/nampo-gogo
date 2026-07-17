import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/place.dart';
import '../repositories/place_repository.dart';
import 'place_detail_screen.dart';
import 'main_navigation_screen.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Place> _places = [];
  List<String> _categories = ['전체'];
  
  String _selectedCategory = '전체';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final categories = await _placeRepository.getCategories();
      final places = await _placeRepository.getPlaces();
      
      setState(() {
        _categories = ['전체', ...categories];
        _places = places;
      });
    } catch (_) {
      // Handled silently by fallbacks
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onCategorySelected(String category) async {
    if (_selectedCategory == category) return;
    
    setState(() {
      _selectedCategory = category;
      _isLoading = true;
      _searchController.clear(); // Clear search query when category changes
    });

    try {
      final filterCat = category == '전체' ? null : category;
      final places = await _placeRepository.getPlaces(category: filterCat);
      setState(() {
        _places = places;
      });
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _onSearch(String query) async {
    setState(() {
      _isLoading = true;
      _selectedCategory = '전체'; // Reset category when searching
    });

    try {
      if (query.trim().isEmpty) {
        final places = await _placeRepository.getPlaces();
        setState(() {
          _places = places;
        });
      } else {
        final places = await _placeRepository.searchPlaces(query);
        setState(() {
          _places = places;
        });
      }
    } catch (_) {
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          AppStrings.exploreTitle,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Box & Category Filters Area
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 12.0),
            child: Column(
              children: [
                // Custom Search Text Field
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: TextField(
                    readOnly: true,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const SearchScreen()),
                      );
                    },
                    decoration: const InputDecoration(
                      hintText: '장소 이름이나 설명 검색...',
                      hintStyle: TextStyle(color: AppColors.textHint, fontSize: 13.0),
                      prefixIcon: Icon(Icons.search, color: AppColors.primary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),
                
                // Horizontal category chips scroll
                SizedBox(
                  height: 38.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) => _onCategorySelected(category),
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.background,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.0,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                            side: BorderSide(
                              color: isSelected ? Colors.transparent : AppColors.border,
                            ),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Place List Container
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _places.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.search_off, size: 48.0, color: AppColors.textHint),
                            SizedBox(height: 12.0),
                            Text(
                              '검색 결과에 맞는 장소가 없습니다.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          return _buildPlaceCard(context, place);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          MainNavigationScreen.selectTab(context, 2);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.map),
        label: const Text('주변 지도 보기', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildPlaceCard(BuildContext context, Place place) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0.5,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border),
        ),
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: place.id)),
            );
          },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Left simulated image banner
                Container(
                  width: 80.0,
                  height: 80.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withAlpha(200),
                        AppColors.secondaryLight.withAlpha(200),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(place.category),
                      color: Colors.white,
                      size: 28.0,
                    ),
                  ),
                ),
                const SizedBox(width: 14.0),
                
                // Right Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              place.category,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(Icons.star, color: AppColors.secondary, size: 13.0),
                              const SizedBox(width: 2.0),
                              Text(
                                place.rating.toString(),
                                style: const TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        place.address,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case '먹거리':
        return Icons.restaurant;
      case '볼거리':
        return Icons.visibility;
      case '맛집':
        return Icons.local_dining;
      default:
        return Icons.place;
    }
  }
}
