import '../services/payment_service.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final PaymentService _service = PaymentService();

  Future<PaymentModel> startPayment({
    required String token,
    required int amount,
    required String paymentMethod,
    required String targetType,
    required String targetId,
    required String idempotencyKey,
  }) async {
    final data = await _service.createPayment(
      token: token,
      amount: amount,
      paymentMethod: paymentMethod,
      targetType: targetType,
      targetId: targetId,
      idempotencyKey: idempotencyKey,
    );
    return PaymentModel.fromJson(data);
  }

  Future<PaymentModel> approvePayment({
    required String token,
    required String paymentId,
    String? mockToken,
  }) async {
    final data = await _service.confirmPayment(
      token: token,
      paymentId: paymentId,
      mockToken: mockToken,
    );
    return PaymentModel.fromJson(data);
  }

  Future<PaymentModel> cancelPayment({
    required String token,
    required String paymentId,
    String? reason,
  }) async {
    final data = await _service.cancelPayment(
      token: token,
      paymentId: paymentId,
      reason: reason,
    );
    return PaymentModel.fromJson(data);
  }

  Future<PaymentRefundModel> refundPayment({
    required String token,
    required String paymentId,
    required int refundAmount,
    required String reason,
  }) async {
    final data = await _service.refundPayment(
      token: token,
      paymentId: paymentId,
      refundAmount: refundAmount,
      reason: reason,
    );
    return PaymentRefundModel.fromJson(data);
  }

  Future<List<PaymentModel>> getPayments({required String token}) async {
    final list = await _service.fetchPayments(token: token);
    return list.map((e) => PaymentModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
