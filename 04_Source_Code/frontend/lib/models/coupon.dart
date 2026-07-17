class Coupon {
  final String id;
  final String title;
  final String description;
  final int costPoints;
  final String image_url;
  final int expiryDays;
  final DateTime createdAt;

  Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.costPoints,
    this.image_url = '',
    required this.expiryDays,
    required this.createdAt,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      costPoints: json['cost_points'] as int? ?? 0,
      image_url: json['image_url'] as String? ?? '',
      expiryDays: json['expiry_days'] as int? ?? 30,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cost_points': costPoints,
      'image_url': image_url,
      'expiry_days': expiryDays,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserCoupon {
  final String id;
  final String userId;
  final String couponId;
  final String status; // 'unused', 'used', 'expired'
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? usedAt;
  final Coupon coupon;

  UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.usedAt,
    required this.coupon,
  });

  factory UserCoupon.fromJson(Map<String, dynamic> json) {
    return UserCoupon(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      couponId: json['coupon_id'] as String? ?? '',
      status: json['status'] as String? ?? 'unused',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now(),
      usedAt: json['used_at'] != null
          ? DateTime.parse(json['used_at'] as String)
          : null,
      coupon: Coupon.fromJson(json['coupon'] as Map<String, dynamic>? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'coupon_id': couponId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'coupon': coupon.toJson(),
    };
  }
}
