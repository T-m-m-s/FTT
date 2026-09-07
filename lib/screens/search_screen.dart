import 'dart:async';
import 'package:flutter/material.dart';
import '../models/library_entry.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../services/cinema_service.dart';
import '../services/database_service.dart';
import '../services/igdb_service.dart';
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
  final cinema = CinemaService();

  late bool _isGameMode;
  MediaType? _cinemaFilter; // null for All, or MediaType.movie, or MediaType.tvShow

  String _query = '';
  bool _isSearching = false;
  Timer? _debounce;
  List<MediaItem> _searchResults = [];
  List<MediaItem> _trendingCinema = [];
  bool _isLoadingTrending = false;

  final List<String> _gameGenres = [
    'RPG',
    'Roguelike',
    'Action',
    'Indie',
    'Souls-like',
    'Deckbuilder',
    'Open World',
    'Horror',
    'Platformer',
    'Strategy',
  ];

  final List<String> _cinemaGenres = [
    'Sci-Fi',
    'Drama',
    'Action',
    'Comedy',
    'Horror',
    'Animation',
    'Thriller',
    'Documentary',
    'Crime',
    'Mystery',
    'Adventure',
    'Fantasy',
  ];

  @override
  void initState() {
    super.initState();
    _isGameMode = db.activeMediaFilter == MediaType.game;
    if (!_isGameMode) {
      _loadTrendingCinema();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingCinema() async {
    if (_trendingCinema.isNotEmpty) return;
    setState(() => _isLoadingTrending = true);
    try {
      final trending = await cinema.getTrendingCinema();
      if (mounted) {
        setState(() {
          _trendingCinema = trending;
          _isLoadingTrending = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingTrending = false);
    }
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

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      List<MediaItem> results;
      if (_isGameMode) {
        results = await igdb.searchGames(query, limit: 20);
      } else {
        results = await cinema.searchCinema(
          query,
          typeFilter: _cinemaFilter,
          limit: 20,
        );
      }

      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    });
  }

  void _switchMode(bool gameMode) {
    if (_isGameMode == gameMode) return;
    setState(() {
      _isGameMode = gameMode;
      _searchResults = [];
      _searchController.clear();
      _query = '';
      _isSearching = false;
    });

    db.setMediaFilter(gameMode ? MediaType.game : MediaType.movie);

    if (!gameMode && _trendingCinema.isEmpty) {
      _loadTrendingCinema();
    }
  }

  void _setCinemaFilter(MediaType? filter) {
    setState(() => _cinemaFilter = filter);
    if (_query.trim().isNotEmpty) {
      _onSearchChanged(_query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final libraryItems = db.currentLibraryFiltered.map((e) => e.mediaItem).toList();
    final isQueryEmpty = _query.trim().isEmpty;

    List<MediaItem> displayItems;
    if (isQueryEmpty) {
      if (_isGameMode) {
        displayItems = libraryItems;
      } else {
        // In Cinema mode, show trending cinema or library items
        var list = _trendingCinema;
        if (_cinemaFilter != null) {
          list = list.where((item) => item.mediaType == _cinemaFilter).toList();
        }
        displayItems = list.isNotEmpty ? list : libraryItems;
      }
    } else {
      displayItems = _searchResults;
      if (!_isGameMode && _cinemaFilter != null) {
        displayItems = displayItems.where((item) => item.mediaType == _cinemaFilter).toList();
      }
    }

    final currentGenres = _isGameMode ? _gameGenres : _cinemaGenres;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(_isGameMode ? 'Discover Games' : 'Discover Cinema'),
        actions: [
          // Mode Toggle Pill
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _switchMode(true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isGameMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_esports_rounded,
                          size: 13,
                          color: _isGameMode ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Games',
                          style: TextStyle(
                            color: _isGameMode ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: _isGameMode ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _switchMode(false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: !_isGameMode ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.movie_filter_rounded,
                          size: 13,
                          color: !_isGameMode ? Colors.white : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Cinema',
                          style: TextStyle(
                            color: !_isGameMode ? Colors.white : AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: !_isGameMode ? FontWeight.bold : FontWeight.w500,
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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  hintText: _isGameMode
                      ? 'Search any game via IGDB (e.g. Elden Ring, Balatro)...'
                      : 'Search movies & TV shows (e.g. Dune, Severance)...',
                  hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
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

          // Cinema Sub-Filter Pills (All, Movies, TV Series)
          if (!_isGameMode) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
              child: Row(
                children: [
                  _buildSubFilterChip('All', null),
                  const SizedBox(width: 8),
                  _buildSubFilterChip('Movies', MediaType.movie),
                  const SizedBox(width: 8),
                  _buildSubFilterChip('TV Series', MediaType.tvShow),
                ],
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Genre discovery chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: currentGenres.length,
              itemBuilder: (context, index) {
                final genre = currentGenres[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(genre),
                    labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    backgroundColor: AppColors.surfaceElevated,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    onPressed: () {
                      _searchController.text = genre;
                      _onSearchChanged(genre);
                    },
                  ),
                );
              },
            ),
          ),

          // Results count & Loading Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Text(
                  _buildResultsHeader(isQueryEmpty, displayItems.length, libraryItems.length),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (_isSearching || (_isLoadingTrending && isQueryEmpty && !_isGameMode)) ...[
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
            child: displayItems.isEmpty && !_isSearching && !_isLoadingTrending
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isQueryEmpty
                              ? (_isGameMode ? Icons.sports_esports_outlined : Icons.movie_creation_outlined)
                              : Icons.search_off_rounded,
                          size: 56,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isQueryEmpty
                              ? (_isGameMode ? 'Explore & Search IGDB Games' : 'Explore Trending Films & Series')
                              : 'No results found for "$_query"',
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
                              onTap: () => _openOrViewDetail(item),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 54,
                                  height: 78,
                                  child: Image.network(
                                    item.posterUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: AppColors.surfaceElevated,
                                      child: Icon(
                                        item.mediaType == MediaType.game
                                            ? Icons.videogame_asset
                                            : (item.mediaType == MediaType.tvShow
                                                ? Icons.tv_rounded
                                                : Icons.movie_outlined),
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),

                            // Info
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _openOrViewDetail(item),
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
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        // Media Type Pill
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                          decoration: BoxDecoration(
                                            color: item.mediaType == MediaType.game
                                                ? AppColors.primaryDark.withValues(alpha: 0.4)
                                                : (item.mediaType == MediaType.tvShow
                                                    ? Colors.purple.withValues(alpha: 0.25)
                                                    : AppColors.accentOrange.withValues(alpha: 0.2)),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            item.mediaType.displayName,
                                            style: TextStyle(
                                              color: item.mediaType == MediaType.game
                                                  ? AppColors.primaryLight
                                                  : (item.mediaType == MediaType.tvShow
                                                      ? Colors.purpleAccent
                                                      : AppColors.accentOrange),
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
                                        if (item.runtimeMinutes != null && item.runtimeMinutes! > 0) ...[
                                          Text(
                                            item.mediaType == MediaType.tvShow
                                                ? '  •  ${item.runtimeMinutes}m/ep'
                                                : '  •  ${item.runtimeMinutes}m',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.creator.isNotEmpty ? item.creator : item.genres.take(2).join(', '),
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

                            // Action Button (Add to Library or View Checkmark)
                            if (inLibrary)
                              IconButton(
                                icon: const Icon(Icons.check_circle_rounded, color: AppColors.primaryLight),
                                tooltip: 'In Library',
                                onPressed: () {
                                  final entry = db.library.firstWhere((e) => e.mediaId == item.id);
                                  widget.onOpenDetail(entry);
                                },
                              )
                            else
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                                tooltip: _isGameMode ? 'Add to Backlog' : 'Add to Watchlist',
                                onPressed: () {
                                  final newEntry = LibraryEntry(
                                    id: 'entry_${item.id}',
                                    mediaId: item.id,
                                    mediaItem: item,
                                    status: LibraryStatus.backlog,
                                    platform: item.mediaType == MediaType.game
                                        ? 'PC - Steam'
                                        : 'Streaming',
                                    format: item.mediaType == MediaType.game
                                        ? 'Digital'
                                        : 'Streaming',
                                  );
                                  db.addOrUpdateEntry(newEntry);
                                  setState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        item.mediaType == MediaType.game
                                            ? 'Added "${item.title}" to Backlog'
                                            : 'Added "${item.title}" to Watchlist',
                                      ),
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

  Widget _buildSubFilterChip(String label, MediaType? filter) {
    final isSelected = _cinemaFilter == filter;
    return GestureDetector(
      onTap: () => _setCinemaFilter(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  String _buildResultsHeader(bool isQueryEmpty, int displayCount, int libraryCount) {
    if (isQueryEmpty) {
      if (_isGameMode) {
        return libraryCount > 0 ? 'In Your Library ($libraryCount)' : 'Explore Games';
      } else {
        return _trendingCinema.isNotEmpty ? 'Trending Films & Series ($displayCount)' : 'Trending Cinema';
      }
    }

    if (_isSearching) {
      return _isGameMode ? 'Searching IGDB Live...' : 'Searching TMDB & TVMaze...';
    }

    return 'Results ($displayCount)';
  }

  void _openOrViewDetail(MediaItem item) {
    final entry = db.library.firstWhere(
      (e) => e.mediaId == item.id,
      orElse: () => LibraryEntry(
        id: 'entry_${item.id}',
        mediaId: item.id,
        mediaItem: item,
        status: LibraryStatus.wishlist,
        platform: item.mediaType == MediaType.game ? 'PC - Steam' : 'Streaming',
        format: item.mediaType == MediaType.game ? 'Digital' : 'Streaming',
      ),
    );
    widget.onOpenDetail(entry);
  }
}
