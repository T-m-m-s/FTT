import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../services/update_service.dart';
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
        final currentLibrary = db.currentLibraryFiltered;
        final playing = db.playingItems;
        final backlog = db.backlogItems;
        final topPlayed = db.topPlayedGames(limit: 10);

        // Dynamic Hero Selection from real user library:
        // 1. Most recently active playing game
        // 2. Highest playtime game
        // 3. Null if library is empty
        LibraryEntry? heroEntry;
        if (playing.isNotEmpty) {
          heroEntry = playing.first;
        } else if (currentLibrary.isNotEmpty) {
          heroEntry = (List<LibraryEntry>.from(currentLibrary)
            ..sort((a, b) => b.timeSpentMinutes.compareTo(a.timeSpentMinutes))).first;
        }

        return CustomScrollView(
          slivers: [
            // Ambient Hero Header or Welcome Banner
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  if (heroEntry != null)
                    HeroBanner(
                      item: heroEntry.mediaItem,
                      onTap: () => onOpenDetail(heroEntry!),
                    )
                  else
                    _buildWelcomeBanner(context, isGame),

                  // Top Action Bar (Mode Switcher Pill + Steam Sync)
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Mode Switcher Pill (Games vs Cinema)
                        _buildModeSwitcher(context, db),

                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                            const SizedBox(width: 8),
                            // Check for Updates Button
                            GestureDetector(
                              onTap: () => UpdateService.checkUpdateManually(context),
                              child: Tooltip(
                                message: 'Check for Updates',
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.system_update_rounded,
                                    size: 16,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // If library is completely empty, show friendly getting started card
            if (currentLibrary.isEmpty)
              SliverToBoxAdapter(
                child: _buildEmptyOnboardingCard(context),
              ),

            // "Playing Now" / "Watching Now" Section
            if (playing.isNotEmpty) ...[
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
                      Text(
                        '${playing.length} active',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
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
            ],

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
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceElevated,
                                child: const Icon(Icons.sports_esports_outlined, color: AppColors.textMuted),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // "Most Played Games" Section (Real User Games)
            if (topPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Text(
                            'Most Played Games',
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
                      Text(
                        '${topPlayed.length} games',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 165,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: topPlayed.length,
                    itemBuilder: (context, index) {
                      final entry = topPlayed[index];
                      final hours = (entry.timeSpentMinutes / 60).toStringAsFixed(1);

                      return GestureDetector(
                        onTap: () => onOpenDetail(entry),
                        child: Container(
                          width: 105,
                          margin: const EdgeInsets.only(right: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    entry.mediaItem.posterUrl,
                                    width: 105,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.surfaceElevated,
                                      child: const Icon(Icons.broken_image, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.mediaItem.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${hours}h played',
                                style: const TextStyle(
                                  color: AppColors.primaryLight,
                                  fontSize: 10,
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
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: 120),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWelcomeBanner(BuildContext context, bool isGame) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.35),
            AppColors.surfaceCard.withValues(alpha: 0.5),
            AppColors.background,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 70,
        left: 24,
        right: 24,
        bottom: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Icon(
              isGame ? Icons.sports_esports_rounded : Icons.movie_outlined,
              size: 36,
              color: AppColors.primaryLight,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isGame ? 'FreeTimeTracker' : 'Cinema Tracker',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your personal gaming library, timeline, and analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOnboardingCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          const Icon(Icons.cloud_sync_rounded, color: AppColors.primaryLight, size: 36),
          const SizedBox(height: 12),
          const Text(
            'Connect Your Steam Library',
            style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Automatically sync all your Steam games, playtime hours, and last-played history without any manual entry.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_sync_rounded, size: 18),
            label: const Text('Connect Steam Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B2838),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SteamSyncScreen()),
            ),
          ),
        ],
      ),
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

