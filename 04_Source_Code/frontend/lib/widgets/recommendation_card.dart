import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/recommendation.dart';

class RecommendationCard extends StatelessWidget {
  final Recommendation recommendation;
  final VoidCallback? onTap;

  const RecommendationCard({
    super.key,
    required this.recommendation,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.0,
      margin: const EdgeInsets.only(right: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5), // 0.02 opacity equivalent
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Placeholder Image
                Container(
                  height: 120.0,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primaryLight.withAlpha(204), // 0.8 opacity
                        AppColors.secondaryLight.withAlpha(204),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(recommendation.category),
                      size: 40.0,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Text details
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category & Rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(26), // 0.1 opacity
                              borderRadius: BorderRadius.circular(4.0),
                            ),
                            child: Text(
                              recommendation.category,
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
                                size: 14.0,
                              ),
                              const SizedBox(width: 2.0),
                              Text(
                                recommendation.rating.toString(),
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
                      const SizedBox(height: 8.0),
                      // Name
                      Text(
                        recommendation.name,
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4.0),
                      // Description
                      Text(
                        recommendation.description,
                        style: const TextStyle(
                          fontSize: 11.0,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8.0),
                      // Tags
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 4.0,
                        children: recommendation.tags.take(2).map((tag) {
                          return Text(
                            '#$tag',
                            style: const TextStyle(
                              fontSize: 10.0,
                              color: AppColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        }).toList(),
                      ),
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
      case '볼거리':
        return Icons.visibility;
      case '맛집':
        return Icons.local_dining;
      default:
        return Icons.place;
    }
  }
}
