import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../repositories/payment_repository.dart';
import '../models/payment_model.dart';

class PaymentProvider extends ChangeNotifier {
  final PaymentRepository _repository = PaymentRepository();
  final _uuid = const Uuid();

  List<PaymentModel> _payments = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PaymentModel> get payments => _payments;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all user payment receipt histories
  Future<void> loadUserPayments(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _payments = await _repository.getPayments(token: token);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Unified payment process executor (Create -> Mock PG Confirm)
  Future<PaymentModel?> executePayment({
    required String token,
    required int amount,
    required String paymentMethod,
    required String targetType,
    required String targetId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Create payment order with a secure idempotency key
      final String idempotencyKey = _uuid.v4();
      final PaymentModel pendingPayment = await _repository.startPayment(
        token: token,
        amount: amount,
        paymentMethod: paymentMethod,
        targetType: targetType,
        targetId: targetId,
        idempotencyKey: idempotencyKey,
      );

      // 2. Simulating Mock PG dialog input check (Delaying for visual UX)
      await Future.delayed(const Duration(milliseconds: 800));

      // 3. Confirm payment order
      final PaymentModel completedPayment = await _repository.approvePayment(
        token: token,
        paymentId: pendingPayment.id,
        mockToken: 'mock_pg_token_${_uuid.v4().substring(0, 8)}',
      );

      // Reload history list if success
      await loadUserPayments(token);
      return completedPayment;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Request refund
  Future<bool> requestRefund({
    required String token,
    required String paymentId,
    required int refundAmount,
    required String reason,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _repository.refundPayment(
        token: token,
        paymentId: paymentId,
        refundAmount: refundAmount,
        reason: reason,
      );
      await loadUserPayments(token);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
