import 'package:flutter/material.dart';
import '../../services/admin_business_service.dart';
import '../../themes/admin_theme.dart';

class AdminBusinessApprovalScreen extends StatefulWidget {
  final String initialStatusFilter;

  const AdminBusinessApprovalScreen({
    super.key,
    this.initialStatusFilter = 'ALL',
  });

  @override
  State<AdminBusinessApprovalScreen> createState() =>
      _AdminBusinessApprovalScreenState();
}

class _AdminBusinessApprovalScreenState
    extends State<AdminBusinessApprovalScreen> {
  final AdminBusinessService _adminService = AdminBusinessService();
  late String _selectedStatus;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatusFilter;
    _fetchApplications();
  }

  @override
  void didUpdateWidget(covariant AdminBusinessApprovalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatusFilter != widget.initialStatusFilter) {
      setState(() {
        _selectedStatus = widget.initialStatusFilter;
      });
      _fetchApplications();
    }
  }

  Future<void> _fetchApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final list = await _adminService.getApplications(
        status: _selectedStatus,
        q: _searchController.text,
      );
      if (mounted) {
        setState(() {
          _applications = list;
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

  void _showDetailDialog(Map<String, dynamic> appItem) async {
    final appId = appItem['id'];
    showDialog(
      context: context,
      builder: (ctx) => _ApplicationDetailDialog(
        applicationId: appId,
        adminService: _adminService,
        onProcessed: () {
          _fetchApplications();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                    '사업자 승인 관리',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '제출된 사업자 회원 가입 및 사업장 승인 신청건을 검토합니다.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AdminTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _fetchApplications,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('목록 새로고침'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminTheme.cardBg,
                  foregroundColor: AdminTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filters
          Row(
            children: [
              // Search input
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '상호명 또는 대표자명 검색...',
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AdminTheme.textSecondary,
                    ),
                    filled: true,
                    fillColor: AdminTheme.cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => _fetchApplications(),
                ),
              ),
              const SizedBox(width: 16),

              // Filter Dropdown / Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AdminTheme.cardBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedStatus,
                    dropdownColor: AdminTheme.cardBg,
                    style: const TextStyle(color: AdminTheme.textPrimary),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('전체 상태')),
                      DropdownMenuItem(
                        value: 'PENDING',
                        child: Text('PENDING (승인 대기)'),
                      ),
                      DropdownMenuItem(
                        value: 'APPROVED',
                        child: Text('APPROVED (승인 완료)'),
                      ),
                      DropdownMenuItem(
                        value: 'REJECTED',
                        child: Text('REJECTED (거절됨)'),
                      ),
                      DropdownMenuItem(
                        value: 'SUSPENDED',
                        child: Text('SUSPENDED (이용 제한)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedStatus = val);
                        _fetchApplications();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Applications List Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AdminTheme.errorRose),
                    ),
                  )
                : _applications.isEmpty
                ? const Center(
                    child: Text(
                      '조건에 해당하는 사업자 신청건이 없습니다.',
                      style: TextStyle(
                        color: AdminTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Card(
                    color: AdminTheme.cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.separated(
                      itemCount: _applications.length,
                      separatorBuilder: (ctx, i) =>
                          const Divider(color: Color(0xFF334155), height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = _applications[idx];
                        final status = item['status'] ?? 'PENDING';
                        final appType = item['application_type'] ?? 'NEW_STORE';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                          title: Row(
                            children: [
                              Text(
                                item['business_name'] ?? '상호 미정',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: AdminTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              _buildTypeBadge(appType),
                              const SizedBox(width: 8),
                              _buildStatusBadge(status),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              '대표: ${item['representative_name']} | 연락처: ${item['phone_masked']} | 사업자번호: ${item['business_registration_number_masked']} | 신청일: ${_formatDate(item['created_at'])}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ),
                          trailing: ElevatedButton(
                            onPressed: () => _showDetailDialog(item),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: status == 'PENDING'
                                  ? AdminTheme.primaryBlue
                                  : Colors.grey[700],
                              foregroundColor: Colors.white,
                            ),
                            child: Text(status == 'PENDING' ? '신청 검토' : '상세보기'),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(String appType) {
    final isNew = appType == 'NEW_STORE';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isNew
            ? Colors.purple.withOpacity(0.2)
            : Colors.blue.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isNew ? Colors.purpleAccent : Colors.blueAccent,
          width: 0.5,
        ),
      ),
      child: Text(
        isNew ? '신규 사업장' : '기존 사업장 연결',
        style: TextStyle(
          fontSize: 11,
          color: isNew ? Colors.purpleAccent : Colors.blueAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'APPROVED':
        bg = AdminTheme.accentEmerald.withOpacity(0.2);
        fg = AdminTheme.accentEmerald;
        label = '승인 완료';
        break;
      case 'REJECTED':
        bg = AdminTheme.errorRose.withOpacity(0.2);
        fg = AdminTheme.errorRose;
        label = '거절됨';
        break;
      case 'SUSPENDED':
        bg = Colors.grey.withOpacity(0.2);
        fg = Colors.grey;
        label = '이용 제한';
        break;
      case 'PENDING':
      default:
        bg = AdminTheme.warningAmber.withOpacity(0.2);
        fg = AdminTheme.warningAmber;
        label = '승인 대기';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.bold),
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return '-';
    return dateStr.toString().split('T').first;
  }
}

class _ApplicationDetailDialog extends StatefulWidget {
  final String applicationId;
  final AdminBusinessService adminService;
  final VoidCallback onProcessed;

  const _ApplicationDetailDialog({
    required this.applicationId,
    required this.adminService,
    required this.onProcessed,
  });

  @override
  State<_ApplicationDetailDialog> createState() =>
      _ApplicationDetailDialogState();
}

class _ApplicationDetailDialogState extends State<_ApplicationDetailDialog> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  bool _isActionLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await widget.adminService.getApplicationDetail(
        widget.applicationId,
      );
      if (mounted) {
        setState(() {
          _detail = detail;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _approve() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사업자 신청 승인 확인'),
        content: Text(
          '\'${_detail?['business_name']}\' 사업자 신청을 승인하시겠습니까?\n승인 시 해당 회원에게 사업자(BUSINESS) 권한 및 매장 소유권이 부여됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.accentEmerald,
            ),
            child: const Text('승인 완료'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await widget.adminService.approveApplication(widget.applicationId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사업자 신청이 성공적으로 승인되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onProcessed();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  Future<void> _reject() async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('사업자 신청 거절 사유 입력'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이 사업자 신청을 거절하시겠습니까?\n거절 사유는 신청자에게 안내되므로 개인정보나 내부 정보가 들어가지 않도록 유의해 주세요.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: '거절 사유 (필수)',
                hintText: '예: 제출된 사업자등록번호가 국세청 조회 결과와 불일치합니다.',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('거절 사유를 입력해 주세요.')),
                );
                return;
              }
              Navigator.pop(ctx, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminTheme.errorRose,
            ),
            child: const Text('신청 거절'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionLoading = true);
    try {
      await widget.adminService.rejectApplication(
        widget.applicationId,
        reasonController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('사업자 신청이 거절 처리되었습니다.'),
            backgroundColor: Colors.orange,
          ),
        );
        widget.onProcessed();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isActionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AdminTheme.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? SizedBox(
                height: 200,
                child: Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AdminTheme.errorRose),
                  ),
                ),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '사업자 신청 상세 검토',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: AdminTheme.textSecondary,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 12),

                  // Account Section
                  _buildSectionTitle('신청자 계정 정보'),
                  _buildDetailRow('닉네임', _detail?['user_nickname'] ?? '-'),
                  _buildDetailRow('이메일', _detail?['user_email_masked'] ?? '-'),

                  const SizedBox(height: 16),
                  // Business Section
                  _buildSectionTitle('사업자 및 신청 정보'),
                  _buildDetailRow('상호명', _detail?['business_name'] ?? '-'),
                  _buildDetailRow(
                    '사업자등록번호',
                    _detail?['business_registration_number'] ?? '-',
                  ),
                  _buildDetailRow(
                    '대표자 성명',
                    _detail?['representative_name'] ?? '-',
                  ),
                  _buildDetailRow('대표 연락처', _detail?['phone'] ?? '-'),
                  _buildDetailRow(
                    '신청 유형',
                    _detail?['application_type'] == 'NEW_STORE'
                        ? '신규 사업장 신청 (승인 시 비공개 초안 매장 생성)'
                        : '기존 사업장 연결 (${_detail?['requested_store_name'] ?? _detail?['requested_store_id']})',
                  ),
                  _buildDetailRow('현재 검토 상태', _detail?['status'] ?? '-'),

                  if (_detail?['status'] == 'REJECTED' &&
                      _detail?['rejection_reason'] != null)
                    _buildDetailRow('거절 사유', _detail?['rejection_reason']),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('닫기'),
                      ),
                      const SizedBox(width: 12),
                      if (_detail?['status'] == 'PENDING') ...[
                        ElevatedButton(
                          onPressed: _isActionLoading ? null : _reject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.errorRose,
                          ),
                          child: const Text('거절'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isActionLoading ? null : _approve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AdminTheme.accentEmerald,
                          ),
                          child: const Text('승인'),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AdminTheme.primaryBlue,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                color: AdminTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AdminTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
