import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';

class IgdbService {
  static final IgdbService _instance = IgdbService._internal();
  factory IgdbService() => _instance;
  IgdbService._internal();

  String clientId = const String.fromEnvironment('TWITCH_CLIENT_ID', defaultValue: '9rcn1iigfjtwmwvfeps442q1shwkik');
  String clientSecret = const String.fromEnvironment('TWITCH_CLIENT_SECRET', defaultValue: 'hsulchji3tbhilwiuolw328796j96o');

  String? _accessToken;
  DateTime? _tokenExpiry;

  bool get isConfigured => clientId.isNotEmpty && clientSecret.isNotEmpty;

  /// Retrieves or refreshes OAuth access token from Twitch
  Future<String?> _getAccessToken() async {
    if (_accessToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    try {
      final tokenUrl = Uri.parse(
        'https://id.twitch.tv/oauth2/token?client_id=$clientId&client_secret=$clientSecret&grant_type=client_credentials',
      );
      final res = await http.post(tokenUrl);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _accessToken = data['access_token'] as String;
        final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
        _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));
        return _accessToken;
      }
    } catch (_) {}
    return null;
  }

  /// Live search games from IGDB
  Future<List<MediaItem>> searchGames(String query, {int limit = 15}) async {
    if (query.trim().isEmpty) return [];

    final token = await _getAccessToken();
    if (token == null) return [];

    try {
      final url = Uri.parse('https://api.igdb.com/v4/games');
      // IGDB Apicalypse query syntax
      final body = '''
        search "$query";
        fields name, summary, cover.image_id, first_release_date, genres.name, total_rating, involved_companies.company.name, screenshots.image_id, external_games.category, external_games.uid;
        limit $limit;
      ''';

      final res = await http.post(
        url,
        headers: {
          'Client-ID': clientId,
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (res.statusCode != 200) return [];

      final List<dynamic> gamesJson = jsonDecode(res.body);
      final List<MediaItem> results = [];

      for (final g in gamesJson) {
        final int id = g['id'] as int;
        final String name = g['name'] as String? ?? 'Unknown Game';
        final String summary = g['summary'] as String? ?? '';

        // Cover
        String posterUrl = '';
        if (g['cover'] != null && g['cover']['image_id'] != null) {
          final hash = g['cover']['image_id'];
          posterUrl = 'https://images.igdb.com/igdb/image/upload/t_cover_big/$hash.webp';
        }

        // Backdrop / Screenshots
        String backdropUrl = '';
        if (g['screenshots'] != null && (g['screenshots'] as List).isNotEmpty) {
          final hash = g['screenshots'][0]['image_id'];
          backdropUrl = 'https://images.igdb.com/igdb/image/upload/t_1080p/$hash.webp';
        } else {
          backdropUrl = posterUrl;
        }

        // Release Date
        int releaseYear = DateTime.now().year;
        String releaseDateFormatted = 'TBA';
        if (g['first_release_date'] != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch((g['first_release_date'] as int) * 1000);
          releaseYear = dt.year;
          releaseDateFormatted = DateFormat('MMM d, yyyy').format(dt);
        }

        // Genres
        final List<String> genres = [];
        if (g['genres'] != null) {
          for (final gen in g['genres'] as List) {
            if (gen['name'] != null) genres.add(gen['name'] as String);
          }
        }
        if (genres.isEmpty) genres.add('Action');

        // Company / Creator
        String creator = 'Game Developer';
        if (g['involved_companies'] != null && (g['involved_companies'] as List).isNotEmpty) {
          final firstComp = g['involved_companies'][0];
          if (firstComp['company'] != null && firstComp['company']['name'] != null) {
            creator = firstComp['company']['name'] as String;
          }
        }

        // Community Rating (0 - 10 scale)
        double rating = 8.0;
        if (g['total_rating'] != null) {
          rating = ((g['total_rating'] as num).toDouble() / 10.0);
          rating = double.parse(rating.toStringAsFixed(1));
        }

        // Steam AppID mapping (category == 1 is Steam)
        int? steamAppId;
        if (g['external_games'] != null) {
          for (final ext in g['external_games'] as List) {
            if (ext['category'] == 1 && ext['uid'] != null) {
              steamAppId = int.tryParse(ext['uid'].toString());
              if (steamAppId != null) break;
            }
          }
        }

        results.add(MediaItem(
          id: 'igdb_$id',
          title: name,
          mediaType: MediaType.game,
          posterUrl: posterUrl,
          backdropUrl: backdropUrl,
          releaseYear: releaseYear,
          releaseDateFormatted: releaseDateFormatted,
          genres: genres,
          synopsis: summary.isNotEmpty ? summary : 'Explore $name and immerse yourself in its gameplay experience.',
          communityRating: rating,
          creator: creator,
          steamAppId: steamAppId,
          runtimeMinutes: 900,
        ));
      }

      return results;
    } catch (_) {
      return [];
    }
  }
}
