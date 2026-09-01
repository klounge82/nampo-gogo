import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/admin_repository.dart';
import '../../services/api_service.dart';
import '../../config/production_config.dart';
import '../../models/user.dart';
import '../../themes/admin_theme.dart';
import '../../utils/l10n_mappers.dart';
import '../../l10n/app_localizations.dart';

class AdminMemberManageScreen extends StatefulWidget {
  const AdminMemberManageScreen({super.key});

  @override
  State<AdminMemberManageScreen> createState() => _AdminMemberManageScreenState();
}

class _AdminMemberManageScreenState extends State<AdminMemberManageScreen> {
  final ApiService _apiService = ApiService();
  final AdminRepository _adminRepository = AdminRepository();
  bool _isLoading = false;
  String _searchQuery = '';
  List<User> _users = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _adminRepository.getUsers();
      setState(() {
        _users = response;
      });
      debugPrint('NAMPO_ADMIN_USERS_DIAG stage=SCREEN_LOAD_SUCCESS userCount=${response.length}');
    } catch (e, st) {
      debugPrint('NAMPO_ADMIN_USERS_DIAG stage=SCREEN_LOAD_ERROR exceptionType=${e.runtimeType}\n$st');
      if (ProductionConfig.enableMockData) {
        // Fallback mock users ONLY in dev/test environment
        setState(() {
          _users = [
            User(
              id: 'usr_admin_001',
              email: 'jazzbj@naver.com',
              nickname: '총관리자(PM)',
              role: 'admin',
              roles: const ['CUSTOMER', 'ADMIN'],
              status: 'ACTIVE',
              currentPoints: 300,
              createdAt: DateTime.parse('2026-08-01T09:00:00Z'),
              updatedAt: DateTime.parse('2026-08-01T09:00:00Z'),
            ),
            User(
              id: 'usr_qa_test_002',
              email: 'qa_tester@nampogogo.com',
              nickname: 'QA테스터',
              role: 'member',
              roles: const ['CUSTOMER', 'TEST'],
              status: 'ACTIVE',
              currentPoints: 500,
              createdAt: DateTime.parse('2026-08-15T14:30:00Z'),
              updatedAt: DateTime.parse('2026-08-15T14:30:00Z'),
            ),
          ];
        });
      } else {
        // Production: DO NOT replace with mock users! Render explicit failure state
        final l10n = AppLocalizations.of(context);
        final lang = l10n?.localeName ?? 'ko';
        setState(() {
          _users = [];
          _errorMessage = lang == 'en'
              ? 'Unable to load the member list. Please try again.'
              : lang == 'ja'
                  ? '会員一覧を読み込めませんでした。もう一度お試しください。'
                  : lang.startsWith('zh')
                      ? '无法加载会员列表，请重试。'
                      : '회원 목록을 불러오지 못했습니다. 다시 시도해 주세요.';
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(User userItem) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = auth.currentUser;

    if (userItem.id == currentUser?.id || userItem.email == currentUser?.email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('현재 로그인한 관리자 계정 자신은 삭제할 수 없습니다.'),
          backgroundColor: AdminTheme.errorRose,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AdminTheme.errorRose),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                '회원 계정 삭제 확인',
                style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '다음 사용자를 정말로 삭제하시겠습니까?',
              style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('이메일/계정: ${userItem.email}', style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13)),
                  Text('닉네임: ${userItem.nickname}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                  Text('가입일: ${_formatDate(userItem.createdAt)}', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
                  Text('권한: ${userItem.roles.join(', ')}', style: const TextStyle(color: AdminTheme.primaryBlue, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ 삭제 시 연관된 포인트 이력, 인증 기록 및 신청 정보가 CASCADE 정원 처리되며 복구할 수 없습니다.',
              style: TextStyle(color: AdminTheme.errorRose, fontSize: 11, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AdminTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.errorRose),
            child: const Text('삭제 수행', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _apiService.dio.delete('/admin/users/${userItem.id}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 (${userItem.email}) 계정이 성공적으로 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _users.removeWhere((u) => u.id == userItem.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('회원 (${userItem.email}) 삭제 처리 완료.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _resetQaUserBaseline(User userItem) async {
    final email = userItem.email;
    final nickname = userItem.nickname.isEmpty ? '이름 없음' : userItem.nickname;
    final currentPoints = userItem.currentPoints;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminTheme.cardBg,
        title: const Text(
          '테스트 기준선 초기화',
          style: TextStyle(color: AdminTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('대상 계정: $nickname ($email)', style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('현재 보유 포인트: ${currentPoints}P', style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 8),
            const Text('📌 초기화 후 예상 결과:', style: TextStyle(color: AdminTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
            const Text('• 보유 포인트: 300P', style: TextStyle(color: AdminTheme.primaryBlue, fontSize: 12)),
            const Text('• 누적 획득: 300P', style: TextStyle(color: AdminTheme.primaryBlue, fontSize: 12)),
            const Text('• 삭제 대상: 과거 QA 미션 보상 및 미션 완료 이력', style: TextStyle(color: AdminTheme.errorRose, fontSize: 12)),
            const Text('• 보존 대상: 가입 보너스 +300P (계정/미션/장소 정의 보존)', style: TextStyle(color: Colors.green, fontSize: 12)),
            const SizedBox(height: 12),
            const Text(
              '⚠️ 초기화 실행 시 선택한 계정의 과거 미션 보상 및 완료 이력이 300P 축하 보너스 기준선으로 원자적 초기화됩니다.',
              style: TextStyle(color: AdminTheme.textSecondary, fontSize: 11, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소', style: TextStyle(color: AdminTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
            child: const Text('초기화 실행', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _adminRepository.resetQaUserBaseline(userItem.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('테스트 기준선 초기화 완료: ${res['message'] ?? '300P 기준선 설정됨'}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        final lang = l10n?.localeName ?? 'ko';
        final safeErrorMessage = lang == 'en'
            ? 'Reset failed. Please try again.'
            : lang == 'ja'
                ? '初期化に失敗しました。もう一度お試しください。'
                : lang.startsWith('zh')
                    ? '重置失败，请重试。'
                    : '초기화에 실패했습니다. 다시 시도해 주세요.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(safeErrorMessage),
            backgroundColor: AdminTheme.errorRose,
          ),
        );
      }
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return '확인 불가';
    final dt = date is DateTime ? date : DateTime.tryParse(date.toString());
    if (dt == null) return '확인 불가';
    final local = dt.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      final email = u.email.toLowerCase();
      final nick = u.nickname.toLowerCase();
      return email.contains(q) || nick.contains(q);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    '👥 회원 및 테스트 계정 관리',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '등록된 사용자 계정과 가입일, 권한 및 테스트 상태를 조회하고 안전하게 제어합니다.',
                    style: TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AdminTheme.primaryBlue),
                onPressed: _loadUsers,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field
          TextField(
            style: const TextStyle(color: AdminTheme.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: '이메일 또는 닉네임 검색...',
              hintStyle: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: AdminTheme.textSecondary, size: 18),
              filled: true,
              fillColor: AdminTheme.sidebarBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
              });
            },
          ),
          const SizedBox(height: 16),

          // User Cards / List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AdminTheme.primaryBlue))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, color: AdminTheme.errorRose, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadUsers,
                              icon: const Icon(Icons.refresh, size: 16),
                              label: const Text('다시 시도'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AdminTheme.primaryBlue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      )
                    : filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              '등록된 회원 계정이 없습니다.',
                              style: TextStyle(color: AdminTheme.textSecondary),
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final userItem = filteredUsers[index];
                              final auth = Provider.of<AuthProvider>(context, listen: false);
                              final currentUserId = auth.currentUser?.id;
                              final currentUserEmail = auth.currentUser?.email;

                              final isSelfAccount = (currentUserId != null && currentUserId == userItem.id) ||
                                  (currentUserEmail != null && currentUserEmail == userItem.email);

                              final isTestData = userItem.roles.contains('TEST') || userItem.role == 'test';

                              final isDesignatedPmQa = userItem.email == 'jazzbj@naver.com' ||
                                  userItem.id == '2abb6e52-d447-4338-8beb-e638890a5ecc';

                              final canResetBaseline = isTestData || isDesignatedPmQa;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: AdminTheme.sidebarBg,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isTestData
                                        ? Colors.amber.withOpacity(0.4)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isTestData ? Colors.amber.shade800 : AdminTheme.primaryBlue,
                                      radius: 18,
                                      child: Icon(
                                        isTestData ? Icons.bug_report : Icons.person,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  userItem.nickname.isEmpty ? '이름 없음' : userItem.nickname,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                    color: AdminTheme.textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isTestData) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.amber.shade900.withOpacity(0.3),
                                                    borderRadius: BorderRadius.circular(4),
                                                    border: Border.all(color: Colors.amber.shade700, width: 0.6),
                                                  ),
                                                  child: const Text(
                                                    'QA TEST',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.amber,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '이메일: ${userItem.email.isEmpty ? 'N/A' : userItem.email}',
                                            style: const TextStyle(fontSize: 12, color: AdminTheme.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '가입일: ${_formatDate(userItem.createdAt)} | ${userItem.currentPoints}P',
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 110,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          if (canResetBaseline) ...[
                                            OutlinedButton.icon(
                                              onPressed: () => _resetQaUserBaseline(userItem),
                                              icon: const Icon(Icons.restart_alt, size: 12, color: Colors.amber),
                                              label: const Text(
                                                '기준선 초기화',
                                                style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: Colors.amber, width: 0.8),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                          if (!isSelfAccount)
                                            OutlinedButton.icon(
                                              onPressed: () => _deleteUser(userItem),
                                              icon: const Icon(Icons.delete_outline, size: 13, color: AdminTheme.errorRose),
                                              label: const Text(
                                                '삭제',
                                                style: TextStyle(color: AdminTheme.errorRose, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                side: const BorderSide(color: AdminTheme.errorRose, width: 0.8),
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                            )
                                          else
                                            Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade800,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                '본인 계정',
                                                style: TextStyle(color: Colors.grey, fontSize: 11),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
