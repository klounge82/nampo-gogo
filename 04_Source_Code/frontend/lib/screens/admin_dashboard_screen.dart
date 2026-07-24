import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/admin_repository.dart';
import '../providers/auth_provider.dart';
import 'admin_user_manage_screen.dart';
import 'admin_store_manage_screen.dart';
import 'admin_mission_manage_screen.dart';
import 'admin_reservation_manage_screen.dart';
import 'admin_review_manage_screen.dart';
import 'admin_audit_log_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminId = authProvider.currentUser?.id;

    try {
      final data = await _adminRepository.getStats(adminId: adminId);
      setState(() {
        _stats = data;
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
          '관리자 시스템',
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('통계를 불러오지 못했습니다: $_errorMessage'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadDashboardStats,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '실시간 지표 현황',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Stats Grid
                    _buildStatsGrid(),
                    const SizedBox(height: 28.0),

                    const Text(
                      '관리 모듈',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Menu items
                    _buildMenuCard(
                      title: '회원 계정 관리',
                      subtitle: '가입 유저 상태 조회 및 이용 제한 정지 처리',
                      icon: Icons.people_outline,
                      color: Colors.blue,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminUserManageScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      title: '협약 매장 관리',
                      subtitle: '남포동 매장 추가, 정보 수정 및 비활성화',
                      icon: Icons.storefront_outlined,
                      color: Colors.orange,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminStoreManageScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      title: '인증 미션 관리',
                      subtitle: '유형별 GPS/QR 미션 등록 및 노출 비활성화',
                      icon: Icons.assignment_turned_in_outlined,
                      color: Colors.purple,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminMissionManageScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      title: '예약 거래 내역',
                      subtitle: '사용자 매장 예약 목록 추적 및 상태 강제 변경',
                      icon: Icons.calendar_month_outlined,
                      color: Colors.teal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminReservationManageScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      title: '리뷰 노출 차단',
                      subtitle: '악성 비방성 후기 조사 및 일반 사용자 숨김 제어',
                      icon: Icons.rate_review_outlined,
                      color: Colors.red,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminReviewManageScreen(),
                        ),
                      ),
                    ),
                    _buildMenuCard(
                      title: '감사 로그 조회',
                      subtitle: '운영 변경 사항 로그 타임라인 기록 추적',
                      icon: Icons.security_outlined,
                      color: Colors.grey.shade700,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminAuditLogScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.6,
      children: [
        _buildStatCard(
          '총 가입자',
          '${_stats?['total_users'] ?? 0}명',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          '협약 매장',
          '${_stats?['total_stores'] ?? 0}개',
          Icons.storefront,
          Colors.orange,
        ),
        _buildStatCard(
          '등록 미션',
          '${_stats?['total_missions'] ?? 0}개',
          Icons.assignment,
          Colors.purple,
        ),
        _buildStatCard(
          '활성 예약',
          '${_stats?['active_reservations'] ?? 0}건',
          Icons.notifications_active,
          Colors.teal,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(icon, size: 18.0, color: color),
              ],
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: Container(
          width: 44.0,
          height: 44.0,
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 11.0,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textHint),
        onTap: onTap,
      ),
    );
  }
}
