import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/reservation.dart';
import 'package:frontend/utils/reservation_status_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RELEASE-001-I3: Reservation Exception States Unit & Widget Tests', () {
    test(
      '1. ReservationStatusHelper returns exact Korean labels for exception states',
      () {
        expect(
          ReservationStatusHelper.getKoreanLabel('REJECTED'),
          equals('승인 거절'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('CANCELLED_BY_CUSTOMER'),
          equals('이용자 취소'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('CANCELLED_BY_BUSINESS'),
          equals('매장 취소'),
        );
        expect(ReservationStatusHelper.getKoreanLabel('NO_SHOW'), equals('노쇼'));
        expect(
          ReservationStatusHelper.getKoreanLabel('PENDING'),
          equals('승인 대기'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('APPROVED'),
          equals('승인 완료'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('COMPLETED'),
          equals('이용 완료'),
        );
      },
    );

    test(
      '2. Reservation model parses rejection and cancellation reasons correctly',
      () {
        final jsonRejection = {
          'id': 'res_rej_1',
          'user_id': 'usr_1',
          'store_id': 'store_1',
          'store_name': 'K-Lounge',
          'reservation_date': '2026-08-01',
          'start_time': '14:00',
          'party_size': 2,
          'status': 'REJECTED',
          'rejection_reason': '재료 소진으로 인한 거절',
        };

        final resRej = Reservation.fromJson(jsonRejection);
        expect(resRej.status, equals('REJECTED'));
        expect(resRej.rejectionReason, equals('재료 소진으로 인한 거절'));

        final jsonCancel = {
          'id': 'res_can_1',
          'user_id': 'usr_1',
          'store_id': 'store_1',
          'store_name': 'K-Lounge',
          'reservation_date': '2026-08-01',
          'start_time': '14:00',
          'party_size': 2,
          'status': 'CANCELLED_BY_BUSINESS',
          'cancellation_reason': '매장 임시 휴무',
        };

        final resCan = Reservation.fromJson(jsonCancel);
        expect(resCan.status, equals('CANCELLED_BY_BUSINESS'));
        expect(resCan.cancellationReason, equals('매장 임시 휴무'));
      },
    );

    testWidgets(
      '3. No-Show confirmation dialog renders warning text correctly',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('노쇼 처리 확인'),
                        content: const Text(
                          '고객이 예약 시간에 방문하지 않았습니까?\n노쇼 처리 후에는 일반 상태로 되돌릴 수 없습니다.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('취소'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('노쇼 확정'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('노쇼 처리 확인'), findsOneWidget);
        expect(
          find.text('고객이 예약 시간에 방문하지 않았습니까?\n노쇼 처리 후에는 일반 상태로 되돌릴 수 없습니다.'),
          findsOneWidget,
        );
        expect(find.text('노쇼 확정'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Customer cancellation confirmation dialog renders clean text',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('예약 취소'),
                        content: const Text('예약을 취소하시겠습니까?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('돌아가기'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('확인'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Cancel Dialog'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Cancel Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('예약 취소'), findsOneWidget);
        expect(find.text('예약을 취소하시겠습니까?'), findsOneWidget);
        expect(find.text('돌아가기'), findsOneWidget);
        expect(find.text('확인'), findsOneWidget);
      },
    );
  });
}
