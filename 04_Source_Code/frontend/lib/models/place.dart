class Place {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String address;
  final String description;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  // Expansion Architecture fields (MAP-001 requirements)
  final Map<String, String> nameTranslations;
  final Map<String, String> descriptionTranslations;
  final String status; // '영업중', '곧 마감', '휴무'
  final String? operatingHours;
  final String? phoneNumber;
  final String? homepageUrl;

  // Review Verification Policy fields
  final String
  reviewVerificationType; // 'BUSINESS_QR', 'ATTRACTION_LOCATION', 'OPEN_REVIEW'
  final int reviewLocationRadiusM;
  final bool manualVisitAllowed;

  const Place({
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.address,
    required this.description,
    this.imageUrl,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.nameTranslations = const {},
    this.descriptionTranslations = const {},
    this.status = '영업중',
    this.operatingHours,
    this.phoneNumber,
    this.homepageUrl,
    this.reviewVerificationType = 'BUSINESS_QR',
    this.reviewLocationRadiusM = 300,
    this.manualVisitAllowed = true,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    // Deserialize name translations if available
    final nameKo = json['name'] as String? ?? '';
    final nameEn = json['name_en'] as String? ?? '';
    final nameJa = json['name_ja'] as String? ?? '';
    final nameZh = json['name_zh'] as String? ?? '';

    final descKo = json['description'] as String? ?? '';
    final descEn = json['description_en'] as String? ?? '';
    final descJa = json['description_ja'] as String? ?? '';
    final descZh = json['description_zh'] as String? ?? '';

    // Mock logic for status if not provided (deterministic mock by rating/id length)
    final mockStatus =
        (json['status'] as String?) ??
        ((json['id'] as String).length % 3 == 0
            ? '휴무'
            : ((json['id'] as String).length % 3 == 1 ? '곧 마감' : '영업중'));

    final cat = json['category'] as String? ?? '';
    final isAttractionFallback =
        cat == '볼거리' ||
        cat == '관광' ||
        nameKo.contains('공원') ||
        nameKo.contains('타워') ||
        nameKo.contains('광장') ||
        nameKo.contains('시장전체') ||
        nameKo.contains('해수욕장') ||
        nameKo.contains('마을');
    final defaultPolicy = isAttractionFallback
        ? 'ATTRACTION_LOCATION'
        : 'BUSINESS_QR';

    return Place(
      id: json['id'] as String? ?? '',
      name: nameKo,
      category: cat,
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : 0.0,
      address: json['address'] as String? ?? '',
      description: descKo,
      imageUrl: json['image_url'] as String?,
      latitude: json['latitude'] != null
          ? (json['latitude'] as num).toDouble()
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] as num).toDouble()
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      nameTranslations: {
        'ko': nameKo,
        'en': nameEn.isNotEmpty ? nameEn : nameKo,
        'ja': nameJa.isNotEmpty ? nameJa : nameKo,
        'zh': nameZh.isNotEmpty ? nameZh : nameKo,
      },
      descriptionTranslations: {
        'ko': descKo,
        'en': descEn.isNotEmpty ? descEn : descKo,
        'ja': descJa.isNotEmpty ? descJa : descKo,
        'zh': descZh.isNotEmpty ? descZh : descKo,
      },
      status: mockStatus,
      operatingHours: json['operating_hours'] as String? ?? '09:00 - 22:00',
      phoneNumber: json['phone_number'] as String? ?? '051-123-4567',
      homepageUrl: json['homepage_url'] as String?,
      reviewVerificationType:
          json['review_verification_type'] as String? ?? defaultPolicy,
      reviewLocationRadiusM: json['review_location_radius_m'] as int? ?? 300,
      manualVisitAllowed: json['manual_visit_allowed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'rating': rating,
      'address': address,
      'description': description,
      'image_url': imageUrl,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'name_en': nameTranslations['en'],
      'name_ja': nameTranslations['ja'],
      'name_zh': nameTranslations['zh'],
      'description_en': descriptionTranslations['en'],
      'description_ja': descriptionTranslations['ja'],
      'description_zh': descriptionTranslations['zh'],
      'status': status,
      'operating_hours': operatingHours,
      'phone_number': phoneNumber,
      'homepage_url': homepageUrl,
      'review_verification_type': reviewVerificationType,
      'review_location_radius_m': reviewLocationRadiusM,
      'manual_visit_allowed': manualVisitAllowed,
    };
  }
}
