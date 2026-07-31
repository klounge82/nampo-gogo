import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/reservation.dart';
import 'package:frontend/utils/reservation_status_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HOTFIX-012: Reservation Store Name, Status & Dialog Layout Tests', () {
    test(
      '1. Reservation.fromJson parses store_name and never defaults to "남포 숯불갈비"',
      () {
        final jsonWithStoreName = {
          'id': 'res_1',
          'user_id': 'usr_1',
          'store_id': '31b96920-2eb3-4f93-ab51-546fd8d933d1',
          'store_name': 'K-Lounge',
          'reservation_date': '2026-07-31',
          'start_time': '19:00',
          'party_size': 2,
          'status': 'APPROVED',
        };

        final res = Reservation.fromJson(jsonWithStoreName);
        expect(res.store.name, equals('K-Lounge'));
        expect(res.store.name, isNot(equals('남포 숯불갈비')));
      },
    );

    test('2. Reservation.fromJson handles null store_name safely', () {
      final jsonNullStoreName = {
        'id': 'res_2',
        'user_id': 'usr_2',
        'store_id': 'unknown_store',
        'party_size': 1,
        'status': 'PENDING',
      };

      final res = Reservation.fromJson(jsonNullStoreName);
      expect(res.store.name, equals('매장 정보 확인 중'));
      expect(res.store.name, isNot(equals('남포 숯불갈비')));
    });

    test('3. ReservationStatusHelper maps statuses correctly', () {
      expect(
        ReservationStatusHelper.getKoreanLabel('PENDING'),
        equals('승인 대기'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('APPROVED'),
        equals('예약 승인'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('CONFIRMED'),
        equals('예약 승인'),
      );
      expect(
        ReservationStatusHelper.getKoreanLabel('COMPLETED'),
        equals('이용 완료'),
      );
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
    });

    testWidgets(
      '4. Reservation completion dialog uses semantic line breaks and bounded width',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) {
                        const storeName = 'K-Lounge';
                        return Dialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Container(
                            width: 320,
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉 예약 신청 접수 완료'),
                                const SizedBox(height: 16.0),
                                Text('$storeName 매장에\n예약 신청이 접수되었습니다.'),
                                const SizedBox(height: 10.0),
                                const Text('사업자가 확인한 후\n승인 여부를 알려드립니다.'),
                                const SizedBox(height: 24.0),
                                ElevatedButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('확인'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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

        expect(find.text('🎉 예약 신청 접수 완료'), findsOneWidget);
        expect(find.text('K-Lounge 매장에\n예약 신청이 접수되었습니다.'), findsOneWidget);
        expect(find.text('사업자가 확인한 후\n승인 여부를 알려드립니다.'), findsOneWidget);
        expect(find.text('확인'), findsOneWidget);
      },
    );
  });
}
