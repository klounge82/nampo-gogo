import 'package:flutter/foundation.dart';
import '../models/reservation.dart';
import '../models/place.dart';
import '../services/reservation_service.dart';

class ReservationRepository {
  final ReservationService _reservationService;

  // Local state cache for offline simulation fallback
  static final List<Reservation> _mockReservations = [
    Reservation(
      id: 'res_mock_1',
      userId: 'usr_mock_999',
      storeId: 'store_mock_1',
      reservationTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      partySize: 2,
      status: 'confirmed',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      store: Place(
        id: 'store_mock_1',
        name: '남포 숯불갈비',
        category: '한식',
        rating: 4.8,
        address: '부산 중구 남포길 12-1',
        description: '숯불로 구워내 더욱 풍미 깊은 양념갈비 맛집입니다.',
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ),
    Reservation(
      id: 'res_mock_2',
      userId: 'usr_mock_999',
      storeId: 'store_mock_2',
      reservationTime: DateTime.now().subtract(const Duration(days: 3)),
      partySize: 4,
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
      store: Place(
        id: 'store_mock_2',
        name: '자갈치 신선 횟집',
        category: '일식/회',
        rating: 4.6,
        address: '부산 중구 자갈치해안로 52',
        description: '자갈치시장에서 갓 잡아 올린 싱싱한 모듬회 전문점.',
        imageUrl: '',
        createdAt: DateTime.now(),
      ),
    ),
  ];

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
        reservationTime: reservationTime,
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
          name: storeId.contains('jagal') ? '자갈치 신선 횟집' : '남포 숯불갈비',
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
      final res = await _reservationService.cancelReservation(
        reservationId,
        userId: userId,
      );
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
