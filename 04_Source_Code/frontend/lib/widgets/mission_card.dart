import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/mission.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';

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
    final rewardText = l10n.rewardLabel;

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
            padding: const EdgeInsets.all(14.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 340;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ROW 1: Category Icon + Category Tag + Auth Badge & Points
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6.0,
                            runSpacing: 4.0,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6.0),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(mission.category).withAlpha(26),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getCategoryIcon(mission.category),
                                  color: _getCategoryColor(mission.category),
                                  size: 18.0,
                                ),
                              ),
                              Text(
                                L10nMappers.mapCategory(l10n, mission.category),
                                style: TextStyle(
                                  color: _getCategoryColor(mission.category),
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  L10nMappers.mapMissionAuthType(l10n, mission.authType),
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (mission.title.contains('[QA') || mission.description.contains('[QA')) ...[
                                const SizedBox(width: 4.0),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                    vertical: 1.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade800,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: const Text(
                                    '테스트용',
                                    style: TextStyle(
                                      fontSize: 9.0,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          '+${mission.points} P',
                          style: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),

                    // ROW 2: Title
                    Text(
                      mission.title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                      softWrap: true,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),

                    // ROW 3: Description
                    Text(
                      mission.description,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      softWrap: true,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),

                    // ROW 4: Reward & Action Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: mission.reward.isNotEmpty
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    '🎁 $rewardText: ${mission.reward}',
                                    style: const TextStyle(
                                      fontSize: 10.0,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        const SizedBox(width: 8.0),
                        ElevatedButton(
                          onPressed: onActionButtonTap ?? () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isNarrow ? 10.0 : 14.0,
                              vertical: 6.0,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                          ),
                          child: Text(
                            _getActionButtonText(l10n, mission.authType),
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
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
    } else if (type.contains('PHOTO') || type.contains('사진')) {
      return l10n.missionAuthActionPhoto;
    }
    return l10n.challengeButton;
  }

  IconData _getCategoryIcon(String category) {
    final cat = category.toUpperCase();
    if (cat.contains('PHOTO') || cat.contains('사진')) {
      return Icons.camera_alt;
    } else if (cat.contains('GPS') || cat.contains('LOCATION')) {
      return Icons.location_on;
    } else if (cat.contains('QR')) {
      return Icons.qr_code;
    }
    return Icons.assignment;
  }

  Color _getCategoryColor(String category) {
    final cat = category.toUpperCase();
    if (cat.contains('PHOTO') || cat.contains('사진')) {
      return AppColors.accent;
    } else if (cat.contains('GPS') || cat.contains('LOCATION')) {
      return AppColors.primary;
    } else if (cat.contains('QR')) {
      return AppColors.secondary;
    }
    return AppColors.textSecondary;
  }
}
