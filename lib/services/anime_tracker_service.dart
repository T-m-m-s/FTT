import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/library_entry.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/play_session.dart';
import 'database_service.dart';

class AnimeTrackerService {
  final DatabaseService _db = DatabaseService();

  /// Sync anime and anime movies directly from MyAnimeList (MAL)
  Future<int> syncMyAnimeList(String rawUsername, {http.Client? client}) async {
    final username = rawUsername.trim();
    if (username.isEmpty) {
      throw Exception('Please enter a valid MyAnimeList username.');
    }

    final httpClient = client ?? http.Client();
    final List<Map<String, dynamic>> allItems = [];
    int offset = 0;
    const int pageSize = 300;

    try {
      while (true) {
        final url = Uri.parse(
          'https://myanimelist.net/animelist/$username/load.json?offset=$offset&status=7',
        );

        final response = await httpClient.get(
          url,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 FreeTimeTracker/1.0',
            'Accept': 'application/json',
          },
        );

        if (response.statusCode == 404 || response.statusCode == 400) {
          throw Exception('User "$username" not found or their anime list is private.');
        }

        if (response.statusCode != 200) {
          throw Exception('MyAnimeList error (HTTP ${response.statusCode}). Please check username and try again.');
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! List) {
          throw Exception('Unexpected response format from MyAnimeList.');
        }

        if (decoded.isEmpty) break;

        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            allItems.add(item);
          }
        }

        if (decoded.length < pageSize) break;
        offset += pageSize;
      }
    } finally {
      if (client == null) httpClient.close();
    }

    if (allItems.isEmpty) {
      throw Exception('No anime found in list for "$username".');
    }

    int importedCount = 0;

    for (final item in allItems) {
      final animeId = item['anime_id']?.toString() ?? '';
      if (animeId.isEmpty) continue;

      final titleEng = (item['anime_title_eng'] as String?)?.trim() ?? '';
      final titleRomaji = (item['anime_title'] as String?)?.trim() ?? '';
      final title = titleEng.isNotEmpty ? titleEng : titleRomaji;
      if (title.isEmpty) continue;

      final typeStr = (item['anime_media_type_string'] as String?)?.toLowerCase() ?? 'tv';
      final isMovie = typeStr == 'movie';
      final mediaType = isMovie ? MediaType.movie : MediaType.tvShow;

      final posterUrl = (item['anime_image_path'] as String?) ?? '';

      // Parse Genres
      final List<String> genres = ['Anime'];
      final rawGenres = item['genres'];
      if (rawGenres is List) {
        for (final g in rawGenres) {
          if (g is Map && g['name'] != null) {
            final name = g['name'].toString().trim();
            if (name.isNotEmpty && !genres.contains(name)) {
              genres.add(name);
            }
          }
        }
      }

      // Parse release year
      int releaseYear = 2020;
      final startStr = (item['anime_start_date_string'] as String?) ?? (item['start_date_string'] as String?) ?? '';
      if (startStr.isNotEmpty) {
        final parts = startStr.split('-');
        if (parts.isNotEmpty) {
          final yearCandidate = int.tryParse(parts.last);
          if (yearCandidate != null) {
            releaseYear = yearCandidate < 50 ? 2000 + yearCandidate : (yearCandidate < 100 ? 1900 + yearCandidate : yearCandidate);
          }
        }
      }

      // Status mapping:
      // 1: watching, 2: completed, 3: on_hold, 4: dropped, 6: plan_to_watch
      final int rawStatus = (item['status'] as num?)?.toInt() ?? 1;
      LibraryStatus status;
      switch (rawStatus) {
        case 1:
          status = LibraryStatus.playing;
          break;
        case 2:
          status = LibraryStatus.completed;
          break;
        case 3:
          status = LibraryStatus.backlog;
          break;
        case 4:
          status = LibraryStatus.abandoned;
          break;
        case 6:
          status = LibraryStatus.wishlist;
          break;
        default:
          status = LibraryStatus.backlog;
      }

      final watchedEps = (item['num_watched_episodes'] as num?)?.toInt() ?? 0;
      final totalEps = (item['anime_num_episodes'] as num?)?.toInt() ?? 0;

      // Score
      final double? userScore = (item['score'] as num?)?.toDouble();
      final double? validRating = (userScore != null && userScore > 0) ? userScore : null;

      // Time spent estimation
      final int timeSpent = isMovie
          ? (status == LibraryStatus.completed ? 105 : 0)
          : (watchedEps * 24);

      // Progress percent
      double progressPercent = 0.0;
      if (isMovie) {
        progressPercent = status == LibraryStatus.completed ? 100.0 : 0.0;
      } else if (totalEps > 0) {
        progressPercent = ((watchedEps / totalEps) * 100.0).clamp(0.0, 100.0);
      } else if (status == LibraryStatus.completed) {
        progressPercent = 100.0;
      }

      final mediaItem = MediaItem(
        id: 'mal_$animeId',
        title: title,
        mediaType: mediaType,
        posterUrl: posterUrl,
        backdropUrl: posterUrl,
        releaseYear: releaseYear,
        releaseDateFormatted: startStr.isNotEmpty ? startStr : '$releaseYear',
        genres: genres,
        synopsis: 'Imported from MyAnimeList ($typeStr).',
        communityRating: (item['anime_score_val'] as num?)?.toDouble() ?? 0.0,
        creator: 'MyAnimeList',
        runtimeMinutes: isMovie ? 105 : 24,
      );

      final entry = LibraryEntry(
        id: 'entry_mal_$animeId',
        mediaId: 'mal_$animeId',
        mediaItem: mediaItem,
        status: status,
        userRating: validRating,
        platform: 'Anime Tracker (MAL)',
        format: 'Digital',
        progressPercent: progressPercent,
        timeSpentMinutes: timeSpent,
        totalEpisodesCount: totalEps > 0 ? totalEps : null,
        watchedEpisodeIds: List.generate(watchedEps, (i) => 'ep_${i + 1}'),
        lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      );

      _db.addOrUpdateEntry(entry);

      if (timeSpent > 0) {
        final session = PlaySession(
          id: 'sess_mal_$animeId',
          mediaId: 'mal_$animeId',
          mediaTitle: title,
          mediaPoster: posterUrl,
          mediaType: mediaType,
          date: DateTime.now().subtract(const Duration(days: 1)),
          durationMinutes: timeSpent > 180 ? 120 : timeSpent,
          platform: 'Anime Tracker (MAL)',
          notes: 'Sync from MyAnimeList ($watchedEps episodes tracked)',
          isCompletion: status == LibraryStatus.completed,
          rating: validRating,
        );
        _db.addSession(session);
      }

      importedCount++;
    }

    await _db.setMalUsername(username);
    return importedCount;
  }

  /// Sync anime and anime movies from AniList via GraphQL
  Future<int> syncAniList(String rawUsername, {http.Client? client}) async {
    final username = rawUsername.trim();
    if (username.isEmpty) {
      throw Exception('Please enter a valid AniList username.');
    }

    final httpClient = client ?? http.Client();
    const query = '''
query (\$userName: String) {
  MediaListCollection(userName: \$userName, type: ANIME) {
    lists {
      name
      status
      entries {
        progress
        score
        media {
          id
          title {
            romaji
            english
          }
          format
          episodes
          duration
          genres
          averageScore
          coverImage {
            large
          }
          startDate {
            year
          }
        }
      }
    }
  }
}
''';

    try {
      final response = await httpClient.post(
        Uri.parse('https://graphql.anilist.co'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'query': query,
          'variables': {'userName': username},
        }),
      );

      if (response.statusCode == 403 || response.statusCode == 503) {
        throw Exception('AniList API is temporarily unavailable or rate-limited. Please try again later or use MyAnimeList.');
      }

      if (response.statusCode != 200) {
        throw Exception('AniList error (HTTP ${response.statusCode}). Please verify your username.');
      }

      final data = jsonDecode(response.body);
      if (data['errors'] != null) {
        final errMsg = (data['errors'] as List).map((e) => e['message']).join(', ');
        throw Exception('AniList: $errMsg');
      }

      final lists = data['data']?['MediaListCollection']?['lists'] as List?;
      if (lists == null || lists.isEmpty) {
        throw Exception('No anime found in AniList profile for "$username".');
      }

      int importedCount = 0;

      for (final list in lists) {
        final listStatus = (list['status'] as String?)?.toUpperCase() ?? '';
        final entries = list['entries'] as List? ?? [];

        LibraryStatus status = LibraryStatus.playing;
        if (listStatus == 'COMPLETED') {
          status = LibraryStatus.completed;
        } else if (listStatus == 'PLANNING') {
          status = LibraryStatus.wishlist;
        } else if (listStatus == 'DROPPED') {
          status = LibraryStatus.abandoned;
        } else if (listStatus == 'PAUSED') {
          status = LibraryStatus.backlog;
        }

        for (final item in entries) {
          final media = item['media'];
          if (media == null) continue;

          final animeId = media['id']?.toString() ?? '';
          final titleEng = (media['title']?['english'] as String?) ?? '';
          final titleRomaji = (media['title']?['romaji'] as String?) ?? '';
          final title = titleEng.isNotEmpty ? titleEng : titleRomaji;
          if (title.isEmpty) continue;

          final format = (media['format'] as String?)?.toUpperCase() ?? 'TV';
          final isMovie = format == 'MOVIE';
          final mediaType = isMovie ? MediaType.movie : MediaType.tvShow;

          final posterUrl = (media['coverImage']?['large'] as String?) ?? '';
          final episodes = (media['episodes'] as num?)?.toInt() ?? 0;
          final duration = (media['duration'] as num?)?.toInt() ?? (isMovie ? 105 : 24);
          final progress = (item['progress'] as num?)?.toInt() ?? 0;
          final score = (item['score'] as num?)?.toDouble();

          final List<String> genres = ['Anime'];
          final rawGenres = media['genres'] as List? ?? [];
          for (final g in rawGenres) {
            final name = g.toString();
            if (name.isNotEmpty && !genres.contains(name)) {
              genres.add(name);
            }
          }

          final year = (media['startDate']?['year'] as num?)?.toInt() ?? 2020;
          final timeSpent = isMovie
              ? (status == LibraryStatus.completed ? duration : 0)
              : (progress * duration);

          double progressPercent = 0.0;
          if (isMovie) {
            progressPercent = status == LibraryStatus.completed ? 100.0 : 0.0;
          } else if (episodes > 0) {
            progressPercent = ((progress / episodes) * 100.0).clamp(0.0, 100.0);
          } else if (status == LibraryStatus.completed) {
            progressPercent = 100.0;
          }

          final mediaItem = MediaItem(
            id: 'anilist_$animeId',
            title: title,
            mediaType: mediaType,
            posterUrl: posterUrl,
            backdropUrl: posterUrl,
            releaseYear: year,
            releaseDateFormatted: '$year',
            genres: genres,
            synopsis: 'Imported from AniList ($format).',
            communityRating: ((media['averageScore'] as num?)?.toDouble() ?? 0.0) / 10.0,
            creator: 'AniList',
            runtimeMinutes: duration,
          );

          final entry = LibraryEntry(
            id: 'entry_anilist_$animeId',
            mediaId: 'anilist_$animeId',
            mediaItem: mediaItem,
            status: status,
            userRating: score != null && score > 0 ? score : null,
            platform: 'Anime Tracker (AniList)',
            format: 'Digital',
            progressPercent: progressPercent,
            timeSpentMinutes: timeSpent,
            totalEpisodesCount: episodes > 0 ? episodes : null,
            watchedEpisodeIds: List.generate(progress, (i) => 'ep_${i + 1}'),
            lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
          );

          _db.addOrUpdateEntry(entry);
          importedCount++;
        }
      }

      await _db.setAnilistUsername(username);
      return importedCount;
    } finally {
      if (client == null) httpClient.close();
    }
  }
}
