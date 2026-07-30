import 'package:dio/dio.dart';
import 'api_service.dart';

class ReservationService {
  Dio get _dio => ApiService().dio;

  // GET /stores/{store_id}/reservation-options
  Future<Map<String, dynamic>> getPublicReservationOptions(
    String storeId,
  ) async {
    try {
      final response = await _dio.get('/stores/$storeId/reservation-options');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 옵션 조회 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /stores/{store_id}/available-slots?date=YYYY-MM-DD
  Future<Map<String, dynamic>> getAvailableSlots(
    String storeId,
    String date,
  ) async {
    try {
      final response = await _dio.get(
        '/stores/$storeId/available-slots',
        queryParameters: {'date': date},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 가능 시간 조회 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /reservations
  Future<Map<String, dynamic>> createReservation({
    required String storeId,
    String? productId,
    required String reservationDate,
    required String startTime,
    required int partySize,
    String? customerNote,
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/reservations',
        data: {
          'store_id': storeId,
          if (productId != null) 'product_id': productId,
          'reservation_date': reservationDate,
          'start_time': startTime,
          'party_size': partySize,
          if (customerNote != null) 'customer_note': customerNote,
          if (userId != null) 'user_id': userId,
        },
      );
      if ((response.statusCode == 201 || response.statusCode == 200) &&
          response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 신청에 실패했습니다.');
    } catch (e) {
      rethrow;
    }
  }

  // GET /reservations/me
  Future<List<dynamic>> getMyReservations() async {
    try {
      final response = await _dio.get('/reservations/me');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // POST /reservations/{reservation_id}/cancel
  Future<Map<String, dynamic>> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/reservations/$reservationId/cancel',
        data: {if (reason != null) 'reason': reason},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 취소 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /users/reservations or /reservations/me
  Future<List<dynamic>> fetchUserReservations({String? userId}) async {
    try {
      final response = await _dio.get('/reservations/me');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
    } catch (_) {}

    try {
      final response = await _dio.get(
        '/users/reservations',
        queryParameters: {if (userId != null) 'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  // GET /reservations/{reservation_id}
  Future<Map<String, dynamic>> fetchReservationDetail(
    String reservationId,
  ) async {
    try {
      final response = await _dio.get('/reservations/$reservationId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 상세 로딩 실패');
    } catch (e) {
      rethrow;
    }
  }

  // --- BUSINESS RESERVATION APIs ---

  Future<Map<String, dynamic>> getBusinessReservationSettings(
    String storeId,
  ) async {
    try {
      final response = await _dio.get(
        '/business/stores/$storeId/reservation-settings',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('사업자 예약 설정 조회 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateBusinessReservationSettings(
    String storeId,
    Map<String, dynamic> settings,
  ) async {
    try {
      final response = await _dio.put(
        '/business/stores/$storeId/reservation-settings',
        data: settings,
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('사업자 예약 설정 저장 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getBusinessReservationBlackouts(String storeId) async {
    try {
      final response = await _dio.get(
        '/business/stores/$storeId/reservation-blackouts',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createBusinessReservationBlackout(
    String storeId,
    Map<String, dynamic> blackout,
  ) async {
    try {
      final response = await _dio.post(
        '/business/stores/$storeId/reservation-blackouts',
        data: blackout,
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 차단 시간 등록 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteBusinessReservationBlackout(
    String storeId,
    String blackoutId,
  ) async {
    try {
      await _dio.delete(
        '/business/stores/$storeId/reservation-blackouts/$blackoutId',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getBusinessStoreReservations(String storeId) async {
    try {
      final response = await _dio.get('/business/stores/$storeId/reservations');
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> approveBusinessReservation(
    String reservationId,
  ) async {
    try {
      final response = await _dio.post(
        '/business/reservations/$reservationId/approve',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 승인 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rejectBusinessReservation(
    String reservationId, {
    String? reason,
  }) async {
    try {
      final response = await _dio.post(
        '/business/reservations/$reservationId/reject',
        data: {if (reason != null) 'reason': reason},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 거절 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeBusinessReservation(
    String reservationId,
  ) async {
    try {
      final response = await _dio.post(
        '/business/reservations/$reservationId/complete',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 완료 처리 실패');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> noShowBusinessReservation(
    String reservationId,
  ) async {
    try {
      final response = await _dio.post(
        '/business/reservations/$reservationId/no-show',
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('노쇼 처리 실패');
    } catch (e) {
      rethrow;
    }
  }
}
