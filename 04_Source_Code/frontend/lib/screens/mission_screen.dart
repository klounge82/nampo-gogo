import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/mission.dart';
import '../repositories/mission_repository.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import '../widgets/mission_card.dart';

class MissionScreen extends StatefulWidget {
  const MissionScreen({super.key});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  final MissionRepository _missionRepository = MissionRepository();

  List<Mission> _missions = [];
  bool _isLoading = false;
  String? _lastLocaleCode;
  String _selectedState = 'AVAILABLE'; // 'AVAILABLE' | 'COMPLETED'
  String _selectedCategory = 'ALL';

  final List<String> _categoryKeys = [
    'ALL',
    'FOOD',
    'ATTRACTION',
    'EXPERIENCE',
    'SHOPPING',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLoc = context.watch<LocaleProvider>().currentLocaleCode;
    if (_lastLocaleCode != currentLoc) {
      _lastLocaleCode = currentLoc;
      _loadMissions();
    }
  }

  Future<void> _loadMissions() async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    setState(() => _isLoading = true);
    try {
      final list = await _missionRepository.getMissions(locale: localeCode);
      setState(() {
        _missions = list;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<Mission> get _filteredMissions {
    // 1st Axis: State Filter (Available vs Completed)
    final stateFiltered = _missions.where((m) {
      if (_selectedState == 'COMPLETED') {
        return m.isCompleted;
      }
      return !m.isCompleted;
    }).toList();

    // 2nd Axis: Category Filter
    if (_selectedCategory == 'ALL') return stateFiltered;
    return stateFiltered.where((m) {
      final cat = m.category.toUpperCase();
      if (_selectedCategory == 'FOOD') {
        return cat.contains('FOOD') || cat.contains('음식') || cat.contains('식당') || cat.contains('맛집') || cat.contains('먹거리');
      } else if (_selectedCategory == 'ATTRACTION') {
        return cat.contains('ATTRACTION') || cat.contains('명소') || cat.contains('관광') || cat.contains('볼거리') || cat.contains('SIGHTS');
      } else if (_selectedCategory == 'EXPERIENCE') {
        return cat.contains('EXPERIENCE') || cat.contains('체험') || cat.contains('문화') || cat.contains('CULTURE');
      } else if (_selectedCategory == 'SHOPPING') {
        return cat.contains('SHOPPING') || cat.contains('쇼핑') || cat.contains('시장') || cat.contains('MARKET');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();
    final isLoggedIn = authProvider.isLoggedIn;
    final user = authProvider.currentUser;
    final currentPoints = user?.currentPoints ?? 0;

    final totalMissions = _missions.length;
    final completedCount = _missions.where((m) => m.isCompleted).length;
    final availableCount = _missions.where((m) => !m.isCompleted).length;
    final progressPercent = totalMissions > 0 ? (completedCount / totalMissions).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.missionTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMissions,
        color: AppColors.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Point & Mission Progress Dashboard Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20.0),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(76),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.missionMyPoints,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isLoggedIn ? '$currentPoints P' : '0 P',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Icon(
                            Icons.stars,
                            color: Colors.white,
                            size: 36.0,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Container(height: 1.0, color: Colors.white24),
                      const SizedBox(height: 12.0),

                      // Clean Mission Progress Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.missionProgressCompletedTotal(completedCount.toString(), totalMissions.toString()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(progressPercent * 100).toInt()}%',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: progressPercent,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          minHeight: 6.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // UX-04: Primary State Selector [도전 가능 N] [완료 N]
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedState = 'AVAILABLE'),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: _selectedState == 'AVAILABLE'
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: _selectedState == 'AVAILABLE'
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            boxShadow: _selectedState == 'AVAILABLE'
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(40),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.flag_outlined,
                                size: 16.0,
                                color: _selectedState == 'AVAILABLE'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                '${l10n.missionStateAvailable} $availableCount',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedState == 'AVAILABLE'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: InkWell(
                        onTap: () => setState(() => _selectedState = 'COMPLETED'),
                        borderRadius: BorderRadius.circular(12.0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          decoration: BoxDecoration(
                            color: _selectedState == 'COMPLETED'
                                ? AppColors.primary
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(12.0),
                            border: Border.all(
                              color: _selectedState == 'COMPLETED'
                                  ? AppColors.primary
                                  : AppColors.border,
                            ),
                            boxShadow: _selectedState == 'COMPLETED'
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withAlpha(40),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 16.0,
                                color: _selectedState == 'COMPLETED'
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                '${l10n.missionStateCompleted} $completedCount',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: _selectedState == 'COMPLETED'
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Secondary Category Filter Tabs
                SizedBox(
                  height: 38.0,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categoryKeys.length,
                    separatorBuilder: (context, idx) => const SizedBox(width: 8.0),
                    itemBuilder: (context, idx) {
                      final key = _categoryKeys[idx];
                      final isSelected = _selectedCategory == key;
                      final label = L10nMappers.mapCategory(l10n, key);

                      return ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13.0,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppColors.primary,
                        backgroundColor: AppColors.surface,
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _selectedCategory = key);
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20.0),

                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedState == 'COMPLETED'
                          ? l10n.missionCompletedCount
                          : l10n.missionAllList,
                      style: const TextStyle(
                        fontSize: 17.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.missionTotalCountLabel(_filteredMissions.length.toString()),
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),

                // Mission List with Clean Cards
                _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : _filteredMissions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40.0),
                          child: Text(
                            l10n.missionEmpty,
                            style: const TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _filteredMissions.length,
                        itemBuilder: (context, index) {
                          final mission = _filteredMissions[index];
                          return MissionCard(mission: mission);
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
