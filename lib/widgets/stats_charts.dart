import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../theme/app_colors.dart';

class RatingsDistributionChart extends StatelessWidget {
  final List<LibraryEntry> entries;

  const RatingsDistributionChart({
    super.key,
    required this.entries,
  });

  @override
  Widget build(BuildContext context) {
    // Count ratings from 1 to 10
    final Map<int, int> counts = {for (var i = 1; i <= 10; i++) i: 0};
    int totalRated = 0;
    double sumRatings = 0.0;

    for (final e in entries) {
      if (e.userRating != null && e.userRating! > 0) {
        final score = e.userRating!.round().clamp(1, 10);
        counts[score] = (counts[score] ?? 0) + 1;
        totalRated++;
        sumRatings += e.userRating!;
      }
    }

    final double avgRating = totalRated > 0 ? (sumRatings / totalRated) : 0.0;
    final int maxCount = counts.values.fold(0, (max, c) => c > max ? c : max);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.star_rate_rounded, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ratings Distribution',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  'All Time',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Average display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                avgRating > 0 ? avgRating.toStringAsFixed(2) : '--',
                style: const TextStyle(
                  color: AppColors.primaryLight,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                ' / 10',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$totalRated rated',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // The 10 Bars Chart
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (index) {
                final score = index + 1;
                final count = counts[score] ?? 0;
                final barHeight = maxCount > 0 ? (count / maxCount) * 90.0 : 0.0;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Count number label above bar
                    if (count > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 16),

                    // Bar
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 18,
                      height: barHeight > 6 ? barHeight : 6,
                      decoration: BoxDecoration(
                        gradient: count > 0
                            ? const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primaryLight,
                                  AppColors.primaryDark,
                                ],
                              )
                            : null,
                        color: count == 0 ? AppColors.surfaceElevated : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Score label below bar (1, 2, ... 10)
                    Text(
                      '$score',
                      style: TextStyle(
                        color: score == 10
                            ? AppColors.primaryLight
                            : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
