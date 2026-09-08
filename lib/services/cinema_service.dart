import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../models/media_item.dart';
import '../models/media_type.dart';
import '../models/tv_season.dart';

class CinemaService {
  static final CinemaService _instance = CinemaService._internal();
  factory CinemaService() => _instance;
  CinemaService._internal();

  /// Bundled TMDB v3 API Key (can be customized via --dart-define=TMDB_API_KEY=...)
  static const String bundledApiKey = String.fromEnvironment(
    'TMDB_API_KEY',
    defaultValue: '4e44d9029b1270a757cddc766a1bcb63',
  );

  static const String _tmdbBaseUrl = 'https://api.themoviedb.org/3';
  static const String _tvMazeBaseUrl = 'https://api.tvmaze.com';

  static const Map<int, String> _genreMap = {
    28: 'Action',
    12: 'Adventure',
    16: 'Animation',
    35: 'Comedy',
    80: 'Crime',
    99: 'Documentary',
    18: 'Drama',
    10751: 'Family',
    14: 'Fantasy',
    36: 'History',
    27: 'Horror',
    10402: 'Music',
    9648: 'Mystery',
    10749: 'Romance',
    878: 'Sci-Fi',
    10770: 'TV Movie',
    53: 'Thriller',
    10752: 'War',
    37: 'Western',
    10759: 'Action & Adventure',
    10762: 'Kids',
    10763: 'News',
    10764: 'Reality',
    10765: 'Sci-Fi & Fantasy',
    10766: 'Soap',
    10767: 'Talk',
    10768: 'War & Politics',
  };

  /// Searches for movies and TV series across TMDB and TVMaze
  Future<List<MediaItem>> searchCinema(
    String query, {
    MediaType? typeFilter,
    int limit = 20,
    String? customApiKey,
  }) async {
    final clean = query.trim();
    if (clean.isEmpty) return [];

    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : bundledApiKey;

    List<MediaItem> results = [];

    // 1. Query TMDB (Movies & Series)
    try {
      String endpoint;
      if (typeFilter == MediaType.movie) {
        endpoint = '$_tmdbBaseUrl/search/movie?api_key=$apiKey&query=${Uri.encodeComponent(clean)}&include_adult=false';
      } else if (typeFilter == MediaType.tvShow) {
        endpoint = '$_tmdbBaseUrl/search/tv?api_key=$apiKey&query=${Uri.encodeComponent(clean)}&include_adult=false';
      } else {
        endpoint = '$_tmdbBaseUrl/search/multi?api_key=$apiKey&query=${Uri.encodeComponent(clean)}&include_adult=false';
      }

      final res = await http.get(
        Uri.parse(endpoint),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['results'] as List<dynamic>? ?? [];

        for (final item in list) {
          final mediaTypeStr = item['media_type'] as String? ??
              (typeFilter == MediaType.tvShow ? 'tv' : 'movie');

          // Only handle movies and tv shows (skip person)
          if (mediaTypeStr != 'movie' && mediaTypeStr != 'tv') continue;

          final isTv = mediaTypeStr == 'tv';
          final mType = isTv ? MediaType.tvShow : MediaType.movie;

          if (typeFilter != null && typeFilter != mType) continue;

          final int id = item['id'] as int;
          final String title = (isTv ? item['name'] : item['title']) as String? ?? 'Untitled';
          final String overview = item['overview'] as String? ?? '';
          final String? posterPath = item['poster_path'] as String?;
          final String? backdropPath = item['backdrop_path'] as String?;
          final String dateStr = (isTv ? item['first_air_date'] : item['release_date']) as String? ?? '';
          final double voteAvg = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
          final genreIds = (item['genre_ids'] as List<dynamic>?)?.map((g) => g as int).toList() ?? [];

          int year = DateTime.now().year;
          String formattedDate = '';
          if (dateStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(dateStr);
              year = parsed.year;
              formattedDate = DateFormat('MMM d, yyyy').format(parsed);
            } catch (_) {
              if (dateStr.length >= 4) {
                year = int.tryParse(dateStr.substring(0, 4)) ?? year;
              }
            }
          }

          final List<String> genres = genreIds.map((id) => _genreMap[id] ?? 'Cinema').take(3).toList();
          if (genres.isEmpty) genres.add(isTv ? 'TV Series' : 'Movie');

          final posterUrl = posterPath != null
              ? 'https://image.tmdb.org/t/p/w500$posterPath'
              : '';
          final backdropUrl = backdropPath != null
              ? 'https://image.tmdb.org/t/p/original$backdropPath'
              : posterUrl;

          results.add(MediaItem(
            id: 'tmdb_${isTv ? "tv" : "movie"}_$id',
            title: title,
            mediaType: mType,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            releaseYear: year,
            releaseDateFormatted: formattedDate,
            genres: genres,
            synopsis: overview,
            communityRating: (voteAvg * 10).round() / 10,
            creator: isTv ? 'TV Network' : 'Cinema Studio',
            runtimeMinutes: isTv ? 45 : 120,
          ));
        }
      }
    } catch (_) {}

    // 2. If results are sparse and user wants TV or All, enrich with TVMaze
    if (results.length < 5 && (typeFilter == null || typeFilter == MediaType.tvShow)) {
      try {
        final tvMazeUrl = Uri.parse('$_tvMazeBaseUrl/search/shows?q=${Uri.encodeComponent(clean)}');
        final res = await http.get(tvMazeUrl).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final List<dynamic> tvList = jsonDecode(res.body);
          for (final item in tvList) {
            final show = item['show'] as Map<String, dynamic>?;
            if (show == null) continue;

            final int id = show['id'] as int;
            final String name = show['name'] as String? ?? 'Unknown Show';

            // Avoid duplicates
            if (results.any((r) => r.title.toLowerCase() == name.toLowerCase())) {
              continue;
            }

            final String premiered = show['premiered'] as String? ?? '';
            int year = DateTime.now().year;
            if (premiered.length >= 4) {
              year = int.tryParse(premiered.substring(0, 4)) ?? year;
            }

            final rawGenres = (show['genres'] as List<dynamic>?)?.map((g) => g.toString()).toList() ?? [];
            if (rawGenres.isEmpty) rawGenres.add('Drama');

            final imgMap = show['image'] as Map<String, dynamic>?;
            final String poster = imgMap?['original'] as String? ?? imgMap?['medium'] as String? ?? '';
            final double rating = (show['rating']?['average'] as num?)?.toDouble() ?? 7.5;
            final int runtime = (show['averageRuntime'] as num?)?.toInt() ?? 45;
            final network = show['webChannel']?['name'] ?? show['network']?['name'] ?? 'TV Network';

            var summary = show['summary'] as String? ?? '';
            summary = summary.replaceAll(RegExp(r'<[^>]*>'), '').trim();

            results.add(MediaItem(
              id: 'tvmaze_$id',
              title: name,
              mediaType: MediaType.tvShow,
              posterUrl: poster,
              backdropUrl: poster,
              releaseYear: year,
              releaseDateFormatted: premiered,
              genres: rawGenres,
              synopsis: summary,
              communityRating: rating,
              creator: network.toString(),
              runtimeMinutes: runtime,
            ));
          }
        }
      } catch (_) {}
    }

    return results.take(limit).toList();
  }

  /// Fetches trending movies and TV shows for discovery
  Future<List<MediaItem>> getTrendingCinema({
    String? customApiKey,
    int limit = 15,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : bundledApiKey;

    try {
      final url = Uri.parse('$_tmdbBaseUrl/trending/all/week?api_key=$apiKey');
      final res = await http.get(
        url,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = data['results'] as List<dynamic>? ?? [];
        final List<MediaItem> items = [];

        for (final item in list) {
          final mediaTypeStr = item['media_type'] as String? ?? 'movie';
          if (mediaTypeStr != 'movie' && mediaTypeStr != 'tv') continue;

          final isTv = mediaTypeStr == 'tv';
          final mType = isTv ? MediaType.tvShow : MediaType.movie;
          final int id = item['id'] as int;
          final String title = (isTv ? item['name'] : item['title']) as String? ?? 'Untitled';
          final String overview = item['overview'] as String? ?? '';
          final String? posterPath = item['poster_path'] as String?;
          final String? backdropPath = item['backdrop_path'] as String?;
          final String dateStr = (isTv ? item['first_air_date'] : item['release_date']) as String? ?? '';
          final double voteAvg = (item['vote_average'] as num?)?.toDouble() ?? 0.0;
          final genreIds = (item['genre_ids'] as List<dynamic>?)?.map((g) => g as int).toList() ?? [];

          int year = DateTime.now().year;
          String formattedDate = '';
          if (dateStr.isNotEmpty) {
            try {
              final parsed = DateTime.parse(dateStr);
              year = parsed.year;
              formattedDate = DateFormat('MMM d, yyyy').format(parsed);
            } catch (_) {
              if (dateStr.length >= 4) {
                year = int.tryParse(dateStr.substring(0, 4)) ?? year;
              }
            }
          }

          final List<String> genres = genreIds.map((id) => _genreMap[id] ?? 'Cinema').take(3).toList();
          if (genres.isEmpty) genres.add(isTv ? 'TV Series' : 'Movie');

          final posterUrl = posterPath != null
              ? 'https://image.tmdb.org/t/p/w500$posterPath'
              : '';
          final backdropUrl = backdropPath != null
              ? 'https://image.tmdb.org/t/p/original$backdropPath'
              : posterUrl;

          items.add(MediaItem(
            id: 'tmdb_${isTv ? "tv" : "movie"}_$id',
            title: title,
            mediaType: mType,
            posterUrl: posterUrl,
            backdropUrl: backdropUrl,
            releaseYear: year,
            releaseDateFormatted: formattedDate,
            genres: genres,
            synopsis: overview,
            communityRating: (voteAvg * 10).round() / 10,
            creator: isTv ? 'Trending Series' : 'Trending Movie',
            runtimeMinutes: isTv ? 45 : 120,
          ));
        }

        if (items.isNotEmpty) {
          return items.take(limit).toList();
        }
      }
    } catch (_) {}

    // Fallback curated trending items
    return _curatedFallbackTrending();
  }

  /// Fetches seasons and episodes for a TV Show from TMDB or TVMaze
  Future<List<TvSeason>> fetchTvSeasonsAndEpisodes(
    MediaItem item, {
    String? customApiKey,
  }) async {
    final apiKey = (customApiKey != null && customApiKey.isNotEmpty)
        ? customApiKey
        : bundledApiKey;

    // 1. Try TMDB if it is a TMDB TV show
    if (item.id.startsWith('tmdb_tv_')) {
      final tmdbId = item.id.replaceFirst('tmdb_tv_', '');
      try {
        final seasons = await _fetchTmdbTvSeasons(tmdbId, apiKey);
        if (seasons.isNotEmpty) return seasons;
      } catch (_) {}
    }

    // 2. Try TVMaze if ID starts with tvmaze_
    if (item.id.startsWith('tvmaze_')) {
      final tvmazeId = item.id.replaceFirst('tvmaze_', '');
      try {
        final seasons = await _fetchTvMazeEpisodesById(tvmazeId);
        if (seasons.isNotEmpty) return seasons;
      } catch (_) {}
    }

    // 3. Fallback: Search TVMaze by Title (universal fallback, works for any show)
    try {
      final seasons = await _fetchTvMazeEpisodesByTitle(item.title);
      if (seasons.isNotEmpty) return seasons;
    } catch (_) {}

    // 4. Fallback: If not tried TMDB yet, search TMDB by title
    if (!item.id.startsWith('tmdb_tv_')) {
      try {
        final searchUrl = Uri.parse('$_tmdbBaseUrl/search/tv?api_key=$apiKey&query=${Uri.encodeComponent(item.title)}&include_adult=false');
        final res = await http.get(searchUrl, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final data = jsonDecode(res.body);
          final results = data['results'] as List<dynamic>? ?? [];
          if (results.isNotEmpty) {
            final int tmdbId = results.first['id'] as int;
            final seasons = await _fetchTmdbTvSeasons(tmdbId.toString(), apiKey);
            if (seasons.isNotEmpty) return seasons;
          }
        }
      } catch (_) {}
    }

    return [];
  }

  Future<List<TvSeason>> _fetchTmdbTvSeasons(String tmdbId, String apiKey) async {
    final showUrl = Uri.parse('$_tmdbBaseUrl/tv/$tmdbId?api_key=$apiKey');
    final res = await http.get(showUrl, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    final rawSeasons = (data['seasons'] as List<dynamic>? ?? [])
        .map((s) => Map<String, dynamic>.from(s as Map))
        .toList();

    // Filter out seasons with 0 episodes
    final validSeasons = rawSeasons.where((s) => ((s['episode_count'] as num?)?.toInt() ?? 0) > 0).toList();
    if (validSeasons.isEmpty) return [];

    // Fetch episodes for all seasons in parallel (cap to max 30 seasons)
    final seasonsToFetch = validSeasons.take(30).toList();
    final List<TvSeason> results = await Future.wait(seasonsToFetch.map((sMap) async {
      final int sNum = (sMap['season_number'] as num?)?.toInt() ?? 1;
      final String sName = sMap['name'] as String? ?? 'Season $sNum';
      final int epCount = (sMap['episode_count'] as num?)?.toInt() ?? 0;
      final String? poster = sMap['poster_path'] != null
          ? 'https://image.tmdb.org/t/p/w500${sMap['poster_path']}'
          : null;
      final String overview = sMap['overview'] as String? ?? '';

      try {
        final epUrl = Uri.parse('$_tmdbBaseUrl/tv/$tmdbId/season/$sNum?api_key=$apiKey');
        final epRes = await http.get(epUrl, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 8));
        if (epRes.statusCode == 200) {
          final epData = jsonDecode(epRes.body);
          final rawEps = (epData['episodes'] as List<dynamic>? ?? []);
          final List<TvEpisode> epList = rawEps.map((e) {
            final eNum = (e['episode_number'] as num?)?.toInt() ?? 1;
            final still = e['still_path'] != null
                ? 'https://image.tmdb.org/t/p/w500${e['still_path']}'
                : null;
            return TvEpisode(
              id: 's${sNum}_e$eNum',
              seasonNumber: sNum,
              episodeNumber: eNum,
              name: (e['name'] as String? ?? 'Episode $eNum').trim(),
              overview: (e['overview'] as String? ?? '').trim(),
              runtimeMinutes: (e['runtime'] as num?)?.toInt(),
              airDate: e['air_date'] as String?,
              stillUrl: still,
            );
          }).toList();

          return TvSeason(
            seasonNumber: sNum,
            name: sName,
            episodeCount: epList.length,
            posterUrl: poster,
            overview: overview,
            episodes: epList,
          );
        }
      } catch (_) {}

      // Fallback if episode endpoint fails: generate stub episodes
      final List<TvEpisode> stubs = List.generate(
        epCount,
        (i) => TvEpisode(
          id: 's${sNum}_e${i + 1}',
          seasonNumber: sNum,
          episodeNumber: i + 1,
          name: 'Episode ${i + 1}',
        ),
      );
      return TvSeason(
        seasonNumber: sNum,
        name: sName,
        episodeCount: epCount,
        posterUrl: poster,
        overview: overview,
        episodes: stubs,
      );
    }));

    results.sort((a, b) => a.seasonNumber.compareTo(b.seasonNumber));
    return results;
  }

  Future<List<TvSeason>> _fetchTvMazeEpisodesById(String tvmazeId) async {
    final url = Uri.parse('$_tvMazeBaseUrl/shows/$tvmazeId/episodes');
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final List<dynamic> eps = jsonDecode(res.body);
      return _groupTvMazeEpisodes(eps);
    }
    return [];
  }

  Future<List<TvSeason>> _fetchTvMazeEpisodesByTitle(String title) async {
    final url = Uri.parse('$_tvMazeBaseUrl/singlesearch/shows?q=${Uri.encodeComponent(title)}&embed=episodes');
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final rawEps = data['_embedded']?['episodes'] as List<dynamic>? ?? [];
      return _groupTvMazeEpisodes(rawEps);
    }
    return [];
  }

  List<TvSeason> _groupTvMazeEpisodes(List<dynamic> rawEpisodes) {
    if (rawEpisodes.isEmpty) return [];

    final Map<int, List<TvEpisode>> seasonMap = {};
    for (final item in rawEpisodes) {
      final sNum = (item['season'] as num?)?.toInt() ?? 1;
      final eNum = (item['number'] as num?)?.toInt() ?? 1;
      final name = (item['name'] as String? ?? 'Episode $eNum').trim();
      var summary = item['summary'] as String? ?? '';
      summary = summary.replaceAll(RegExp(r'<[^>]*>'), '').trim();
      final runtime = (item['runtime'] as num?)?.toInt();
      final airDate = item['airdate'] as String?;
      final img = item['image']?['medium'] as String? ?? item['image']?['original'] as String?;

      final ep = TvEpisode(
        id: 's${sNum}_e$eNum',
        seasonNumber: sNum,
        episodeNumber: eNum,
        name: name,
        overview: summary,
        runtimeMinutes: runtime,
        airDate: airDate,
        stillUrl: img,
      );

      seasonMap.putIfAbsent(sNum, () => []).add(ep);
    }

    final List<TvSeason> seasons = [];
    final sortedKeys = seasonMap.keys.toList()..sort();
    for (final sNum in sortedKeys) {
      final eps = seasonMap[sNum]!;
      seasons.add(TvSeason(
        seasonNumber: sNum,
        name: 'Season $sNum',
        episodeCount: eps.length,
        episodes: eps,
      ));
    }

    return seasons;
  }

  static List<MediaItem> _curatedFallbackTrending() {
    return [
      const MediaItem(
        id: 'movie_dune2',
        title: 'Dune: Part Two',
        mediaType: MediaType.movie,
        posterUrl: 'https://image.tmdb.org/t/p/w500/1pdfLvkbY9ohJlCjQH2CZjjYVvJ.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/xOMo8BRK7PfcJv9JCnx7s5200bm.jpg',
        releaseYear: 2024,
        releaseDateFormatted: 'Mar 1, 2024',
        genres: ['Sci-Fi', 'Adventure', 'Drama'],
        synopsis: 'Paul Atreides unites with Chani and the Fremen while seeking revenge against the conspirators who destroyed his family.',
        communityRating: 8.7,
        creator: 'Denis Villeneuve',
        runtimeMinutes: 166,
      ),
      const MediaItem(
        id: 'tv_severance',
        title: 'Severance',
        mediaType: MediaType.tvShow,
        posterUrl: 'https://image.tmdb.org/t/p/w500/jtA82x4kL3sMtz7dFkP8eT1o55p.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/bKxiLRPVWe2nZUCyY6i2qR17Z.jpg',
        releaseYear: 2022,
        releaseDateFormatted: 'Feb 18, 2022',
        genres: ['Sci-Fi', 'Mystery', 'Thriller'],
        synopsis: 'Mark leads a team of office workers whose memories have been surgically divided between their work and personal lives.',
        communityRating: 8.9,
        creator: 'Apple TV+',
        runtimeMinutes: 55,
      ),
      const MediaItem(
        id: 'tv_arcane',
        title: 'Arcane',
        mediaType: MediaType.tvShow,
        posterUrl: 'https://image.tmdb.org/t/p/w500/fqldf2t8ztc9aiwn397rFriYe9l.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/uDgy6hyPd82kOHh6I95FLtLnj6p.jpg',
        releaseYear: 2021,
        releaseDateFormatted: 'Nov 6, 2021',
        genres: ['Animation', 'Sci-Fi', 'Action'],
        synopsis: 'Amid the stark discord of twin cities Piltover and Zaun, two sisters fight on rival sides of a war between magic technologies.',
        communityRating: 9.0,
        creator: 'Netflix',
        runtimeMinutes: 42,
      ),
      const MediaItem(
        id: 'movie_oppenheimer',
        title: 'Oppenheimer',
        mediaType: MediaType.movie,
        posterUrl: 'https://image.tmdb.org/t/p/w500/8Gxv8gSFCU0XGDykEGv7zR1n2ua.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/fm6KqXpk3M2HVveHwCrBSSBaO0V.jpg',
        releaseYear: 2023,
        releaseDateFormatted: 'Jul 21, 2023',
        genres: ['Drama', 'History', 'Biography'],
        synopsis: 'The story of J. Robert Oppenheimer’s role in the development of the atomic bomb during World War II.',
        communityRating: 8.8,
        creator: 'Christopher Nolan',
        runtimeMinutes: 180,
      ),
      const MediaItem(
        id: 'tv_shogun',
        title: 'Shōgun',
        mediaType: MediaType.tvShow,
        posterUrl: 'https://image.tmdb.org/t/p/w500/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg',
        backdropUrl: 'https://image.tmdb.org/t/p/original/7O4iVfOMQmdCSxhOg1WnzG1AgYT.jpg',
        releaseYear: 2024,
        releaseDateFormatted: 'Feb 27, 2024',
        genres: ['Drama', 'History', 'War'],
        synopsis: 'When a mysterious European ship is found marooned in a nearby fishing village, Lord Toranaga discovers secrets that could tip the scales of power in feudal Japan.',
        communityRating: 8.8,
        creator: 'FX / Hulu',
        runtimeMinutes: 60,
      ),
    ];
  }
}
