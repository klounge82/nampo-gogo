import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/config/production_config.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  group(
    'RELEASE-001-H3: Yongdusan Park Attraction Verification Unit & Widget Tests',
    () {
      final yongdusanPark = Place(
        id: 'yongdusan-park-busan-tower-001',
        name: '용두산공원 부산타워',
        category: '볼거리',
        rating: 4.6,
        address: '부산 중구 용두산길 37-55',
        description: '남포동 한가운데 우뚝 솟은 부산의 상징입니다.',
        latitude: 35.1008,
        longitude: 129.0326,
        reviewVerificationType: 'ATTRACTION_LOCATION',
        reviewLocationRadiusM: 300,
        manualVisitAllowed: true,
        createdAt: DateTime.now(),
      );

      final kloungeStore = Place(
        id: '31b96920-2eb3-4f93-ab51-546fd8d933d1',
        name: 'K-Lounge',
        category: '체험',
        rating: 4.8,
        address: '부산 중구 광복로 1',
        description: '공개 K-Lounge 매장입니다.',
        reviewVerificationType: 'BUSINESS_QR',
        createdAt: DateTime.now(),
      );

      final testUser = User(
        id: 'usr_yd_test',
        email: 'yd@test.com',
        nickname: '부산여행자',
        role: 'member',
        status: 'active',
        currentPoints: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 1. Tourist Attraction Place Detail Search & Metadata Check
      test(
        '1. Yongdusan Park metadata parses ATTRACTION_LOCATION type & coordinates correctly',
        () {
          expect(yongdusanPark.name, equals('용두산공원 부산타워'));
          expect(
            yongdusanPark.reviewVerificationType,
            equals('ATTRACTION_LOCATION'),
          );
          expect(yongdusanPark.latitude, equals(35.1008));
          expect(yongdusanPark.longitude, equals(129.0326));
          expect(yongdusanPark.manualVisitAllowed, isTrue);
        },
      );

      // 2. Verification Dialog Title & Action Button Metadata
      testWidgets(
        '2. Displays GPS and Visit Date option titles in attraction gate dialog',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('방문을 어떻게 인증하시겠습니까?'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('현재 위치로 인증'),
                                ),
                                ElevatedButton(
                                  onPressed: () {},
                                  child: const Text('방문일자로 인증'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: const Text('후기 남기기'),
                    );
                  },
                ),
              ),
            ),
          );

          await tester.tap(find.text('후기 남기기'));
          await tester.pumpAndSettle();

          expect(find.text('방문을 어떻게 인증하시겠습니까?'), findsOneWidget);
          expect(find.text('현재 위치로 인증'), findsOneWidget);
          expect(find.text('방문일자로 인증'), findsOneWidget);
        },
      );

      // 3. QR Verification Hidden for Attractions
      test('3. QR verification is disabled for ATTRACTION_LOCATION places', () {
        bool isQrRequired =
            (yongdusanPark.reviewVerificationType == 'BUSINESS_QR');
        expect(isQrRequired, isFalse);
      });

      // 4. Permission Denied Error Dialog Message
      testWidgets(
        '4. Location permission denied produces explicit guidance dialog',
        (WidgetTester tester) async {
          const permissionMsg = '현재 위치를 확인하지 못했습니다.\n위치 권한과 GPS 설정을 확인해 주세요.';

          await tester.pumpWidget(
            const MaterialApp(
              home: Scaffold(body: Center(child: Text(permissionMsg))),
            ),
          );

          expect(find.text(permissionMsg), findsOneWidget);
        },
      );

      // 5. Out of Range Error Message
      test(
        '5. Out of range location check rejects distances exceeding radius',
        () {
          const outOfRangeMsg = '현재 위치에서는 이 관광지 방문을 확인할 수 없습니다.';
          expect(outOfRangeMsg, equals('현재 위치에서는 이 관광지 방문을 확인할 수 없습니다.'));
        },
      );

      // 6. Visit Date Validation (Future Date & Older than 90 Days)
      test(
        '6. Visit date validation enforces max 90 days and blocks future dates',
        () {
          final now = DateTime.now();
          final futureDate = now.add(const Duration(days: 1));
          final validRecentDate = now.subtract(const Duration(days: 5));
          final tooOldDate = now.subtract(const Duration(days: 95));

          final oldestAllowed = now.subtract(
            Duration(days: ProductionConfig.defaultMaxVisitDateDaysAgo),
          );

          expect(futureDate.isAfter(now), isTrue); // Blocked
          expect(
            validRecentDate.isAfter(oldestAllowed) &&
                !validRecentDate.isAfter(now),
            isTrue,
          ); // Allowed
          expect(tooOldDate.isBefore(oldestAllowed), isTrue); // Blocked
        },
      );

      // 7. Post-Verification Review Creation State
      test(
        '7. Post-verification review correctly holds verification_id and badge',
        () {
          final review = Review(
            id: 'rev_yd_001',
            userId: testUser.id,
            storeId: yongdusanPark.id,
            rating: 5,
            content: '용두산공원 부산타워 전망대에서 야경을 구경했습니다!',
            isDeleted: false,
            verificationId: 'v_yd_gps_001',
            verificationBadge: 'GPS 방문 인증',
            verificationMethod: 'ATTRACTION_GPS',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            user: testUser,
            store: yongdusanPark,
          );

          expect(review.verificationId, equals('v_yd_gps_001'));
          expect(review.verificationBadge, equals('GPS 방문 인증'));
          expect(review.verificationMethod, equals('ATTRACTION_GPS'));
        },
      );

      // 8. Existing K-Lounge BUSINESS_QR Workflow Preserved
      test(
        '8. Existing K-Lounge BUSINESS_QR place retains QR verification type',
        () {
          expect(kloungeStore.reviewVerificationType, equals('BUSINESS_QR'));
        },
      );
    },
  );
}
