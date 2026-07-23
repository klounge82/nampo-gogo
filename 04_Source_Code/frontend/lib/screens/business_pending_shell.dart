import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/business_theme.dart';

class BusinessPendingShell extends StatelessWidget {
  const BusinessPendingShell({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final businessApp = user?.businessApplicationStatus ?? 'PENDING';

    return Theme(
      data: BusinessTheme.themeData,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FA),
        appBar: AppBar(
          title: const Text(
            '사업자 승인 대기',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: BusinessTheme.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE6F4F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 56.0,
                        color: BusinessTheme.primaryTeal,
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    const Text(
                      '사업자 승인 대기 중',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: BusinessTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      '제출하신 사업자 회원 가입 신청건이 관리자 검토 단계에 있습니다.\n검토 완료 후 결과가 안내됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.0,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24.0),
                    const Divider(),
                    const SizedBox(height: 16.0),

                    _buildInfoRow('계정 이메일', user?.email ?? '-'),
                    const SizedBox(height: 8.0),
                    _buildInfoRow('닉네임', user?.nickname ?? '-'),
                    const SizedBox(height: 8.0),
                    _buildInfoRow('신청 상태', '검토 중 (PENDING)'),

                    const SizedBox(height: 28.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.mode_standby),
                        label: const Text(
                          '이용자(Customer) 모드로 이동',
                          style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BusinessTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          final modeProvider = Provider.of<AppModeProvider>(context, listen: false);
                          modeProvider.switchMode(AppMode.customer, user);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14.0,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: BusinessTheme.darkSlate,
          ),
        ),
      ],
    );
  }
}
