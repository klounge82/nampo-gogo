import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/mission.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import '../screens/mission_detail_screen.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context);
    final langCode = locale.languageCode;
    final rewardText = l10n.rewardLabel;

    final displayTitle = mission.localizedTitle(langCode);
    final displayDescription = mission.localizedDescription(langCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap ??
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MissionDetailScreen(missionId: mission.id),
                  ),
                );
              },
          borderRadius: BorderRadius.circular(12.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category & Badges Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6.0),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(mission.category).withAlpha(20),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Icon(
                        _getCategoryIcon(mission.category),
                        size: 16.0,
                        color: _getCategoryColor(mission.category),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Text(
                      L10nMappers.mapCategory(l10n, mission.category),
                      style: TextStyle(
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                        color: _getCategoryColor(mission.category),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        L10nMappers.mapMissionAuthType(l10n, mission.authType),
                        style: const TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    if (mission.title.contains('[QA') || mission.description.contains('[QA')) ...[
                      const SizedBox(width: 6.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Text(
                          l10n.badgeTest,
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10.0),

                // Title
                Text(
                  displayTitle,
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),

                // Description
                Text(
                  displayDescription,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12.0),

                // Points & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mission.points}P $rewardText',
                      style: const TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: onActionButtonTap ??
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MissionDetailScreen(missionId: mission.id),
                              ),
                            );
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _getActionButtonText(l10n, mission.authType),
                        style: const TextStyle(
                          fontSize: 12.0,
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

  String _getActionButtonText(AppLocalizations l10n, String authType) {
    final type = authType.toUpperCase();
    if (type.contains('QR')) {
      return l10n.missionAuthActionQr;
    } else if (type.contains('GPS') || type.contains('LOCATION')) {
      return l10n.missionAuthActionGps;
    } else if (type.contains('PHOTO')) {
      return l10n.missionAuthActionPhoto;
    }
    return l10n.challengeButton;
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toUpperCase();
    if (cat.contains('PHOTO') || cat.contains('사진')) {
      return Icons.camera_alt_outlined;
    } else if (cat.contains('GPS') || cat.contains('LOCATION') || cat.contains('위치')) {
      return Icons.location_on_outlined;
    } else if (cat.contains('QR')) {
      return Icons.qr_code_scanner_rounded;
    } else if (cat.contains('FOOD') || cat.contains('식당') || cat.contains('음식')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('SHOPPING') || cat.contains('쇼핑')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.explore_outlined;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toUpperCase();
    if (cat.contains('PHOTO') || cat.contains('사진')) {
      return Colors.purple;
    } else if (cat.contains('GPS') || cat.contains('LOCATION') || cat.contains('위치')) {
      return Colors.blue;
    } else if (cat.contains('QR')) {
      return Colors.teal;
    } else if (cat.contains('FOOD') || cat.contains('식당') || cat.contains('음식')) {
      return Colors.orange;
    } else if (cat.contains('SHOPPING') || cat.contains('쇼핑')) {
      return Colors.pink;
    }
    return AppColors.primary;
  }
}
