import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class AccountDeleteScreen extends StatefulWidget {
  const AccountDeleteScreen({super.key});

  @override
  State<AccountDeleteScreen> createState() => _AccountDeleteScreenState();
}

class _AccountDeleteScreenState extends State<AccountDeleteScreen> {
  bool _agreeToTerms = false;
  bool _isSubmitting = false;

  Future<void> _submitWithdrawal() async {
    if (!_agreeToTerms) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<ProfileProvider>().withdrawAccount(context);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('회원탈퇴 완료'),
            content: const Text('그동안 남포 GoGo 앱을 이용해주셔서 감사합니다. 정상적으로 회원탈퇴가 완료되었습니다.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  // Clean screen stack and go back to auth screen
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('탈퇴 처리 실패: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원탈퇴'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.redAccent,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  '회원탈퇴 진행 전 반드시 확인해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black80,
                  ),
                ),
                const SizedBox(height: 30),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. 보유 포인트 전액 소멸',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text('탈퇴 완료 즉시 현재 보유하고 계신 모든 미션 포인트는 전액 영구 소멸되며, 복구가 불가능합니다.\n'),
                          Text(
                            '2. 미션 및 쿠폰 내역 삭제',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text('진행 중인 미션 스탬프와 구매 후 미사용된 모든 쿠폰 또한 즉시 무효화됩니다.\n'),
                          Text(
                            '3. 개인 식별 정보 파기',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text('계정에 기입된 이메일 정보와 프로필 데이터 등은 개인정보 처리 방침에 의거하여 마스킹 및 물리 격리 파기됩니다.\n'),
                          Text(
                            '4. 예약 히스토리 보존',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text('관광 통계 및 상가 거래 증빙을 위해 예약 기록은 삭제되지 않고 익명화 보존됩니다.'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  title: const Text(
                    '위 안내사항을 모두 확인하였으며, 이에 동의합니다.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  value: _agreeToTerms,
                  activeColor: Colors.redAccent,
                  onChanged: (val) {
                    setState(() {
                      _agreeToTerms = val ?? false;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_agreeToTerms && !_isSubmitting) ? _submitWithdrawal : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.redAccent,
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: const Text('최종 회원탈퇴 진행', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
