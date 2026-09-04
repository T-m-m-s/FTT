import 'media_type.dart';

class MediaItem {
  final String id;
  final String title;
  final MediaType mediaType;
  final String posterUrl;
  final String backdropUrl;
  final int releaseYear;
  final String releaseDateFormatted;
  final List<String> genres;
  final String synopsis;
  final double communityRating; // 0.0 - 10.0
  final String creator; // Developer for games, Director/Network for movies/shows
  final int? steamAppId;
  final int? runtimeMinutes; // Average game length or movie duration

  const MediaItem({
    required this.id,
    required this.title,
    required this.mediaType,
    required this.posterUrl,
    required this.backdropUrl,
    required this.releaseYear,
    required this.releaseDateFormatted,
    required this.genres,
    required this.synopsis,
    required this.communityRating,
    required this.creator,
    this.steamAppId,
    this.runtimeMinutes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mediaType': mediaType.name,
      'posterUrl': posterUrl,
      'backdropUrl': backdropUrl,
      'releaseYear': releaseYear,
      'releaseDateFormatted': releaseDateFormatted,
      'genres': genres.join(','),
      'synopsis': synopsis,
      'communityRating': communityRating,
      'creator': creator,
      'steamAppId': steamAppId,
      'runtimeMinutes': runtimeMinutes,
    };
  }

  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as String,
      title: map['title'] as String,
      mediaType: MediaType.values.byName(map['mediaType'] as String),
      posterUrl: map['posterUrl'] as String,
      backdropUrl: map['backdropUrl'] as String,
      releaseYear: map['releaseYear'] as int,
      releaseDateFormatted: map['releaseDateFormatted'] as String? ?? '',
      genres: (map['genres'] as String).split(','),
      synopsis: map['synopsis'] as String? ?? '',
      communityRating: (map['communityRating'] as num?)?.toDouble() ?? 0.0,
      creator: map['creator'] as String? ?? '',
      steamAppId: map['steamAppId'] as int?,
      runtimeMinutes: map['runtimeMinutes'] as int?,
    );
  }
}
