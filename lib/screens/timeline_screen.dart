import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/timeline_view.dart';
import 'steam_sync_screen.dart';

class TimelineScreen extends StatelessWidget {
  final Function(LibraryEntry)? onOpenDetail;

  const TimelineScreen({super.key, this.onOpenDetail});

  void _handleSessionTap(BuildContext context, DatabaseService db, PlaySession session) {
    final entry = db.library.firstWhere(
      (e) => e.mediaId == session.mediaId,
      orElse: () => LibraryEntry(
        id: 'entry_${session.mediaId}',
        mediaId: session.mediaId,
        mediaItem: MediaItem(
          id: session.mediaId,
          title: session.mediaTitle,
          mediaType: session.mediaType,
          posterUrl: session.mediaPoster,
          backdropUrl: session.mediaPoster,
          releaseYear: 2024,
          releaseDateFormatted: 'Recent',
          genres: ['Game'],
          synopsis: '',
          communityRating: 8.0,
          creator: '',
        ),
        status: LibraryStatus.playing,
        platform: session.platform ?? 'PC - Steam',
      ),
    );
    onOpenDetail?.call(entry);
  }

  void _showLogSessionSheet(BuildContext context, DatabaseService db) {
    final isGame = db.activeMediaFilter == MediaType.game;
    final library = db.currentLibraryFiltered;
    if (library.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isGame
                ? 'Please add or sync games to your library before logging sessions.'
                : 'Please add films or series to your watchlist before logging sessions.',
          ),
          backgroundColor: AppColors.surfaceElevated,
        ),
      );
      return;
    }

    LibraryEntry selectedEntry = library.first;
    final defaultRuntime = selectedEntry.mediaItem.runtimeMinutes;
    int minutes = (defaultRuntime != null && defaultRuntime > 0)
        ? defaultRuntime
        : (isGame ? 60 : (selectedEntry.mediaItem.mediaType == MediaType.tvShow ? 45 : 120));
    final notesController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isGame ? 'Log Play Session' : 'Log Watch Session',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),

              // Media Selector
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<LibraryEntry>(
                    value: selectedEntry,
                    isExpanded: true,
                    dropdownColor: AppColors.surfaceElevated,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    items: library.map((e) {
                      return DropdownMenuItem(
                        value: e,
                        child: Text(
                          e.mediaItem.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() {
                          selectedEntry = val;
                          final rt = val.mediaItem.runtimeMinutes;
                          if (rt != null && rt > 0) {
                            minutes = rt;
                          }
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Duration Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Duration', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  Text(
                    '${minutes ~/ 60}h ${minutes % 60}m',
                    style: const TextStyle(color: AppColors.primaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Slider(
                value: minutes.toDouble().clamp(15.0, 360.0),
                min: 15,
                max: 360,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceCard,
                onChanged: (val) => setSheetState(() => minutes = val.toInt()),
              ),
              const SizedBox(height: 10),

              // Session notes
              TextField(
                controller: notesController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: isGame ? 'Notes / milestone reached...' : 'Episode / watch notes...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final session = PlaySession(
                      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                      mediaId: selectedEntry.mediaId,
                      mediaTitle: selectedEntry.mediaItem.title,
                      mediaPoster: selectedEntry.mediaItem.posterUrl,
                      mediaType: selectedEntry.mediaItem.mediaType,
                      date: DateTime.now(),
                      durationMinutes: minutes,
                      platform: selectedEntry.platform,
                      notes: notesController.text.trim(),
                    );
                    db.addSession(session);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Logged ${session.formattedDuration} of ${selectedEntry.mediaItem.title}'),
                        backgroundColor: AppColors.primary,
                      ),
                    );
                  },
                  child: const Text(
                    'Log Session',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
                icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.primaryLight),
                tooltip: 'Log Session',
                onPressed: () => _showLogSessionSheet(context, db),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: TimelineView(
            sessions: sessions,
            onSessionTap: (session) => _handleSessionTap(context, db, session),
            onConnectSteam: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SteamSyncScreen()),
            ),
            onLogSession: () => _showLogSessionSheet(context, db),
          ),
        );
      },
    );
  }
}
