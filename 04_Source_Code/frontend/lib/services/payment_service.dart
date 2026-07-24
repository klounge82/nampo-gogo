import 'package:dio/dio.dart';
import '../config/api_config.dart';

class PaymentService {
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

  // POST /payments/create
  Future<Map<String, dynamic>> createPayment({
    required String token,
    required int amount,
    required String paymentMethod,
    required String targetType,
    required String targetId,
    required String idempotencyKey,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/create',
        data: {
          'amount': amount,
          'payment_method': paymentMethod,
          'target_type': targetType,
          'target_id': targetId,
          'idempotency_key': idempotencyKey,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // POST /payments/confirm
  Future<Map<String, dynamic>> confirmPayment({
    required String token,
    required String paymentId,
    String? mockToken,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/confirm',
        data: {
          'payment_id': paymentId,
          if (mockToken != null) 'mock_token': mockToken,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // POST /payments/cancel
  Future<Map<String, dynamic>> cancelPayment({
    required String token,
    required String paymentId,
    String? reason,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/cancel',
        data: {'payment_id': paymentId, if (reason != null) 'reason': reason},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // POST /payments/refund
  Future<Map<String, dynamic>> refundPayment({
    required String token,
    required String paymentId,
    required int refundAmount,
    required String reason,
  }) async {
    try {
      final res = await _dio.post(
        '/payments/refund',
        data: {
          'payment_id': paymentId,
          'refund_amount': refundAmount,
          'reason': reason,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  // GET /payments
  Future<List<dynamic>> fetchPayments({required String token}) async {
    try {
      final res = await _dio.get(
        '/payments',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.data as List<dynamic>;
    } catch (e) {
      rethrow;
    }
  }
}
