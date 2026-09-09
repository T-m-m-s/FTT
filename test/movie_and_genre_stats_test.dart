import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/models/media_item.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/screens/media_detail_screen.dart';
import 'package:ftt/services/database_service.dart';
import 'package:ftt/services/update_service.dart';
import 'package:ftt/widgets/playing_now_card.dart';
import 'package:ftt/widgets/stats_charts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    UpdateService.enableAutoCheck = false;
    await DatabaseService().init();
  });

  testWidgets('Movie does not display percentage indicator in MediaDetailScreen and PlayingNowCard', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final movieEntry = LibraryEntry(
      id: 'movie_1',
      mediaId: 'tmdb_movie_1',
      mediaItem: const MediaItem(
        id: 'tmdb_movie_1',
        title: 'Oppenheimer',
        mediaType: MediaType.movie,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2023,
        releaseDateFormatted: 'July 2023',
        genres: ['Biography', 'Drama', 'History'],
        synopsis: 'The story of J. Robert Oppenheimer.',
        communityRating: 8.9,
        creator: 'Christopher Nolan',
        runtimeMinutes: 180,
      ),
      status: LibraryStatus.backlog,
      progressPercent: 0.0,
      timeSpentMinutes: 0,
    );

    final db = DatabaseService();
    db.clearAllData();
    db.addOrUpdateEntry(movieEntry);

    // 1. Verify PlayingNowCard has no CircularProgressIndicator for Movie
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PlayingNowCard(
          entry: movieEntry,
          onTap: () {},
          onLogSession: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // No CircularProgressIndicator for Movie
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('In Watchlist'), findsOneWidget);

    // 2. Open MediaDetailScreen for Movie
    await tester.pumpWidget(MaterialApp(
      home: MediaDetailScreen(entry: movieEntry),
    ));
    await tester.pumpAndSettle();

    // No CircularProgressIndicator in playthrough card for Movie
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('0%'), findsNothing);
    expect(find.text('Status: In Watchlist'), findsOneWidget);
    expect(find.text('Runtime: 180 min'), findsOneWidget);
    expect(find.text('+ Watched'), findsOneWidget);

    // 3. Tap '+ Watched' button
    await tester.tap(find.text('+ Watched'));
    await tester.pumpAndSettle();

    // Status is now Watched (completed)
    expect(movieEntry.status, LibraryStatus.completed);
    expect(find.text('Status: Watched'), findsOneWidget);
    expect(find.text('Watched'), findsWidgets);
    expect(find.text('0%'), findsNothing);
    expect(find.text('100%'), findsNothing);
  });

  testWidgets('GenreDistributionChart aggregates genres by titles and time spent', (WidgetTester tester) async {
    final entry1 = LibraryEntry(
      id: 'g1',
      mediaId: 'm1',
      mediaItem: const MediaItem(
        id: 'm1',
        title: 'Cyberpunk 2077',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2020,
        releaseDateFormatted: '2020',
        genres: ['RPG', 'Sci-Fi', 'Action'],
        synopsis: '',
        communityRating: 8.5,
        creator: 'CD Projekt Red',
      ),
      status: LibraryStatus.completed,
      timeSpentMinutes: 360, // 6h
    );

    final entry2 = LibraryEntry(
      id: 'g2',
      mediaId: 'm2',
      mediaItem: const MediaItem(
        id: 'm2',
        title: 'The Witcher 3',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2015,
        releaseDateFormatted: '2015',
        genres: ['RPG', 'Fantasy', 'Adventure'],
        synopsis: '',
        communityRating: 9.5,
        creator: 'CD Projekt Red',
      ),
      status: LibraryStatus.completed,
      timeSpentMinutes: 600, // 10h
    );

    final entry3 = LibraryEntry(
      id: 'g3',
      mediaId: 'm3',
      mediaItem: const MediaItem(
        id: 'm3',
        title: 'DOOM Eternal',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2020,
        releaseDateFormatted: '2020',
        genres: ['Action', 'Sci-Fi', 'Shooter'],
        synopsis: '',
        communityRating: 8.8,
        creator: 'id Software',
      ),
      status: LibraryStatus.playing,
      timeSpentMinutes: 120, // 2h
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: GenreDistributionChart(
            entries: [entry1, entry2, entry3],
            isGame: true,
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Title mode
    expect(find.text('Top Game Genres'), findsOneWidget);
    expect(find.text('RPG'), findsOneWidget);
    expect(find.text('Action'), findsOneWidget);
    expect(find.text('Sci-Fi'), findsOneWidget);

    // RPG has 2 games
    expect(find.text('2 games • 16h'), findsOneWidget);

    // Switch to Time mode
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    // In time mode, subtitle shows duration first
    expect(find.text('16h (2 games)'), findsOneWidget);
  });
}
