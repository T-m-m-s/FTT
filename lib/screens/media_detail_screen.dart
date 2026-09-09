import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/library_entry.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import '../models/tv_season.dart';
import '../services/cinema_service.dart';
import '../services/database_service.dart';
import '../theme/app_colors.dart';
import '../widgets/format_bottom_sheet.dart';

class MediaDetailScreen extends StatefulWidget {
  final LibraryEntry entry;

  const MediaDetailScreen({super.key, required this.entry});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  late LibraryEntry _entry;
  final db = DatabaseService();
  List<TvSeason> _seasons = [];
  bool _isLoadingSeasons = false;
  int _selectedSeasonNumber = 1;
  final Set<String> _expandedEpisodeIds = {};

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    if (_entry.mediaItem.mediaType == MediaType.tvShow) {
      if (_entry.cachedSeasons != null && _entry.cachedSeasons!.isNotEmpty) {
        _seasons = List.from(_entry.cachedSeasons!);
        _pickInitialSeason();
      } else {
        _loadTvSeasons();
      }
    }
  }

  void _pickInitialSeason() {
    if (_seasons.isEmpty) return;
    for (final s in _seasons) {
      final hasUnwatched = s.episodes.any(
        (e) => !_entry.isEpisodeWatched(s.seasonNumber, e.episodeNumber),
      );
      if (hasUnwatched) {
        _selectedSeasonNumber = s.seasonNumber;
        return;
      }
    }
    _selectedSeasonNumber = _seasons.first.seasonNumber;
  }

  Future<void> _loadTvSeasons() async {
    setState(() => _isLoadingSeasons = true);
    try {
      final fetched = await CinemaService().fetchTvSeasonsAndEpisodes(_entry.mediaItem);
      if (mounted) {
        setState(() {
          _seasons = fetched;
          _isLoadingSeasons = false;
          _pickInitialSeason();

          final mainSeasons = fetched.where((s) => s.seasonNumber > 0).toList();
          final effectiveSeasons = mainSeasons.isNotEmpty ? mainSeasons : fetched;
          final totalCount = effectiveSeasons.fold<int>(0, (sum, s) => sum + s.episodes.length);
          if (totalCount > 0) {
            _entry.totalEpisodesCount = totalCount;
            _entry.cachedSeasons = fetched;
            _entry.updateTvProgress();
            db.addOrUpdateEntry(_entry);
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingSeasons = false);
      }
    }
  }

  ({TvSeason season, TvEpisode episode})? _findNextUnwatchedEpisode() {
    for (final season in _seasons) {
      for (final ep in season.episodes) {
        if (!_entry.isEpisodeWatched(season.seasonNumber, ep.episodeNumber)) {
          return (season: season, episode: ep);
        }
      }
    }
    return null;
  }

  void _watchNextEpisode() {
    final next = _findNextUnwatchedEpisode();
    if (next != null) {
      _toggleEpisodeWatch(next.season, next.episode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Watched S${next.season.seasonNumber}E${next.episode.episodeNumber}: ${next.episode.name}'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  void _toggleEpisodeWatch(TvSeason season, TvEpisode episode) {
    final key = episode.canonicalKey;
    final isWatched = _entry.isEpisodeWatched(season.seasonNumber, episode.episodeNumber);
    final runtime = episode.runtimeMinutes ?? _entry.mediaItem.runtimeMinutes ?? 45;

    setState(() {
      if (isWatched) {
        _entry.watchedEpisodeIds.remove(key);
        _entry.timeSpentMinutes = (_entry.timeSpentMinutes - runtime).clamp(0, 9999999);
        if (_entry.status == LibraryStatus.completed) {
          _entry.status = LibraryStatus.playing;
        }
      } else {
        if (!_entry.watchedEpisodeIds.contains(key)) {
          _entry.watchedEpisodeIds.add(key);
        }
        _entry.timeSpentMinutes += runtime;
        _entry.lastActivity = DateTime.now();

        final session = PlaySession(
          id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
          mediaId: _entry.mediaId,
          mediaTitle: _entry.mediaItem.title,
          mediaPoster: _entry.mediaItem.posterUrl,
          mediaType: _entry.mediaItem.mediaType,
          date: DateTime.now(),
          durationMinutes: runtime,
          platform: _entry.platform,
          notes: 'S${season.seasonNumber}E${episode.episodeNumber}: ${episode.name}',
        );
        db.addSession(session);
      }

      _entry.updateTvProgress();
      db.addOrUpdateEntry(_entry);
    });
  }

  void _toggleSeasonWatch(TvSeason season) {
    final allWatched = season.episodes.isNotEmpty &&
        season.episodes.every((e) => _entry.isEpisodeWatched(season.seasonNumber, e.episodeNumber));
    int timeDelta = 0;

    setState(() {
      if (allWatched) {
        for (final ep in season.episodes) {
          final key = ep.canonicalKey;
          if (_entry.watchedEpisodeIds.remove(key)) {
            final runtime = ep.runtimeMinutes ?? _entry.mediaItem.runtimeMinutes ?? 45;
            timeDelta -= runtime;
          }
        }
        _entry.timeSpentMinutes = (_entry.timeSpentMinutes + timeDelta).clamp(0, 9999999);
        if (_entry.status == LibraryStatus.completed) {
          _entry.status = LibraryStatus.playing;
        }
      } else {
        for (final ep in season.episodes) {
          final key = ep.canonicalKey;
          if (!_entry.watchedEpisodeIds.contains(key)) {
            _entry.watchedEpisodeIds.add(key);
            final runtime = ep.runtimeMinutes ?? _entry.mediaItem.runtimeMinutes ?? 45;
            timeDelta += runtime;
          }
        }
        _entry.timeSpentMinutes += timeDelta;
        _entry.lastActivity = DateTime.now();

        final session = PlaySession(
          id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
          mediaId: _entry.mediaId,
          mediaTitle: _entry.mediaItem.title,
          mediaPoster: _entry.mediaItem.posterUrl,
          mediaType: _entry.mediaItem.mediaType,
          date: DateTime.now(),
          durationMinutes: timeDelta > 0 ? timeDelta : 45,
          platform: _entry.platform,
          notes: 'Watched all of ${season.name}',
        );
        db.addSession(session);
      }

      _entry.updateTvProgress();
      db.addOrUpdateEntry(_entry);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          allWatched
              ? 'Unmarked ${season.name}'
              : 'Marked ${season.name} as watched (${season.episodes.length} ep)',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showFormatSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FormatBottomSheet(
        entry: _entry,
        onSave: (updated) {
          setState(() => _entry = updated);
          db.addOrUpdateEntry(_entry);
        },
      ),
    );
  }

  void _confirmDeleteEntry() {
    final title = _entry.mediaItem.title;
    final typeStr = _entry.mediaItem.mediaType == MediaType.game
        ? 'game'
        : (_entry.mediaItem.mediaType == MediaType.tvShow ? 'series' : 'movie');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Remove $typeStr?',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "$title" from your library? Your watch history and progress will be deleted.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              db.removeEntry(_entry.mediaId);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Close detail screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed "$title" from your library'),
                  duration: const Duration(seconds: 2),
                  backgroundColor: AppColors.surfaceElevated,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _quickLogCinemaSession({required int duration, required String note, bool isCompletion = false}) {
    final session = PlaySession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      mediaId: _entry.mediaId,
      mediaTitle: _entry.mediaItem.title,
      mediaPoster: _entry.mediaItem.posterUrl,
      mediaType: _entry.mediaItem.mediaType,
      date: DateTime.now(),
      durationMinutes: duration,
      platform: _entry.platform,
      notes: note,
      isCompletion: isCompletion,
    );
    db.addSession(session);
    setState(() {
      _entry.timeSpentMinutes += duration;
      _entry.lastActivity = DateTime.now();
      if (isCompletion) {
        _entry.status = LibraryStatus.completed;
        _entry.progressPercent = 100.0;
      } else if (_entry.status == LibraryStatus.backlog || _entry.status == LibraryStatus.wishlist) {
        _entry.status = LibraryStatus.playing;
      }
    });
    db.addOrUpdateEntry(_entry);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged $note ($duration min) for ${_entry.mediaItem.title}'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _markMovieWatched() {
    final duration = (_entry.mediaItem.runtimeMinutes != null && _entry.mediaItem.runtimeMinutes! > 0)
        ? _entry.mediaItem.runtimeMinutes!
        : 120;
    _quickLogCinemaSession(
      duration: duration,
      note: 'Full Movie',
      isCompletion: true,
    );
  }

  void _toggleMovieWatchedStatus() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _entry.mediaItem.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.replay_rounded, color: AppColors.primaryLight),
                title: const Text('Log Rewatch', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Add another watch session to your timeline', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _markMovieWatched();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark_remove_outlined, color: AppColors.statusAbandoned),
                title: const Text('Mark as Unwatched (Move to Watchlist)', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Reverts status to watchlist', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _entry.status = LibraryStatus.backlog;
                    _entry.progressPercent = 0.0;
                  });
                  db.addOrUpdateEntry(_entry);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Marked "${_entry.mediaItem.title}" as unwatched (in Watchlist)'),
                      backgroundColor: AppColors.surfaceElevated,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSessionDialog() {
    final isTv = _entry.mediaItem.mediaType == MediaType.tvShow;
    final isMovie = _entry.mediaItem.mediaType == MediaType.movie;
    final defaultRuntime = _entry.mediaItem.runtimeMinutes;
    int minutes = (defaultRuntime != null && defaultRuntime > 0)
        ? defaultRuntime
        : (isTv ? 45 : (isMovie ? 120 : 60));
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Log ${_entry.mediaItem.mediaType == MediaType.game ? "Play" : "Watch"} Session',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Duration: ${minutes ~/ 60}h ${minutes % 60}m',
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Slider(
                value: minutes.toDouble().clamp(15.0, 360.0),
                min: 15,
                max: 360,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceCard,
                onChanged: (val) => setDlgState(() => minutes = val.toInt()),
              ),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  hintText: isTv
                      ? 'Episode notes (e.g. S01E03)...'
                      : (isMovie ? 'Movie watch notes...' : 'Notes for this session...'),
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final session = PlaySession(
                  id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
                  mediaId: _entry.mediaId,
                  mediaTitle: _entry.mediaItem.title,
                  mediaPoster: _entry.mediaItem.posterUrl,
                  mediaType: _entry.mediaItem.mediaType,
                  date: DateTime.now(),
                  durationMinutes: minutes,
                  platform: _entry.platform,
                  notes: notesController.text,
                );
                db.addSession(session);
                setState(() {
                  _entry.timeSpentMinutes += minutes;
                  _entry.lastActivity = DateTime.now();
                  if (_entry.status == LibraryStatus.backlog || _entry.status == LibraryStatus.wishlist) {
                    _entry.status = LibraryStatus.playing;
                  }
                });
                db.addOrUpdateEntry(_entry);
                Navigator.pop(ctx);
              },
              child: const Text('Log Session', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _entry.mediaItem;
    final isGame = item.mediaType == MediaType.game;
    final inLibrary = db.library.any((e) => e.mediaId == _entry.mediaId);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Collapsible Hero App Bar
          SliverAppBar(
            expandedHeight: 380,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            actions: [
              if (inLibrary)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.5),
                    child: IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                      tooltip: 'Remove from Library',
                      onPressed: _confirmDeleteEntry,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    item.backdropUrl.isNotEmpty ? item.backdropUrl : item.posterUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: AppColors.surfaceElevated),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                          AppColors.background.withValues(alpha: 0.8),
                          AppColors.background,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 175,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(item.posterUrl, fit: BoxFit.cover),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Status Pill
                  _buildStatusDropdown(),
                  const SizedBox(height: 14),

                  // Title
                  Text(
                    item.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.releaseDateFormatted}  •  ${item.genres.join(', ')}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Playthrough Card (Matching Screenshot 1 Screen 4)
                  _buildPlaythroughCard(isGame),
                  const SizedBox(height: 16),

                  // TV Seasons & Episodes Explorer
                  if (item.mediaType == MediaType.tvShow) ...[
                    _buildTvSeasonsSection(),
                    const SizedBox(height: 16),
                  ],

                  // Platforms & Formats Card (Matching Screenshot 1 Screen 5)
                  _buildPlatformCard(),
                  const SizedBox(height: 16),

                  // User Rating Section
                  _buildRatingSection(),
                  const SizedBox(height: 16),

                  // Synopsis
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Synopsis',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.synopsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remove from Library Action
                  if (inLibrary) ...[
                    const SizedBox(height: 24),
                    Center(
                      child: TextButton.icon(
                        onPressed: _confirmDeleteEntry,
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        label: Text(
                          _entry.mediaItem.mediaType == MediaType.game
                              ? 'Remove Game from Library'
                              : (_entry.mediaItem.mediaType == MediaType.tvShow
                                  ? 'Remove Series from Library'
                                  : 'Remove Film from Library'),
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          backgroundColor: Colors.red.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.3)),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LibraryStatus>(
          value: _entry.status,
          dropdownColor: AppColors.surfaceElevated,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryLight, size: 20),
          isDense: true,
          items: LibraryStatus.values.map((s) {
            return DropdownMenuItem<LibraryStatus>(
              value: s,
              child: Text(
                s.label,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: (newStatus) {
            if (newStatus != null) {
              setState(() => _entry.status = newStatus);
              db.updateStatus(_entry.mediaId, newStatus);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPlaythroughCard(bool isGame) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Text(
                isGame ? 'Playthroughs' : 'Watch History',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isGame) ...[
                    if (_entry.mediaItem.mediaType == MediaType.tvShow) ...[
                      if (_seasons.isNotEmpty) ...[
                        Builder(
                          builder: (context) {
                            final next = _findNextUnwatchedEpisode();
                            if (next != null) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: OutlinedButton.icon(
                                  onPressed: _watchNextEpisode,
                                  icon: const Icon(Icons.play_circle_outline_rounded, size: 14),
                                  label: Text(
                                    'S${next.season.seasonNumber}E${next.episode.episodeNumber}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primaryLight,
                                    side: const BorderSide(color: AppColors.primaryLight),
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                ),
                              );
                            } else {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.6)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, size: 13, color: Colors.greenAccent),
                                      SizedBox(width: 4),
                                      Text(
                                        'All Watched',
                                        style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        OutlinedButton(
                          onPressed: () {
                            final duration = (_entry.mediaItem.runtimeMinutes != null && _entry.mediaItem.runtimeMinutes! > 0)
                                ? _entry.mediaItem.runtimeMinutes!
                                : 45;
                            _quickLogCinemaSession(
                              duration: duration,
                              note: '+1 Episode',
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primaryLight,
                            side: const BorderSide(color: AppColors.primaryLight),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('+1 Ep', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ] else ...[
                      if (_entry.status == LibraryStatus.completed) ...[
                        OutlinedButton.icon(
                          onPressed: _toggleMovieWatchedStatus,
                          icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.success),
                          label: const Text('Watched', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success)),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.success.withValues(alpha: 0.12),
                            side: const BorderSide(color: AppColors.success),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ] else ...[
                        OutlinedButton.icon(
                          onPressed: _markMovieWatched,
                          icon: const Icon(Icons.check_rounded, size: 14, color: AppColors.primaryLight),
                          label: const Text('+ Watched', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primaryLight),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ],
                  ElevatedButton.icon(
                    onPressed: _showAddSessionDialog,
                    icon: const Icon(Icons.add, size: 16, color: Colors.white),
                    label: const Text('Log Session', style: TextStyle(color: Colors.white, fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Circular progress indicator (Games/TV) or Binary status badge (Movies)
              if (_entry.mediaItem.mediaType == MediaType.movie) ...[
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: _entry.status == LibraryStatus.completed
                        ? AppColors.success.withValues(alpha: 0.15)
                        : AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _entry.status == LibraryStatus.completed
                          ? AppColors.success
                          : AppColors.borderSubtle,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _entry.status == LibraryStatus.completed
                        ? Icons.check_circle_rounded
                        : Icons.bookmark_outline_rounded,
                    color: _entry.status == LibraryStatus.completed
                        ? AppColors.success
                        : AppColors.textSecondary,
                    size: 30,
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: (_entry.progressPercent / 100.0).clamp(0.0, 1.0),
                        strokeWidth: 6,
                        backgroundColor: AppColors.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
                      ),
                      Center(
                        child: Text(
                          '${_entry.progressPercent.toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_entry.mediaItem.mediaType == MediaType.tvShow) ...[
                      Text(
                        _entry.totalEpisodesCount != null && _entry.totalEpisodesCount! > 0
                            ? 'Episodes: ${_entry.watchedEpisodesCount} / ${_entry.totalEpisodesCount}'
                            : 'Episodes: ${_entry.watchedEpisodesCount} watched',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                    ],
                    if (_entry.mediaItem.mediaType == MediaType.movie) ...[
                      Text(
                        _entry.status == LibraryStatus.completed ? 'Status: Watched' : 'Status: In Watchlist',
                        style: TextStyle(
                          color: _entry.status == LibraryStatus.completed ? AppColors.success : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (_entry.mediaItem.runtimeMinutes != null && _entry.mediaItem.runtimeMinutes! > 0) ...[
                        Text(
                          'Runtime: ${_entry.mediaItem.runtimeMinutes} min',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 3),
                      ],
                    ] else ...[
                      Text(
                        'Time: ${_entry.formattedTimeSpent}',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Status: ${_entry.status.shortLabel}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 3),
                    ],
                    Text(
                      _entry.lastActivity != null
                          ? 'Last: ${DateFormat("MMM d, y").format(_entry.lastActivity!)}'
                          : 'No sessions logged',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTvSeasonsSection() {
    final currentSeason = _seasons.firstWhere(
      (s) => s.seasonNumber == _selectedSeasonNumber,
      orElse: () => _seasons.isNotEmpty ? _seasons.first : const TvSeason(seasonNumber: 1, name: 'Season 1', episodeCount: 0),
    );

    final totalEps = _entry.totalEpisodesCount ?? _seasons.fold<int>(0, (sum, s) => sum + s.episodes.length);
    final watchedEps = _entry.watchedEpisodesCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title & Overall Counter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.tv_rounded, color: AppColors.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Seasons & Episodes',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (_isLoadingSeasons)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                )
              else if (totalEps > 0)
                Text(
                  '$watchedEps / $totalEps ep (${_entry.progressPercent.toInt()}%)',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Linear Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_entry.progressPercent / 100.0).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryLight),
            ),
          ),
          const SizedBox(height: 16),

          // Content body
          if (_isLoadingSeasons && _seasons.isEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primaryLight),
                    SizedBox(height: 12),
                    Text(
                      'Fetching seasons and episodes...',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_seasons.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppColors.textMuted, size: 36),
                    const SizedBox(height: 8),
                    const Text(
                      'Episodes not available offline or not found.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _loadTvSeasons,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Retry Fetching'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryLight,
                        side: const BorderSide(color: AppColors.primaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Season Selector Dropdown + Batch Mark Season Button
            Row(
              children: [
                // Dropdown Pill
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: currentSeason.seasonNumber,
                        dropdownColor: AppColors.surfaceElevated,
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primaryLight, size: 20),
                        items: _seasons.map((s) {
                          final sWatched = s.episodes.where(
                            (e) => _entry.isEpisodeWatched(s.seasonNumber, e.episodeNumber),
                          ).length;
                          final isAll = s.episodes.isNotEmpty && sWatched == s.episodes.length;
                          return DropdownMenuItem<int>(
                            value: s.seasonNumber,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    s.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: isAll ? AppColors.primaryLight : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$sWatched/${s.episodes.length}',
                                  style: TextStyle(
                                    color: isAll ? AppColors.primaryLight : AppColors.textMuted,
                                    fontSize: 11,
                                    fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedSeasonNumber = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Batch Mark Season Button
                Builder(
                  builder: (context) {
                    final allSeasonWatched = currentSeason.episodes.isNotEmpty &&
                        currentSeason.episodes.every(
                          (e) => _entry.isEpisodeWatched(currentSeason.seasonNumber, e.episodeNumber),
                        );
                    return OutlinedButton.icon(
                      onPressed: () => _toggleSeasonWatch(currentSeason),
                      icon: Icon(
                        allSeasonWatched ? Icons.check_circle_rounded : Icons.done_all_rounded,
                        size: 14,
                      ),
                      label: Text(
                        allSeasonWatched ? 'Season Watched' : 'Mark Season',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: allSeasonWatched ? AppColors.primaryLight : AppColors.textSecondary,
                        side: BorderSide(
                          color: allSeasonWatched ? AppColors.primaryLight : AppColors.borderSubtle,
                        ),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Episodes List for Current Season
            if (currentSeason.episodes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text(
                    'No episodes listed for this season.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              )
            else
              ...currentSeason.episodes.map((ep) {
                final isWatched = _entry.isEpisodeWatched(currentSeason.seasonNumber, ep.episodeNumber);
                final isExpanded = _expandedEpisodeIds.contains(ep.canonicalKey);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isWatched
                        ? AppColors.surfaceElevated.withValues(alpha: 0.45)
                        : AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isWatched
                          ? AppColors.primaryLight.withValues(alpha: 0.25)
                          : AppColors.borderSubtle.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Watch Checkbox / Toggle Button
                          GestureDetector(
                            onTap: () => _toggleEpisodeWatch(currentSeason, ep),
                            behavior: HitTestBehavior.opaque,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: Icon(
                                isWatched ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                color: isWatched ? AppColors.primaryLight : AppColors.textMuted,
                                size: 22,
                              ),
                            ),
                          ),

                          // Episode Info (Tap to toggle plot overview)
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                if (ep.overview.isNotEmpty) {
                                  setState(() {
                                    if (isExpanded) {
                                      _expandedEpisodeIds.remove(ep.canonicalKey);
                                    } else {
                                      _expandedEpisodeIds.add(ep.canonicalKey);
                                    }
                                  });
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'E${ep.episodeNumber.toString().padLeft(2, "0")}  •  ${ep.name}',
                                    style: TextStyle(
                                      color: isWatched ? AppColors.textSecondary : Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: isWatched ? TextDecoration.lineThrough : null,
                                    ),
                                    maxLines: isExpanded ? null : 1,
                                    overflow: isExpanded ? null : TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${ep.runtimeMinutes ?? _entry.mediaItem.runtimeMinutes ?? 45}m'
                                    '${ep.airDate != null && ep.airDate!.isNotEmpty ? "  •  ${ep.airDate}" : ""}',
                                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Expand / Collapse Chevron if synopsis exists
                          if (ep.overview.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textMuted,
                                size: 18,
                              ),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() {
                                  if (isExpanded) {
                                    _expandedEpisodeIds.remove(ep.canonicalKey);
                                  } else {
                                    _expandedEpisodeIds.add(ep.canonicalKey);
                                  }
                                });
                              },
                            ),
                        ],
                      ),
                      if (isExpanded && ep.overview.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          ep.overview,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }

  Widget _buildPlatformCard() {
    return GestureDetector(
      onTap: _showFormatSheet,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.devices_rounded, color: AppColors.primaryLight, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Platforms & Formats',
                    style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_entry.platform}  •  ${_entry.format}  •  ${_entry.isOwned ? "Owned" : "Unowned"}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    final rating = _entry.userRating ?? 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Personal Rating',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              Text(
                rating > 0 ? '${rating.toStringAsFixed(1)} / 10' : 'Unrated',
                style: const TextStyle(color: AppColors.primaryLight, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Slider(
            value: rating,
            min: 0.0,
            max: 10.0,
            divisions: 20,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.surfaceElevated,
            onChanged: (val) {
              setState(() => _entry.userRating = val);
              db.updateRating(_entry.mediaId, val);
            },
          ),
        ],
      ),
    );
  }
}
