import 'package:flutter_test/flutter_test.dart';
import 'package:ftt/services/steam_service.dart';

void main() {
  group('SteamService Input Parsing', () {
    test('extracts vanity from profile URL', () {
      expect(
        SteamService.extractUsernameOrId('https://steamcommunity.com/id/gabelogannewell/'),
        'gabelogannewell',
      );
      expect(
        SteamService.extractUsernameOrId('steamcommunity.com/id/myusername?tab=all'),
        'myusername',
      );
    });

    test('extracts numeric steamID from profile URL', () {
      expect(
        SteamService.extractUsernameOrId('https://steamcommunity.com/profiles/76561198028175941'),
        '76561198028175941',
      );
    });

    test('preserves plain username or steamID', () {
      expect(SteamService.extractUsernameOrId('Catalysm'), 'Catalysm');
      expect(SteamService.extractUsernameOrId('76561198028175941'), '76561198028175941');
    });

    test('generates demo profile without errors', () async {
      final profile = await SteamService.generateDemoProfile('Catalysm');
      expect(profile.personaName, isNotEmpty);
      expect(profile.games, isNotEmpty);
      expect(profile.games.first.name, isNotEmpty);
      expect(profile.totalHoursPlayed, greaterThan(0));
    });

    test('fetches real user profile for 76561199041297020', () async {
      final profile = await SteamService.fetchProfile(usernameOrId: '76561199041297020');
      expect(profile, isNotNull);
      expect(profile!.personaName, 'FrigoBar');
      expect(profile.steamId, '76561199041297020');
      expect(profile.games, isNotEmpty);
      // ignore: avoid_print
      print('SYNCED ${profile.games.length} GAMES:');
      for (final g in profile.games) {
        // ignore: avoid_print
        print('  • ${g.name} (${g.totalHours}h)');
      }
      final gameNames = profile.games.map((g) => g.name).toList();
      expect(gameNames.any((n) => n.contains('Blasphemous') || n.contains('Buckshot Roulette') || n.contains('Titan Souls')), isTrue);
      expect(gameNames.contains('The Witcher 3: Wild Hunt'), isFalse);
    });

    test('syncs full library from local Steam client without API key', () async {
      if (!SteamService.hasLocalSteamClient()) {
        // Skip on CI environments (like GitHub Actions runners) where desktop Steam is not installed
        return;
      }
      expect(SteamService.hasLocalSteamClient(), isTrue);
      final profile = await SteamService.syncFromLocalSteamClient();
      expect(profile, isNotNull);
      expect(profile!.games.length, greaterThan(20));
      // ignore: avoid_print
      print('LOCAL STEAM CLIENT IMPORTED ${profile.games.length} GAMES:');
      for (final g in profile.games.take(10)) {
        // ignore: avoid_print
        print('  • ${g.name} (${g.totalHours}h)');
      }
    });
  });
}
