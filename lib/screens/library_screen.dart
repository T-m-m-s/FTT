import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/shelf_view.dart';
import 'steam_sync_screen.dart';
import 'search_screen.dart';

class LibraryScreen extends StatefulWidget {
  final Function(LibraryEntry) onOpenDetail;

  const LibraryScreen({super.key, required this.onOpenDetail});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  bool _isShelvesView = true;
  final db = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final entries = db.currentLibraryFiltered;
        final backlog = db.backlogItems;
        final completed = db.completedItems;
        final playing = db.playingItems;
        final isGame = db.activeMediaFilter == MediaType.game;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: Text(isGame ? 'Game Library' : 'Cinema Library'),
            actions: [
              // Shelves vs Grid toggle pill
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isShelvesView = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isShelvesView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.shelves, size: 14, color: _isShelvesView ? Colors.white : AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Shelves',
                              style: TextStyle(
                                color: _isShelvesView ? Colors.white : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isShelvesView = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: !_isShelvesView ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.grid_view_rounded,
                          size: 14,
                          color: !_isShelvesView ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          body: entries.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: Icon(
                            isGame ? Icons.sports_esports_outlined : Icons.movie_outlined,
                            size: 40,
                            color: AppColors.primaryLight,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isGame ? 'Your Game Library is Empty' : 'Your Watchlist is Empty',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isGame
                              ? 'Connect your Steam account or search titles to build your collection.'
                              : 'Search and add films or shows to build your collection.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
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
                                builder: (_) => SearchScreen(onOpenDetail: widget.onOpenDetail),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              : _isShelvesView
                  ? ListView(
                      padding: const EdgeInsets.only(bottom: 120),
                      children: [
                        // Full Library Shelf
                        ShelfView(
                          title: 'Full Library',
                          subtitle: '${entries.length} items',
                          icon: Icons.auto_stories_rounded,
                          entries: entries,
                          onEntryTap: widget.onOpenDetail,
                        ),

                        // In Backlog Shelf
                        if (backlog.isNotEmpty)
                          ShelfView(
                            title: isGame ? 'In Backlog' : 'Watchlist',
                            subtitle: '${backlog.length} items',
                            icon: Icons.list_alt_rounded,
                            entries: backlog,
                            onEntryTap: widget.onOpenDetail,
                          ),

                        // Playing / Active Shelf
                        if (playing.isNotEmpty)
                          ShelfView(
                            title: isGame ? 'Currently Playing' : 'Currently Watching',
                            subtitle: '${playing.length} items',
                            icon: Icons.play_arrow_rounded,
                            entries: playing,
                            onEntryTap: widget.onOpenDetail,
                          ),

                        // Completed Shelf
                        if (completed.isNotEmpty)
                          ShelfView(
                            title: 'Completed',
                            subtitle: '${completed.length} items',
                            icon: Icons.check_circle_outline_rounded,
                            entries: completed,
                            onEntryTap: widget.onOpenDetail,
                          ),
                      ],
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 0.64,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return GestureDetector(
                          onTap: () => widget.onOpenDetail(entry),
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
                        );
                      },
                    ),
        );
      },
    );
  }
}
