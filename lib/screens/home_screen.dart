import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/hero_banner.dart';
import '../widgets/playing_now_card.dart';
import 'steam_sync_screen.dart';
import 'search_screen.dart';
import 'settings_screen.dart';

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

                  // Top Action Bar (Mode Switcher Pill + Steam Sync / Cinema Discover)
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
                            // Manage Shelves Button
                            GestureDetector(
                              onTap: () => _showManageShelvesSheet(context, db),
                              child: Tooltip(
                                message: 'Manage Home Shelves',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: AppColors.primaryLight,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Settings & Connections Button
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const SettingsScreen()),
                              ),
                              child: Tooltip(
                                message: 'Settings & Connections',
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated.withValues(alpha: 0.9),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.settings_rounded,
                                    size: 18,
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
                child: _buildEmptyOnboardingCard(context, isGame),
              ),

            // Dynamic Home Shelves based on User Categories
            for (final cat in db.homeCategories) ...[
              Builder(
                builder: (context) {
                  final catEntries = db.getEntriesForCategory(cat.id);
                  final entries = (cat.id == 'cat_now_playing' && catEntries.isEmpty)
                      ? playing
                      : catEntries;

                  if (entries.isEmpty) {
                    return const SliverToBoxAdapter(child: SizedBox.shrink());
                  }

                  final isNowPlaying = cat.id == 'cat_now_playing';
                  final title = isNowPlaying
                      ? (isGame ? 'Playing Now' : 'Watching Now')
                      : cat.name;

                  return SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showManageShelvesSheet(context, db),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceElevated,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppColors.borderSubtle),
                                      ),
                                      child: const Icon(
                                        Icons.tune_rounded,
                                        size: 13,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${entries.length} ${entries.length == 1 ? "item" : "items"}',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 195,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              final entry = entries[index];
                              return PlayingNowCard(
                                entry: entry,
                                onTap: () => onOpenDetail(entry),
                                onLogSession: () {
                                  final isTv = entry.mediaItem.mediaType == MediaType.tvShow;
                                  final isMovie = entry.mediaItem.mediaType == MediaType.movie;
                                  final movieRuntime = entry.mediaItem.runtimeMinutes;
                                  final int logDuration = (isMovie && movieRuntime != null && movieRuntime > 0)
                                      ? movieRuntime
                                      : 45;
                                  final session = PlaySession(
                                    id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                                    mediaId: entry.mediaId,
                                    mediaTitle: entry.mediaItem.title,
                                    mediaPoster: entry.mediaItem.posterUrl,
                                    mediaType: entry.mediaItem.mediaType,
                                    date: DateTime.now(),
                                    durationMinutes: logDuration,
                                    platform: entry.platform,
                                    notes: isTv
                                        ? 'Episode logged from Home'
                                        : (isMovie ? 'Movie watch session logged from Home' : 'Quick session logged from Home'),
                                    isCompletion: isMovie,
                                  );
                                  db.addSession(session);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isTv
                                            ? 'Logged episode for ${entry.mediaItem.title} (${logDuration}m)'
                                            : (isMovie
                                                ? 'Marked as watched: ${entry.mediaItem.title} (${logDuration}m)'
                                                : 'Logged $logDuration min for ${entry.mediaItem.title}'),
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
                                child: Icon(
                                  isGame ? Icons.sports_esports_outlined : Icons.movie_outlined,
                                  color: AppColors.textMuted,
                                ),
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

            // "Most Played Games" / "Most Watched Cinema" Section (Real User Data)
            if (topPlayed.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            isGame ? 'Most Played Games' : 'Most Watched Cinema',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
                        ],
                      ),
                      Text(
                        '${topPlayed.length} ${isGame ? 'games' : 'titles'}',
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
                                      child: Icon(
                                        isGame ? Icons.broken_image : Icons.movie_outlined,
                                        color: AppColors.textMuted,
                                      ),
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
                                isGame ? '${hours}h played' : '${hours}h watched',
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
          Text(
            isGame
                ? 'Your personal gaming library, timeline, and analytics.'
                : 'Your personal movie and TV series library, timeline, and analytics.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyOnboardingCard(BuildContext context, bool isGame) {
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
          Icon(
            isGame ? Icons.cloud_sync_rounded : Icons.movie_creation_outlined,
            color: AppColors.primaryLight,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            isGame ? 'Connect Your Steam Library' : 'Start Your Cinema Collection',
            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            isGame
                ? 'Automatically sync all your Steam games, playtime hours, and last-played history without any manual entry.'
                : 'Discover movies and TV series, track your watchlists, and log watch sessions and episodes effortlessly.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          if (isGame)
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
            )
          else
            ElevatedButton.icon(
              icon: const Icon(Icons.search_rounded, size: 18),
              label: const Text('Discover Films & Shows'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchScreen(onOpenDetail: onOpenDetail),
                ),
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

  void _showManageShelvesSheet(BuildContext context, DatabaseService db) {
    final newCatController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final allCats = db.categories;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Manage Home Shelves',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.view_agenda_outlined, color: AppColors.primaryLight, size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toggle which category shelves appear on your Home screen.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: allCats.length,
                      separatorBuilder: (_, _) => const Divider(color: AppColors.borderSubtle, height: 1),
                      itemBuilder: (ctx, index) {
                        final cat = allCats[index];
                        final count = db.getEntriesForCategory(cat.id).length;
                        final isDefault = cat.id == 'cat_now_playing';

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            cat.name,
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '$count items in this shelf',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch.adaptive(
                                value: cat.showOnHome,
                                activeTrackColor: AppColors.primary,
                                onChanged: (val) async {
                                  await db.toggleCategoryOnHome(cat.id);
                                  setSheetState(() {});
                                },
                              ),
                              if (!isDefault)
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  tooltip: 'Delete Category',
                                  onPressed: () async {
                                    await db.deleteCategory(cat.id);
                                    setSheetState(() {});
                                  },
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: newCatController,
                          decoration: InputDecoration(
                            hintText: 'New shelf category...',
                            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                            filled: true,
                            fillColor: AppColors.surfaceElevated,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.borderSubtle),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () async {
                          final text = newCatController.text.trim();
                          if (text.isNotEmpty) {
                            await db.addCategory(text, showOnHome: true);
                            newCatController.clear();
                            setSheetState(() {});
                          }
                        },
                        child: const Text('Add Shelf', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

