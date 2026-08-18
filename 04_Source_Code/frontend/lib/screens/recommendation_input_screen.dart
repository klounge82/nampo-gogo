import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/personalization_provider.dart';
import '../services/location_service.dart';
import '../l10n/app_localizations.dart';
import 'recommendation_result_screen.dart';
import 'saved_courses_screen.dart';

class RecommendationInputScreen extends StatefulWidget {
  const RecommendationInputScreen({super.key});

  @override
  State<RecommendationInputScreen> createState() =>
      _RecommendationInputScreenState();
}

class _RecommendationInputScreenState extends State<RecommendationInputScreen> {
  final LocationService _locationService = LocationService();

  String _selectedTravelType = 'COUPLE'; // SOLO, COUPLE, FAMILY, FRIENDS
  String _selectedDuration = 'HALF_DAY'; // TWO_HOURS, HALF_DAY, FULL_DAY
  String _selectedTransport = 'WALK'; // WALK, TRANSIT, DRIVE

  final List<String> _selectedCategories = [
    'FOOD',
    'CAFE',
  ]; // FOOD, CAFE, TOURISM, SHOPPING, EXPERIENCE

  bool _isLocating = false;

  void _toggleCategory(String cat) {
    setState(() {
      if (_selectedCategories.contains(cat)) {
        if (_selectedCategories.length > 1) {
          _selectedCategories.remove(cat);
        }
      } else {
        _selectedCategories.add(cat);
      }
    });
  }

  Future<void> _submitRequest() async {
    setState(() => _isLocating = true);

    // Get current position
    Position? position;
    try {
      position = await _locationService.getCurrentLocation();
    } catch (e) {
      // Geolocator error or permission denied -> fallback to Busan station
      position = null;
    }

    setState(() => _isLocating = false);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    final personalProvider = Provider.of<PersonalizationProvider>(
      context,
      listen: false,
    );

    if (!mounted) return;

    // Navigate to Results Screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecommendationResultScreen(
          userId: userId,
          travelType: _selectedTravelType,
          travelDuration: _selectedDuration,
          categories: _selectedCategories,
          transportMode: _selectedTransport,
          latitude: position?.latitude,
          longitude: position?.longitude,
          usePersonalization: personalProvider.usePersonalization,
          excludeVisited: personalProvider.preferNewPlaces,
          preferRewards: personalProvider.preferRewards,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoggedIn = authProvider.isLoggedIn;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.recommendTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          if (isLoggedIn)
            IconButton(
              icon: const Icon(Icons.bookmark_outline),
              tooltip: l10n.mySavedCourses,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SavedCoursesScreen()),
              ),
            ),
        ],
      ),
      body: _isLocating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16.0),
                  Text(
                    l10n.mapLoading,
                    style: const TextStyle(
                      fontSize: 13.0,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recommendTitle,
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      l10n.aiStepCompanionTitle,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24.0),

                    // 1. Travel Type
                    _buildSectionTitle(l10n.aiStepCompanionTitle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSelectableChip(
                          l10n.aiCompanionSolo,
                          'SOLO',
                          _selectedTravelType,
                          (val) => setState(() => _selectedTravelType = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiCompanionCouple,
                          'COUPLE',
                          _selectedTravelType,
                          (val) => setState(() => _selectedTravelType = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSelectableChip(
                          l10n.aiCompanionFamily,
                          'FAMILY',
                          _selectedTravelType,
                          (val) => setState(() => _selectedTravelType = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiCompanionFriends,
                          'FRIENDS',
                          _selectedTravelType,
                          (val) => setState(() => _selectedTravelType = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 2. Duration
                    _buildSectionTitle(l10n.aiStepTimeTitle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSelectableChip(
                          l10n.aiTime2Hours,
                          'TWO_HOURS',
                          _selectedDuration,
                          (val) => setState(() => _selectedDuration = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiTimeHalfDay,
                          'HALF_DAY',
                          _selectedDuration,
                          (val) => setState(() => _selectedDuration = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiTimeFullDay,
                          'FULL_DAY',
                          _selectedDuration,
                          (val) => setState(() => _selectedDuration = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 3. Category selector (Multi-select)
                    _buildSectionTitle(l10n.aiStepCategoryTitle),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: [
                        _buildMultiSelectChip('🍕 ${l10n.aiCategoryMeal}', 'FOOD'),
                        _buildMultiSelectChip('☕ ${l10n.aiCategoryCafe}', 'CAFE'),
                        _buildMultiSelectChip('📸 ${l10n.aiCategorySights}', 'TOURISM'),
                        _buildMultiSelectChip('🛍️ ${l10n.aiCategoryMarket}', 'SHOPPING'),
                        _buildMultiSelectChip('🎯 ${l10n.aiCategoryCulture}', 'EXPERIENCE'),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 4. Transport Mode
                    _buildSectionTitle(l10n.aiStepTransitTitle),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSelectableChip(
                          l10n.aiTransitWalk,
                          'WALK',
                          _selectedTransport,
                          (val) => setState(() => _selectedTransport = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiTransitPublic,
                          'TRANSIT',
                          _selectedTransport,
                          (val) => setState(() => _selectedTransport = val),
                        ),
                        _buildSelectableChip(
                          l10n.aiTransitCar,
                          'DRIVE',
                          _selectedTransport,
                          (val) => setState(() => _selectedTransport = val),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24.0),

                    // 5. Personalization Options
                    _buildSectionTitle(l10n.recommendOptPersonalizedTitle),
                    Consumer<PersonalizationProvider>(
                      builder: (context, personal, child) {
                        return Column(
                          children: [
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.recommendOptPersonalizedToggle,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                l10n.recommendOptPersonalizedDesc,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: Colors.grey,
                                ),
                              ),
                              value: personal.usePersonalization,
                              onChanged: (val) {
                                final token = context
                                    .read<AuthProvider>()
                                    .accessToken;
                                personal.togglePersonalization(
                                  value: val,
                                  token: token,
                                );
                              },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.recommendOptExcludeVisitedToggle,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                l10n.recommendOptExcludeVisitedDesc,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: Colors.grey,
                                ),
                              ),
                              value: personal.preferNewPlaces,
                              onChanged: (val) {
                                final token = context
                                    .read<AuthProvider>()
                                    .accessToken;
                                personal.toggleExcludeVisited(
                                  value: val,
                                  token: token,
                                );
                              },
                            ),
                            SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                l10n.recommendOptPreferRewardsToggle,
                                style: const TextStyle(
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              subtitle: Text(
                                l10n.recommendOptPreferRewardsDesc,
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  color: Colors.grey,
                                ),
                              ),
                              value: personal.preferRewards,
                              onChanged: (val) {
                                final token = context
                                    .read<AuthProvider>()
                                    .accessToken;
                                personal.togglePreferRewards(
                                  value: val,
                                  token: token,
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 36.0),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 48.0,
                      child: ElevatedButton(
                        onPressed: _submitRequest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          l10n.aiGenerateButton,
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSelectableChip(
    String label,
    String value,
    String currentSelected,
    ValueChanged<String> onSelected, {
    double height = 54.0,
  }) {
    final bool isSel = value == currentSelected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onSelected(value),
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSel ? AppColors.primary.withAlpha(20) : AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSel ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.0,
              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              color: isSel ? AppColors.primary : AppColors.textPrimary,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMultiSelectChip(String label, String value) {
    final bool isSel = _selectedCategories.contains(value);
    return GestureDetector(
      onTap: () => _toggleCategory(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary.withAlpha(20) : AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSel ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
            color: isSel ? AppColors.primary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
