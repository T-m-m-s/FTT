import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/media_type.dart';
import '../models/library_entry.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/stats_charts.dart';

class StatisticsScreen extends StatelessWidget {
  final Function(LibraryEntry)? onOpenDetail;

  const StatisticsScreen({super.key, this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final entries = db.currentLibraryFiltered;
        final completed = db.completedItems;
        final playing = db.playingItems;
        final backlog = db.backlogItems;
        final sessions = db.currentSessionsFiltered;
        final isGame = db.activeMediaFilter == MediaType.game;

        final totalMinutes = entries.fold<int>(0, (sum, e) => sum + e.timeSpentMinutes);
        final totalHours = (totalMinutes / 60).round();

        // Top played games
        final topPlayed = db.topPlayedGames(limit: 5);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistics',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  isGame ? 'Gaming Insights & Analytics' : 'Cinema Watch Insights',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Text(
                  DateFormat('yyyy').format(DateTime.now()),
                  style: const TextStyle(
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
              // Top 4 Metric KPI Cards (2x2 Grid)
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
                    title: isGame ? 'Total Games' : 'Total Media',
                    value: '${entries.length}',
                    icon: isGame ? Icons.sports_esports_rounded : Icons.movie_outlined,
                    accentColor: AppColors.accentCyan,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMetricCard(
                    title: isGame ? 'Finished' : 'Watched',
                    value: '${completed.length}',
                    icon: Icons.check_circle_outline_rounded,
                    accentColor: AppColors.statusCompleted,
                  ),
                  const SizedBox(width: 12),
                  _buildMetricCard(
                    title: isGame ? 'Playing Now' : 'Watching',
                    value: '${playing.length}',
                    icon: Icons.play_circle_outline_rounded,
                    accentColor: AppColors.accentOrange,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Most Played Games Leaderboard
              _buildTopPlayedSection(context, topPlayed),
              const SizedBox(height: 24),

              // Library Status Breakdown
              _buildLibraryDistribution(
                total: entries.length,
                playing: playing.length,
                completed: completed.length,
                backlog: backlog.length,
                isGame: isGame,
              ),
              const SizedBox(height: 24),

              // Real Play Activity & History Calendar
              _buildActivitySection(context, sessions, entries),
              const SizedBox(height: 24),

              // Ratings Distribution
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopPlayedSection(BuildContext context, List<LibraryEntry> topPlayed) {
    if (topPlayed.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: const Column(
          children: [
            Icon(Icons.leaderboard_rounded, size: 36, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text(
              'No Playtime Logged Yet',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Sync Steam or log play sessions to view your most played games.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final maxMinutes = topPlayed.first.timeSpentMinutes;

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
            children: [
              const Icon(Icons.leaderboard_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Most Played Games',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Top ${topPlayed.length}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...topPlayed.asMap().entries.map((item) {
            final rank = item.key + 1;
            final entry = item.value;
            final hours = (entry.timeSpentMinutes / 60).toStringAsFixed(1);
            final ratio = maxMinutes > 0 ? (entry.timeSpentMinutes / maxMinutes).clamp(0.05, 1.0) : 0.05;

            // Medal colors
            Color medalColor = AppColors.textMuted;
            if (rank == 1) medalColor = const Color(0xFFFFD700); // Gold
            if (rank == 2) medalColor = const Color(0xFFC0C0C0); // Silver
            if (rank == 3) medalColor = const Color(0xFFCD7F32); // Bronze

            return InkWell(
              onTap: () => onOpenDetail?.call(entry),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    // Rank Badge
                    Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: medalColor.withValues(alpha: rank <= 3 ? 0.2 : 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: medalColor.withValues(alpha: rank <= 3 ? 0.8 : 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          color: rank <= 3 ? medalColor : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Game Poster
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        entry.mediaItem.posterUrl,
                        width: 36,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 36,
                          height: 48,
                          color: AppColors.surfaceElevated,
                          child: const Icon(Icons.broken_image, size: 16, color: AppColors.textMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Game Title & Relative Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.mediaItem.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${hours}h',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 5,
                              backgroundColor: AppColors.surfaceElevated,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                rank == 1 ? AppColors.primaryLight : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLibraryDistribution({
    required int total,
    required int playing,
    required int completed,
    required int backlog,
    required bool isGame,
  }) {
    if (total == 0) return const SizedBox.shrink();

    final playingPct = (playing / total);
    final completedPct = (completed / total);
    final backlogPct = (backlog / total);

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
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.accentCyan, size: 20),
              SizedBox(width: 8),
              Text(
                'Library Breakdown',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Multi-segmented bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  if (playing > 0)
                    Flexible(
                      flex: (playingPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.primary),
                    ),
                  if (completed > 0)
                    Flexible(
                      flex: (completedPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.statusCompleted),
                    ),
                  if (backlog > 0)
                    Flexible(
                      flex: (backlogPct * 100).round().clamp(1, 100),
                      child: Container(color: AppColors.accentOrange),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Playing', playing, AppColors.primary, (playingPct * 100).round()),
              _buildLegendItem('Completed', completed, AppColors.statusCompleted, (completedPct * 100).round()),
              _buildLegendItem('Backlog', backlog, AppColors.accentOrange, (backlogPct * 100).round()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, Color color, int percent) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: $count',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Text(
              '$percent%',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivitySection(
    BuildContext context,
    List<PlaySession> sessions,
    List<LibraryEntry> entries,
  ) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: const Column(
          children: [
            Icon(Icons.calendar_today_rounded, size: 36, color: AppColors.textMuted),
            SizedBox(height: 10),
            Text(
              'No Play History Logged',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text(
              'Connect Steam or log sessions to see monthly play activity.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    // Group sessions by Month (e.g. "Sep 2026", "Aug 2026")
    final Map<String, List<PlaySession>> monthlySessions = {};
    for (final s in sessions) {
      final key = DateFormat('MMM yyyy').format(s.date);
      monthlySessions.putIfAbsent(key, () => []).add(s);
    }

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
                  Icon(Icons.calendar_month_rounded, color: AppColors.statusCompleted, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Monthly Activity',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Text(
                '${sessions.length} sessions',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...monthlySessions.entries.take(5).map((entry) {
            final month = entry.key;
            final monthList = entry.value;
            final monthMinutes = monthList.fold<int>(0, (sum, s) => sum + s.durationMinutes);
            final monthHours = (monthMinutes / 60).toStringAsFixed(1);

            // Distinct game covers in this month
            final uniqueCovers = <String>{};
            for (final s in monthList) {
              uniqueCovers.add(s.mediaPoster);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          month,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${monthHours}h',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 42,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: uniqueCovers.take(6).map((coverUrl) {
                          return Container(
                            width: 32,
                            height: 42,
                            margin: const EdgeInsets.only(right: 6),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                coverUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: AppColors.surfaceElevated,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${monthList.length} ${monthList.length == 1 ? "session" : "sessions"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
