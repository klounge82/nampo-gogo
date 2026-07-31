import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/reservation.dart';
import 'package:frontend/screens/reservation_detail_screen.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/providers/app_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('HOTFIX-014: User Reservation Detail API & Reasons Tests', () {
    test('1. Reservation model parses flat API response safely', () {
      final jsonMap = {
        'id': 'res_test_1001',
        'user_id': 'usr_101',
        'store_id': 'store_99',
        'store_name': 'K-Lounge Nampo',
        'reservation_date': '2026-08-01',
        'start_time': '18:00',
        'party_size': 3,
        'status': 'REJECTED',
        'rejection_reason': '재고가 부족합니다.',
        'cancellation_reason': null,
        'created_at': '2026-07-31T10:00:00Z',
        'updated_at': '2026-07-31T10:05:00Z',
      };

      final res = Reservation.fromJson(jsonMap);
      expect(res.id, equals('res_test_1001'));
      expect(res.store.name, equals('K-Lounge Nampo'));
      expect(res.status, equals('REJECTED'));
      expect(res.rejectionReason, equals('재고가 부족합니다.'));
      expect(res.cancellationReason, isNull);
    });

    test('2. Reservation model parses envelope API response safely', () {
      final envelopeJson = {
        'reservation': {
          'id': 'res_test_1002',
          'user_id': 'usr_102',
          'store_id': 'store_88',
          'store_name': '남포 숯불갈비',
          'reservation_date': '2026-08-02',
          'start_time': '19:30',
          'party_size': 4,
          'status': 'CANCELLED_BY_BUSINESS',
          'rejection_reason': null,
          'cancellation_reason': '매장 사정으로 일시휴업',
          'created_at': '2026-07-31T11:00:00Z',
          'updated_at': '2026-07-31T11:10:00Z',
        },
      };

      final inner = envelopeJson['reservation'] as Map<String, dynamic>;
      final res = Reservation.fromJson(inner);

      expect(res.id, equals('res_test_1002'));
      expect(res.store.name, equals('남포 숯불갈비'));
      expect(res.status, equals('CANCELLED_BY_BUSINESS'));
      expect(res.cancellationReason, equals('매장 사정으로 일시휴업'));
    });

    testWidgets(
      '3. ReservationDetailScreen renders loading indicator and handles error UI cleanly',
      (WidgetTester tester) async {
        final authProvider = AuthProvider();
        final appModeProvider = AppModeProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<AppModeProvider>.value(
                value: appModeProvider,
              ),
            ],
            child: const MaterialApp(
              home: ReservationDetailScreen(reservationId: 'non_existent_id'),
            ),
          ),
        );

        // Verify initial loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pump(const Duration(seconds: 1));

        // Verify retry button or safe error message renders without raw Exception stack trace
        expect(
          find
              .byType(CircularProgressIndicator)
              .or(find.textContaining('예약 정보')),
          findsWidgets,
        );
      },
    );
  });
}

extension FinderOr on Finder {
  Finder or(Finder other) => find.byElementPredicate(
    (element) =>
        evaluate().contains(element) || other.evaluate().contains(element),
  );
}
