import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/models/media_item.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/tv_season.dart';
import 'package:ftt/screens/media_detail_screen.dart';
import 'package:ftt/services/database_service.dart';
import 'package:ftt/services/update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    UpdateService.enableAutoCheck = false;
    await DatabaseService().init();
  });

  testWidgets('MediaDetailScreen renders TV Show seasons, episodes, and calculates progress', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const season1 = TvSeason(
      seasonNumber: 1,
      name: 'Season 1',
      episodeCount: 2,
      episodes: [
        TvEpisode(
          id: 's1_e1',
          seasonNumber: 1,
          episodeNumber: 1,
          name: 'Pilot Episode',
          overview: 'Introduction to the show',
          runtimeMinutes: 45,
        ),
        TvEpisode(
          id: 's1_e2',
          seasonNumber: 1,
          episodeNumber: 2,
          name: 'Second Episode',
          overview: 'The story continues',
          runtimeMinutes: 50,
        ),
      ],
    );

    const season2 = TvSeason(
      seasonNumber: 2,
      name: 'Season 2',
      episodeCount: 2,
      episodes: [
        TvEpisode(
          id: 's2_e1',
          seasonNumber: 2,
          episodeNumber: 1,
          name: 'Season 2 Premiere',
          overview: 'A new adventure begins',
          runtimeMinutes: 48,
        ),
        TvEpisode(
          id: 's2_e2',
          seasonNumber: 2,
          episodeNumber: 2,
          name: 'Season 2 Finale',
          overview: 'Climactic ending',
          runtimeMinutes: 55,
        ),
      ],
    );

    final tvEntry = LibraryEntry(
      id: 'entry_test_tv',
      mediaId: 'test_tv_1',
      mediaItem: const MediaItem(
        id: 'test_tv_1',
        title: 'Cyberpunk Adventure',
        mediaType: MediaType.tvShow,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2024,
        releaseDateFormatted: 'Jan 2024',
        genres: ['Sci-Fi', 'Action'],
        synopsis: 'A futuristic show.',
        communityRating: 8.8,
        creator: 'Studio Trigger',
      ),
      status: LibraryStatus.playing,
      totalEpisodesCount: 4,
      cachedSeasons: [season1, season2],
      watchedEpisodeIds: ['s1_e1'], // 1 of 4 watched = 25%
      progressPercent: 25.0,
      timeSpentMinutes: 45,
    );

    DatabaseService().addOrUpdateEntry(tvEntry);

    await tester.pumpWidget(MaterialApp(
      home: MediaDetailScreen(entry: tvEntry),
    ));
    await tester.pumpAndSettle();

    // Verify title and TV section header
    expect(find.text('Cyberpunk Adventure'), findsOneWidget);
    expect(find.text('Seasons & Episodes'), findsOneWidget);

    // Initial progress is 25% (1 of 4)
    expect(find.text('25%'), findsWidgets);
    expect(find.text('1 / 4 ep (25%)'), findsOneWidget);

    // Next unwatched episode button appears: S1E2
    expect(find.text('S1E2'), findsOneWidget);

    // Pilot episode is marked watched (checked icon)
    expect(find.byIcon(Icons.check_circle_rounded), findsWidgets);

    // Tap next episode button (S1E2) in playthrough card
    await tester.tap(find.text('S1E2'));
    await tester.pumpAndSettle();

    // Now 2 of 4 watched = 50%
    expect(find.text('2 / 4 ep (50%)'), findsOneWidget);
    expect(find.text('50%'), findsWidgets);

    // Next episode button now advances to S2E1
    expect(find.text('S2E1'), findsOneWidget);

    // Switch to Season 2 in dropdown
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();

    // Tap Season 2 option in dropdown
    await tester.tap(find.text('Season 2').last);
    await tester.pumpAndSettle();

    expect(find.text('E01  •  Season 2 Premiere'), findsOneWidget);

    // Tap Mark Season
    await tester.tap(find.text('Mark Season'));
    await tester.pumpAndSettle();

    // All 4 episodes are now watched (100%)
    expect(find.text('4 / 4 ep (100%)'), findsOneWidget);
    expect(find.text('100%'), findsWidgets);
    expect(find.text('All Watched'), findsWidgets);
  });

  testWidgets('MediaDetailScreen can remove a TV Show from the library', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = DatabaseService();
    final tvEntry = LibraryEntry(
      id: 'entry_delete_test',
      mediaId: 'delete_test_id',
      mediaItem: const MediaItem(
        id: 'delete_test_id',
        title: 'Show To Remove',
        mediaType: MediaType.tvShow,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2024,
        releaseDateFormatted: '2024',
        genres: ['Drama'],
        synopsis: 'A show to drop.',
        communityRating: 7.0,
        creator: 'Channel',
      ),
      status: LibraryStatus.playing,
    );

    db.addOrUpdateEntry(tvEntry);
    expect(db.library.any((e) => e.mediaId == 'delete_test_id'), isTrue);

    await tester.pumpWidget(MaterialApp(
      home: MediaDetailScreen(entry: tvEntry),
    ));
    await tester.pumpAndSettle();

    // Verify remove button is present in AppBar and bottom
    expect(find.byIcon(Icons.delete_outline_rounded), findsWidgets);

    // Tap Delete icon button in AppBar
    await tester.tap(find.byIcon(Icons.delete_outline_rounded).first);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Remove series?'), findsOneWidget);
    expect(find.text('Are you sure you want to remove "Show To Remove" from your library? Your watch history and progress will be deleted.'), findsOneWidget);

    // Tap Remove button in dialog
    await tester.tap(find.widgetWithText(ElevatedButton, 'Remove'));
    await tester.pumpAndSettle();

    // Verified removed from DatabaseService
    expect(db.library.any((e) => e.mediaId == 'delete_test_id'), isFalse);
  });
}
