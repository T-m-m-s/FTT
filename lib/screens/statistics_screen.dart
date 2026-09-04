import 'package:flutter/material.dart';
import '../models/media_type.dart';
import '../models/library_entry.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stats_charts.dart';

class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final entries = db.currentLibraryFiltered;
        final completed = db.completedItems;
        final playing = db.playingItems;
        final isGame = db.activeMediaFilter == MediaType.game;

        final totalMinutes = entries.fold<int>(0, (sum, e) => sum + e.timeSpentMinutes);
        final totalHours = totalMinutes ~/ 60;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('Statistics'),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Text(
                  '2026',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              // Top KPI Summary Cards
              Row(
                children: [
                  _buildMetricCard(
                    title: 'Time Tracked',
                    value: '${totalHours}h',
                    icon: Icons.timer_outlined,
                    accentColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: isGame ? 'Finished' : 'Watched',
                    value: '${completed.length}',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppColors.statusCompleted,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: 'In Progress',
                    value: '${playing.length}',
                    icon: Icons.play_circle_outline_rounded,
                    accentColor: AppColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Calendar Heatmap / Posters Grid (Screenshot 1 Screen 1)
              _buildMonthlyGrid(entries),
              const SizedBox(height: 20),

              // Ratings Distribution Bar Chart (Screenshot 1 Screen 1)
              RatingsDistributionChart(entries: entries),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accentColor, size: 20),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGrid(List<LibraryEntry> entries) {
    final months = ['APR', 'MAY', 'JUN', 'JUL', 'AUG'];

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activity Calendar',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.calendar_month_rounded, color: AppColors.textSecondary, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          ...months.map((month) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      month,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(6, (i) {
                        final entryIndex = (i + month.hashCode) % (entries.isEmpty ? 1 : entries.length);
                        final hasPoster = entries.isNotEmpty && (i < 4);

                        return Container(
                          width: 38,
                          height: 38,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: AppColors.borderSubtle.withValues(alpha: 0.4),
                            ),
                          ),
                          child: hasPoster
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    entries[entryIndex].mediaItem.posterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                                  ),
                                )
                              : null,
                        );
                      }),
                    ),
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
