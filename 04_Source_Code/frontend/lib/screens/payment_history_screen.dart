import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../config/production_config.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken;
      if (token != null && token.isNotEmpty) {
        context.read<PaymentProvider>().loadUserPayments(token);
      }
    });
  }

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _refundTransaction(String paymentId, int amount) async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null || token.isEmpty) return;

    if (!ProductionConfig.isMockPayment) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('운영 환불 기능 제한'),
          content: const Text('현재 운영(Live) 결제 환경입니다. 가상 PG 환불 처리는 불가능하며, 고객 센터를 통해 환불 요청을 진행하십시오.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // Show refund reason dialog input
    final TextEditingController reasonController = TextEditingController();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('환불 신청'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('환불 신청 금액: ${_currencyFormat.format(amount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '환불 사유',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('확인')),
        ],
      ),
    );

    if (confirm == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('환불 사유를 입력하셔야 합니다.')),
        );
        return;
      }

      final success = await context.read<PaymentProvider>().requestRefund(
            token: token,
            paymentId: paymentId,
            refundAmount: amount,
            reason: reason,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('환불 처리가 성공적으로 완료되었습니다.')),
          );
        } else {
          final err = context.read<PaymentProvider>().errorMessage ?? '환불 에러';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('환불 실패: $err'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('결제 및 이용 이력', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.errorMessage != null) {
            return Center(child: Text('결제 내역 조회 실패: ${provider.errorMessage}'));
          }

          final list = provider.payments;
          if (list.isEmpty) {
            return const Center(child: Text('결제 및 이용 내역이 존재하지 않습니다.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final pay = list[index];
              final bool canRefund = pay.status == 'paid';

              return Container(
                margin: const EdgeInsets.only(bottom: 12.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          pay.targetType == 'POINT_CHARGE' ? '💎 포인트 충전' : '📅 예약 보증금 결제',
                          style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: pay.status == 'paid'
                                ? Colors.green.withAlpha(20)
                                : pay.status == 'refunded'
                                    ? Colors.orange.withAlpha(20)
                                    : Colors.grey.withAlpha(20),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            pay.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: pay.status == 'paid'
                                  ? Colors.green
                                  : pay.status == 'refunded'
                                      ? Colors.orange
                                      : Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      _currencyFormat.format(pay.amount),
                      style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '결제일자: ${_dateFormat.format(pay.createdAt)}',
                      style: const TextStyle(fontSize: 11.0, color: Colors.grey),
                    ),
                    if (pay.refunds.isNotEmpty) ...[
                      const Divider(height: 20.0),
                      Text(
                        '환불 사유: ${pay.refunds.first.reason ?? '사유 없음'}',
                        style: const TextStyle(fontSize: 11.5, color: Colors.deepOrange, fontWeight: FontWeight.w500),
                      ),
                    ],
                    if (canRefund) ...[
                      const Divider(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () => _refundTransaction(pay.id, pay.amount),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          ),
                          child: const Text('환불 신청', style: TextStyle(fontSize: 11.5)),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
