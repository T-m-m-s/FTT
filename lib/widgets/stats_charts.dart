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

class GenreDistributionChart extends StatefulWidget {
  final List<LibraryEntry> entries;
  final bool isGame;

  const GenreDistributionChart({
    super.key,
    required this.entries,
    required this.isGame,
  });

  @override
  State<GenreDistributionChart> createState() => _GenreDistributionChartState();
}

class _GenreDistributionChartState extends State<GenreDistributionChart> {
  bool _sortByTime = false;

  static const List<List<Color>> _gradientGradients = [
    [Color(0xFF6C5CE7), Color(0xFF38BDF8)],
    [Color(0xFF00B894), Color(0xFF00CEC9)],
    [Color(0xFFFF7675), Color(0xFFFDCB6E)],
    [Color(0xFF8C7AE6), Color(0xFFE84393)],
    [Color(0xFFFF7A45), Color(0xFFFFBE76)],
    [Color(0xFF00D2D3), Color(0xFF0984E3)],
  ];

  String _formatDuration(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, int> titleCounts = {};
    final Map<String, int> timeCounts = {};

    for (final e in widget.entries) {
      for (final rawGenre in e.mediaItem.genres) {
        final g = rawGenre.trim();
        if (g.isEmpty) continue;
        titleCounts[g] = (titleCounts[g] ?? 0) + 1;
        timeCounts[g] = (timeCounts[g] ?? 0) + e.timeSpentMinutes;
      }
    }

    if (titleCounts.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.category_outlined,
              size: 36,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 10),
            const Text(
              'No Genre Data Available',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isGame
                  ? 'Add games with genres to see your gaming breakdown.'
                  : 'Add movies or TV series to see your cinema genre breakdown.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Sort genres
    final sortedGenres = titleCounts.keys.toList()
      ..sort((a, b) {
        if (_sortByTime) {
          final cmp = (timeCounts[b] ?? 0).compareTo(timeCounts[a] ?? 0);
          if (cmp != 0) return cmp;
          return (titleCounts[b] ?? 0).compareTo(titleCounts[a] ?? 0);
        } else {
          final cmp = (titleCounts[b] ?? 0).compareTo(titleCounts[a] ?? 0);
          if (cmp != 0) return cmp;
          return (timeCounts[b] ?? 0).compareTo(timeCounts[a] ?? 0);
        }
      });

    final topGenres = sortedGenres.take(6).toList();
    final int maxVal = _sortByTime
        ? topGenres.fold<int>(1, (max, g) => (timeCounts[g] ?? 0) > max ? timeCounts[g]! : max)
        : topGenres.fold<int>(1, (max, g) => (titleCounts[g] ?? 0) > max ? titleCounts[g]! : max);

    return Container(
      padding: const EdgeInsets.all(20),
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
              Row(
                children: [
                  const Icon(Icons.pie_chart_outline_rounded, color: AppColors.primaryLight, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    widget.isGame ? 'Top Game Genres' : 'Top Cinema Genres',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              // Filter Toggle: Titles vs Time
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _sortByTime = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: !_sortByTime ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Titles',
                          style: TextStyle(
                            color: !_sortByTime ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _sortByTime = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _sortByTime ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Time',
                          style: TextStyle(
                            color: _sortByTime ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...topGenres.asMap().entries.map((item) {
            final idx = item.key;
            final genre = item.value;
            final count = titleCounts[genre] ?? 0;
            final minutes = timeCounts[genre] ?? 0;
            final colors = _gradientGradients[idx % _gradientGradients.length];

            final double fraction = _sortByTime
                ? (maxVal > 0 ? minutes / maxVal : 0.0)
                : (maxVal > 0 ? count / maxVal : 0.0);

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: colors.first,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            genre,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _sortByTime
                            ? '${_formatDuration(minutes)} ($count ${count == 1 ? (widget.isGame ? 'game' : 'title') : (widget.isGame ? 'games' : 'titles')})'
                            : '$count ${count == 1 ? (widget.isGame ? 'game' : 'title') : (widget.isGame ? 'games' : 'titles')} • ${_formatDuration(minutes)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction.clamp(0.04, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
