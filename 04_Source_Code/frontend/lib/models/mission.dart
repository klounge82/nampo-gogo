// ignore_for_file: prefer_initializing_formals

class Mission {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final String? titleEn;
  final String? titleJa;
  final String? titleZh;
  final String? descriptionEn;
  final String? descriptionJa;
  final String? descriptionZh;
  final int points;
  final String authType; // 'GPS', 'QR', 'PHOTO'
  final DateTime? _createdAt;
  final String reward;
  final String category;
  final bool isCompleted;

  const Mission({
    required this.id,
    this.storeId = '',
    required this.title,
    required this.description,
    this.titleEn,
    this.titleJa,
    this.titleZh,
    this.descriptionEn,
    this.descriptionJa,
    this.descriptionZh,
    required this.points,
    this.authType = 'GPS',
    DateTime? createdAt,
    this.reward = '',
    this.category = '일반',
    this.isCompleted = false,
  }) : _createdAt = createdAt;

  DateTime get createdAt => _createdAt ?? DateTime.now();

  String localizedTitle(String languageCode) {
    final lang = languageCode.toLowerCase();
    if (lang.contains('zh')) {
      return (titleZh != null && titleZh!.trim().isNotEmpty) ? titleZh! : title;
    } else if (lang.contains('ja')) {
      return (titleJa != null && titleJa!.trim().isNotEmpty) ? titleJa! : title;
    } else if (lang.contains('en')) {
      return (titleEn != null && titleEn!.trim().isNotEmpty) ? titleEn! : title;
    }
    return title;
  }

  String localizedDescription(String languageCode) {
    final lang = languageCode.toLowerCase();
    if (lang.contains('zh')) {
      return (descriptionZh != null && descriptionZh!.trim().isNotEmpty) ? descriptionZh! : description;
    } else if (lang.contains('ja')) {
      return (descriptionJa != null && descriptionJa!.trim().isNotEmpty) ? descriptionJa! : description;
    } else if (lang.contains('en')) {
      return (descriptionEn != null && descriptionEn!.trim().isNotEmpty) ? descriptionEn! : description;
    }
    return description;
  }

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      storeId: json['store_id'] as String? ?? json['storeId'] as String? ?? '',
      title: json['title'] as String,
      description: json['description'] as String,
      titleEn: json['title_en'] as String? ?? json['titleEn'] as String?,
      titleJa: json['title_ja'] as String? ?? json['titleJa'] as String?,
      titleZh: json['title_zh_hans'] as String? ?? json['title_zh'] as String? ?? json['titleZh'] as String?,
      descriptionEn: json['description_en'] as String? ?? json['descriptionEn'] as String?,
      descriptionJa: json['description_ja'] as String? ?? json['descriptionJa'] as String?,
      descriptionZh: json['description_zh_hans'] as String? ?? json['description_zh'] as String? ?? json['descriptionZh'] as String?,
      points: json['points'] as int? ?? 0,
      authType: json['auth_type'] as String? ?? json['authType'] as String? ?? 'GPS',
      reward: json['reward'] as String? ?? '',
      category: json['category'] as String? ?? '일반',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'title': title,
      'description': description,
      'title_en': titleEn,
      'title_ja': titleJa,
      'title_zh': titleZh,
      'description_en': descriptionEn,
      'description_ja': descriptionJa,
      'description_zh': descriptionZh,
      'points': points,
      'auth_type': authType,
      'reward': reward,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
