import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../widgets/activity_card.dart';
import 'travel_log_screen.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  void initState() {
    super.initState();
    _refreshList();
  }

  void _refreshList() {
    final token = context.read<AuthProvider>().accessToken;
    context.read<ActivityProvider>().loadActivities(token: token);
  }

  String _getDateGroup(String dateStr) {
    try {
      final parsed = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final parsedDay = DateTime(parsed.year, parsed.month, parsed.day);

      if (parsedDay == today) {
        return 'today';
      } else if (parsedDay == yesterday) {
        return 'yesterday';
      } else if (today.difference(parsedDay).inDays < 7) {
        return 'thisWeek';
      } else if (today.difference(parsedDay).inDays < 30) {
        return 'thisMonth';
      } else {
        return 'older';
      }
    } catch (_) {
      return 'older';
    }
  }

  String _getGroupLabel(String key, AppLocalizations? l10n) {
    switch (key) {
      case 'today':
        return l10n?.activityToday ?? 'Today';
      case 'yesterday':
        return l10n?.activityYesterday ?? 'Yesterday';
      case 'thisWeek':
        return l10n?.activityThisWeek ?? 'This Week';
      case 'thisMonth':
        return l10n?.activityThisMonth ?? 'This Month';
      case 'older':
      default:
        return l10n?.activityOlder ?? 'Earlier';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actProvider = context.watch<ActivityProvider>();
    final l10n = AppLocalizations.of(context);

    // 1. Group activities
    final Map<String, List<dynamic>> groupedMap = {};
    for (var act in actProvider.activities) {
      final dateStr = act['created_at'] as String;
      final group = _getDateGroup(dateStr);
      groupedMap.putIfAbsent(group, () => []).add(act);
    }

    // Define priority order for groups
    final groupOrder = ['today', 'yesterday', 'thisWeek', 'thisMonth', 'older'];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.profileActivityLog ?? 'Activity Log',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_stories),
            tooltip: l10n?.travelLogTitle ?? 'Travel Log',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const TravelLogScreen()),
              );
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshList),
        ],
      ),
      body: actProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : actProvider.activities.isEmpty
          ? _buildEmptyState(l10n)
          : RefreshIndicator(
              onRefresh: () async => _refreshList(),
              child: ListView.builder(
                itemCount: groupOrder.length,
                itemBuilder: (context, index) {
                  final groupKey = groupOrder[index];
                  final items = groupedMap[groupKey];
                  if (items == null || items.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Title Header
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20.0,
                          top: 16.0,
                          bottom: 8.0,
                        ),
                        child: Text(
                          _getGroupLabel(groupKey, l10n),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent.shade700,
                          ),
                        ),
                      ),
                      // Cards in Group
                      ...items
                          .map((act) => ActivityCard(activity: act))
                          .toList(),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            l10n?.noActivityLogs ?? 'No activity history.',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.startAppActivityDesc ?? 'Start exploring with Nampo GoGo to build your activity history.',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
