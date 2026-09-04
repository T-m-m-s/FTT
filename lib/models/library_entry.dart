import 'media_item.dart';

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
  final MediaItem mediaItem;
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
  }) : addedDate = addedDate ?? DateTime.now();

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
    };
  }
}
