import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/steam_profile.dart';
import '../models/steam_achievement.dart';

class SteamService {
  static const String _baseUrl = 'https://api.steampowered.com';

  /// Compile-time bundled API key provided via --dart-define=STEAM_API_KEY=...
  /// Keeps public GitHub repository code 100% secret-free.
  static const String bundledApiKey = String.fromEnvironment('STEAM_API_KEY');

  static final Map<int, String> _appNamesCache = {
    297130: 'Titan Souls',
    2835570: 'Buckshot Roulette',
    3431040: "That's not my Neighbor",
    1604000: 'Milk outside a bag of milk outside a bag of milk',
    2019810: 'Boxes: Lost Fragments',
    774361: 'Blasphemous',
    1392820: 'Milk inside a bag of milk inside a bag of milk',
    1150640: 'Yu-Gi-Oh! Legacy of the Duelist : Link Evolution',
    367520: 'Hollow Knight',
    1449850: 'Yu-Gi-Oh!  Master Duel',
    431960: 'Wallpaper Engine',
    1245620: 'ELDEN RING',
    1903340: 'Clair Obscur: Expedition 33',
    2114740: 'Blasphemous 2',
    2379780: 'Balatro',
    570940: 'DARK SOULS™: REMASTERED',
    787480: 'Phoenix Wright: Ace Attorney Trilogy',
    438100: 'VRChat',
    2680010: 'The First Berserker: Khazan',
    1818750: 'MultiVersus',
    646570: 'Slay the Spire',
    397740: 'Hylics',
    371970: 'Barony',
    1002300: 'Fear & Hunger',
    1158850: 'The Great Ace Attorney Chronicles',
    2057760: 'Esoteric Ebb',
    1766100: 'The Last Hero of Nostalgaia',
    3444230: 'Abulia',
  };

  static const Map<String, String> _defaultHeaders = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Extracts the username, vanity slug, or SteamID64 from a URL or raw text
  static String extractUsernameOrId(String input) {
    var clean = input.trim();
    // 1. Direct match for 17-digit SteamID (e.g. 76561199041297020) anywhere in input or URL
    final id64Match = RegExp(r'(?:profiles/|\b)(7656\d{13})\b').firstMatch(clean);
    if (id64Match != null) {
      return id64Match.group(1)!;
    }

    // 2. Vanity URL or custom id slug (e.g. steamcommunity.com/id/vanity/ or id/vanity)
    final vanityMatch = RegExp(r'(?:steamcommunity\.com/id/|/id/|^id/)([^/?#]+)').firstMatch(clean);
    if (vanityMatch != null) {
      return vanityMatch.group(1)!;
    }

    // 3. Fallback for any profiles/slug
    final profilesMatch = RegExp(r'(?:steamcommunity\.com/profiles/|/profiles/|^profiles/)([^/?#]+)').firstMatch(clean);
    if (profilesMatch != null) {
      return profilesMatch.group(1)!;
    }

    // 4. Remove leading/trailing slashes or query parameters
    clean = clean.replaceAll(RegExp(r'^/+|\?.*$|#.*$|/+$'), '').trim();
    return clean;
  }

  /// Resolves any public Steam profile (by username or vanity URL) without an API key
  static Future<Map<String, dynamic>?> resolvePublicSteamProfile(String input) async {
    final clean = extractUsernameOrId(input);
    if (clean.isEmpty) return null;

    final isNumericId = RegExp(r'^\d{17}$').hasMatch(clean);
    final url = isNumericId
        ? 'https://steamcommunity.com/profiles/$clean/?xml=1'
        : 'https://steamcommunity.com/id/$clean/?xml=1';

    try {
      final res = await http.get(
        Uri.parse(url),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final body = res.body;

        // Check if Steam returned error message in XML
        if (body.contains('<error>') || body.contains('The specified profile could not be found')) {
          return null;
        }

        final idMatch = RegExp(r'<steamID64>(\d+)<\/steamID64>').firstMatch(body);
        final nameMatch = RegExp(r'<steamID><!\[CDATA\[(.*?)\]\]><\/steamID>').firstMatch(body)
            ?? RegExp(r'<steamID>(.*?)<\/steamID>').firstMatch(body);
        final avatarMatch = RegExp(r'<avatarFull><!\[CDATA\[(.*?)\]\]><\/avatarFull>').firstMatch(body)
            ?? RegExp(r'<avatarFull>(.*?)<\/avatarFull>').firstMatch(body);

        if (idMatch != null) {
          final steamId = idMatch.group(1)!;
          final personaName = nameMatch?.group(1) ?? clean;
          final avatarUrl = avatarMatch?.group(1) ?? '';

          // Attempt to extract any recent games from public XML
          final List<SteamGame> recentGames = [];
          final gameBlocks = RegExp(r'<mostRecentGame>([\s\S]*?)<\/mostRecentGame>').allMatches(body);
          for (final block in gameBlocks) {
            final content = block.group(1) ?? '';
            final gName = RegExp(r'<gameName><!\[CDATA\[(.*?)\]\]><\/gameName>').firstMatch(content)?.group(1)
                ?? RegExp(r'<gameName>(.*?)<\/gameName>').firstMatch(content)?.group(1);
            final gId = RegExp(r'<gameID>(\d+)<\/gameID>').firstMatch(content)?.group(1)
                ?? RegExp(r'/app/(\d+)').firstMatch(content)?.group(1);
            final gHours = RegExp(r'<hoursOnRecord>([\d.,]+)<\/hoursOnRecord>').firstMatch(content)?.group(1)
                ?? RegExp(r'<hoursPlayed>([\d.,]+)<\/hoursPlayed>').firstMatch(content)?.group(1);
            final g2Wk = RegExp(r'<hoursPlayed>([\d.,]+)<\/hoursPlayed>').firstMatch(content)?.group(1);

            if (gName != null && gId != null) {
              final appId = int.tryParse(gId) ?? 0;
              final totalH = double.tryParse(gHours?.replaceAll(',', '') ?? '0') ?? 0.0;
              final twoWkH = double.tryParse(g2Wk?.replaceAll(',', '') ?? '0') ?? 0.0;
              recentGames.add(SteamGame(
                appId: appId,
                name: gName,
                playtimeForeverMinutes: (totalH * 60).round(),
                playtime2WeeksMinutes: (twoWkH * 60).round(),
              ));
            }
          }

          return {
            'steamId': steamId,
            'personaName': personaName,
            'avatarUrl': avatarUrl,
            'recentGames': recentGames,
          };
        }
      }
    } on SocketException catch (e) {
      throw Exception('Network error: Unable to reach Steam ($e). Please check your internet connection.');
    } on http.ClientException catch (e) {
      throw Exception('Network error connecting to Steam ($e).');
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        throw Exception('Steam connection timed out. Please verify your internet connection.');
      }
      if (e.toString().contains('Network error')) rethrow;
    }
    return null;
  }

  /// Fetches game achievements for a user and app via Steam Community public XML.
  /// Works completely without an API key using public HTTP requests:
  /// `https://steamcommunity.com/profiles/{steamIdOrProfile}/stats/{appId}/?xml=1`
  /// (or `https://steamcommunity.com/id/{steamIdOrProfile}/stats/{appId}/?xml=1`)
  static Future<List<SteamAchievement>> fetchGameAchievements({
    required String steamIdOrProfile,
    required int appId,
    http.Client? client,
  }) async {
    final clean = extractUsernameOrId(steamIdOrProfile);
    if (clean.isEmpty || appId <= 0) return [];

    final isNumericId = RegExp(r'^\d{17}$').hasMatch(clean);
    final url = isNumericId
        ? 'https://steamcommunity.com/profiles/$clean/stats/$appId/?xml=1'
        : 'https://steamcommunity.com/id/$clean/stats/$appId/?xml=1';

    try {
      final httpClient = client ?? http.Client();
      final res = await httpClient.get(
        Uri.parse(url),
        headers: _defaultHeaders,
      ).timeout(const Duration(seconds: 12));

      if (res.statusCode != 200) return [];

      final body = res.body;
      if (body.contains('<error>') || !body.contains('<achievements>')) {
        return [];
      }

      final List<SteamAchievement> achievements = [];
      final achievementMatches = RegExp(
        r'<achievement closed="([01])">([\s\S]*?)<\/achievement>',
      ).allMatches(body);

      for (final match in achievementMatches) {
        final isClosed = match.group(1) == '1';
        final block = match.group(2) ?? '';

        final apiNameMatch = RegExp(r'<apiname><!\[CDATA\[(.*?)\]\]><\/apiname>').firstMatch(block)
            ?? RegExp(r'<apiname>(.*?)<\/apiname>').firstMatch(block);
        final nameMatch = RegExp(r'<name><!\[CDATA\[(.*?)\]\]><\/name>').firstMatch(block)
            ?? RegExp(r'<name>(.*?)<\/name>').firstMatch(block);
        final descMatch = RegExp(r'<description><!\[CDATA\[(.*?)\]\]><\/description>').firstMatch(block)
            ?? RegExp(r'<description>(.*?)<\/description>').firstMatch(block);
        final iconClosedMatch = RegExp(r'<iconClosed><!\[CDATA\[(.*?)\]\]><\/iconClosed>').firstMatch(block)
            ?? RegExp(r'<iconClosed>(.*?)<\/iconClosed>').firstMatch(block);
        final iconOpenMatch = RegExp(r'<iconOpen><!\[CDATA\[(.*?)\]\]><\/iconOpen>').firstMatch(block)
            ?? RegExp(r'<iconOpen>(.*?)<\/iconOpen>').firstMatch(block);
        final timestampMatch = RegExp(r'<unlockTimestamp>(\d+)<\/unlockTimestamp>').firstMatch(block);

        final apiName = apiNameMatch?.group(1) ?? '';
        final name = nameMatch?.group(1) ?? apiName;
        final description = descMatch?.group(1) ?? '';
        final iconClosed = iconClosedMatch?.group(1);
        final iconOpen = iconOpenMatch?.group(1);

        DateTime? unlockTime;
        if (timestampMatch != null) {
          final ts = int.tryParse(timestampMatch.group(1)!);
          if (ts != null && ts > 0) {
            unlockTime = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
          }
        }

        // On Steam: iconOpen is the unlocked (color) icon, iconClosed is locked (gray) icon
        final mainIcon = (isClosed ? (iconOpen ?? iconClosed) : (iconClosed ?? iconOpen)) ?? '';

        achievements.add(SteamAchievement(
          apiName: apiName,
          name: name,
          description: description,
          iconUrl: mainIcon,
          iconLockedUrl: iconClosed,
          isUnlocked: isClosed,
          unlockTime: isClosed ? unlockTime : null,
        ));
      }

      return achievements;
    } catch (_) {
      return [];
    }
  }

  static Future<String> _resolveAppName(int appId) async {
    if (_appNamesCache.containsKey(appId)) {
      return _appNamesCache[appId]!;
    }
    try {
      final res = await http.get(
        Uri.parse('https://store.steampowered.com/api/appdetails?appids=$appId&filters=basic'),
      ).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final name = data['$appId']?['data']?['name'] as String?;
        if (name != null && name.isNotEmpty) {
          _appNamesCache[appId] = name;
          return name;
        }
      }
    } catch (_) {}
    return 'Steam App $appId';
  }

  /// Extracts publicly visible games from user reviews, badges, and recent activity
  static Future<List<SteamGame>> fetchPublicReviewedAndBadgeGames(String steamId) async {
    final List<SteamGame> results = [];
    final Set<int> seenAppIds = {};

    try {
      // 0. Fetch recent games from profile HTML (e.g. Wallpaper Engine, Yu-Gi-Oh! Master Duel, Elden Ring)
      final profileUrl = Uri.parse('https://steamcommunity.com/profiles/$steamId/');
      final res = await http.get(profileUrl, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = res.body;
        final recentGamesMatch = RegExp(
          r'class="game_info"[\s\S]*?steamcommunity\.com/app/(\d+)[\s\S]*?([\d.,]+)\s*hrs on record[\s\S]*?class="game_name"><a[^>]*>([^<]+)</a>',
          caseSensitive: false,
        ).allMatches(body);

        for (final m in recentGamesMatch) {
          final appId = int.tryParse(m.group(1)!) ?? 0;
          final hours = double.tryParse(m.group(2)?.replaceAll(',', '') ?? '0') ?? 0.0;
          final name = m.group(3)?.trim() ?? '';
          if (appId > 0 && !seenAppIds.contains(appId)) {
            seenAppIds.add(appId);
            results.add(SteamGame(
              appId: appId,
              name: name.isNotEmpty ? name : await _resolveAppName(appId),
              playtimeForeverMinutes: (hours * 60).round(),
              playtime2WeeksMinutes: 0,
            ));
          }
        }
      }
    } catch (_) {}

    try {
      // 1. Fetch public reviews
      final reviewsUrl = Uri.parse('https://steamcommunity.com/profiles/$steamId/recommended/');
      final res = await http.get(reviewsUrl).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = res.body;
        final reviewMatches = RegExp(
          r'<div[^>]*class="[^"]*review_box[^"]*"[\s\S]*?(?=<div[^>]*class="[^"]*review_box|$)',
          caseSensitive: false,
        ).allMatches(body);

        for (final m in reviewMatches) {
          final block = m.group(0) ?? '';
          final idMatch = RegExp(r'steamcommunity\.com/app/(\d+)').firstMatch(block);
          final hoursMatch = RegExp(r'([\d.,]+)\s*hrs on record', caseSensitive: false).firstMatch(block);

          if (idMatch != null) {
            final appId = int.tryParse(idMatch.group(1)!) ?? 0;
            if (appId > 0 && !seenAppIds.contains(appId)) {
              seenAppIds.add(appId);
              final hours = double.tryParse(hoursMatch?.group(1)?.replaceAll(',', '') ?? '0') ?? 0.0;
              final name = await _resolveAppName(appId);
              results.add(SteamGame(
                appId: appId,
                name: name,
                playtimeForeverMinutes: (hours * 60).round(),
                playtime2WeeksMinutes: 0,
              ));
            }
          }
        }
      }
    } catch (_) {}

    try {
      // 2. Fetch badges (e.g. Hollow Knight)
      final badgesUrl = Uri.parse('https://steamcommunity.com/profiles/$steamId/badges/');
      final res = await http.get(badgesUrl).timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final body = res.body;
        final cardMatches = RegExp(r'/gamecards/(\d+)').allMatches(body);
        for (final m in cardMatches) {
          final appId = int.tryParse(m.group(1)!) ?? 0;
          if (appId > 0 && !seenAppIds.contains(appId)) {
            seenAppIds.add(appId);
            final name = await _resolveAppName(appId);
            results.add(SteamGame(
              appId: appId,
              name: name,
              playtimeForeverMinutes: 0,
              playtime2WeeksMinutes: 0,
            ));
          }
        }
      }
    } catch (_) {}

    results.sort((a, b) => b.playtimeForeverMinutes.compareTo(a.playtimeForeverMinutes));
    return results;
  }

  /// Fetches player profile info and games (works with or without API key)
  static Future<SteamProfile?> fetchProfile({
    String? apiKey,
    required String usernameOrId,
  }) async {
    final clean = extractUsernameOrId(usernameOrId);
    if (clean.isEmpty) return null;

    // 1. Resolve to SteamID64, persona name, and avatar from public Steam Community
    final publicInfo = await resolvePublicSteamProfile(clean);
    if (publicInfo == null) {
      return null;
    }

    final steamId = publicInfo['steamId'] as String;
    final personaName = publicInfo['personaName'] as String;
    final avatarUrl = (publicInfo['avatarUrl'] as String).isNotEmpty
        ? publicInfo['avatarUrl'] as String
        : 'https://avatars.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg';
    final recentGames = (publicInfo['recentGames'] as List<SteamGame>?) ?? [];

    final effectiveApiKey = (apiKey != null && apiKey.isNotEmpty)
        ? apiKey
        : (bundledApiKey.isNotEmpty ? bundledApiKey : null);

    // 2. Fetch owned games if an API key is provided (or bundled via --dart-define)
    List<SteamGame> games = [];
    if (effectiveApiKey != null && effectiveApiKey.isNotEmpty) {
      games = await fetchOwnedGames(apiKey: effectiveApiKey, steamId: steamId);
    }

    // 3. If no games from API, look for recent XML games and public activity (reviews, badges)
    if (games.isEmpty) {
      final Map<int, SteamGame> gameMap = {};
      for (final g in recentGames) {
        gameMap[g.appId] = g;
      }
      final activityGames = await fetchPublicReviewedAndBadgeGames(steamId);
      for (final g in activityGames) {
        if (!gameMap.containsKey(g.appId)) {
          gameMap[g.appId] = g;
        } else if (g.playtimeForeverMinutes > gameMap[g.appId]!.playtimeForeverMinutes) {
          gameMap[g.appId] = g;
        }
      }
      games = gameMap.values.toList()
        ..sort((a, b) => b.playtimeForeverMinutes.compareTo(a.playtimeForeverMinutes));
    }

    // NEVER inject fake games into real profiles!
    return SteamProfile(
      steamId: steamId,
      personaName: personaName,
      avatarUrl: avatarUrl,
      profileUrl: 'https://steamcommunity.com/profiles/$steamId',
      lastSynced: DateTime.now(),
      games: games,
    );
  }

  /// Checks if a local Steam desktop client installation exists
  static bool hasLocalSteamClient() {
    return findLocalSteamUserDataDir() != null;
  }

  /// Discovers local Steam installation directory across OSes
  static Directory? findLocalSteamUserDataDir() {
    try {
      if (Platform.isLinux) {
        final home = Platform.environment['HOME'] ?? '';
        final candidates = [
          Directory('$home/.steam/steam/userdata'),
          Directory('$home/.local/share/Steam/userdata'),
          Directory('$home/.var/app/com.valvesoftware.Steam/.steam/steam/userdata'),
        ];
        for (final c in candidates) {
          if (c.existsSync()) return c;
        }
      } else if (Platform.isWindows) {
        final candidates = [
          Directory(r'C:\Program Files (x86)\Steam\userdata'),
          Directory(r'C:\Program Files\Steam\userdata'),
        ];
        for (final c in candidates) {
          if (c.existsSync()) return c;
        }
      } else if (Platform.isMacOS) {
        final home = Platform.environment['HOME'] ?? '';
        final c = Directory('$home/Library/Application Support/Steam/userdata');
        if (c.existsSync()) return c;
      }
    } catch (_) {}
    return null;
  }

  /// Imports all owned & played games directly from the local Steam desktop client without any API key or password
  static Future<SteamProfile?> syncFromLocalSteamClient() async {
    final userDataDir = findLocalSteamUserDataDir();
    if (userDataDir == null) return null;

    try {
      // Find the user directory containing config/localconfig.vdf
      final subDirs = userDataDir.listSync().whereType<Directory>().toList();
      if (subDirs.isEmpty) return null;

      Directory? activeUserDir;
      File? configFile;
      for (final dir in subDirs) {
        final candidate = File('${dir.path}/config/localconfig.vdf');
        if (candidate.existsSync()) {
          activeUserDir = dir;
          configFile = candidate;
          break;
        }
      }

      if (activeUserDir == null || configFile == null) return null;

      final accountId3 = activeUserDir.path.split(Platform.pathSeparator).last;
      final steamId3Int = int.tryParse(accountId3) ?? 0;
      final steamId64 = (76561197960265728 + steamId3Int).toString();

      // Resolve persona name and avatar from public community XML
      final publicInfo = await resolvePublicSteamProfile(steamId64);
      final personaName = publicInfo?['personaName'] ?? 'FrigoBar';
      final avatarUrl = (publicInfo?['avatarUrl'] as String?)?.isNotEmpty == true
          ? publicInfo!['avatarUrl'] as String
          : 'https://avatars.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg';

      // Parse installed games from appmanifest_*.acf
      final Map<int, String> manifestNames = {};
      final steamAppsDir = Directory('${userDataDir.parent.path}/steamapps');
      if (steamAppsDir.existsSync()) {
        final acfFiles = steamAppsDir.listSync().whereType<File>().where((f) => f.path.contains('appmanifest_'));
        for (final acf in acfFiles) {
          try {
            final content = acf.readAsStringSync();
            final idMatch = RegExp(r'"appid"\s*"(\d+)"').firstMatch(content);
            final nameMatch = RegExp(r'"name"\s*"([^"]+)"').firstMatch(content);
            if (idMatch != null && nameMatch != null) {
              manifestNames[int.parse(idMatch.group(1)!)] = nameMatch.group(1)!;
            }
          } catch (_) {}
        }
      }

      // Parse localconfig.vdf
      final text = await configFile.readAsString();
      final appsSection = RegExp(r'"apps"\s*\{([\s\S]*?)\n\t\t\}').firstMatch(text);
      final List<SteamGame> games = [];

      if (appsSection != null) {
        final blocks = RegExp(r'"(\d+)"\s*\{([\s\S]*?)\}').allMatches(appsSection.group(1)!);
        final List<Map<String, dynamic>> rawApps = [];

        for (final block in blocks) {
          final appId = int.tryParse(block.group(1)!) ?? 0;
          if (appId <= 0) continue;

          // Skip Steam runtime and tools (e.g. Proton, Steamworks Common Redistributables)
          if (appId == 228980 || appId == 1070560 || appId == 1391110) continue;

          final body = block.group(2) ?? '';
          final ptMatch = RegExp(r'"Playtime"\s*"(\d+)"').firstMatch(body);
          final lpMatch = RegExp(r'"LastPlayed"\s*"(\d+)"').firstMatch(body);
          final minutes = int.tryParse(ptMatch?.group(1) ?? '0') ?? 0;
          final lastPlayed = int.tryParse(lpMatch?.group(1) ?? '0');

          rawApps.add({
            'appId': appId,
            'minutes': minutes,
            'lastPlayed': lastPlayed,
          });
        }

        // Parallel resolution of game names
        await Future.wait(rawApps.map((raw) async {
          final appId = raw['appId'] as int;
          String name = manifestNames[appId] ?? _appNamesCache[appId] ?? '';
          if (name.isEmpty) {
            name = await _resolveAppName(appId);
          }
          raw['name'] = name;
        }));

        for (final raw in rawApps) {
          final lastPlayed = raw['lastPlayed'] as int?;
          games.add(SteamGame(
            appId: raw['appId'] as int,
            name: raw['name'] as String,
            playtimeForeverMinutes: raw['minutes'] as int,
            playtime2WeeksMinutes: 0,
            rtimeLastPlayed: (lastPlayed != null && lastPlayed > 0) ? lastPlayed : null,
          ));
        }
      }

      games.sort((a, b) => b.playtimeForeverMinutes.compareTo(a.playtimeForeverMinutes));

      return SteamProfile(
        steamId: steamId64,
        personaName: personaName,
        avatarUrl: avatarUrl,
        profileUrl: 'https://steamcommunity.com/profiles/$steamId64',
        lastSynced: DateTime.now(),
        games: games,
      );
    } catch (_) {
      return null;
    }
  }

  /// Generates a demo profile for instant testing without network
  static Future<SteamProfile> generateDemoProfile([String usernameOrId = 'Catalysm']) async {
    return SteamProfile(
      steamId: '76561198028175941',
      personaName: 'Catalysm (Demo)',
      avatarUrl: 'https://avatars.steamstatic.com/fef49e7fa7e1997310d705b2a6158ff8dc1cdfeb_full.jpg',
      profileUrl: 'https://steamcommunity.com/profiles/76561198028175941',
      lastSynced: DateTime.now(),
      games: _generateSmartGamesList(),
    );
  }

  /// Fetches owned games with playtime using Steam Web API
  static Future<List<SteamGame>> fetchOwnedGames({
    required String apiKey,
    required String steamId,
  }) async {
    try {
      final gamesUrl = Uri.parse(
        '$_baseUrl/IPlayerService/GetOwnedGames/v0001/?key=$apiKey&steamid=$steamId&include_appinfo=1&include_played_free_games=1&format=json',
      );
      final gamesRes = await http.get(gamesUrl).timeout(const Duration(seconds: 10));
      if (gamesRes.statusCode != 200) return [];

      final data = jsonDecode(gamesRes.body);
      final gamesList = data['response']?['games'] as List?;
      if (gamesList == null) return [];

      return gamesList.map((g) => SteamGame.fromJson(g)).toList()
        ..sort((a, b) => b.playtimeForeverMinutes.compareTo(a.playtimeForeverMinutes));
    } catch (_) {
      return [];
    }
  }

  static List<SteamGame> _generateSmartGamesList() {
    return [
      SteamGame(
        appId: 1245620,
        name: 'Elden Ring',
        playtimeForeverMinutes: 7200,
        playtime2WeeksMinutes: 180,
      ),
      SteamGame(
        appId: 292030,
        name: 'The Witcher 3: Wild Hunt',
        playtimeForeverMinutes: 5400,
        playtime2WeeksMinutes: 0,
      ),
      SteamGame(
        appId: 1086940,
        name: "Baldur's Gate 3",
        playtimeForeverMinutes: 6300,
        playtime2WeeksMinutes: 320,
      ),
      SteamGame(
        appId: 1091500,
        name: 'Cyberpunk 2077',
        playtimeForeverMinutes: 4800,
        playtime2WeeksMinutes: 0,
      ),
      SteamGame(
        appId: 1145360,
        name: 'Hades',
        playtimeForeverMinutes: 2400,
        playtime2WeeksMinutes: 90,
      ),
      SteamGame(
        appId: 1888930,
        name: 'The Last of Us™ Part I',
        playtimeForeverMinutes: 1020,
        playtime2WeeksMinutes: 0,
      ),
    ];
  }
}
