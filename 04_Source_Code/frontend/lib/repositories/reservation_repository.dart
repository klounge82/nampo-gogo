import 'package:flutter/foundation.dart';
import '../models/reservation.dart';
import '../models/place.dart';
import '../services/reservation_service.dart';

class ReservationRepository {
  final ReservationService _reservationService;

  // Local state cache for offline simulation fallback
  static final List<Reservation> _mockReservations = [];

  ReservationRepository({ReservationService? reservationService})
    : _reservationService = reservationService ?? ReservationService();

  // Create Reservation
  Future<Reservation> createReservation({
    required String storeId,
    required DateTime reservationTime,
    required int partySize,
    String? userId,
  }) async {
    try {
      final res = await _reservationService.createReservation(
        storeId: storeId,
        reservationDate: reservationTime.toIso8601String().substring(0, 10),
        startTime:
            "${reservationTime.hour.toString().padLeft(2, '0')}:${reservationTime.minute.toString().padLeft(2, '0')}",
        partySize: partySize,
        userId: userId,
      );
      return Reservation.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReservationRepository: Failed to create reservation online. Simulating offline. Error: $e',
        );
      }

      // Fallback offline simulator
      final newId = 'res_mock_${DateTime.now().millisecondsSinceEpoch}';

      // Attempt to load place info or default
      final newRes = Reservation(
        id: newId,
        userId: userId ?? 'usr_mock_999',
        storeId: storeId,
        reservationTime: reservationTime,
        partySize: partySize,
        status: 'pending',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        store: Place(
          id: storeId,
          name: '매장 정보 확인 중',
          category: '음식점',
          rating: 4.5,
          address: '부산 중구 남포길 1',
          description: '남포 GoGo 협약 제공 매장입니다.',
          imageUrl: '',
          createdAt: DateTime.now(),
        ),
      );

      _mockReservations.insert(0, newRes);
      return newRes;
    }
  }

  // Cancel Reservation
  Future<bool> cancelReservation(String reservationId, {String? userId}) async {
    try {
      final res = await _reservationService.cancelReservation(reservationId);
      return res['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReservationRepository: Failed to cancel reservation online. Simulating offline. Error: $e',
        );
      }

      final index = _mockReservations.indexWhere((r) => r.id == reservationId);
      if (index != -1) {
        final current = _mockReservations[index];
        if (current.status == 'cancelled' || current.status == 'completed') {
          throw Exception('이미 취소 또는 완료된 예약입니다. (오프라인 모드)');
        }

        _mockReservations[index] = Reservation(
          id: current.id,
          userId: current.userId,
          storeId: current.storeId,
          reservationTime: current.reservationTime,
          partySize: current.partySize,
          status: 'cancelled',
          createdAt: current.createdAt,
          updatedAt: DateTime.now(),
          store: current.store,
        );
        return true;
      }
      throw Exception('해당 예약 신청 건을 찾을 수 없습니다.');
    }
  }

  // Get user reservations list
  Future<List<Reservation>> getUserReservations({String? userId}) async {
    try {
      final list = await _reservationService.fetchUserReservations(
        userId: userId,
      );
      return list
          .map((json) => Reservation.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReservationRepository: Failed to fetch reservations. Simulating offline. Error: $e',
        );
      }
      return List.from(_mockReservations);
    }
  }

  // Get reservation detail
  Future<Reservation> getReservationDetail(String reservationId) async {
    try {
      final res = await _reservationService.fetchReservationDetail(
        reservationId,
      );
      return Reservation.fromJson(res);
    } catch (e) {
      if (kDebugMode) {
        print(
          'ReservationRepository: Failed to get reservation detail. Simulating offline. Error: $e',
        );
      }
      return _mockReservations.firstWhere(
        (r) => r.id == reservationId,
        orElse: () => throw Exception('해당 예약 정보를 찾을 수 없습니다.'),
      );
    }
  }
}
