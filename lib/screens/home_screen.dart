import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../services/sample_data.dart';
import '../theme/app_colors.dart';
import '../widgets/hero_banner.dart';
import '../widgets/playing_now_card.dart';
import 'steam_sync_screen.dart';

class HomeScreen extends StatelessWidget {
  final Function(LibraryEntry) onOpenDetail;

  const HomeScreen({super.key, required this.onOpenDetail});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final isGame = db.activeMediaFilter == MediaType.game;
        final playing = db.playingItems;
        final backlog = db.backlogItems;
        final releases = isGame ? SampleData.sampleGames : SampleData.sampleCinema;
        final heroItem = isGame ? SampleData.sampleGames[0] : SampleData.sampleCinema[0];

        return CustomScrollView(
          slivers: [
            // Ambient Hero Header
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  HeroBanner(
                    item: heroItem,
                    onTap: () {
                      final entry = db.library.firstWhere(
                        (e) => e.mediaId == heroItem.id,
                        orElse: () => LibraryEntry(
                          id: 'entry_${heroItem.id}',
                          mediaId: heroItem.id,
                          mediaItem: heroItem,
                          status: LibraryStatus.playing,
                        ),
                      );
                      onOpenDetail(entry);
                    },
                  ),

                  // Top Action Bar (Mode Pill + Steam Sync)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mode Switcher Pill (Games vs Cinema)
                        _buildModeSwitcher(context, db),

                        // Steam Sync Button
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SteamSyncScreen()),
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1B2838).withValues(alpha: 0.85),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: db.steamProfile != null
                                    ? AppColors.statusCompleted.withValues(alpha: 0.6)
                                    : Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cloud_sync_rounded,
                                  size: 16,
                                  color: db.steamProfile != null
                                      ? AppColors.statusCompleted
                                      : Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  db.steamProfile != null ? 'Steam Connected' : 'Steam Sync',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // "Playing Now" / "Watching Now" Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isGame ? 'Playing Now' : 'Watching Now',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
            ),

            // Horizontal Scroll of Playing Now Cards
            SliverToBoxAdapter(
              child: SizedBox(
                height: 195,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playing.length,
                  itemBuilder: (context, index) {
                    final entry = playing[index];
                    return PlayingNowCard(
                      entry: entry,
                      onTap: () => onOpenDetail(entry),
                      onLogSession: () {
                        // Quick 45-min session
                        final session = PlaySession(
                          id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                          mediaId: entry.mediaId,
                          mediaTitle: entry.mediaItem.title,
                          mediaPoster: entry.mediaItem.posterUrl,
                          mediaType: entry.mediaItem.mediaType,
                          date: DateTime.now(),
                          durationMinutes: 45,
                          platform: entry.platform,
                          notes: 'Quick session logged from Home',
                        );
                        db.addSession(session);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Logged 45 min for ${entry.mediaItem.title}'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),

            // "Up Next" / "Backlog" Section
            if (backlog.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isGame ? 'Up Next (Backlog)' : 'Watchlist',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        '${backlog.length} items',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: backlog.length,
                    itemBuilder: (context, index) {
                      final entry = backlog[index];
                      return GestureDetector(
                        onTap: () => onOpenDetail(entry),
                        child: Container(
                          width: 95,
                          margin: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              entry.mediaItem.posterUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceElevated),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // "New & Notable Releases" Carousel (Matching Screenshot 1 Screen 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                child: const Row(
                  children: [
                    Text(
                      'New Releases',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: releases.length,
                  itemBuilder: (context, index) {
                    final item = releases[index];
                    return GestureDetector(
                      onTap: () {
                        final entry = db.library.firstWhere(
                          (e) => e.mediaId == item.id,
                          orElse: () => LibraryEntry(
                            id: 'entry_${item.id}',
                            mediaId: item.id,
                            mediaItem: item,
                            status: LibraryStatus.wishlist,
                          ),
                        );
                        onOpenDetail(entry);
                      },
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  item.posterUrl,
                                  width: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceElevated),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        );
      },
    );
  }

  Widget _buildModeSwitcher(BuildContext context, DatabaseService db) {
    final isGame = db.activeMediaFilter == MediaType.game;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => db.setMediaFilter(MediaType.game),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isGame ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sports_esports_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Games',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: isGame ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: () => db.setMediaFilter(MediaType.movie),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !isGame ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.movie_filter_rounded, size: 14, color: Colors.white),
                  const SizedBox(width: 5),
                  Text(
                    'Cinema',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: !isGame ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
