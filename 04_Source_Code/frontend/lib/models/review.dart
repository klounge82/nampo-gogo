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
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    var imagesList = json['images'] as List<dynamic>? ?? [];
    List<ReviewImage> parsedImages = imagesList
        .map((img) => ReviewImage.fromJson(img as Map<String, dynamic>))
        .toList();

    return Review(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      guestId: json['guest_id'] as String?,
      storeId: json['store_id'] as String? ?? '',
      rating: json['rating'] as int? ?? 5,
      content: json['content'] as String? ?? '',
      isDeleted: json['is_deleted'] as bool? ?? false,
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
    };
  }
}
