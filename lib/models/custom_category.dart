class CustomCategory {
  final String id;
  String name;
  bool showOnHome;
  int order;
  DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.name,
    this.showOnHome = true,
    this.order = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'showOnHome': showOnHome ? 1 : 0,
      'order': order,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      showOnHome: (map['showOnHome'] as int? ?? 1) == 1,
      order: (map['order'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
