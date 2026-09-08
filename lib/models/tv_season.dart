class TvEpisode {
  final String id;
  final int seasonNumber;
  final int episodeNumber;
  final String name;
  final String overview;
  final int? runtimeMinutes;
  final String? airDate;
  final String? stillUrl;

  const TvEpisode({
    required this.id,
    required this.seasonNumber,
    required this.episodeNumber,
    required this.name,
    this.overview = '',
    this.runtimeMinutes,
    this.airDate,
    this.stillUrl,
  });

  /// Canonical identifier across providers: e.g. "s1_e1"
  String get canonicalKey => 's${seasonNumber}_e$episodeNumber';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'seasonNumber': seasonNumber,
      'episodeNumber': episodeNumber,
      'name': name,
      'overview': overview,
      'runtimeMinutes': runtimeMinutes,
      'airDate': airDate,
      'stillUrl': stillUrl,
    };
  }

  factory TvEpisode.fromMap(Map<String, dynamic> map) {
    return TvEpisode(
      id: map['id']?.toString() ?? '',
      seasonNumber: (map['seasonNumber'] as num?)?.toInt() ?? 1,
      episodeNumber: (map['episodeNumber'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? '',
      overview: map['overview'] as String? ?? '',
      runtimeMinutes: (map['runtimeMinutes'] as num?)?.toInt(),
      airDate: map['airDate'] as String?,
      stillUrl: map['stillUrl'] as String?,
    );
  }
}

class TvSeason {
  final int seasonNumber;
  final String name;
  final int episodeCount;
  final String? posterUrl;
  final String overview;
  final List<TvEpisode> episodes;

  const TvSeason({
    required this.seasonNumber,
    required this.name,
    required this.episodeCount,
    this.posterUrl,
    this.overview = '',
    this.episodes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'seasonNumber': seasonNumber,
      'name': name,
      'episodeCount': episodeCount,
      'posterUrl': posterUrl,
      'overview': overview,
      'episodes': episodes.map((e) => e.toMap()).toList(),
    };
  }

  factory TvSeason.fromMap(Map<String, dynamic> map) {
    return TvSeason(
      seasonNumber: (map['seasonNumber'] as num?)?.toInt() ?? 1,
      name: map['name'] as String? ?? 'Season ${(map['seasonNumber'] ?? 1)}',
      episodeCount: (map['episodeCount'] as num?)?.toInt() ?? (map['episodes'] as List?)?.length ?? 0,
      posterUrl: map['posterUrl'] as String?,
      overview: map['overview'] as String? ?? '',
      episodes: (map['episodes'] as List<dynamic>?)
              ?.map((e) => TvEpisode.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList() ??
          const [],
    );
  }

  TvSeason copyWith({
    int? seasonNumber,
    String? name,
    int? episodeCount,
    String? posterUrl,
    String? overview,
    List<TvEpisode>? episodes,
  }) {
    return TvSeason(
      seasonNumber: seasonNumber ?? this.seasonNumber,
      name: name ?? this.name,
      episodeCount: episodeCount ?? this.episodeCount,
      posterUrl: posterUrl ?? this.posterUrl,
      overview: overview ?? this.overview,
      episodes: episodes ?? this.episodes,
    );
  }
}
