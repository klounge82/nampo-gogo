import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_mode_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/business_theme.dart';

class BusinessPendingShell extends StatefulWidget {
  const BusinessPendingShell({super.key});

  @override
  State<BusinessPendingShell> createState() => _BusinessPendingShellState();
}

class _BusinessPendingShellState extends State<BusinessPendingShell> {
  bool _isRefreshing = false;

  Future<void> _refreshState() async {
    setState(() => _isRefreshing = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.autoLogin();
    if (mounted) setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final status = user?.businessApplicationStatus ?? 'PENDING';

    return Theme(
      data: BusinessTheme.themeData,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FA),
        appBar: AppBar(
          title: Text(
            _getAppBarTitle(status),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: BusinessTheme.primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: _isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isRefreshing ? null : _refreshState,
              tooltip: '상태 새로고침',
            ),
          ],
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
                      decoration: BoxDecoration(
                        color: _getIconBgColor(status),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        size: 56.0,
                        color: _getIconColor(status),
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      _getMainTitle(status),
                      style: const TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: BusinessTheme.darkSlate,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _getDescriptionText(status),
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
                    _buildInfoRow('신청 상태', _getStatusLabel(status)),

                    const SizedBox(height: 28.0),

                    if (status == 'APPROVED') ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.storefront),
                          label: const Text(
                            '사업자 모드 시작',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: () async {
                            await authProvider.autoLogin();
                            final modeProvider = Provider.of<AppModeProvider>(
                              context,
                              listen: false,
                            );
                            final updatedUser = authProvider.currentUser;
                            if (updatedUser != null) {
                              modeProvider.switchMode(
                                AppMode.business,
                                updatedUser,
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12.0),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.person_outline),
                        label: const Text(
                          '이용자(Customer) 모드로 이동',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BusinessTheme.primaryTeal,
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          side: const BorderSide(
                            color: BusinessTheme.primaryTeal,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        onPressed: () {
                          final modeProvider = Provider.of<AppModeProvider>(
                            context,
                            listen: false,
                          );
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

  String _getAppBarTitle(String status) {
    switch (status) {
      case 'APPROVED':
        return '사업자 승인 완료';
      case 'REJECTED':
        return '사업자 승인 반려';
      case 'SUSPENDED':
        return '사업자 기능 제한';
      case 'PENDING':
      default:
        return '사업자 승인 대기';
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'APPROVED':
        return Icons.check_circle_outline;
      case 'REJECTED':
        return Icons.cancel_outlined;
      case 'SUSPENDED':
        return Icons.block;
      case 'PENDING':
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  Color _getIconBgColor(String status) {
    switch (status) {
      case 'APPROVED':
        return const Color(0xFFE8F5E9);
      case 'REJECTED':
        return const Color(0xFFFFEBEE);
      case 'SUSPENDED':
        return const Color(0xFFECEFF1);
      case 'PENDING':
      default:
        return const Color(0xFFE6F4F1);
    }
  }

  Color _getIconColor(String status) {
    switch (status) {
      case 'APPROVED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      case 'SUSPENDED':
        return Colors.blueGrey;
      case 'PENDING':
      default:
        return BusinessTheme.primaryTeal;
    }
  }

  String _getMainTitle(String status) {
    switch (status) {
      case 'APPROVED':
        return '사업자 회원 승인 완료';
      case 'REJECTED':
        return '사업자 회원 신청 미승인';
      case 'SUSPENDED':
        return '사업자 기능 이용 제한';
      case 'PENDING':
      default:
        return '사업자 승인 대기 중';
    }
  }

  String _getDescriptionText(String status) {
    switch (status) {
      case 'APPROVED':
        return '축하합니다! 사업자 회원 승인이 완료되었습니다.\n아래 [사업자 모드 시작] 버튼을 눌러 매장을 관리해 보세요.';
      case 'REJECTED':
        return '사업자 회원 신청이 승인되지 않았습니다.\n제출 서류 및 사업자 정보를 확인해 주세요.';
      case 'SUSPENDED':
        return '현재 계정의 사업자 관리 기능 이용이 제한되었습니다.\n문의사항은 관리자에게 연락해 주세요.';
      case 'PENDING':
      default:
        return '제출하신 사업자 회원 가입 신청건이 관리자 검토 단계에 있습니다.\n검토 완료 후 결과가 안내됩니다.';
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'APPROVED':
        return '승인 완료 (APPROVED)';
      case 'REJECTED':
        return '반려/거절됨 (REJECTED)';
      case 'SUSPENDED':
        return '이용 제한 (SUSPENDED)';
      case 'PENDING':
      default:
        return '검토 중 (PENDING)';
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14.0, color: Colors.grey)),
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
