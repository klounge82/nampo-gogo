import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
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

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'ko_KR',
    symbol: '₩',
  );
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  Future<void> _refundTransaction(String paymentId, int amount) async {
    final l10n = AppLocalizations.of(context);
    final token = context.read<AuthProvider>().accessToken;
    if (token == null || token.isEmpty) return;

    if (!ProductionConfig.isMockPayment) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n?.policyRefundTitle ?? 'Policy'),
          content: Text(
            l10n?.policyNoticeHeader ??
                'Live payment environment. Direct refunds are handled via customer support.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.confirm ?? 'OK'),
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
        title: Text(l10n?.refundRequest ?? 'Request Refund'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n?.refundRequest ?? 'Refund'}: ${_currencyFormat.format(amount)}'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: l10n?.refundReason ?? 'Refund Reason',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.confirm ?? 'OK'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final reason = reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.refundReason ?? 'Please enter a refund reason.'),
          ),
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
            SnackBar(
              content: Text(l10n?.refundSuccess ?? 'Refund processed successfully.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.refundFailed ?? 'Failed to process refund request.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.profilePaymentHistory ?? 'Payment History',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (provider.errorMessage != null) {
            return Center(child: Text(l10n?.errorNetwork ?? 'Network error.'));
          }

          final list = provider.payments;
          if (list.isEmpty) {
            return Center(
              child: Text(
                l10n?.noPaymentsHistory ?? 'No payment history found.',
              ),
            );
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
                          pay.targetType == 'POINT_CHARGE'
                              ? '💎 ${l10n?.pointCharge ?? 'Point Charge'}'
                              : '📅 ${l10n?.reservationDeposit ?? 'Reservation Deposit'}',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
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
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${l10n?.paymentDateLabel ?? 'Date'}: ${_dateFormat.format(pay.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: Colors.grey,
                      ),
                    ),
                    if (pay.refunds.isNotEmpty) ...[
                      const Divider(height: 20.0),
                      Text(
                        '${l10n?.refundReason ?? 'Refund Reason'}: ${pay.refunds.first.reason ?? '-'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Colors.deepOrange,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (canRefund) ...[
                      const Divider(height: 20.0),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton(
                          onPressed: () =>
                              _refundTransaction(pay.id, pay.amount),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                          ),
                          child: Text(
                            l10n?.refundRequest ?? 'Request Refund',
                            style: const TextStyle(fontSize: 11.5),
                          ),
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
