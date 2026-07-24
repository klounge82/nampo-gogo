import 'package:flutter/material.dart';
import '../../services/admin_business_service.dart';
import '../../themes/admin_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  final Function(String statusFilter) onSelectFilter;

  const AdminDashboardScreen({super.key, required this.onSelectFilter});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminBusinessService _adminService = AdminBusinessService();
  Map<String, dynamic>? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSummary();
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final summary = await _adminService.getSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: AdminTheme.errorRose, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchSummary,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final pendingCount = _summary?['pending_count'] ?? 0;
    final todayCount = _summary?['today_count'] ?? 0;
    final approvedCount = _summary?['approved_count'] ?? 0;
    final rejectedCount = _summary?['rejected_count'] ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '총관리자 대시보드',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '남포동 고고 시스템 운영 현황 및 사업자 신청 검토',
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.refresh,
                  color: AdminTheme.textSecondary,
                ),
                onPressed: _fetchSummary,
                tooltip: '새로고침',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stat Cards Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              final crossAxisCount = isWide ? 4 : 2;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.8 : 1.5,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    title: '승인 대기 신청',
                    count: pendingCount,
                    icon: Icons.hourglass_top,
                    color: AdminTheme.warningAmber,
                    onTap: () => widget.onSelectFilter('PENDING'),
                  ),
                  _buildStatCard(
                    title: '오늘 접수된 신청',
                    count: todayCount,
                    icon: Icons.today,
                    color: AdminTheme.primaryBlue,
                    onTap: () => widget.onSelectFilter('ALL'),
                  ),
                  _buildStatCard(
                    title: '승인 완료 사업자',
                    count: approvedCount,
                    icon: Icons.check_circle_outline,
                    color: AdminTheme.accentEmerald,
                    onTap: () => widget.onSelectFilter('APPROVED'),
                  ),
                  _buildStatCard(
                    title: '거절된 신청',
                    count: rejectedCount,
                    icon: Icons.cancel_outlined,
                    color: AdminTheme.errorRose,
                    onTap: () => widget.onSelectFilter('REJECTED'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AdminTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AdminTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              '$count건',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Row(
              children: [
                Text('목록 바로가기', style: TextStyle(fontSize: 12, color: color)),
                Icon(Icons.chevron_right, size: 16, color: color),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
