// ignore_for_file: prefer_initializing_formals

class Mission {
  final String id;
  final String storeId;
  final String title;
  final String description;
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
    required this.points,
    this.authType = 'GPS',
    DateTime? createdAt,
    this.reward = '',
    this.category = '일반',
    this.isCompleted = false,
  }) : _createdAt = createdAt;

  DateTime get createdAt => _createdAt ?? DateTime.now();

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'] as String,
      storeId: json['store_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      points: json['points'] as int,
      authType: json['auth_type'] as String,
      reward: json['reward'] as String? ?? '',
      category: json['category'] as String? ?? '일반',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'store_id': storeId,
      'title': title,
      'description': description,
      'points': points,
      'auth_type': authType,
      'reward': reward,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
