import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/activity_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/activity_card.dart';

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
        return '오늘';
      } else if (parsedDay == yesterday) {
        return '어제';
      } else if (today.difference(parsedDay).inDays < 7) {
        return '이번 주';
      } else if (today.difference(parsedDay).inDays < 30) {
        return '이번 달';
      } else {
        return '이전 활동';
      }
    } catch (_) {
      return '이전 활동';
    }
  }

  @override
  Widget build(BuildContext context) {
    final actProvider = context.watch<ActivityProvider>();

    // 1. Group activities
    final Map<String, List<dynamic>> groupedMap = {};
    for (var act in actProvider.activities) {
      final dateStr = act['created_at'] as String;
      final group = _getDateGroup(dateStr);
      groupedMap.putIfAbsent(group, () => []).add(act);
    }

    // Define priority order for groups
    final groupOrder = ['오늘', '어제', '이번 주', '이번 달', '이전 활동'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '내 활동 기록',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshList),
        ],
      ),
      body: actProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : actProvider.activities.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: () async => _refreshList(),
              child: ListView.builder(
                itemCount: groupOrder.length,
                itemBuilder: (context, index) {
                  final groupName = groupOrder[index];
                  final items = groupedMap[groupName];
                  if (items == null || items.isEmpty)
                    return const SizedBox.shrink();

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
                          groupName,
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

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            '활동 기록이 없습니다.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '남포 GoGo 앱을 사용하면서 활동을 시작해 보세요.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
