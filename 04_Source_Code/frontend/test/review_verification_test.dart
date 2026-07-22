import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';

void main() {
  group('Review Verification Policy Unit Tests', () {
    test('Place model correctly parses review_verification_type', () {
      final jsonBusiness = {
        'id': 'store_001',
        'name': 'K-Lounge',
        'category': '체험',
        'rating': 4.8,
        'address': '부산 중구',
        'description': '마사지 매장',
        'review_verification_type': 'BUSINESS_QR',
        'review_location_radius_m': 300,
        'manual_visit_allowed': true,
      };
      final placeBusiness = Place.fromJson(jsonBusiness);
      expect(placeBusiness.reviewVerificationType, equals('BUSINESS_QR'));

      final jsonAttraction = {
        'id': 'store_002',
        'name': '용두산공원 부산타워',
        'category': '볼거리',
        'rating': 4.5,
        'address': '부산 중구 용두산길',
        'description': '전망대',
        'review_verification_type': 'ATTRACTION_LOCATION',
        'review_location_radius_m': 500,
        'manual_visit_allowed': true,
      };
      final placeAttraction = Place.fromJson(jsonAttraction);
      expect(
        placeAttraction.reviewVerificationType,
        equals('ATTRACTION_LOCATION'),
      );
      expect(placeAttraction.reviewLocationRadiusM, equals(500));
    });

    test(
      'Place model applies attraction fallback policy for landmark categories',
      () {
        final jsonLandmark = {
          'id': 'store_003',
          'name': '자갈치시장 전체',
          'category': '볼거리',
          'rating': 4.6,
          'address': '부산 중구',
          'description': '어시장 전체',
        };
        final place = Place.fromJson(jsonLandmark);
        expect(place.reviewVerificationType, equals('ATTRACTION_LOCATION'));
      },
    );

    test(
      'Review model deserializes verification badge and method correctly',
      () {
        final reviewJson = {
          'id': 'rev_101',
          'store_id': 'store_001',
          'rating': 5,
          'content': 'QR 인증 완료된 10자 이상의 리뷰 본문 내용입니다.',
          'is_deleted': false,
          'verification_id': 'v_abc_123',
          'verification_method': 'BUSINESS_QR',
          'verification_badge': 'QR 방문 인증',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'user': {
            'id': 'usr_1',
            'email': 'user@example.com',
            'nickname': '인증고객',
            'role': 'member',
            'status': 'active',
            'current_points': 100,
            'language_code': 'ko',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          },
        };

        final review = Review.fromJson(reviewJson);
        expect(review.verificationId, equals('v_abc_123'));
        expect(review.verificationMethod, equals('BUSINESS_QR'));
        expect(review.verificationBadge, equals('QR 방문 인증'));
      },
    );
  });
}
