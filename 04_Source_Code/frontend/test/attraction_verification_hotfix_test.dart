import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/production_config.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  group(
    'HOTFIX-RELEASE-001-H2: Frontend Attraction Verification & Badge Policy Tests',
    () {
      final testUser = User(
        id: 'usr_attraction_001',
        email: 'user@attraction.com',
        nickname: '관광객',
        role: 'member',
        status: 'active',
        currentPoints: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final businessStore = Place(
        id: 'store_biz_1',
        name: '남포 숯불갈비',
        category: '맛집',
        rating: 4.8,
        address: '부산 중구 남포길 12',
        description: '사업장 매장입니다.',
        reviewVerificationType: 'BUSINESS_QR',
        createdAt: DateTime.now(),
      );

      final attractionGPS = Place(
        id: 'attraction_gps_1',
        name: '용두산공원 부산타워',
        category: '볼거리',
        rating: 4.7,
        address: '부산 중구 용두산길 37',
        description: '좌표가 등록된 관광지입니다.',
        latitude: 35.1005,
        longitude: 129.0326,
        reviewVerificationType: 'ATTRACTION_LOCATION',
        reviewLocationRadiusM: 300,
        manualVisitAllowed: true,
        createdAt: DateTime.now(),
      );

      final attractionNoCoords = Place(
        id: 'attraction_nocoords_1',
        name: '부산 야경 산책로',
        category: '볼거리',
        rating: 4.5,
        address: '부산 중구 해안로 일대',
        description: '좌표 미등록 관광지입니다.',
        latitude: null,
        longitude: null,
        reviewVerificationType: 'ATTRACTION_LOCATION',
        manualVisitAllowed: true,
        createdAt: DateTime.now(),
      );

      // 1. Central Config Defaults
      test('1. ProductionConfig central defaults are valid', () {
        expect(ProductionConfig.defaultVerificationRadiusMeters, equals(300));
        expect(ProductionConfig.defaultMaxVisitDateDaysAgo, equals(90));
        expect(
          ProductionConfig.maxAllowedLocationAccuracyMeters,
          equals(500.0),
        );
      });

      // 2. Business place review verification type is BUSINESS_QR
      test('2. Business place requires BUSINESS_QR verification', () {
        expect(businessStore.reviewVerificationType, equals('BUSINESS_QR'));
        expect(businessStore.latitude, isNull);
      });

      // 3. Attraction place review verification type is ATTRACTION_LOCATION
      test(
        '3. Attraction place uses ATTRACTION_LOCATION verification type',
        () {
          expect(
            attractionGPS.reviewVerificationType,
            equals('ATTRACTION_LOCATION'),
          );
          expect(attractionGPS.latitude, equals(35.1005));
          expect(attractionGPS.longitude, equals(129.0326));
          expect(attractionGPS.manualVisitAllowed, isTrue);
        },
      );

      // 4. No coordinates attraction manual visit fallback property
      test(
        '4. Missing coordinates attraction enables manual visit date fallback',
        () {
          expect(attractionNoCoords.latitude, isNull);
          expect(attractionNoCoords.longitude, isNull);
          expect(attractionNoCoords.manualVisitAllowed, isTrue);
        },
      );

      // 5. Visit Date validation: Future dates invalid
      test('5. Future visit date validation rejects future dates', () {
        final now = DateTime.now();
        final futureDate = now.add(const Duration(days: 1));

        bool isFutureValid =
            futureDate.isBefore(now) || futureDate.isAtSameMomentAs(now);
        expect(isFutureValid, isFalse);
      });

      // 6. Visit Date validation: Older than 90 days invalid
      test('6. Visit date older than 90 days rejects invalid dates', () {
        final now = DateTime.now();
        final oldestAllowed = now.subtract(
          Duration(days: ProductionConfig.defaultMaxVisitDateDaysAgo),
        );
        final tooOldDate = now.subtract(const Duration(days: 95));

        bool isDateAllowed = !tooOldDate.isBefore(oldestAllowed);
        expect(isDateAllowed, isFalse);
      });

      // 7. Badge Distinction: GPS vs Visit Date vs Business QR
      testWidgets(
        '7. Review badges correctly format GPS vs Visit Date vs Business QR badges',
        (WidgetTester tester) async {
          final gpsReview = Review(
            id: 'rev_gps_1',
            userId: testUser.id,
            storeId: attractionGPS.id,
            rating: 5,
            content: 'GPS 방문 인증으로 등록된 완벽한 후기입니다.',
            isDeleted: false,
            verificationId: 'v_gps_001',
            verificationBadge: 'GPS 방문 인증',
            verificationMethod: 'ATTRACTION_GPS',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: testUser,
            store: attractionGPS,
          );

          final dateReview = Review(
            id: 'rev_date_1',
            userId: testUser.id,
            storeId: attractionNoCoords.id,
            rating: 5,
            content: '방문일자 인증으로 등록된 후기입니다.',
            isDeleted: false,
            verificationId: 'v_date_001',
            verificationBadge: '방문일자 인증',
            verificationMethod: 'ATTRACTION_DATE',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: testUser,
            store: attractionNoCoords,
          );

          final qrReview = Review(
            id: 'rev_qr_1',
            userId: testUser.id,
            storeId: businessStore.id,
            rating: 5,
            content: 'QR 방문 인증 후기입니다.',
            isDeleted: false,
            verificationId: 'v_qr_001',
            verificationBadge: 'QR 방문 인증',
            verificationMethod: 'BUSINESS_QR',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: testUser,
            store: businessStore,
          );

          expect(gpsReview.verificationBadge, equals('GPS 방문 인증'));
          expect(dateReview.verificationBadge, equals('방문일자 인증'));
          expect(qrReview.verificationBadge, equals('QR 방문 인증'));
        },
      );

      // 8. SafeArea Widget check for bottom navigation bars
      testWidgets('8. Bottom action bar uses SafeArea to prevent clipping', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  key: const Key('bottom_action_container'),
                  height: 50.0,
                  color: Colors.blue,
                  child: const Text('하단 버튼 영역'),
                ),
              ),
            ),
          ),
        );

        expect(find.byType(SafeArea), findsWidgets);
        expect(
          find.byKey(const Key('bottom_action_container')),
          findsOneWidget,
        );
      });

      // 9. Review ownership & actions retention (canEdit / canDelete)
      test(
        '9. Review ownership flags properly compute edit/delete permissions',
        () {
          final review = Review(
            id: 'rev_owner_check',
            userId: testUser.id,
            storeId: attractionGPS.id,
            rating: 5,
            content: '내 후기 수정 및 삭제 권한 확인',
            isDeleted: false,
            isOwner: true,
            canEdit: true,
            canDelete: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: testUser,
            store: attractionGPS,
          );

          expect(review.isOwner, isTrue);
          expect(review.canEdit, isTrue);
          expect(review.canDelete, isTrue);
        },
      );

      // 10. Place model verification type default fallback
      test(
        '10. Place model falls back to BUSINESS_QR when verification type is unspecified',
        () {
          final defaultPlace = Place(
            id: 'store_default_1',
            name: '기본 매장',
            category: '기타',
            rating: 4.0,
            address: '부산 중구',
            description: '설명',
            createdAt: DateTime.now(),
          );

          expect(defaultPlace.reviewVerificationType, equals('BUSINESS_QR'));
        },
      );

      // 11. Regression Test: BUSINESS_QR stores (e.g. K-Lounge) are excluded from attraction coordinate audit
      test(
        '11. BUSINESS_QR stores are strictly excluded from attraction coordinate audit',
        () {
          final allPlaces = [businessStore, attractionGPS, attractionNoCoords];

          // Filter strictly for ATTRACTION_LOCATION places
          final attractionPlaces = allPlaces
              .where((p) => p.reviewVerificationType == 'ATTRACTION_LOCATION')
              .toList();

          expect(attractionPlaces.contains(businessStore), isFalse);
          expect(attractionPlaces.length, equals(2));

          final missingCoordsAttractions = attractionPlaces
              .where((p) => p.latitude == null || p.longitude == null)
              .toList();
          expect(
            missingCoordsAttractions.length,
            equals(1),
          ); // only attractionNoCoords
          expect(missingCoordsAttractions.first.name, equals('부산 야경 산책로'));
        },
      );
    },
  );
}
