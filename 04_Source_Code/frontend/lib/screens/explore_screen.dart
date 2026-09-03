import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../models/mission.dart';
import '../providers/locale_provider.dart';
import '../repositories/place_repository.dart';
import '../repositories/mission_repository.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import 'place_detail_screen.dart';
import 'search_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();
  final MissionRepository _missionRepository = MissionRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Place> _places = [];
  Map<String, List<Mission>> _placeMissionsMap = {};
  List<String> _categories = const ['전체', '먹거리', '관광', '쇼핑', '체험'];

  String _selectedCategory = '전체';
  bool _isLoading = false;
  String? _lastLocaleCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLoc = context.watch<LocaleProvider>().currentLocaleCode;
    if (_lastLocaleCode != currentLoc) {
      _lastLocaleCode = currentLoc;
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _categories = const ['전체', '먹거리', '관광', '쇼핑', '체험'];
      });
    }
    try {
      final results = await Future.wait([
        _placeRepository.getPlaces(locale: localeCode),
        _missionRepository.getMissions(locale: localeCode),
      ]);

      final places = results[0] as List<Place>;
      final missions = results[1] as List<Mission>;

      final Map<String, List<Mission>> map = {};
      for (final m in missions) {
        if (m.storeId.isNotEmpty) {
          map.putIfAbsent(m.storeId, () => []).add(m);
        }
      }

      if (mounted) {
        setState(() {
          _places = places;
          _placeMissionsMap = map;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onCategorySelected(String category) async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    if (_selectedCategory == category) return;

    if (mounted) {
      setState(() {
        _selectedCategory = category;
        _isLoading = true;
        _searchController.clear();
      });
    }

    try {
      final filterCat = category == '전체' ? null : category;
      final places = await _placeRepository.getPlaces(category: filterCat, locale: localeCode);
      if (mounted) {
        setState(() {
          _places = places;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.exploreTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 16.0,
              bottom: 12.0,
            ),
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
                    decoration: InputDecoration(
                      hintText: l10n.searchHint,
                      hintStyle: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14.0,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textSecondary,
                        size: 20.0,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 12.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12.0),

                // Horizontal Category Filter List
                SizedBox(
                  height: 38.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8.0),
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      final localizedLabel = L10nMappers.mapCategory(l10n, cat);

                      return ChoiceChip(
                        label: Text(
                          localizedLabel,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        onSelected: (_) => _onCategorySelected(cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main Place List Section
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _places.isEmpty
                ? Center(
                    child: Text(
                      l10n.noReviewsYet,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadInitialData,
                    color: AppColors.primary,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      itemCount: _places.length,
                      itemBuilder: (context, index) {
                        final place = _places[index];
                        final rawMissions = _placeMissionsMap[place.id] ?? [];
                        final availableMissions = rawMissions.where((m) => !m.isCompleted).toList();
                        return _buildPlaceItem(context, place, availableMissions, l10n);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceItem(
    BuildContext context,
    Place place,
    List<Mission> availableMissions,
    AppLocalizations l10n,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14.0),
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
              MaterialPageRoute(
                builder: (_) => PlaceDetailScreen(placeId: place.id),
              ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26),
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              L10nMappers.mapCategory(l10n, place.category),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.secondary,
                                size: 13.0,
                              ),
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
                        L10nMappers.mapPlaceName(place, l10n.localeName),
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
                        L10nMappers.mapPlaceAddress(place, l10n.localeName),
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (availableMissions.isNotEmpty) ...[
                        const SizedBox(height: 6.0),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withAlpha(30),
                                borderRadius: BorderRadius.circular(4.0),
                                border: Border.all(
                                  color: AppColors.secondary.withAlpha(100),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    size: 11.0,
                                    color: AppColors.secondary,
                                  ),
                                  const SizedBox(width: 3.0),
                                  Text(
                                    availableMissions.length == 1
                                        ? l10n.exploreMissionRewardBadge(availableMissions.first.points.toString())
                                        : l10n.exploreMissionAvailableBadge(availableMissions.length.toString()),
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
      case '관광':
      case '볼거리':
        return Icons.visibility;
      case '쇼핑':
        return Icons.shopping_bag;
      case '체험':
        return Icons.palette;
      default:
        return Icons.place;
    }
  }
}
