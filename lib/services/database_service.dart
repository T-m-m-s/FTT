import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  static const String _keyLibrary = 'ftt_library';
  static const String _keySessions = 'ftt_sessions';
  static const String _keySteamProfile = 'ftt_steam_profile';
  static const String _keyActiveFilter = 'ftt_active_filter';

  SharedPreferences? _prefs;

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
    _persistFilter();
    notifyListeners();
  }

  Future<SharedPreferences?> _getPrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      return null;
    }
  }

  /// Initialize database - restores persistent state across app restarts
  Future<void> init() async {
    final prefs = await _getPrefs();

    // 1. Load active filter
    final savedFilter = prefs?.getString(_keyActiveFilter);
    if (savedFilter != null && savedFilter.isNotEmpty) {
      try {
        _activeMediaFilter = MediaType.values.byName(savedFilter);
      } catch (_) {}
    }

    // 2. Load Steam Profile
    final profileJson = prefs?.getString(_keySteamProfile);
    if (profileJson != null && profileJson.isNotEmpty) {
      try {
        final map = jsonDecode(profileJson) as Map<String, dynamic>;
        _steamProfile = SteamProfile.fromMap(map);
      } catch (e) {
        debugPrint('Error loading saved Steam profile: $e');
      }
    }

    // 3. Load Library
    final libraryJson = prefs?.getString(_keyLibrary);
    if (libraryJson != null && libraryJson.isNotEmpty) {
      try {
        final list = jsonDecode(libraryJson) as List<dynamic>;
        _library.clear();
        for (final item in list) {
          _library.add(LibraryEntry.fromMap(Map<String, dynamic>.from(item as Map)));
        }
      } catch (e) {
        debugPrint('Error loading saved library: $e');
      }
    }

    // 4. Load Sessions
    final sessionsJson = prefs?.getString(_keySessions);
    if (sessionsJson != null && sessionsJson.isNotEmpty) {
      try {
        final list = jsonDecode(sessionsJson) as List<dynamic>;
        _sessions.clear();
        for (final item in list) {
          _sessions.add(PlaySession.fromMap(Map<String, dynamic>.from(item as Map)));
        }
        _sessions.sort((a, b) => b.date.compareTo(a.date));
      } catch (e) {
        debugPrint('Error loading saved sessions: $e');
      }
    }

    // Purge any legacy sample data so only real user data appears
    final initialLibCount = _library.length;
    _library.removeWhere((e) => e.id.startsWith('entry_game_') || e.mediaId.startsWith('game_'));
    if (_library.length != initialLibCount) _persistLibrary();

    final initialSessCount = _sessions.length;
    _sessions.removeWhere((s) => s.id.startsWith('sess_game_') || s.mediaId.startsWith('game_'));
    if (_sessions.length != initialSessCount) _persistSessions();

    notifyListeners();
  }

  // Persistence helpers
  Future<void> _persistLibrary() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      final jsonString = jsonEncode(_library.map((e) => e.toMap()).toList());
      await prefs.setString(_keyLibrary, jsonString);
    } catch (e) {
      debugPrint('Error persisting library: $e');
    }
  }

  Future<void> _persistSessions() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      final jsonString = jsonEncode(_sessions.map((s) => s.toMap()).toList());
      await prefs.setString(_keySessions, jsonString);
    } catch (e) {
      debugPrint('Error persisting sessions: $e');
    }
  }

  Future<void> _persistSteamProfile() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      if (_steamProfile != null) {
        await prefs.setString(_keySteamProfile, jsonEncode(_steamProfile!.toMap()));
      } else {
        await prefs.remove(_keySteamProfile);
      }
    } catch (e) {
      debugPrint('Error persisting Steam profile: $e');
    }
  }

  Future<void> _persistFilter() async {
    try {
      final prefs = await _getPrefs();
      if (prefs == null) return;
      await prefs.setString(_keyActiveFilter, _activeMediaFilter.name);
    } catch (e) {
      debugPrint('Error persisting filter: $e');
    }
  }

  /// Explicit flush of all state to storage
  Future<void> persistAll() async {
    await Future.wait([
      _persistLibrary(),
      _persistSessions(),
      _persistSteamProfile(),
      _persistFilter(),
    ]);
  }

  // Filtered queries
  List<LibraryEntry> get currentLibraryFiltered {
    if (_activeMediaFilter == MediaType.game) {
      return _library.where((entry) => entry.mediaItem.mediaType == MediaType.game).toList();
    } else {
      return _library
          .where((entry) =>
              entry.mediaItem.mediaType == MediaType.movie ||
              entry.mediaItem.mediaType == MediaType.tvShow)
          .toList();
    }
  }

  List<LibraryEntry> get movieItems =>
      _library.where((e) => e.mediaItem.mediaType == MediaType.movie).toList();

  List<LibraryEntry> get tvItems =>
      _library.where((e) => e.mediaItem.mediaType == MediaType.tvShow).toList();

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
    if (_activeMediaFilter == MediaType.game) {
      return _sessions.where((s) => s.mediaType == MediaType.game).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } else {
      return _sessions
          .where((s) => s.mediaType == MediaType.movie || s.mediaType == MediaType.tvShow)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }
  }

  // Add or update library entry
  void addOrUpdateEntry(LibraryEntry entry) {
    final index = _library.indexWhere((e) => e.mediaId == entry.mediaId);
    if (index >= 0) {
      _library[index] = entry;
    } else {
      _library.add(entry);
    }
    _persistLibrary();
    notifyListeners();
  }

  void updateStatus(String mediaId, LibraryStatus status) {
    final index = _library.indexWhere((e) => e.mediaId == mediaId);
    if (index >= 0) {
      _library[index].status = status;
      if (status == LibraryStatus.completed) {
        _library[index].progressPercent = 100.0;
      }
      _persistLibrary();
      notifyListeners();
    }
  }

  void updateRating(String mediaId, double rating) {
    final index = _library.indexWhere((e) => e.mediaId == mediaId);
    if (index >= 0) {
      _library[index].userRating = rating;
      _persistLibrary();
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
      _persistLibrary();
    }
    _persistSessions();
    notifyListeners();
  }

  // Steam Sync integration
  void clearSteamProfile() {
    _steamProfile = null;
    _library.removeWhere((e) => e.id.startsWith('entry_steam_'));
    _sessions.removeWhere((s) => s.id.startsWith('steam_session_'));
    _persistSteamProfile();
    _persistLibrary();
    _persistSessions();
    notifyListeners();
  }

  void clearAllData() {
    _library.clear();
    _sessions.clear();
    _steamProfile = null;
    _persistSteamProfile();
    _persistLibrary();
    _persistSessions();
    notifyListeners();
  }

  void loadSampleData() {
    _library.clear();
    _sessions.clear();
    _library.addAll(SampleData.getInitialLibrary());
    _sessions.addAll(SampleData.getInitialSessions());
    _sessions.sort((a, b) => b.date.compareTo(a.date));
    _persistLibrary();
    _persistSessions();
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
          genres: const ['Steam'],
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
    _persistSteamProfile();
    _persistLibrary();
    _persistSessions();
    notifyListeners();
  }
}
