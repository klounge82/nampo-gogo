import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/payment_provider.dart';
import '../providers/auth_provider.dart';
import '../config/production_config.dart';
import 'payment_result_screen.dart';

class PaymentScreen extends StatefulWidget {
  final int amount;
  final String targetType; // 'RESERVATION_DEPOSIT', 'POINT_CHARGE'
  final String targetId;
  final String targetName; // e.g. '자갈치시장 횟집 예약 보증금'

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.targetType,
    required this.targetId,
    required this.targetName,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'CARD'; // CARD, TOSS, KAKAO, STRIPE, ALIPAY

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

  Future<void> _processPayment() async {
    final token = context.read<AuthProvider>().accessToken;
    if (token == null || token.isEmpty) return;

    if (ProductionConfig.isProduction) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('결제 기능 준비 중'),
          content: const Text('현재 남포 GoGo 정식 운영 환경입니다. 결제 모듈이 승인 심사 중에 있으며, 정식 오픈 후 실결제 서비스 이용이 가능합니다.'),
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

    if (!ProductionConfig.isMockPayment) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('운영 결제 기능 제한'),
          content: const Text('현재 운영(Live) 결제 환경입니다. 실제 PG 가맹점 연동 계약 완료 후 사용 가능합니다. 개발자 설정에서 Mock 모드를 확인해 주세요.'),
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

    // Show mock authorization overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(width: 20),
            Text('가상 PG사 승인 요청 중...'),
          ],
        ),
      ),
    );

    final paymentResult = await context.read<PaymentProvider>().executePayment(
          token: token,
          amount: widget.amount,
          paymentMethod: _selectedMethod,
          targetType: widget.targetType,
          targetId: widget.targetId,
        );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss overlay
    }

    if (paymentResult != null) {
      // Navigate to success receipt screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => PaymentResultScreen(payment: paymentResult),
          ),
        );
      }
    } else {
      // Show failed snackbar
      if (mounted) {
        final err = context.read<PaymentProvider>().errorMessage ?? '결제 승인 오류';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('결제 실패: $err'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('보안 결제', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('결제 상품 정보', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                  const SizedBox(height: 4.0),
                  Text(widget.targetName, style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold)),
                  const Divider(height: 24.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('최종 결제 금액', style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600)),
                      Text(
                        _currencyFormat.format(widget.amount),
                        style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            const Text(
              '결제 수단 선택',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12.0),

            _buildMethodTile('신용/체크카드', 'CARD', Icons.credit_card, Colors.blue),
            _buildMethodTile('토스페이 (Toss Payments)', 'TOSS', Icons.send_to_mobile, Colors.blue.shade800),
            _buildMethodTile('카카오페이 (KakaoPay)', 'KAKAO', Icons.payment, Colors.amber),
            _buildMethodTile('스트라이프 글로벌 (Stripe)', 'STRIPE', Icons.public, Colors.indigo),
            _buildMethodTile('알리페이 (Alipay)', 'ALIPAY', Icons.wallet_membership, Colors.lightBlue),

            const SizedBox(height: 40.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                ),
                child: Text('${_currencyFormat.format(widget.amount)} 안전 결제하기', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String label, String code, IconData icon, Color color) {
    final bool isSel = _selectedMethod == code;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
      ),
      child: RadioListTile<String>(
        value: code,
        groupValue: _selectedMethod,
        activeColor: AppColors.primary,
        title: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500)),
          ],
        ),
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedMethod = val);
          }
        },
      ),
    );
  }
}
