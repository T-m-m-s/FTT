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
}
