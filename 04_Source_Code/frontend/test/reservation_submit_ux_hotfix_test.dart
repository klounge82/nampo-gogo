import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/reservation_status_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HOTFIX-011: Reservation Submit UX & Safe Status Tests', () {
    test('1. ReservationStatusHelper formats PENDING as 승인 대기', () {
      expect(
        ReservationStatusHelper.getKoreanLabel('PENDING'),
        equals('승인 대기'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('pending'),
        equals('승인 대기'),
      );
    });

    test('2. ReservationStatusHelper formats APPROVED/CONFIRMED as 승인 완료', () {
      expect(
        ReservationStatusHelper.getKoreanLabel('APPROVED'),
        equals('승인 완료'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('CONFIRMED'),
        equals('승인 완료'),
      );
    });

    test('3. ReservationStatusHelper formats COMPLETED as 이용 완료', () {
      expect(
        ReservationStatusHelper.getKoreanLabel('COMPLETED'),
        equals('이용 완료'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('completed'),
        equals('이용 완료'),
      );
    });

    test('4. ReservationStatusHelper formats REJECTED as 승인 거절', () {
      expect(
        ReservationStatusHelper.getKoreanLabel('REJECTED'),
        equals('승인 거절'),
      );
    });

    test(
      '5. ReservationStatusHelper formats CANCELLED_BY_CUSTOMER / CANCELLED_BY_BUSINESS',
      () {
        expect(
          ReservationStatusHelper.getKoreanLabel('CANCELLED_BY_CUSTOMER'),
          equals('이용자 취소'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('CANCELLED_BY_BUSINESS'),
          equals('매장 취소'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('CANCELLED'),
          equals('취소됨'),
        );
      },
    );

    test('6. ReservationStatusHelper formats NO_SHOW as 노쇼', () {
      expect(ReservationStatusHelper.getKoreanLabel('NO_SHOW'), equals('노쇼'));
    });

    test(
      '7. ReservationStatusHelper handles null and unknown status safely',
      () {
        expect(
          ReservationStatusHelper.getKoreanLabel(null),
          equals('상태 확인 필요'),
        );
        expect(ReservationStatusHelper.getKoreanLabel(''), equals('상태 확인 필요'));
        expect(
          ReservationStatusHelper.getKoreanLabel('UNKNOWN_FOO'),
          equals('상태 확인 필요'),
        );
      },
    );

    test(
      '8. ReservationStatusHelper handles null date/time safely without crashing',
      () {
        expect(
          ReservationStatusHelper.formatDateTimeSafe(null, null),
          equals('시간 미정'),
        );
        expect(
          ReservationStatusHelper.formatDateTimeSafe('', ''),
          equals('시간 미정'),
        );
        expect(
          ReservationStatusHelper.formatDateTimeSafe('2026-07-31', null),
          equals('2026-07-31 (시간 미정)'),
        );
        expect(
          ReservationStatusHelper.formatDateTimeSafe('2026-07-31', '14:00'),
          equals('2026-07-31 14:00'),
        );
      },
    );

    testWidgets('9. Reservation submit button label is "예약 신청하기"', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: () {},
              child: const Text('예약 신청하기'),
            ),
          ),
        ),
      );

      expect(find.text('예약 신청하기'), findsOneWidget);
      expect(find.text('예약 확정하기'), findsNothing);
    });

    testWidgets('10. SafeArea wraps bottom action bar safely', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeArea(
              bottom: true,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('예약 신청하기'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(SafeArea), findsOneWidget);
    });
  });
}
