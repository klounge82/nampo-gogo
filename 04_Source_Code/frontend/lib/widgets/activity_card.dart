import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/place_detail_screen.dart';
import '../screens/mission_detail_screen.dart';
import '../screens/user_coupon_screen.dart';

class ActivityCard extends StatelessWidget {
  final dynamic activity;

  const ActivityCard({super.key, required this.activity});

  IconData _getIcon(String iconStr) {
    switch (iconStr.toLowerCase()) {
      case 'calendar_today':
        return Icons.calendar_today;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'paid':
        return Icons.paid;
      case 'redeem':
        return Icons.redeem;
      case 'star':
        return Icons.star;
      case 'favorite':
        return Icons.favorite;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'person_add':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }

  Color _getColor(String colorStr) {
    switch (colorStr.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'amber':
        return Colors.amber;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'deeporange':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  void _handleDeepLink(BuildContext context) {
    final String? targetType = activity['target_type'] as String?;
    final String? targetId = activity['target_id'] as String?;
    if (targetType == null || targetId == null) return;

    if (targetType == 'PLACE') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: targetId)),
      );
    } else if (targetType == 'MISSION') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MissionDetailScreen(missionId: targetId)),
      );
    } else if (targetType == 'COUPON') {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const UserCouponScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = activity['title'] as String;
    final String description = activity['description'] as String;
    final String iconStr = activity['icon'] as String? ?? 'info';
    final String colorStr = activity['color'] as String? ?? 'grey';
    final String createdAtStr = activity['created_at'] as String;

    final DateTime parsedTime = DateTime.parse(createdAtStr);
    final String timeFormatted = DateFormat('HH:mm').format(parsedTime);

    final iconData = _getIcon(iconStr);
    final themeColor = _getColor(colorStr);

    final hasLink = activity['target_type'] != null && activity['target_id'] != null;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Icon Background
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: themeColor, size: 20),
            ),
            const SizedBox(width: 12),
            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        timeFormatted,
                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ],
              ),
            ),
            if (hasLink) ...[
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                onPressed: () => _handleDeepLink(context),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
