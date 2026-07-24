import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/profile_provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submitChange() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await context.read<ProfileProvider>().changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('비밀번호 변경 완료'),
            content: const Text(
              '비밀번호가 안전하게 변경되었습니다. 보안 세션을 위해 로그아웃되며 새 비밀번호로 다시 로그인해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close Dialog
                  // Perform logout and redirect to login/auth flow
                  context.read<ProfileProvider>().withdrawAccount(context);
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('비밀번호 변경 실패: $e')));
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
        title: const Text('비밀번호 변경'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '계정 보안을 위해 정기적으로 비밀번호를 변경해 주세요.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  // Current Password
                  TextFormField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '현재 비밀번호',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '현재 비밀번호를 입력해 주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // New Password
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호',
                      helperText: '최소 8자 이상, 영문과 숫자를 반드시 포함해야 합니다.',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_reset),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 입력해 주세요.';
                      }
                      if (value.length < 8) {
                        return '비밀번호는 최소 8자 이상이어야 합니다.';
                      }
                      if (!RegExp(r'[a-zA-Z]').hasMatch(value) ||
                          !RegExp(r'[0-9]').hasMatch(value)) {
                        return '영문자와 숫자를 모두 포함해야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  // Confirm New Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '새 비밀번호 확인',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_clock),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '새 비밀번호를 다시 입력해 주세요.';
                      }
                      if (value != _newPasswordController.text) {
                        return '입력한 비밀번호가 일치하지 않습니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitChange,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: const Text('변경 완료'),
                  ),
                ],
              ),
            ),
          ),
          if (_isSubmitting)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
