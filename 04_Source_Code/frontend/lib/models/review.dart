import 'user.dart';
import 'place.dart';

class ReviewImage {
  final String id;
  final String reviewId;
  final String imageUrl;
  final DateTime createdAt;

  ReviewImage({
    required this.id,
    required this.reviewId,
    required this.imageUrl,
    required this.createdAt,
  });

  factory ReviewImage.fromJson(Map<String, dynamic> json) {
    return ReviewImage(
      id: json['id'] as String? ?? '',
      reviewId: json['review_id'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_id': reviewId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Review {
  final String id;
  final String? userId;
  final String? guestId;
  final String storeId;
  final int rating;
  final String content;
  final bool isDeleted;
  final String? verificationId;
  final String? verificationMethod;
  final String? verificationBadge;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User user;
  final List<ReviewImage> images;
  final Place? store;

  final bool isOwner;
  final bool canEdit;
  final bool canDelete;
  final bool canRestore;
  final bool canRewrite;

  Review({
    required this.id,
    this.userId,
    this.guestId,
    required this.storeId,
    required this.rating,
    required this.content,
    required this.isDeleted,
    this.verificationId,
    this.verificationMethod,
    this.verificationBadge,
    required this.createdAt,
    required this.updatedAt,
    required this.user,
    this.images = const [],
    this.store,
    this.isOwner = false,
    this.canEdit = false,
    this.canDelete = false,
    this.canRestore = false,
    this.canRewrite = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    var imagesList = json['images'] as List<dynamic>? ?? [];
    List<ReviewImage> parsedImages = imagesList
        .map((img) => ReviewImage.fromJson(img as Map<String, dynamic>))
        .toList();

    final isDel = json['is_deleted'] as bool? ?? false;
    final isOwn = json['is_owner'] as bool? ?? false;

    return Review(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      guestId: json['guest_id'] as String?,
      storeId: json['store_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      content: json['content'] as String? ?? '',
      isDeleted: isDel,
      verificationId: json['verification_id'] as String?,
      verificationMethod: json['verification_method'] as String?,
      verificationBadge: json['verification_badge'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      user: User.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      images: parsedImages,
      store: json['store'] != null
          ? Place.fromJson(json['store'] as Map<String, dynamic>)
          : null,
      isOwner: isOwn,
      canEdit: json['can_edit'] as bool? ?? (isOwn && !isDel),
      canDelete: json['can_delete'] as bool? ?? (isOwn && !isDel),
      canRestore: json['can_restore'] as bool? ?? (isOwn && isDel),
      canRewrite: json['can_rewrite'] as bool? ?? (isOwn && isDel),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'guest_id': guestId,
      'store_id': storeId,
      'rating': rating,
      'content': content,
      'is_deleted': isDeleted,
      'verification_id': verificationId,
      'verification_method': verificationMethod,
      'verification_badge': verificationBadge,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user': user.toJson(),
      'images': images.map((img) => img.toJson()).toList(),
      if (store != null) 'store': store!.toJson(),
      'is_owner': isOwner,
      'can_edit': canEdit,
      'can_delete': canDelete,
      'can_restore': canRestore,
      'can_rewrite': canRewrite,
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? guestId,
    String? storeId,
    int? rating,
    String? content,
    bool? isDeleted,
    String? verificationId,
    String? verificationMethod,
    String? verificationBadge,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? user,
    List<ReviewImage>? images,
    Place? store,
    bool? isOwner,
    bool? canEdit,
    bool? canDelete,
    bool? canRestore,
    bool? canRewrite,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      guestId: guestId ?? this.guestId,
      storeId: storeId ?? this.storeId,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      isDeleted: isDeleted ?? this.isDeleted,
      verificationId: verificationId ?? this.verificationId,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      user: user ?? this.user,
      images: images ?? this.images,
      store: store ?? this.store,
      isOwner: isOwner ?? this.isOwner,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canRestore: canRestore ?? this.canRestore,
      canRewrite: canRewrite ?? this.canRewrite,
    );
  }
}

class MyReviewResult {
  final String status; // 'ACTIVE', 'DELETED', 'NONE'
  final Review? review;
  final bool canEdit;
  final bool canDelete;
  final bool canRestore;
  final bool canRewrite;

  MyReviewResult({
    required this.status,
    this.review,
    this.canEdit = false,
    this.canDelete = false,
    this.canRestore = false,
    this.canRewrite = false,
  });

  factory MyReviewResult.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String? ?? 'NONE';
    final revJson = json['review'] as Map<String, dynamic>?;
    final rev = revJson != null ? Review.fromJson(revJson) : null;

    return MyReviewResult(
      status: statusStr,
      review: rev,
      canEdit: json['can_edit'] as bool? ?? (rev?.canEdit ?? false),
      canDelete: json['can_delete'] as bool? ?? (rev?.canDelete ?? false),
      canRestore: json['can_restore'] as bool? ?? (rev?.canRestore ?? false),
      canRewrite: json['can_rewrite'] as bool? ?? (rev?.canRewrite ?? false),
    );
  }
}
