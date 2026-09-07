import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/models/media_item.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/play_session.dart';
import 'package:ftt/models/steam_profile.dart';
import 'package:ftt/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  group('Model Serialization Tests', () {
    test('SteamGame and SteamProfile toMap and fromMap round-trip', () {
      final game = SteamGame(
        appId: 1449850,
        name: 'Yu-Gi-Oh! Master Duel',
        playtimeForeverMinutes: 2840,
        playtime2WeeksMinutes: 120,
        iconUrl: 'https://example.com/icon.jpg',
        rtimeLastPlayed: 1700000000,
      );

      final gameMap = game.toMap();
      final restoredGame = SteamGame.fromMap(gameMap);

      expect(restoredGame.appId, 1449850);
      expect(restoredGame.name, 'Yu-Gi-Oh! Master Duel');
      expect(restoredGame.playtimeForeverMinutes, 2840);
      expect(restoredGame.playtime2WeeksMinutes, 120);
      expect(restoredGame.iconUrl, 'https://example.com/icon.jpg');
      expect(restoredGame.rtimeLastPlayed, 1700000000);

      final profile = SteamProfile(
        steamId: '76561199041297020',
        personaName: 'FrigoBar',
        avatarUrl: 'https://example.com/avatar.jpg',
        profileUrl: 'https://steamcommunity.com/profiles/76561199041297020',
        lastSynced: DateTime(2026, 9, 7, 12, 0),
        games: [game],
      );

      final profileMap = profile.toMap();
      final restoredProfile = SteamProfile.fromMap(profileMap);

      expect(restoredProfile.steamId, '76561199041297020');
      expect(restoredProfile.personaName, 'FrigoBar');
      expect(restoredProfile.avatarUrl, 'https://example.com/avatar.jpg');
      expect(restoredProfile.games.length, 1);
      expect(restoredProfile.games.first.name, 'Yu-Gi-Oh! Master Duel');
      expect(restoredProfile.totalHoursPlayed, (2840 / 60).round());
    });

    test('MediaItem and LibraryEntry toMap and fromMap round-trip for Movie/TV', () {
      const movieItem = MediaItem(
        id: 'tmdb_movie_157336',
        title: 'Interstellar',
        mediaType: MediaType.movie,
        posterUrl: 'https://image.tmdb.org/t/p/w500/interstellar.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/interstellar_bd.jpg',
        releaseYear: 2014,
        releaseDateFormatted: 'Nov 5, 2014',
        genres: ['Science Fiction', 'Drama', 'Adventure'],
        synopsis: 'The adventures of a group of explorers who make use of a newly discovered wormhole.',
        communityRating: 8.6,
        creator: 'Christopher Nolan',
        runtimeMinutes: 169,
      );

      final entry = LibraryEntry(
        id: 'entry_tmdb_movie_157336',
        mediaId: movieItem.id,
        mediaItem: movieItem,
        status: LibraryStatus.completed,
        userRating: 9.5,
        platform: 'Netflix',
        format: 'Streaming',
        progressPercent: 100.0,
        timeSpentMinutes: 169,
        notes: 'Masterpiece cinema experience.',
      );

      final entryMap = entry.toMap();
      final restoredEntry = LibraryEntry.fromMap(entryMap);

      expect(restoredEntry.id, 'entry_tmdb_movie_157336');
      expect(restoredEntry.mediaItem.title, 'Interstellar');
      expect(restoredEntry.mediaItem.mediaType, MediaType.movie);
      expect(restoredEntry.mediaItem.creator, 'Christopher Nolan');
      expect(restoredEntry.mediaItem.runtimeMinutes, 169);
      expect(restoredEntry.status, LibraryStatus.completed);
      expect(restoredEntry.userRating, 9.5);
      expect(restoredEntry.platform, 'Netflix');
      expect(restoredEntry.format, 'Streaming');
      expect(restoredEntry.progressPercent, 100.0);
      expect(restoredEntry.notes, 'Masterpiece cinema experience.');
    });

    test('PlaySession toMap and fromMap round-trip for Cinema and Gaming', () {
      final session = PlaySession(
        id: 'sess_tv_arcane_1',
        mediaId: 'tmdb_tv_94605',
        mediaTitle: 'Arcane',
        mediaPoster: 'https://image.tmdb.org/poster.jpg',
        mediaType: MediaType.tvShow,
        date: DateTime(2026, 9, 7, 20, 30),
        durationMinutes: 45,
        rating: 10.0,
        platform: 'Netflix',
        notes: 'Watched Season 2 Episode 1',
        isCompletion: false,
      );

      final sessionMap = session.toMap();
      final restoredSession = PlaySession.fromMap(sessionMap);

      expect(restoredSession.id, 'sess_tv_arcane_1');
      expect(restoredSession.mediaTitle, 'Arcane');
      expect(restoredSession.mediaType, MediaType.tvShow);
      expect(restoredSession.durationMinutes, 45);
      expect(restoredSession.rating, 10.0);
      expect(restoredSession.notes, 'Watched Season 2 Episode 1');
      expect(restoredSession.platform, 'Netflix');
    });
  });

  group('DatabaseService Persistence Tests', () {
    test('Saves and restores Steam Profile across restarts', () async {
      final db = DatabaseService();
      db.clearAllData();
      await db.init();

      expect(db.steamProfile, isNull);

      final steamProfile = SteamProfile(
        steamId: '76561199041297020',
        personaName: 'FrigoBar',
        avatarUrl: 'https://example.com/avatar.jpg',
        profileUrl: 'https://steamcommunity.com/profiles/76561199041297020',
        games: [
          SteamGame(
            appId: 1449850,
            name: 'Yu-Gi-Oh! Master Duel',
            playtimeForeverMinutes: 2840,
            rtimeLastPlayed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
          SteamGame(
            appId: 774361,
            name: 'Blasphemous',
            playtimeForeverMinutes: 2220,
            rtimeLastPlayed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        ],
      );

      db.setSteamProfile(steamProfile);
      await db.persistAll();

      expect(db.steamProfile?.personaName, 'FrigoBar');
      expect(db.library.length, 2);
      expect(db.sessions.length, 2);

      // Simulate app restart: re-run init() as happens on cold app launch
      await db.init();

      expect(db.steamProfile, isNotNull);
      expect(db.steamProfile?.steamId, '76561199041297020');
      expect(db.steamProfile?.personaName, 'FrigoBar');
      expect(db.steamProfile?.games.length, 2);
      expect(db.library.length, 2);
      expect(db.sessions.length, 2);
    });

    test('Saves and restores Cinema (Movies/TV) entries and watch sessions across restarts', () async {
      final db = DatabaseService();
      db.clearAllData();
      await db.init();

      // Add a TV show
      const tvShow = MediaItem(
        id: 'tmdb_tv_94605',
        title: 'Arcane',
        mediaType: MediaType.tvShow,
        posterUrl: 'https://image.tmdb.org/t/p/w500/arcane.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/arcane_bd.jpg',
        releaseYear: 2021,
        releaseDateFormatted: 'Nov 6, 2021',
        genres: ['Animation', 'Sci-Fi & Fantasy', 'Action & Adventure'],
        synopsis: 'Amid the stark discord of twin cities Piltover and Zaun...',
        communityRating: 9.0,
        creator: 'Riot Games',
        runtimeMinutes: 45,
      );

      final entry = LibraryEntry(
        id: 'entry_tmdb_tv_94605',
        mediaId: tvShow.id,
        mediaItem: tvShow,
        status: LibraryStatus.playing,
        platform: 'Netflix',
        format: 'Streaming',
        timeSpentMinutes: 45,
      );

      db.addOrUpdateEntry(entry);

      // Add watch session
      final session = PlaySession(
        id: 'sess_watch_1',
        mediaId: tvShow.id,
        mediaTitle: tvShow.title,
        mediaPoster: tvShow.posterUrl,
        mediaType: MediaType.tvShow,
        date: DateTime.now(),
        durationMinutes: 45,
        notes: 'Season 1 Episode 1',
        platform: 'Netflix',
      );

      db.addSession(session);
      db.setMediaFilter(MediaType.movie); // Switch active filter to Cinema
      await db.persistAll();

      expect(db.currentLibraryFiltered.length, 1);
      expect(db.currentSessionsFiltered.length, 1);
      expect(db.activeMediaFilter, MediaType.movie);

      // Simulate app restart
      await db.init();

      expect(db.activeMediaFilter, MediaType.movie);
      expect(db.tvItems.length, 1);
      expect(db.tvItems.first.mediaItem.title, 'Arcane');
      expect(db.tvItems.first.timeSpentMinutes, 90); // 45 initial + 45 from session
      expect(db.currentSessionsFiltered.length, 1);
      expect(db.currentSessionsFiltered.first.notes, 'Season 1 Episode 1');
    });

    test('Clearing Steam profile unlinks and removes Steam items from persistent storage', () async {
      final db = DatabaseService();
      db.clearAllData();
      await db.init();

      final steamProfile = SteamProfile(
        steamId: '76561199041297020',
        personaName: 'FrigoBar',
        avatarUrl: 'https://example.com/avatar.jpg',
        profileUrl: 'https://steamcommunity.com/profiles/76561199041297020',
        games: [
          SteamGame(
            appId: 1449850,
            name: 'Yu-Gi-Oh! Master Duel',
            playtimeForeverMinutes: 2840,
            rtimeLastPlayed: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          ),
        ],
      );

      db.setSteamProfile(steamProfile);
      await db.persistAll();
      expect(db.steamProfile, isNotNull);

      // Disconnect Steam
      db.clearSteamProfile();
      await db.persistAll();

      expect(db.steamProfile, isNull);
      expect(db.library, isEmpty);
      expect(db.sessions, isEmpty);

      // Restart app
      await db.init();

      expect(db.steamProfile, isNull);
      expect(db.library, isEmpty);
      expect(db.sessions, isEmpty);
    });

    test('Updating status and rating persists to storage', () async {
      final db = DatabaseService();
      db.clearAllData();
      await db.init();

      const game = MediaItem(
        id: 'igdb_123',
        title: 'Hollow Knight: Silksong',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2025,
        releaseDateFormatted: '2025',
        genres: ['Metroidvania'],
        synopsis: 'Play as Hornet...',
        communityRating: 9.8,
        creator: 'Team Cherry',
      );

      final entry = LibraryEntry(
        id: 'entry_igdb_123',
        mediaId: game.id,
        mediaItem: game,
        status: LibraryStatus.backlog,
      );

      db.addOrUpdateEntry(entry);
      db.updateStatus(game.id, LibraryStatus.completed);
      db.updateRating(game.id, 9.7);
      await db.persistAll();

      // Restart app
      await db.init();

      expect(db.library.length, 1);
      final restored = db.library.first;
      expect(restored.status, LibraryStatus.completed);
      expect(restored.progressPercent, 100.0);
      expect(restored.userRating, 9.7);
    });
  });
}
