import 'media_type.dart';

class PlaySession {
  final String id;
  final String mediaId;
  final String mediaTitle;
  final String mediaPoster;
  final MediaType mediaType;
  final DateTime date;
  final int durationMinutes;
  final double? progressPercentage;
  final String? platform;
  final double? rating; // 1 to 10
  final bool isCompletion;
  final String notes;
  final List<String> achievements;

  PlaySession({
    required this.id,
    required this.mediaId,
    required this.mediaTitle,
    required this.mediaPoster,
    required this.mediaType,
    required this.date,
    required this.durationMinutes,
    this.progressPercentage,
    this.platform,
    this.rating,
    this.isCompletion = false,
    this.notes = '',
    this.achievements = const [],
  });

  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '$mins min';
    if (mins == 0) return '$hours hr';
    return '$hours hr, $mins min';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mediaId': mediaId,
      'mediaTitle': mediaTitle,
      'mediaPoster': mediaPoster,
      'mediaType': mediaType.name,
      'date': date.toIso8601String(),
      'durationMinutes': durationMinutes,
      'progressPercentage': progressPercentage,
      'platform': platform,
      'rating': rating,
      'isCompletion': isCompletion ? 1 : 0,
      'notes': notes,
      'achievements': achievements.join('|'),
    };
  }

  factory PlaySession.fromMap(Map<String, dynamic> map) {
    return PlaySession(
      id: map['id'] as String,
      mediaId: map['mediaId'] as String,
      mediaTitle: map['mediaTitle'] as String,
      mediaPoster: map['mediaPoster'] as String,
      mediaType: MediaType.values.byName(map['mediaType'] as String),
      date: DateTime.parse(map['date'] as String),
      durationMinutes: map['durationMinutes'] as int,
      progressPercentage: (map['progressPercentage'] as num?)?.toDouble(),
      platform: map['platform'] as String?,
      rating: (map['rating'] as num?)?.toDouble(),
      isCompletion: (map['isCompletion'] as int?) == 1,
      notes: map['notes'] as String? ?? '',
      achievements: (map['achievements'] as String?)?.isNotEmpty == true
          ? (map['achievements'] as String).split('|')
          : [],
    );
  }
}
