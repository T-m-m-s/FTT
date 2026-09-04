import 'package:flutter/material.dart';
import '../models/media_type.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/timeline_view.dart';

class TimelineScreen extends StatelessWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final sessions = db.currentSessionsFiltered;
        final isGame = db.activeMediaFilter == MediaType.game;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isGame ? 'Play History' : 'Watch History',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${sessions.length} sessions logged',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: TimelineView(sessions: sessions),
        );
      },
    );
  }
}
