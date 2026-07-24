import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/mission.dart';

class MissionCard extends StatelessWidget {
  final Mission mission;
  final VoidCallback? onTap;
  final VoidCallback? onActionButtonTap;

  const MissionCard({
    super.key,
    required this.mission,
    this.onTap,
    this.onActionButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5), // 0.02 opacity equivalent
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon based on mission category
                Container(
                  padding: const EdgeInsets.all(10.0),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(
                      mission.category,
                    ).withAlpha(26), // 0.1 opacity
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(mission.category),
                    color: _getCategoryColor(mission.category),
                    size: 24.0,
                  ),
                ),
                const SizedBox(width: 16.0),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Tag
                      Text(
                        mission.category,
                        style: TextStyle(
                          color: _getCategoryColor(mission.category),
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      // Title
                      Text(
                        mission.title,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      // Description
                      Text(
                        mission.description,
                        style: const TextStyle(
                          fontSize: 12.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      // Reward
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          '🎁 보상: ${mission.reward}',
                          style: const TextStyle(
                            fontSize: 10.0,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                // Points & Action Button
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+${mission.points} P',
                      style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    ElevatedButton(
                      onPressed: onActionButtonTap ?? () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                      ),
                      child: const Text(
                        '도전',
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
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
      case '사진인증':
        return Icons.camera_alt;
      case 'GPS인증':
        return Icons.location_on;
      case 'QR인증':
        return Icons.qr_code;
      default:
        return Icons.assignment;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '사진인증':
        return AppColors.accent;
      case 'GPS인증':
        return AppColors.primary;
      case 'QR인증':
        return AppColors.secondary;
      default:
        return AppColors.textSecondary;
    }
  }
}
