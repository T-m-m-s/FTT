import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/screens/settings_screen.dart';
import 'package:ftt/services/anime_tracker_service.dart';
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

  testWidgets('SettingsScreen renders centralized sections and connects', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final db = DatabaseService();
    db.clearAllData();

    await tester.pumpWidget(const MaterialApp(
      home: SettingsScreen(),
    ));
    await tester.pumpAndSettle();

    // 1. Verify Headers & Titles
    expect(find.text('Settings & Connections'), findsOneWidget);
    expect(find.text('App & System Updates'), findsOneWidget);
    expect(find.text('Gaming Connections'), findsOneWidget);
    expect(find.text('Anime & Cinema Trackers'), findsOneWidget);
    expect(find.text('Storage & Library Management'), findsOneWidget);

    // 2. Verify Steam and Trackers cards exist
    expect(find.text('Steam Profile'), findsOneWidget);
    expect(find.text('Connect Steam'), findsOneWidget);

    expect(find.text('MyAnimeList (MAL)'), findsOneWidget);
    expect(find.text('Connect MAL'), findsOneWidget);

    expect(find.text('AniList'), findsOneWidget);
    expect(find.text('Connect AniList'), findsOneWidget);

    // 3. Tap Connect MAL button -> dialog appears
    await tester.tap(find.text('Connect MAL'));
    await tester.pumpAndSettle();

    expect(find.text('Connect MyAnimeList'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Connect MyAnimeList'), findsNothing);
  });

  test('AnimeTrackerService syncs MyAnimeList with correct TV/Movie classification', () async {
    final db = DatabaseService();
    db.clearAllData();

    final mockMalJson = [
      {
        'anime_id': 21,
        'anime_title': 'One Piece',
        'anime_title_eng': 'One Piece',
        'anime_media_type_string': 'TV',
        'anime_image_path': 'https://example.com/onepiece.jpg',
        'anime_start_date_string': '10-20-99',
        'genres': [{'id': 1, 'name': 'Action'}, {'id': 2, 'name': 'Adventure'}],
        'status': 1, // Watching
        'score': 9,
        'num_watched_episodes': 1000,
        'anime_num_episodes': 1100,
        'anime_score_val': 8.7,
      },
      {
        'anime_id': 199,
        'anime_title': 'Sen to Chihiro no Kamikakushi',
        'anime_title_eng': 'Spirited Away',
        'anime_media_type_string': 'Movie',
        'anime_image_path': 'https://example.com/spiritedaway.jpg',
        'anime_start_date_string': '07-20-01',
        'genres': [{'id': 10, 'name': 'Fantasy'}],
        'status': 2, // Completed
        'score': 10,
        'num_watched_episodes': 1,
        'anime_num_episodes': 1,
        'anime_score_val': 8.8,
      }
    ];

    final mockClient = MockClient((request) async {
      if (request.url.path.contains('/animelist/TestUser/load.json')) {
        final offset = request.url.queryParameters['offset'] ?? '0';
        if (offset == '0') {
          return http.Response(jsonEncode(mockMalJson), 200, headers: {'content-type': 'application/json'});
        } else {
          return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
        }
      }
      return http.Response('Not found', 404);
    });

    final service = AnimeTrackerService();
    final imported = await service.syncMyAnimeList('TestUser', client: mockClient);

    expect(imported, 2);
    expect(db.malUsername, 'TestUser');
    expect(db.malAnimeCount, 2);

    // Verify TV show
    final op = db.library.firstWhere((e) => e.mediaItem.title == 'One Piece');
    expect(op.mediaItem.mediaType, MediaType.tvShow);
    expect(op.status, LibraryStatus.playing);
    expect(op.watchedEpisodesCount, 1000);
    expect(op.totalEpisodesCount, 1100);
    expect(op.userRating, 9.0);
    expect(op.mediaItem.genres.contains('Anime'), isTrue);
    expect(op.mediaItem.genres.contains('Action'), isTrue);

    // Verify Movie
    final spirited = db.library.firstWhere((e) => e.mediaItem.title == 'Spirited Away');
    expect(spirited.mediaItem.mediaType, MediaType.movie);
    expect(spirited.status, LibraryStatus.completed);
    expect(spirited.progressPercent, 100.0);
    expect(spirited.userRating, 10.0);
    expect(spirited.mediaItem.genres.contains('Anime'), isTrue);
    expect(spirited.mediaItem.genres.contains('Fantasy'), isTrue);

    // Verify Timeline sessions generated
    expect(db.sessions.length, 2);
    final opSession = db.sessions.firstWhere((s) => s.mediaTitle == 'One Piece');
    expect(opSession.platform, 'Anime Tracker (MAL)');
    expect(opSession.rating, 9.0);

    // Verify Disconnect / Clear
    db.clearMalData();
    expect(db.malUsername, isNull);
    expect(db.malAnimeCount, 0);
    expect(db.library.any((e) => e.mediaItem.title == 'One Piece'), isFalse);
    expect(db.sessions.any((s) => s.mediaTitle == 'One Piece'), isFalse);
  });
}
