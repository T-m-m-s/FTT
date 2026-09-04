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

  /// Initialize database with rich data
  Future<void> init() async {
    if (_library.isEmpty) {
      _library.addAll(SampleData.getInitialLibrary());
      _sessions.addAll(SampleData.getInitialSessions());
      _sessions.sort((a, b) => b.date.compareTo(a.date));
      notifyListeners();
    }
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
    notifyListeners();
  }

  void setSteamProfile(SteamProfile profile) {
    _steamProfile = profile;

    // Merge Steam games into Library
    for (final steamGame in profile.games) {
      final existingIndex = _library.indexWhere(
        (e) => e.mediaItem.steamAppId == steamGame.appId || e.mediaItem.title.toLowerCase() == steamGame.name.toLowerCase(),
      );

      if (existingIndex >= 0) {
        // Update hours from Steam
        final existing = _library[existingIndex];
        if (steamGame.playtimeForeverMinutes > existing.timeSpentMinutes) {
          existing.timeSpentMinutes = steamGame.playtimeForeverMinutes;
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
          status: steamGame.playtimeForeverMinutes > 0
              ? (steamGame.playtimeForeverMinutes > 3000 ? LibraryStatus.completed : LibraryStatus.playing)
              : LibraryStatus.backlog,
          platform: 'PC - Steam',
          format: 'Digital',
          isOwned: true,
          timeSpentMinutes: steamGame.playtimeForeverMinutes,
          progressPercent: steamGame.playtimeForeverMinutes > 3000 ? 100.0 : 45.0,
          lastActivity: steamGame.rtimeLastPlayed != null
              ? DateTime.fromMillisecondsSinceEpoch(steamGame.rtimeLastPlayed! * 1000)
              : DateTime.now().subtract(const Duration(days: 4)),
        );

        _library.add(newEntry);
      }
    }

    notifyListeners();
  }
}
