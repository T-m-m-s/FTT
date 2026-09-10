import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ftt/models/custom_category.dart';
import 'package:ftt/models/library_entry.dart';
import 'package:ftt/models/media_item.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/steam_achievement.dart';
import 'package:ftt/services/database_service.dart';
import 'package:ftt/services/steam_service.dart';
import 'package:ftt/screens/media_detail_screen.dart';
import 'package:ftt/screens/home_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SteamAchievement & CustomCategory Models', () {
    test('SteamAchievement correctly serializes and deserializes', () {
      final now = DateTime.now();
      final ach = SteamAchievement(
        apiName: 'ACH_MASTER_01',
        name: 'Master Duelist',
        description: 'Win 50 duels',
        iconUrl: 'https://example.com/icon_open.jpg',
        iconLockedUrl: 'https://example.com/icon_closed.jpg',
        isUnlocked: true,
        unlockTime: now,
      );

      final map = ach.toMap();
      expect(map['apiName'], 'ACH_MASTER_01');
      expect(map['name'], 'Master Duelist');
      expect(map['isUnlocked'], 1);

      final fromMap = SteamAchievement.fromMap(map);
      expect(fromMap.apiName, 'ACH_MASTER_01');
      expect(fromMap.name, 'Master Duelist');
      expect(fromMap.isUnlocked, isTrue);
      expect(fromMap.unlockTime, isNotNull);
    });

    test('CustomCategory correctly serializes and deserializes', () {
      final cat = CustomCategory(
        id: 'cat_favs',
        name: 'Favorites',
        showOnHome: true,
        order: 1,
      );

      final map = cat.toMap();
      expect(map['id'], 'cat_favs');
      expect(map['name'], 'Favorites');
      expect(map['showOnHome'], 1);
      expect(map['order'], 1);

      final fromMap = CustomCategory.fromMap(map);
      expect(fromMap.id, 'cat_favs');
      expect(fromMap.name, 'Favorites');
      expect(fromMap.showOnHome, isTrue);
      expect(fromMap.order, 1);
    });

    test('LibraryEntry calculates game progress percentage from Steam achievements', () {
      final item = MediaItem(
        id: 'steam_1449850',
        title: 'Master Duel',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2022,
        releaseDateFormatted: '2022',
        genres: const ['Card Game'],
        synopsis: 'Duel',
        communityRating: 8.0,
        creator: 'Konami',
        steamAppId: 1449850,
      );

      final entry = LibraryEntry(
        id: 'entry_steam_1449850',
        mediaId: item.id,
        mediaItem: item,
        status: LibraryStatus.playing,
        cachedAchievements: [
          const SteamAchievement(
            apiName: 'ach_1',
            name: 'Welcome',
            description: 'Start game',
            iconUrl: '',
            isUnlocked: true,
          ),
          const SteamAchievement(
            apiName: 'ach_2',
            name: 'Summoner',
            description: 'Special summon 50 monsters',
            iconUrl: '',
            isUnlocked: true,
          ),
          const SteamAchievement(
            apiName: 'ach_3',
            name: 'Chain',
            description: 'Chain 100 times',
            iconUrl: '',
            isUnlocked: false,
          ),
          const SteamAchievement(
            apiName: 'ach_4',
            name: 'Final Boss',
            description: 'Win platinum',
            iconUrl: '',
            isUnlocked: false,
          ),
        ],
      );

      entry.updateGameAchievementProgress();
      expect(entry.totalAchievementsCount, 4);
      expect(entry.unlockedAchievementsCount, 2);
      expect(entry.progressPercent, 50.0);
      expect(entry.status, LibraryStatus.playing);

      // When all achievements unlocked -> status completes
      entry.cachedAchievements = [
        const SteamAchievement(apiName: 'a1', name: 'A1', description: '', iconUrl: '', isUnlocked: true),
        const SteamAchievement(apiName: 'a2', name: 'A2', description: '', iconUrl: '', isUnlocked: true),
      ];
      entry.updateGameAchievementProgress();
      expect(entry.totalAchievementsCount, 2);
      expect(entry.unlockedAchievementsCount, 2);
      expect(entry.progressPercent, 100.0);
      expect(entry.status, LibraryStatus.completed);
    });
  });

  group('SteamService Achievement Fetching (Public XML)', () {
    test('fetches and parses achievements without API key from XML', () async {
      const mockXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<playerstats>
	<privacyState>public</privacyState>
	<visibilityState>3</visibilityState>
	<achievements>
		<achievement closed="1">
			<iconClosed><![CDATA[https://cdn.steam.com/locked1.jpg]]></iconClosed>
			<iconOpen><![CDATA[https://cdn.steam.com/unlocked1.jpg]]></iconOpen>
			<name><![CDATA[First Step]]></name>
			<apiname><![CDATA[ach_step_1]]></apiname>
			<description><![CDATA[Complete tutorial]]></description>
			<unlockTimestamp>1643702169</unlockTimestamp>
		</achievement>
		<achievement closed="0">
			<iconClosed><![CDATA[https://cdn.steam.com/locked2.jpg]]></iconClosed>
			<iconOpen><![CDATA[https://cdn.steam.com/unlocked2.jpg]]></iconOpen>
			<name><![CDATA[Grand Champion]]></name>
			<apiname><![CDATA[ach_champion]]></apiname>
			<description><![CDATA[Reach highest rank]]></description>
		</achievement>
	</achievements>
</playerstats>''';

      final client = MockClient((request) async {
        if (request.url.toString().contains('stats/1449850/?xml=1')) {
          return http.Response(mockXml, 200, headers: {'content-type': 'application/xml; charset=utf-8'});
        }
        return http.Response('Not Found', 404);
      });

      final achievements = await SteamService.fetchGameAchievements(
        steamIdOrProfile: '76561199041297020',
        appId: 1449850,
        client: client,
      );

      expect(achievements.length, 2);

      final ach1 = achievements[0];
      expect(ach1.apiName, 'ach_step_1');
      expect(ach1.name, 'First Step');
      expect(ach1.description, 'Complete tutorial');
      expect(ach1.isUnlocked, isTrue);
      expect(ach1.iconUrl, 'https://cdn.steam.com/unlocked1.jpg');
      expect(ach1.unlockTime, isNotNull);

      final ach2 = achievements[1];
      expect(ach2.apiName, 'ach_champion');
      expect(ach2.name, 'Grand Champion');
      expect(ach2.description, 'Reach highest rank');
      expect(ach2.isUnlocked, isFalse);
      expect(ach2.iconUrl, 'https://cdn.steam.com/locked2.jpg');
      expect(ach2.unlockTime, isNull);
    });
  });

  group('DatabaseService Category Operations', () {
    test('manages custom categories and entry category tags', () async {
      final db = DatabaseService();
      await db.init();

      // Ensure default 'Now Playing' category exists
      expect(db.categories.any((c) => c.id == 'cat_now_playing'), isTrue);

      // Add a custom category
      await db.addCategory('Favorites', showOnHome: true);
      expect(db.categories.any((c) => c.name == 'Favorites'), isTrue);
      final favCat = db.categories.firstWhere((c) => c.name == 'Favorites');
      expect(favCat.showOnHome, isTrue);

      // Add a sample entry and assign category
      final item = MediaItem(
        id: 'test_game_1',
        title: 'Balatro',
        mediaType: MediaType.game,
        posterUrl: '',
        backdropUrl: '',
        releaseYear: 2024,
        releaseDateFormatted: '2024',
        genres: const ['Roguelike'],
        synopsis: 'Poker roguelike',
        communityRating: 9.0,
        creator: 'LocalThunk',
      );
      final entry = LibraryEntry(
        id: 'entry_test_game_1',
        mediaId: item.id,
        mediaItem: item,
        status: LibraryStatus.playing,
      );
      db.addOrUpdateEntry(entry);

      // Toggle category for entry
      db.toggleEntryCategory(entry.mediaId, favCat.id);
      expect(entry.customCategories.contains(favCat.id), isTrue);

      // Verify getEntriesForCategory
      final favEntries = db.getEntriesForCategory(favCat.id);
      expect(favEntries.length, 1);
      expect(favEntries.first.mediaId, 'test_game_1');

      // Toggle Home shelf visibility
      await db.toggleCategoryOnHome(favCat.id);
      expect(db.homeCategories.any((c) => c.id == favCat.id), isFalse);

      await db.toggleCategoryOnHome(favCat.id);
      expect(db.homeCategories.any((c) => c.id == favCat.id), isTrue);

      // Delete category
      await db.deleteCategory(favCat.id);
      expect(db.categories.any((c) => c.id == favCat.id), isFalse);
      expect(entry.customCategories.contains(favCat.id), isFalse);
    });
  });

  group('UI Widgets for Achievements and Categories', () {
    testWidgets('MediaDetailScreen renders achievements explorer and category tags', (tester) async {
      final db = DatabaseService();
      await db.init();

      final item = MediaItem(
        id: 'game_ach_test',
        title: 'Dark Souls Remastered',
        mediaType: MediaType.game,
        posterUrl: 'https://example.com/poster.jpg',
        backdropUrl: '',
        releaseYear: 2018,
        releaseDateFormatted: '2018',
        genres: const ['Action RPG'],
        synopsis: 'Praise the sun',
        communityRating: 9.2,
        creator: 'FromSoftware',
        steamAppId: 570940,
      );

      final entry = LibraryEntry(
        id: 'entry_game_ach_test',
        mediaId: item.id,
        mediaItem: item,
        status: LibraryStatus.playing,
        cachedAchievements: [
          const SteamAchievement(
            apiName: 'ach_fire',
            name: 'Enkindle',
            description: 'Light bonfire flame',
            iconUrl: '',
            isUnlocked: true,
          ),
          const SteamAchievement(
            apiName: 'ach_bell',
            name: 'Ring the Bell',
            description: 'Ring Awakening Bell',
            iconUrl: '',
            isUnlocked: false,
          ),
        ],
      );
      entry.updateGameAchievementProgress();
      db.addOrUpdateEntry(entry);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaDetailScreen(entry: entry),
        ),
      );
      await tester.pumpAndSettle();

      // Check achievement text in Playthrough card
      expect(find.textContaining('Achievements: 1 / 2'), findsOneWidget);

      // Check Steam Achievements Explorer section
      expect(find.text('Steam Achievements'), findsOneWidget);
      expect(find.textContaining('1 of 2 Unlocked'), findsOneWidget);
      expect(find.text('Enkindle'), findsOneWidget);
      expect(find.text('Ring the Bell'), findsOneWidget);

      // Check Category Picker button
      expect(find.text('Add to Category'), findsOneWidget);
    });

    testWidgets('HomeScreen renders dynamic category shelf and manage shelves button', (tester) async {
      final db = DatabaseService();
      await db.init();

      final item = MediaItem(
        id: 'home_game_1',
        title: 'Hollow Knight',
        mediaType: MediaType.game,
        posterUrl: 'https://example.com/hk.jpg',
        backdropUrl: '',
        releaseYear: 2017,
        releaseDateFormatted: '2017',
        genres: const ['Metroidvania'],
        synopsis: 'Forge your path',
        communityRating: 9.5,
        creator: 'Team Cherry',
      );
      final entry = LibraryEntry(
        id: 'entry_home_game_1',
        mediaId: item.id,
        mediaItem: item,
        status: LibraryStatus.playing,
      );
      db.addOrUpdateEntry(entry);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(onOpenDetail: (_) {}),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "Playing Now" default category shelf should be rendered
      expect(find.text('Playing Now'), findsOneWidget);
      expect(find.text('Hollow Knight'), findsWidgets);

      // Manage Shelves button should be present in header
      expect(find.byTooltip('Manage Home Shelves'), findsOneWidget);

      // Tapping Manage Shelves opens bottom sheet
      await tester.tap(find.byTooltip('Manage Home Shelves'));
      await tester.pumpAndSettle();

      expect(find.text('Manage Home Shelves'), findsOneWidget);
      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text('Add Shelf'), findsOneWidget);
    });
  });
}
