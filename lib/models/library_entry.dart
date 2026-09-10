import 'media_item.dart';
import 'media_type.dart';
import 'tv_season.dart';
import 'steam_achievement.dart';

enum LibraryStatus {
  playing,
  backlog,
  completed,
  wishlist,
  abandoned;

  String get label {
    switch (this) {
      case LibraryStatus.playing:
        return 'Playing / Watching';
      case LibraryStatus.backlog:
        return 'In Backlog';
      case LibraryStatus.completed:
        return 'Completed';
      case LibraryStatus.wishlist:
        return 'Wishlist';
      case LibraryStatus.abandoned:
        return 'Dropped';
    }
  }

  String get shortLabel {
    switch (this) {
      case LibraryStatus.playing:
        return 'Active';
      case LibraryStatus.backlog:
        return 'Backlog';
      case LibraryStatus.completed:
        return 'Finished';
      case LibraryStatus.wishlist:
        return 'Wishlist';
      case LibraryStatus.abandoned:
        return 'Dropped';
    }
  }
}

class LibraryEntry {
  final String id;
  final String mediaId;
  MediaItem mediaItem;
  LibraryStatus status;
  double? userRating; // 1 to 10
  String platform; // e.g. "PC - Steam", "PlayStation 5", "Netflix"
  String format; // "Digital", "Physical", "Subscription"
  bool isOwned;
  double? pricePaid;
  DateTime? purchaseDate;
  double progressPercent; // 0.0 to 100.0
  int timeSpentMinutes; // total minutes
  int playthroughCount;
  String notes;
  DateTime? lastActivity;
  DateTime addedDate;
  List<String> watchedEpisodeIds; // e.g. ["s1_e1", "s1_e2"]
  int? totalEpisodesCount;
  List<TvSeason>? cachedSeasons;
  List<SteamAchievement>? cachedAchievements;
  int? unlockedAchievementsCount;
  int? totalAchievementsCount;
  List<String> customCategories;

  LibraryEntry({
    required this.id,
    required this.mediaId,
    required this.mediaItem,
    required this.status,
    this.userRating,
    this.platform = 'PC - Steam',
    this.format = 'Digital',
    this.isOwned = true,
    this.pricePaid,
    this.purchaseDate,
    this.progressPercent = 0.0,
    this.timeSpentMinutes = 0,
    this.playthroughCount = 1,
    this.notes = '',
    this.lastActivity,
    DateTime? addedDate,
    List<String>? watchedEpisodeIds,
    this.totalEpisodesCount,
    this.cachedSeasons,
    this.cachedAchievements,
    this.unlockedAchievementsCount,
    this.totalAchievementsCount,
    List<String>? customCategories,
  })  : addedDate = addedDate ?? DateTime.now(),
        watchedEpisodeIds = watchedEpisodeIds ?? [],
        customCategories = customCategories ?? [];

  bool isEpisodeWatched(int season, int episode) {
    return watchedEpisodeIds.contains('s${season}_e$episode');
  }

  int get watchedEpisodesCount => watchedEpisodeIds.length;

  /// Recalculates TV show progress percentage and status based on watched episodes
  void updateTvProgress() {
    if (mediaItem.mediaType == MediaType.tvShow && totalEpisodesCount != null && totalEpisodesCount! > 0) {
      progressPercent = ((watchedEpisodeIds.length / totalEpisodesCount!) * 100.0).clamp(0.0, 100.0);
      if (watchedEpisodeIds.length >= totalEpisodesCount!) {
        status = LibraryStatus.completed;
      } else if (watchedEpisodeIds.isNotEmpty &&
          (status == LibraryStatus.backlog || status == LibraryStatus.wishlist)) {
        status = LibraryStatus.playing;
      }
    }
  }

  /// Recalculates game progress percentage based on Steam achievements
  void updateGameAchievementProgress() {
    if (cachedAchievements != null && cachedAchievements!.isNotEmpty) {
      totalAchievementsCount = cachedAchievements!.length;
      unlockedAchievementsCount = cachedAchievements!.where((a) => a.isUnlocked).length;
      progressPercent = ((unlockedAchievementsCount! / totalAchievementsCount!) * 100.0).clamp(0.0, 100.0);
      if (unlockedAchievementsCount == totalAchievementsCount && totalAchievementsCount! > 0) {
        status = LibraryStatus.completed;
      }
    }
  }

  String get formattedTimeSpent {
    final hours = timeSpentMinutes ~/ 60;
    final minutes = timeSpentMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaId': mediaId,
      'mediaItem': mediaItem.toMap(),
      'status': status.name,
      'userRating': userRating,
      'platform': platform,
      'format': format,
      'isOwned': isOwned ? 1 : 0,
      'pricePaid': pricePaid,
      'purchaseDate': purchaseDate?.toIso8601String(),
      'progressPercent': progressPercent,
      'timeSpentMinutes': timeSpentMinutes,
      'playthroughCount': playthroughCount,
      'notes': notes,
      'lastActivity': lastActivity?.toIso8601String(),
      'addedDate': addedDate.toIso8601String(),
      'watchedEpisodeIds': watchedEpisodeIds,
      'totalEpisodesCount': totalEpisodesCount,
      'cachedSeasons': cachedSeasons?.map((s) => s.toMap()).toList(),
      'cachedAchievements': cachedAchievements?.map((a) => a.toMap()).toList(),
      'unlockedAchievementsCount': unlockedAchievementsCount,
      'totalAchievementsCount': totalAchievementsCount,
      'customCategories': customCategories,
    };
  }

  factory LibraryEntry.fromMap(Map<String, dynamic> map) {
    return LibraryEntry(
      id: map['id'] as String? ?? '',
      mediaId: map['mediaId'] as String? ?? '',
      mediaItem: map['mediaItem'] != null
          ? MediaItem.fromMap(Map<String, dynamic>.from(map['mediaItem'] as Map))
          : MediaItem(
              id: map['mediaId'] as String? ?? 'unknown',
              title: 'Unknown Title',
              mediaType: MediaType.game,
              posterUrl: '',
              backdropUrl: '',
              releaseYear: 2020,
              releaseDateFormatted: '',
              genres: const [],
              synopsis: '',
              communityRating: 0.0,
              creator: '',
            ),
      status: LibraryStatus.values.byName(map['status'] as String? ?? 'backlog'),
      userRating: (map['userRating'] as num?)?.toDouble(),
      platform: map['platform'] as String? ?? 'PC - Steam',
      format: map['format'] as String? ?? 'Digital',
      isOwned: (map['isOwned'] as int? ?? 1) == 1,
      pricePaid: (map['pricePaid'] as num?)?.toDouble(),
      purchaseDate: map['purchaseDate'] != null
          ? DateTime.tryParse(map['purchaseDate'] as String)
          : null,
      progressPercent: (map['progressPercent'] as num?)?.toDouble() ?? 0.0,
      timeSpentMinutes: (map['timeSpentMinutes'] as num?)?.toInt() ?? 0,
      playthroughCount: (map['playthroughCount'] as num?)?.toInt() ?? 1,
      notes: map['notes'] as String? ?? '',
      lastActivity: map['lastActivity'] != null
          ? DateTime.tryParse(map['lastActivity'] as String)
          : null,
      addedDate: map['addedDate'] != null
          ? DateTime.tryParse(map['addedDate'] as String)
          : null,
      watchedEpisodeIds: (map['watchedEpisodeIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      totalEpisodesCount: (map['totalEpisodesCount'] as num?)?.toInt(),
      cachedSeasons: (map['cachedSeasons'] as List<dynamic>?)
          ?.map((s) => TvSeason.fromMap(Map<String, dynamic>.from(s as Map)))
          .toList(),
      cachedAchievements: (map['cachedAchievements'] as List<dynamic>?)
          ?.map((a) => SteamAchievement.fromMap(Map<String, dynamic>.from(a as Map)))
          .toList(),
      unlockedAchievementsCount: (map['unlockedAchievementsCount'] as num?)?.toInt(),
      totalAchievementsCount: (map['totalAchievementsCount'] as num?)?.toInt(),
      customCategories: (map['customCategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}
