import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/models/media_type.dart';
import 'package:ftt/models/steam_profile.dart';
import 'package:ftt/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  test('Database starts clean without any hardcoded games or sessions', () async {
    final db = DatabaseService();
    db.clearAllData();
    await db.init();

    expect(db.library, isEmpty);
    expect(db.sessions, isEmpty);
    expect(db.playingItems, isEmpty);
    expect(db.backlogItems, isEmpty);
    expect(db.completedItems, isEmpty);
  });

  test('Steam profile sync automatically populates real library and timeline sessions', () {
    final db = DatabaseService();
    db.clearAllData();

    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final mockProfile = SteamProfile(
      steamId: '76561199041297020',
      personaName: 'FrigoBar',
      avatarUrl: 'https://example.com/avatar.jpg',
      profileUrl: 'https://steamcommunity.com/profiles/76561199041297020',
      games: [
        SteamGame(
          appId: 1449850,
          name: 'Yu-Gi-Oh! Master Duel',
          playtimeForeverMinutes: 2828,
          playtime2WeeksMinutes: 120,
          rtimeLastPlayed: nowSec - 3600,
        ),
        SteamGame(
          appId: 774361,
          name: 'Blasphemous',
          playtimeForeverMinutes: 2228,
          rtimeLastPlayed: nowSec - 86400 * 5,
        ),
        SteamGame(
          appId: 1245620,
          name: 'ELDEN RING',
          playtimeForeverMinutes: 462,
          rtimeLastPlayed: nowSec - 86400 * 20,
        ),
        SteamGame(
          appId: 999999,
          name: 'Unplayed Backlog Game',
          playtimeForeverMinutes: 0,
          rtimeLastPlayed: 0,
        ),
      ],
    );

    db.setSteamProfile(mockProfile);

    // Verify Library
    expect(db.library.length, 4);
    final masterDuel = db.library.firstWhere((e) => e.mediaItem.title == 'Yu-Gi-Oh! Master Duel');
    expect(masterDuel.timeSpentMinutes, 2828);
    expect(masterDuel.mediaItem.mediaType, MediaType.game);
    expect(masterDuel.platform, 'PC - Steam');

    // Verify Timeline Sessions were automatically generated
    expect(db.sessions.length, 3); // 3 games with playtime > 0 and rtimeLastPlayed > 0
    final topSession = db.sessions.first;
    expect(topSession.mediaTitle, 'Yu-Gi-Oh! Master Duel');
    expect(topSession.durationMinutes, 120);

    // Verify Top Played Games query
    final topGames = db.topPlayedGames(limit: 5);
    expect(topGames.length, 3);
    expect(topGames[0].mediaItem.title, 'Yu-Gi-Oh! Master Duel');
    expect(topGames[1].mediaItem.title, 'Blasphemous');
    expect(topGames[2].mediaItem.title, 'ELDEN RING');

    // Verify no hardcoded sample games exist
    final allTitles = db.library.map((e) => e.mediaItem.title).toList();
    expect(allTitles.contains('Silent Hill f'), isFalse);
    expect(allTitles.contains("The Legend of Zelda: Link's Awakening"), isFalse);
    expect(allTitles.contains("Assassin's Creed Shadows"), isFalse);
    expect(allTitles.contains("Pathologic 3"), isFalse);
  });
}
