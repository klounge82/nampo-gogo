import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/admin_repository.dart';
import '../providers/auth_provider.dart';

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  List<AdminAuditLogModel> _logs = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAuditLogs();
  }

  Future<void> _loadAuditLogs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminId = authProvider.currentUser?.id;

    try {
      final list = await _adminRepository.getAuditLogs(adminId: adminId);
      setState(() {
        _logs = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '감사 로그 조회',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(child: Text('에러 발생: $_errorMessage'))
          : _logs.isEmpty
          ? const Center(
              child: Text(
                '기록된 감사 로그가 없습니다.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadAuditLogs,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  return _buildLogCard(log);
                },
              ),
            ),
    );
  }

  Widget _buildLogCard(AdminAuditLogModel log) {
    final dateStr =
        '${log.createdAt.year}.${log.createdAt.month.toString().padLeft(2, '0')}.${log.createdAt.day.toString().padLeft(2, '0')} ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8.0,
                    vertical: 4.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    log.action,
                    style: const TextStyle(
                      fontSize: 10.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              log.details ?? '변경 세부 정보 없음',
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.person, size: 12.0, color: AppColors.textHint),
                const SizedBox(width: 4.0),
                Text(
                  '수행 관리자: ${log.admin?.nickname ?? "시스템"} (${log.admin?.email ?? "이메일 없음"})',
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
