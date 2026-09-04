import 'package:flutter/foundation.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/library_entry.dart';
import '../models/play_session.dart';
import '../models/steam_profile.dart';
import 'sample_data.dart';

class DatabaseService extends ChangeNotifier {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  final List<LibraryEntry> _library = [];
  final List<PlaySession> _sessions = [];
  SteamProfile? _steamProfile;
  MediaType _activeMediaFilter = MediaType.game; // Default to games or unified

  List<LibraryEntry> get library => List.unmodifiable(_library);
  List<PlaySession> get sessions => List.unmodifiable(_sessions);
  SteamProfile? get steamProfile => _steamProfile;
  MediaType get activeMediaFilter => _activeMediaFilter;

  void setMediaFilter(MediaType type) {
    _activeMediaFilter = type;
    notifyListeners();
  }

  /// Initialize database - starts clean with real user data only
  Future<void> init() async {
    // Purge any legacy sample data so only real user data appears
    _library.removeWhere((e) => e.id.startsWith('entry_game_') || e.mediaId.startsWith('game_'));
    _sessions.removeWhere((s) => s.id.startsWith('sess_game_') || s.mediaId.startsWith('game_'));
    notifyListeners();
  }

  // Filtered queries
  List<LibraryEntry> get currentLibraryFiltered {
    return _library.where((entry) => entry.mediaItem.mediaType == _activeMediaFilter).toList();
  }

  List<LibraryEntry> get playingItems {
    return currentLibraryFiltered
        .where((e) => e.status == LibraryStatus.playing)
        .toList();
  }

  List<LibraryEntry> get backlogItems {
    return currentLibraryFiltered
        .where((e) => e.status == LibraryStatus.backlog)
        .toList();
  }

  List<LibraryEntry> get completedItems {
    return currentLibraryFiltered
        .where((e) => e.status == LibraryStatus.completed)
        .toList();
  }

  List<LibraryEntry> topPlayedGames({int limit = 5}) {
    final played = currentLibraryFiltered.where((e) => e.timeSpentMinutes > 0).toList()
      ..sort((a, b) => b.timeSpentMinutes.compareTo(a.timeSpentMinutes));
    return played.take(limit).toList();
  }

  List<PlaySession> get currentSessionsFiltered {
    return _sessions.where((s) => s.mediaType == _activeMediaFilter).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  // Add or update library entry
  void addOrUpdateEntry(LibraryEntry entry) {
    final index = _library.indexWhere((e) => e.mediaId == entry.mediaId);
    if (index >= 0) {
      _library[index] = entry;
    } else {
      _library.add(entry);
    }
    notifyListeners();
  }

  void updateStatus(String mediaId, LibraryStatus status) {
    final index = _library.indexWhere((e) => e.mediaId == mediaId);
    if (index >= 0) {
      _library[index].status = status;
      if (status == LibraryStatus.completed) {
        _library[index].progressPercent = 100.0;
      }
      notifyListeners();
    }
  }

  void updateRating(String mediaId, double rating) {
    final index = _library.indexWhere((e) => e.mediaId == mediaId);
    if (index >= 0) {
      _library[index].userRating = rating;
      notifyListeners();
    }
  }

  // Add play / watch session to timeline
  void addSession(PlaySession session) {
    _sessions.insert(0, session);
    _sessions.sort((a, b) => b.date.compareTo(a.date));

    // Update corresponding library entry if exists
    final index = _library.indexWhere((e) => e.mediaId == session.mediaId);
    if (index >= 0) {
      final entry = _library[index];
      entry.timeSpentMinutes += session.durationMinutes;
      entry.lastActivity = session.date;
      if (session.isCompletion) {
        entry.status = LibraryStatus.completed;
        entry.progressPercent = 100.0;
      } else if (session.progressPercentage != null) {
        entry.progressPercent = session.progressPercentage!;
      }
      if (session.rating != null) {
        entry.userRating = session.rating;
      }
    }
    notifyListeners();
  }

  // Steam Sync integration
  void clearSteamProfile() {
    _steamProfile = null;
    _library.removeWhere((e) => e.id.startsWith('entry_steam_'));
    _sessions.removeWhere((s) => s.id.startsWith('steam_session_'));
    notifyListeners();
  }

  void clearAllData() {
    _library.clear();
    _sessions.clear();
    _steamProfile = null;
    notifyListeners();
  }

  void loadSampleData() {
    _library.clear();
    _sessions.clear();
    _library.addAll(SampleData.getInitialLibrary());
    _sessions.addAll(SampleData.getInitialSessions());
    _sessions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  void setSteamProfile(SteamProfile profile) {
    _steamProfile = profile;

    // Remove any hardcoded sample entries when connecting real Steam profile
    _library.removeWhere((e) => e.id.startsWith('entry_game_') || e.mediaId.startsWith('game_'));
    _sessions.removeWhere((s) => s.id.startsWith('sess_game_') || s.mediaId.startsWith('game_'));

    // Merge Steam games into Library
    for (final steamGame in profile.games) {
      final existingIndex = _library.indexWhere(
        (e) => e.mediaItem.steamAppId == steamGame.appId || e.mediaItem.title.toLowerCase() == steamGame.name.toLowerCase(),
      );

      final hasPlayed = steamGame.playtimeForeverMinutes > 0;
      final lastPlayedDate = (steamGame.rtimeLastPlayed != null && steamGame.rtimeLastPlayed! > 0)
          ? DateTime.fromMillisecondsSinceEpoch(steamGame.rtimeLastPlayed! * 1000)
          : null;

      // Classify status:
      // Over 2400 mins (40h) -> completed/mastered
      // Has played -> playing
      // Unplayed -> backlog
      final LibraryStatus status = !hasPlayed
          ? LibraryStatus.backlog
          : (steamGame.playtimeForeverMinutes >= 2400 ? LibraryStatus.completed : LibraryStatus.playing);

      if (existingIndex >= 0) {
        // Update hours from Steam
        final existing = _library[existingIndex];
        if (steamGame.playtimeForeverMinutes > existing.timeSpentMinutes) {
          existing.timeSpentMinutes = steamGame.playtimeForeverMinutes;
        }
        if (lastPlayedDate != null) {
          existing.lastActivity = lastPlayedDate;
        }
        existing.platform = 'PC - Steam';
        existing.isOwned = true;
      } else {
        // Auto-create new game entry from Steam
        final newItem = MediaItem(
          id: 'steam_${steamGame.appId}',
          title: steamGame.name,
          mediaType: MediaType.game,
          posterUrl: steamGame.posterUrl,
          backdropUrl: steamGame.headerUrl,
          releaseYear: 2020,
          releaseDateFormatted: 'Steam Library',
          genres: ['Steam'],
          synopsis: 'Imported from your connected Steam Library.',
          communityRating: 8.5,
          creator: 'Valve / Steam',
          steamAppId: steamGame.appId,
          runtimeMinutes: steamGame.playtimeForeverMinutes,
        );

        final newEntry = LibraryEntry(
          id: 'entry_steam_${steamGame.appId}',
          mediaId: newItem.id,
          mediaItem: newItem,
          status: status,
          platform: 'PC - Steam',
          format: 'Digital',
          isOwned: true,
          timeSpentMinutes: steamGame.playtimeForeverMinutes,
          progressPercent: status == LibraryStatus.completed
              ? 100.0
              : (hasPlayed ? 50.0 : 0.0),
          lastActivity: lastPlayedDate ?? DateTime.now().subtract(const Duration(days: 30)),
        );

        _library.add(newEntry);
      }

      // Automatically generate PlaySession for the Timeline if game was played
      if (hasPlayed && lastPlayedDate != null) {
        final sessionId = 'steam_session_${steamGame.appId}_${steamGame.rtimeLastPlayed}';
        final sessionExists = _sessions.any((s) => s.id == sessionId);

        if (!sessionExists) {
          final durationMins = steamGame.playtime2WeeksMinutes > 0
              ? steamGame.playtime2WeeksMinutes
              : (steamGame.playtimeForeverMinutes > 120 ? 120 : steamGame.playtimeForeverMinutes);

          _sessions.add(PlaySession(
            id: sessionId,
            mediaId: 'steam_${steamGame.appId}',
            mediaTitle: steamGame.name,
            mediaPoster: steamGame.posterUrl,
            mediaType: MediaType.game,
            date: lastPlayedDate,
            durationMinutes: durationMins > 0 ? durationMins : 60,
            platform: 'PC - Steam',
            notes: 'Steam play session (${(steamGame.playtimeForeverMinutes / 60).toStringAsFixed(1)}h total recorded on Steam)',
            progressPercentage: status == LibraryStatus.completed ? 100.0 : null,
            isCompletion: status == LibraryStatus.completed,
          ));
        }
      }
    }

    _sessions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }
}
