import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  bool _isLoginMode = true; // true: Login, false: SignUp
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    if (_isLoginMode) {
      final success = await authProvider.login(
        email: email,
        password: password,
      );
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('로그인 성공! 기존 게스트 데이터가 회원 계정에 안전하게 연결되었습니다.'),
              backgroundColor: AppColors.primary,
            ),
          );
          Navigator.of(context).pop(); // Go back
        } else {
          _showErrorDialog('로그인 실패', '이메일 또는 비밀번호를 다시 확인해 주세요.');
        }
      }
    } else {
      try {
        final user = await authProvider.signUp(
          email: email,
          password: password,
          nickname: nickname,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '회원가입 완료! [${user.nickname}]님, 기존 게스트 데이터가 안전하게 연결되었습니다. 로그인해 주세요.',
              ),
              backgroundColor: AppColors.primary,
            ),
          );
          // Toggle mode to Login
          setState(() {
            _isLoginMode = true;
          });
        }
      } catch (e) {
        _showErrorDialog('회원가입 실패', '이미 가입된 이메일이거나 회원가입 정보에 문제가 있습니다.');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _isLoginMode ? '남포 GoGo 로그인' : '남포 GoGo 회원가입',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.directions_run,
                    size: 64.0,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    _isLoginMode
                        ? '로그인하여 게스트 데이터를 회원 계정으로 연결하세요!'
                        : '남포 GoGo 회원가입을 환영합니다.',
                    style: const TextStyle(
                      fontSize: 14.0,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28.0),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null ||
                          value.trim().isEmpty ||
                          !value.contains('@')) {
                        return '올바른 이메일 주소를 입력해 주세요.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: '비밀번호 (최소 8자 이상)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty || value.length < 8) {
                        return '비밀번호는 최소 8자 이상이어야 합니다.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16.0),

                  // Password Confirmation (SignUp Mode Only)
                  if (!_isLoginMode) ...[
                    TextFormField(
                      controller: _passwordConfirmController,
                      obscureText: !_isConfirmPasswordVisible,
                      decoration: InputDecoration(
                        labelText: '비밀번호 확인',
                        prefixIcon: const Icon(Icons.lock_reset_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '비밀번호 확인을 입력해 주세요.';
                        }
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),

                    // Nickname
                    TextFormField(
                      controller: _nicknameController,
                      decoration: const InputDecoration(
                        labelText: '닉네임',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return '닉네임을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24.0),
                  ],

                  // Action Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isLoginMode ? '로그인' : '가입하기',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16.0),

                  // Mode Toggle
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isLoginMode = !_isLoginMode;
                        _formKey.currentState?.reset();
                      });
                    },
                    child: Text(
                      _isLoginMode ? '계정이 없으신가요? 회원가입' : '이미 계정이 있으신가요? 로그인',
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
