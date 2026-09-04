import 'dart:async';
import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/database_service.dart';
import '../services/igdb_service.dart';
import '../services/sample_data.dart';
import '../theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  final Function(LibraryEntry) onOpenDetail;

  const SearchScreen({super.key, required this.onOpenDetail});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final db = DatabaseService();
  final igdb = IgdbService();

  String _query = '';
  bool _isSearching = false;
  Timer? _debounce;
  List<MediaItem> _searchResults = [];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() => _query = query);
    _debounce?.cancel();

    if (query.trim().isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      // 1. Live search from IGDB for games
      final liveGames = await igdb.searchGames(query, limit: 15);

      // 2. Filter cinema from local sample catalog
      final cinemaMatches = SampleData.sampleCinema.where((item) {
        final titleMatch = item.title.toLowerCase().contains(query.toLowerCase());
        final genreMatch = item.genres.any((g) => g.toLowerCase().contains(query.toLowerCase()));
        return titleMatch || genreMatch;
      }).toList();

      if (mounted) {
        setState(() {
          _searchResults = [...liveGames, ...cinemaMatches];
          _isSearching = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final defaultCatalog = [...SampleData.sampleGames, ...SampleData.sampleCinema];
    final displayItems = _query.trim().isEmpty ? defaultCatalog : _searchResults;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Discover & Search'),
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search games, movies, series (e.g. NieR, Zelda)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // Results count & Loading Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  _query.isEmpty
                      ? 'Trending & Curated'
                      : (_isSearching ? 'Searching IGDB Live...' : 'Results (${displayItems.length})'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isSearching) ...[
                  const SizedBox(width: 10),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                  ),
                ],
              ],
            ),
          ),

          // Search Results List
          Expanded(
            child: displayItems.isEmpty && !_isSearching
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 56, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          'No results found for "$_query"',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                    itemCount: displayItems.length,
                    itemBuilder: (context, index) {
                      final item = displayItems[index];
                      final inLibrary = db.library.any((e) => e.mediaId == item.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            // Poster
                            GestureDetector(
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
                                widget.onOpenDetail(entry);
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 52,
                                  height: 74,
                                  child: Image.network(
                                    item.posterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.surfaceElevated,
                                      child: const Icon(Icons.videogame_asset, color: AppColors.textMuted),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: GestureDetector(
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
                                  widget.onOpenDetail(entry);
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: BoxDecoration(
                                            color: item.mediaType == MediaType.game
                                                ? AppColors.primaryDark.withValues(alpha: 0.4)
                                                : AppColors.accentOrange.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.mediaType.displayName,
                                            style: TextStyle(
                                              color: item.mediaType == MediaType.game
                                                  ? AppColors.primaryLight
                                                  : AppColors.accentOrange,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item.releaseYear}  •  ★ ${item.communityRating}',
                                          style: const TextStyle(
                                            color: AppColors.textSecondary,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.creator,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Action Button (Add to Backlog or Open)
                            if (inLibrary)
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight),
                                onPressed: () {
                                  final entry = db.library.firstWhere((e) => e.mediaId == item.id);
                                  widget.onOpenDetail(entry);
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                                onPressed: () {
                                  final newEntry = LibraryEntry(
                                    id: 'entry_${item.id}',
                                    mediaId: item.id,
                                    mediaItem: item,
                                    status: LibraryStatus.backlog,
                                  );
                                  db.addOrUpdateEntry(newEntry);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Added "${item.title}" to Backlog'),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: AppColors.primary,
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
