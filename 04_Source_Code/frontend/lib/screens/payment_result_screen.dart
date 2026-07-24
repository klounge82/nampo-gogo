import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../models/payment_model.dart';
import 'main_navigation_screen.dart';

class PaymentResultScreen extends StatelessWidget {
  final PaymentModel payment;

  const PaymentResultScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
    );
    final DateFormat dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Success check animation header
              Container(
                width: 72.0,
                height: 72.0,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 40.0, color: Colors.white),
              ),
              const SizedBox(height: 20.0),
              const Text(
                '결제가 완료되었습니다',
                style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                '안전하게 트랜잭션 처리가 완료되었습니다.',
                style: TextStyle(fontSize: 12.0, color: Colors.grey),
              ),
              const SizedBox(height: 36.0),

              // Receipt panel
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '결제 영수증 명세',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 24.0),
                    _buildReceiptRow(
                      '결제 금액',
                      currencyFormat.format(payment.amount),
                      isPrimary: true,
                    ),
                    _buildReceiptRow('결제 수단', payment.paymentMethod),
                    _buildReceiptRow('결제 종류', payment.targetType),
                    _buildReceiptRow(
                      '결제 상태',
                      payment.status.toUpperCase(),
                      valueColor: Colors.green,
                    ),
                    _buildReceiptRow(
                      '결제 시간',
                      dateFormat.format(payment.createdAt),
                    ),
                    _buildReceiptRow('거래 고유번호', payment.id.substring(0, 18)),
                    _buildReceiptRow(
                      '중복방지 키',
                      payment.idempotencyKey.substring(0, 18),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48.0),

              // Button actions
              SizedBox(
                width: double.infinity,
                height: 48.0,
                child: ElevatedButton(
                  onPressed: () {
                    // Navigate back to Main Screen
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => const MainNavigationScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text(
                    '확인 (홈으로 이동)',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isPrimary = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isPrimary ? 15.0 : 12.0,
              fontWeight: isPrimary ? FontWeight.bold : FontWeight.w500,
              color:
                  valueColor ??
                  (isPrimary ? AppColors.primary : AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
