class PaymentRefundModel {
  final String id;
  final String paymentId;
  final int refundAmount;
  final String? reason;
  final String status;
  final DateTime createdAt;

  PaymentRefundModel({
    required this.id,
    required this.paymentId,
    required this.refundAmount,
    this.reason,
    required this.status,
    required this.createdAt,
  });

  factory PaymentRefundModel.fromJson(Map<String, dynamic> json) {
    return PaymentRefundModel(
      id: json['id'] as String? ?? '',
      paymentId: json['payment_id'] as String? ?? '',
      refundAmount: json['refund_amount'] as int? ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class PaymentModel {
  final String id;
  final String userId;
  final int amount;
  final String paymentMethod;
  final String targetType;
  final String targetId;
  final String status;
  final String idempotencyKey;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<PaymentRefundModel> refunds;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    required this.targetType,
    required this.targetId,
    required this.status,
    required this.idempotencyKey,
    required this.createdAt,
    required this.updatedAt,
    required this.refunds,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    var refundsList = json['refunds'] as List<dynamic>? ?? [];
    List<PaymentRefundModel> parsedRefunds = refundsList
        .map((e) => PaymentRefundModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaymentModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      paymentMethod: json['payment_method'] as String? ?? '',
      targetType: json['target_type'] as String? ?? '',
      targetId: json['target_id'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      idempotencyKey: json['idempotency_key'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      refunds: parsedRefunds,
    );
  }
}
