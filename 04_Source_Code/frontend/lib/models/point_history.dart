class PointHistory {
  final String id;
  final String userId;
  final int points;
  final String activity;
  final DateTime createdAt;

  PointHistory({
    required this.id,
    required this.userId,
    required this.points,
    required this.activity,
    required this.createdAt,
  });

  factory PointHistory.fromJson(Map<String, dynamic> json) {
    return PointHistory(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      activity: json['activity'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'points': points,
      'activity': activity,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
