class SteamAchievement {
  final String apiName;
  final String name;
  final String description;
  final String iconUrl;
  final String? iconLockedUrl;
  final bool isUnlocked;
  final DateTime? unlockTime;

  const SteamAchievement({
    required this.apiName,
    required this.name,
    required this.description,
    required this.iconUrl,
    this.iconLockedUrl,
    required this.isUnlocked,
    this.unlockTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'apiName': apiName,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'iconLockedUrl': iconLockedUrl,
      'isUnlocked': isUnlocked ? 1 : 0,
      'unlockTime': unlockTime?.toIso8601String(),
    };
  }

  factory SteamAchievement.fromMap(Map<String, dynamic> map) {
    return SteamAchievement(
      apiName: map['apiName'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      iconLockedUrl: map['iconLockedUrl'] as String?,
      isUnlocked: (map['isUnlocked'] as int? ?? 0) == 1,
      unlockTime: map['unlockTime'] != null ? DateTime.tryParse(map['unlockTime'] as String) : null,
    );
  }
}
