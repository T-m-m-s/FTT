import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/models/media_item.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/play_session.dart';
import 'package:ftt/services/cinema_service.dart';
import 'package:ftt/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    HttpOverrides.global = null;
  });

  group('CinemaService tests', () {
    final cinema = CinemaService();

    test('getTrendingCinema returns list of valid cinema and TV items', () async {
      final trending = await cinema.getTrendingCinema(limit: 10);
      expect(trending, isNotEmpty);
      expect(trending.length, lessThanOrEqualTo(10));

      for (final item in trending) {
        expect(
          item.mediaType == MediaType.movie || item.mediaType == MediaType.tvShow,
          isTrue,
        );
        expect(item.id, isNotEmpty);
        expect(item.title, isNotEmpty);
        expect(item.releaseYear, greaterThan(2000));
        expect(item.communityRating, greaterThanOrEqualTo(0.0));
      }
    });

    test('searchCinema with empty query returns empty list', () async {
      final results = await cinema.searchCinema('');
      expect(results, isEmpty);

      final whitespaceResults = await cinema.searchCinema('   ');
      expect(whitespaceResults, isEmpty);
    });

    test('searchCinema fetches live results from TMDB / TVMaze', () async {
      final results = await cinema.searchCinema('Inception', limit: 5);
      expect(results, isNotEmpty);
      final hasMatch = results.any((item) => item.title.toLowerCase().contains('inception'));
      expect(hasMatch, isTrue);
    });

    test('searchCinema with tvShow filter returns series', () async {
      final results = await cinema.searchCinema('Breaking Bad', typeFilter: MediaType.tvShow, limit: 5);
      expect(results, isNotEmpty);
      expect(results.first.mediaType, MediaType.tvShow);
    });
  });

  group('DatabaseService Cinema integration tests', () {
    test('Cinema filter includes both movie and tvShow items and excludes games', () {
      final db = DatabaseService();
      db.clearAllData();

      // Add 1 game, 1 movie, and 1 tv show
      final gameEntry = LibraryEntry(
        id: 'entry_game_1',
        mediaId: 'game_1',
        mediaItem: const MediaItem(
          id: 'game_1',
          title: 'Elden Ring',
          mediaType: MediaType.game,
          posterUrl: '',
          backdropUrl: '',
          releaseYear: 2022,
          releaseDateFormatted: '2022',
          genres: ['RPG'],
          synopsis: '',
          communityRating: 9.5,
          creator: 'FromSoftware',
        ),
        status: LibraryStatus.playing,
        timeSpentMinutes: 300,
      );

      final movieEntry = LibraryEntry(
        id: 'entry_movie_1',
        mediaId: 'movie_1',
        mediaItem: const MediaItem(
          id: 'movie_1',
          title: 'Dune: Part Two',
          mediaType: MediaType.movie,
          posterUrl: '',
          backdropUrl: '',
          releaseYear: 2024,
          releaseDateFormatted: '2024',
          genres: ['Sci-Fi'],
          synopsis: '',
          communityRating: 8.7,
          creator: 'Denis Villeneuve',
          runtimeMinutes: 166,
        ),
        status: LibraryStatus.completed,
        timeSpentMinutes: 166,
      );

      final tvEntry = LibraryEntry(
        id: 'entry_tv_1',
        mediaId: 'tv_1',
        mediaItem: const MediaItem(
          id: 'tv_1',
          title: 'Severance',
          mediaType: MediaType.tvShow,
          posterUrl: '',
          backdropUrl: '',
          releaseYear: 2022,
          releaseDateFormatted: '2022',
          genres: ['Sci-Fi', 'Thriller'],
          synopsis: '',
          communityRating: 8.9,
          creator: 'Apple TV+',
          runtimeMinutes: 55,
        ),
        status: LibraryStatus.playing,
        timeSpentMinutes: 110,
      );

      db.addOrUpdateEntry(gameEntry);
      db.addOrUpdateEntry(movieEntry);
      db.addOrUpdateEntry(tvEntry);

      // In Game mode
      db.setMediaFilter(MediaType.game);
      expect(db.currentLibraryFiltered.length, 1);
      expect(db.currentLibraryFiltered.first.mediaItem.title, 'Elden Ring');

      // Switch to Cinema mode
      db.setMediaFilter(MediaType.movie);
      expect(db.currentLibraryFiltered.length, 2);
      final titles = db.currentLibraryFiltered.map((e) => e.mediaItem.title).toList();
      expect(titles.contains('Dune: Part Two'), isTrue);
      expect(titles.contains('Severance'), isTrue);
      expect(titles.contains('Elden Ring'), isFalse);

      // Specific getters
      expect(db.movieItems.length, 1);
      expect(db.movieItems.first.mediaItem.title, 'Dune: Part Two');
      expect(db.tvItems.length, 1);
      expect(db.tvItems.first.mediaItem.title, 'Severance');

      // Top watched
      final topWatched = db.topPlayedGames();
      expect(topWatched.length, 2);
      expect(topWatched.first.mediaItem.title, 'Dune: Part Two'); // 166 min > 110 min
    });

    test('Cinema sessions are properly filtered by mediaType in DatabaseService', () {
      final db = DatabaseService();
      db.clearAllData();

      final gameSession = PlaySession(
        id: 'sess_1',
        mediaId: 'game_1',
        mediaTitle: 'Elden Ring',
        mediaPoster: '',
        mediaType: MediaType.game,
        date: DateTime.now().subtract(const Duration(days: 2)),
        durationMinutes: 60,
      );

      final movieSession = PlaySession(
        id: 'sess_2',
        mediaId: 'movie_1',
        mediaTitle: 'Dune: Part Two',
        mediaPoster: '',
        mediaType: MediaType.movie,
        date: DateTime.now().subtract(const Duration(days: 1)),
        durationMinutes: 166,
      );

      final tvSession = PlaySession(
        id: 'sess_3',
        mediaId: 'tv_1',
        mediaTitle: 'Severance',
        mediaPoster: '',
        mediaType: MediaType.tvShow,
        date: DateTime.now(),
        durationMinutes: 55,
      );

      db.addSession(gameSession);
      db.addSession(movieSession);
      db.addSession(tvSession);

      // Game filter
      db.setMediaFilter(MediaType.game);
      expect(db.currentSessionsFiltered.length, 1);
      expect(db.currentSessionsFiltered.first.mediaTitle, 'Elden Ring');

      // Cinema filter
      db.setMediaFilter(MediaType.movie);
      expect(db.currentSessionsFiltered.length, 2);
      final sessionTitles = db.currentSessionsFiltered.map((s) => s.mediaTitle).toList();
      expect(sessionTitles.contains('Dune: Part Two'), isTrue);
      expect(sessionTitles.contains('Severance'), isTrue);
      expect(sessionTitles.contains('Elden Ring'), isFalse);
    });
  });
}
