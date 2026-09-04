import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/play_session.dart';
import '../theme/app_colors.dart';

class TimelineView extends StatelessWidget {
  final List<PlaySession> sessions;
  final Function(PlaySession)? onSessionTap;

  const TimelineView({
    super.key,
    required this.sessions,
    this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 12),
            const Text(
              'No play sessions recorded yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Group sessions by Day
    final Map<String, List<PlaySession>> grouped = {};
    for (final session in sessions) {
      final key = DateFormat('yyyy-MM-dd').format(session.date);
      grouped.putIfAbsent(key, () => []).add(session);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 120, left: 16, right: 16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final key = sortedKeys[index];
        final daySessions = grouped[key]!;
        final firstDate = daySessions.first.date;

        return _buildDaySection(context, firstDate, daySessions);
      },
    );
  }

  Widget _buildDaySection(
    BuildContext context,
    DateTime date,
    List<PlaySession> daySessions,
  ) {
    final dayNum = DateFormat('d').format(date);
    final dayName = DateFormat('E').format(date);
    final fullDate = DateFormat('EEEE, MMMM d, y').format(date);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Timeline Track with Badge
          SizedBox(
            width: 50,
            child: Column(
              children: [
                // The rounded Date Badge on the line
                Container(
                  width: 44,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        dayNum,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dayName,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Continuous vertical line down
                Expanded(
                  child: Container(
                    width: 2,
                    color: AppColors.borderSubtle.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right Content: Date Title + Session Cards
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 8),
                  child: Text(
                    fullDate,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ...daySessions.map((s) => _buildSessionCard(context, s)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(BuildContext context, PlaySession session) {
    return GestureDetector(
      onTap: () => onSessionTap?.call(session),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.borderSubtle.withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Poster
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 70,
                child: Image.network(
                  session.mediaPoster,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.surfaceCard,
                    child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    session.mediaTitle,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  if (session.isCompletion) ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 14,
                          color: AppColors.statusCompleted,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '1 playthrough completed',
                          style: TextStyle(
                            color: AppColors.statusCompleted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (session.rating != null) ...[
                      const SizedBox(height: 4),
                      _buildRatingStars(session.rating!),
                    ],
                  ] else ...[
                    Text(
                      '1 session  •  ${session.formattedDuration}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],

                  if (session.platform != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      session.platform!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    final starCount = (rating.round()).clamp(1, 10);
    return Row(
      children: [
        ...List.generate(
          starCount,
          (i) => const Padding(
            padding: EdgeInsets.only(right: 2.0),
            child: Icon(
              Icons.star_rounded,
              color: AppColors.primaryLight,
              size: 13,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(0),
          style: const TextStyle(
            color: AppColors.primaryLight,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
