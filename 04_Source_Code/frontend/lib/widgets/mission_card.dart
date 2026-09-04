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
    final isCompleted = mission.isCompleted;

    final displayTitle = mission.localizedTitle(langCode);
    final displayDescription = mission.localizedDescription(langCode);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF8FAFC) : AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isCompleted ? AppColors.border.withAlpha(120) : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isCompleted ? 2 : 5),
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
          borderRadius: BorderRadius.circular(14.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Canonical Auth Label + Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(mission.category).withAlpha(20),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getCategoryIcon(mission.category),
                            size: 14.0,
                            color: _getCategoryColor(mission.category),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            L10nMappers.mapCategory(l10n, mission.category),
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(mission.category),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: _getAuthColor(mission.authType).withAlpha(20),
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        L10nMappers.mapMissionAuthType(l10n, mission.authType),
                        style: TextStyle(
                          fontSize: 11.0,
                          fontWeight: FontWeight.bold,
                          color: _getAuthColor(mission.authType),
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(color: Colors.green.withAlpha(80), width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle, size: 12.0, color: Colors.green),
                            const SizedBox(width: 4.0),
                            Text(
                              l10n.statusCompleted,
                              style: const TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (mission.title.contains('[QA') || mission.description.contains('[QA')) ...[
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
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.textSecondary : AppColors.textPrimary,
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

                // Reward points & Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.grey.withAlpha(25)
                            : AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        '+ ${mission.points} P',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? AppColors.textSecondary : AppColors.primary,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: isCompleted
                          ? null
                          : onActionButtonTap ??
                              () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MissionDetailScreen(missionId: mission.id),
                                  ),
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCompleted ? Colors.grey.shade300 : AppColors.primary,
                        foregroundColor: isCompleted ? Colors.grey.shade600 : Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isCompleted ? l10n.statusCompleted : l10n.missionStartAction,
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

  IconData _getAuthIcon(String authType) {
    final type = authType.toUpperCase();
    if (type.contains('PHOTO')) {
      return Icons.camera_alt_outlined;
    } else if (type.contains('QR')) {
      return Icons.qr_code_scanner_rounded;
    } else if (type.contains('ROUTE') || type.contains('TRAIL') || type.contains('EXPLORE')) {
      return Icons.explore_outlined;
    }
    return Icons.place_outlined;
  }

  Color _getAuthColor(String authType) {
    final type = authType.toUpperCase();
    if (type.contains('PHOTO')) {
      return Colors.purple;
    } else if (type.contains('QR')) {
      return Colors.teal;
    } else if (type.contains('ROUTE') || type.contains('TRAIL') || type.contains('EXPLORE')) {
      return Colors.indigo;
    }
    return Colors.blue;
  }
}
