import 'package:dio/dio.dart';
import '../config/api_config.dart';

class ReservationService {
  Dio get _dio => Dio(
    BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  // POST /reservations
  Future<Map<String, dynamic>> createReservation({
    required String storeId,
    required DateTime reservationTime,
    required int partySize,
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/reservations',
        data: {
          'store_id': storeId,
          'reservation_time': reservationTime.toIso8601String(),
          'party_size': partySize,
          if (userId != null) 'user_id': userId,
        },
      );
      if (response.statusCode == 201 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 생성 실패');
    } catch (e) {
      rethrow;
    }
  }

  // POST /reservations/{reservation_id}/cancel
  Future<Map<String, dynamic>> cancelReservation(
    String reservationId, {
    String? userId,
  }) async {
    try {
      final response = await _dio.post(
        '/reservations/$reservationId/cancel',
        data: {'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception('예약 취소 실패');
    } catch (e) {
      rethrow;
    }
  }

  // GET /users/reservations
  Future<List<dynamic>> fetchUserReservations({String? userId}) async {
    try {
      final response = await _dio.get(
        '/users/reservations',
        queryParameters: {if (userId != null) 'user_id': userId},
      );
      if (response.statusCode == 200 && response.data != null) {
        return response.data as List<dynamic>;
      }
      throw Exception('예약 목록 로딩 실패');
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
}
