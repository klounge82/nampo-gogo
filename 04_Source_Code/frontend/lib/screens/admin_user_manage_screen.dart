import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/user.dart';
import '../repositories/admin_repository.dart';
import '../providers/auth_provider.dart';

class AdminUserManageScreen extends StatefulWidget {
  const AdminUserManageScreen({super.key});

  @override
  State<AdminUserManageScreen> createState() => _AdminUserManageScreenState();
}

class _AdminUserManageScreenState extends State<AdminUserManageScreen> {
  final AdminRepository _adminRepository = AdminRepository();
  final TextEditingController _searchController = TextEditingController();

  List<User> _users = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminId = authProvider.currentUser?.id;

    try {
      final list = await _adminRepository.getUsers(
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        adminId: adminId,
      );
      setState(() {
        _users = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(User user) async {
    final newStatus = user.status == 'active' ? 'blocked' : 'active';
    final label = newStatus == 'blocked' ? '이용 제한(정지)' : '이용 정지 해제';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: Text(
          '정말로 ${user.nickname}님을 $label 처리하시겠습니까?\n정지 시 해당 사용자는 로그인이 즉시 차단됩니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final adminId = authProvider.currentUser?.id;

    try {
      await _adminRepository.updateUserStatus(
        user.id,
        newStatus,
        adminId: adminId,
      );
      Navigator.of(context).pop(); // Dismiss loader
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✍️ ${user.nickname}님의 상태가 변경되었습니다.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadUsers();
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss loader
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('변경 실패'),
          content: Text(cleanMsg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '회원 계정 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(fontSize: 13.0),
                    decoration: InputDecoration(
                      hintText: '이메일 또는 닉네임 검색',
                      hintStyle: const TextStyle(
                        fontSize: 12.0,
                        color: AppColors.textHint,
                      ),
                      prefixIcon: const Icon(Icons.search, size: 18.0),
                      fillColor: AppColors.surface,
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (val) {
                      setState(() {
                        _searchQuery = val.trim();
                      });
                      _loadUsers();
                    },
                  ),
                ),
                const SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = _searchController.text.trim();
                    });
                    _loadUsers();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    '검색',
                    style: TextStyle(color: Colors.white, fontSize: 13.0),
                  ),
                ),
              ],
            ),
          ),

          // User list
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _errorMessage != null
                ? Center(child: Text('에러 발생: $_errorMessage'))
                : _users.isEmpty
                ? const Center(
                    child: Text(
                      '해당 유저를 찾을 수 없습니다.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      final user = _users[index];
                      return _buildUserTile(user);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(User user) {
    final bool isBlocked = user.status == 'blocked';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 4.0,
        ),
        title: Row(
          children: [
            Text(
              user.nickname,
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6.0,
                vertical: 2.0,
              ),
              decoration: BoxDecoration(
                color: isBlocked
                    ? Colors.red.withAlpha(20)
                    : Colors.green.withAlpha(20),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: Text(
                isBlocked ? '이용정지' : '활성',
                style: TextStyle(
                  fontSize: 9.0,
                  fontWeight: FontWeight.bold,
                  color: isBlocked ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2.0),
            Text(
              user.email,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2.0),
            Text(
              '포인트: ${user.currentPoints} P  |  역할: ${user.role}',
              style: const TextStyle(fontSize: 11.0, color: AppColors.textHint),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _toggleUserStatus(user),
          style: TextButton.styleFrom(
            foregroundColor: isBlocked ? Colors.green : AppColors.secondary,
          ),
          child: Text(
            isBlocked ? '정지해제' : '정지하기',
            style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
