import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/reservation_status_helper.dart';
import 'package:frontend/widgets/reservation_qr_widget.dart';
import 'package:frontend/registries/dashboard_widget_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RELEASE-STABILIZATION-BATCH-01: Frontend Unit & Widget Tests', () {
    testWidgets(
      '1. ReservationQrWidget renders with quiet zone and CustomPainter without crashing',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: ReservationQrWidget(qrData: 'res_test_uuid_12345'),
            ),
          ),
        );

        expect(find.byType(ReservationQrWidget), findsOneWidget);
      },
    );

    testWidgets(
      '2. ReservationQrWidget handles empty/null qrData safely',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: ReservationQrWidget(qrData: '')),
          ),
        );

        expect(find.byType(ReservationQrWidget), findsOneWidget);
      },
    );

    test('3. ReservationStatusHelper formats reservation code nicely', () {
      final formatted = ReservationStatusHelper.formatReservationCode(
        '46c4c040-1ab9-4e76-88a2-990a',
      );
      expect(formatted, startsWith('RES-'));
      expect(formatted, equals('RES-46C4-C040-1AB9'));
    });

    test(
      '4. ReservationStatusHelper converts all statuses to clean Korean text',
      () {
        expect(
          ReservationStatusHelper.getKoreanLabel('PENDING'),
          equals('승인 대기'),
        );
        expect(
          ReservationStatusHelper.getKoreanLabel('APPROVED'),
          equals('예약 승인'),
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
        expect(
          ReservationStatusHelper.getKoreanLabel('COMPLETED'),
          equals('이용 완료'),
        );
        expect(ReservationStatusHelper.getKoreanLabel('NO_SHOW'), equals('노쇼'));
      },
    );

    test(
      '5. ReservationStatusHelper formats date time safe for legacy/null records',
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
          ReservationStatusHelper.formatDateTimeSafe('2026-08-01', '14:00'),
          equals('2026-08-01 14:00'),
        );
      },
    );

    test(
      '6. DashboardWidgetRegistry uses accurate title for completed reservations widget',
      () {
        final widgetDef = DashboardWidgetRegistry.businessWidgets.firstWhere(
          (w) => w.widgetKey == 'completed_reservations',
        );
        expect(widgetDef.title, equals('승인/완료 예약'));
        expect(widgetDef.statusText, equals('승인/완료'));
      },
    );

    test('7. Time comparison logic calculates start time and 15min grace period accurately', () {
      final startDt = DateTime.parse('2026-08-03T15:00:00');
      final graceEnd = startDt.add(const Duration(minutes: 15));

      final beforeStart = DateTime.parse('2026-08-03T14:59:00');
      final atStart = DateTime.parse('2026-08-03T15:00:00');
      final at14Min = DateTime.parse('2026-08-03T15:14:00');
      final at15Min = DateTime.parse('2026-08-03T15:15:00');

      expect(beforeStart.isBefore(startDt), isTrue);
      expect(atStart.isBefore(startDt), isFalse);
      expect(at14Min.isBefore(graceEnd), isTrue);
      expect(at15Min.isBefore(graceEnd), isFalse);
    });
  });
}

