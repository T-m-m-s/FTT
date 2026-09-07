class SteamGame {
  final int appId;
  final String name;
  final int playtimeForeverMinutes;
  final int playtime2WeeksMinutes;
  final String iconUrl;
  final int? rtimeLastPlayed;

  SteamGame({
    required this.appId,
    required this.name,
    required this.playtimeForeverMinutes,
    this.playtime2WeeksMinutes = 0,
    this.iconUrl = '',
    this.rtimeLastPlayed,
  });

  String get posterUrl =>
      'https://steamcdn-a.akamaihd.net/steam/apps/$appId/library_600x900_2x.jpg';
  String get headerUrl =>
      'https://steamcdn-a.akamaihd.net/steam/apps/$appId/header.jpg';

  int get totalHours => (playtimeForeverMinutes / 60).round();

  Map<String, dynamic> toMap() {
    return {
      'appId': appId,
      'name': name,
      'playtimeForeverMinutes': playtimeForeverMinutes,
      'playtime2WeeksMinutes': playtime2WeeksMinutes,
      'iconUrl': iconUrl,
      'rtimeLastPlayed': rtimeLastPlayed,
    };
  }

  factory SteamGame.fromMap(Map<String, dynamic> map) {
    return SteamGame(
      appId: (map['appId'] as num?)?.toInt() ?? 0,
      name: map['name'] as String? ?? '',
      playtimeForeverMinutes: (map['playtimeForeverMinutes'] as num?)?.toInt() ?? 0,
      playtime2WeeksMinutes: (map['playtime2WeeksMinutes'] as num?)?.toInt() ?? 0,
      iconUrl: map['iconUrl'] as String? ?? '',
      rtimeLastPlayed: (map['rtimeLastPlayed'] as num?)?.toInt(),
    );
  }

  factory SteamGame.fromJson(Map<String, dynamic> json) {
    return SteamGame(
      appId: json['appid'] as int,
      name: json['name'] as String? ?? 'App $json["appid"]',
      playtimeForeverMinutes: json['playtime_forever'] as int? ?? 0,
      playtime2WeeksMinutes: json['playtime_2weeks'] as int? ?? 0,
      iconUrl: json['img_icon_url'] as String? ?? '',
      rtimeLastPlayed: json['rtime_last_played'] as int?,
    );
  }
}

class SteamProfile {
  final String steamId;
  final String personaName;
  final String avatarUrl;
  final String profileUrl;
  final DateTime? lastSynced;
  final List<SteamGame> games;

  SteamProfile({
    required this.steamId,
    required this.personaName,
    required this.avatarUrl,
    required this.profileUrl,
    this.lastSynced,
    this.games = const [],
  });

  int get totalHoursPlayed =>
      games.fold(0, (sum, g) => sum + (g.playtimeForeverMinutes / 60).round());

  Map<String, dynamic> toMap() {
    return {
      'steamId': steamId,
      'personaName': personaName,
      'avatarUrl': avatarUrl,
      'profileUrl': profileUrl,
      'lastSynced': lastSynced?.toIso8601String(),
      'games': games.map((g) => g.toMap()).toList(),
    };
  }

  factory SteamProfile.fromMap(Map<String, dynamic> map) {
    return SteamProfile(
      steamId: map['steamId'] as String? ?? '',
      personaName: map['personaName'] as String? ?? 'Steam User',
      avatarUrl: map['avatarUrl'] as String? ?? '',
      profileUrl: map['profileUrl'] as String? ?? '',
      lastSynced: map['lastSynced'] != null
          ? DateTime.tryParse(map['lastSynced'] as String)
          : null,
      games: (map['games'] as List<dynamic>?)
              ?.map((g) => SteamGame.fromMap(Map<String, dynamic>.from(g as Map)))
              .toList() ??
          const [],
    );
  }
}
