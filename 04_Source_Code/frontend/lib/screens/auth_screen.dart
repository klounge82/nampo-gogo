import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import 'business_pending_shell.dart';

enum AuthViewMode {
  login,
  signupSelection,
  customerSignup,
  businessSignup,
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Account controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nicknameController = TextEditingController();

  // Business controllers
  final _businessNameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _repNameController = TextEditingController();
  final _phoneController = TextEditingController();

  AuthViewMode _viewMode = AuthViewMode.login;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _nicknameController.dispose();
    _businessNameController.dispose();
    _regNumController.dispose();
    _repNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await authProvider.login(
      email: email,
      password: password,
    );
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인 성공! 계정이 연결되었습니다.'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.of(context).pop();
      } else {
        _showErrorDialog('로그인 실패', '이메일 또는 비밀번호가 올바르지 않습니다.');
      }
    }
  }

  Future<void> _submitCustomerSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    try {
      final user = await authProvider.signUp(
        email: email,
        password: password,
        nickname: nickname,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일반회원 가입이 완료되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        // Switch to login
        setState(() {
          _viewMode = AuthViewMode.login;
        });
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showErrorDialog('회원가입 실패', msg.isNotEmpty ? msg : '이미 가입된 이메일이거나 입력 정보에 오류가 있습니다.');
    }
  }

  Future<void> _submitBusinessSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final nickname = _nicknameController.text.trim();

    try {
      final user = await authProvider.signUpBusiness(
        email: email,
        password: password,
        nickname: nickname,
        businessName: _businessNameController.text.trim(),
        businessRegistrationNumber: _regNumController.text.trim(),
        representativeName: _repNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('사업자 신청 접수 완료', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              '사업자회원 가입과 승인 신청이 정상적으로 접수되었습니다.\n관리자가 제출 내용을 검토한 후 승인 여부를 알려드리겠습니다.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _viewMode = AuthViewMode.login;
                  });
                },
                child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      _showErrorDialog(
        '사업자 가입 실패',
        msg.contains('이미 가입')
            ? '이미 가입된 계정입니다.\n로그인 후 사업자회원 신청을 진행해 주세요.'
            : msg,
      );
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
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: _viewMode != AuthViewMode.login
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    if (_viewMode == AuthViewMode.customerSignup ||
                        _viewMode == AuthViewMode.businessSignup) {
                      _viewMode = AuthViewMode.signupSelection;
                    } else {
                      _viewMode = AuthViewMode.login;
                    }
                  });
                },
              )
            : null,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _buildBodyContent(isLoading),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_viewMode) {
      case AuthViewMode.login:
        return '남포 GoGo 로그인';
      case AuthViewMode.signupSelection:
        return '회원가입 유형 선택';
      case AuthViewMode.customerSignup:
        return '일반회원 가입';
      case AuthViewMode.businessSignup:
        return '사업자회원 가입';
    }
  }

  Widget _buildBodyContent(bool isLoading) {
    if (_viewMode == AuthViewMode.signupSelection) {
      return _buildSignupSelectionCards();
    }

    return Container(
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
            Icon(
              _viewMode == AuthViewMode.businessSignup
                  ? Icons.storefront
                  : Icons.directions_run,
              size: 56.0,
              color: _viewMode == AuthViewMode.businessSignup
                  ? const Color(0xFF00897B)
                  : AppColors.primary,
            ),
            const SizedBox(height: 16.0),
            Text(
              _getHeaderSubtitle(),
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),

            // Fields
            ..._buildFormFields(),

            const SizedBox(height: 24.0),

            // Submit Button
            ElevatedButton(
              onPressed: isLoading ? null : _handleFormSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _viewMode == AuthViewMode.businessSignup
                    ? const Color(0xFF00897B)
                    : AppColors.primary,
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
                      _getSubmitButtonText(),
                      style: const TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16.0),

            // Bottom Mode Toggle
            TextButton(
              onPressed: () {
                setState(() {
                  if (_viewMode == AuthViewMode.login) {
                    _viewMode = AuthViewMode.signupSelection;
                  } else {
                    _viewMode = AuthViewMode.login;
                  }
                  _formKey.currentState?.reset();
                });
              },
              child: Text(
                _viewMode == AuthViewMode.login
                    ? '계정이 없으신가요? 회원가입'
                    : '이미 계정이 있으신가요? 로그인',
                style: TextStyle(
                  color: _viewMode == AuthViewMode.businessSignup
                      ? const Color(0xFF00897B)
                      : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getHeaderSubtitle() {
    switch (_viewMode) {
      case AuthViewMode.login:
        return '로그인하여 남포동 여행과 매장 서비스를 이용하세요!';
      case AuthViewMode.customerSignup:
        return '일반회원 계정을 생성합니다.';
      case AuthViewMode.businessSignup:
        return '사업자 계정과 승인 신청서를 작성합니다.';
      default:
        return '';
    }
  }

  String _getSubmitButtonText() {
    switch (_viewMode) {
      case AuthViewMode.login:
        return '로그인';
      case AuthViewMode.customerSignup:
        return '일반회원 가입하기';
      case AuthViewMode.businessSignup:
        return '사업자 회원가입 및 승인 신청';
      default:
        return '확인';
    }
  }

  void _handleFormSubmit() {
    switch (_viewMode) {
      case AuthViewMode.login:
        _submitLogin();
        break;
      case AuthViewMode.customerSignup:
        _submitCustomerSignup();
        break;
      case AuthViewMode.businessSignup:
        _submitBusinessSignup();
        break;
      default:
        break;
    }
  }

  Widget _buildSignupSelectionCards() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '남포 GoGo 회원가입',
          style: TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8.0),
        const Text(
          '가입하려는 회원 유형을 선택해 주세요.',
          style: TextStyle(fontSize: 14.0, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24.0),

        // Card A: Customer
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: () {
              setState(() {
                _viewMode = AuthViewMode.customerSignup;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 32.0,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '일반회원으로 가입',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '여행지, 맛집, 코스, 즐겨찾기와 리뷰를 이용합니다.',
                          style: TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16.0),

        // Card B: Business
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16.0),
            onTap: () {
              setState(() {
                _viewMode = AuthViewMode.businessSignup;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE0F2F1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.storefront_outlined,
                      size: 32.0,
                      color: Color(0xFF00897B),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          '사업자회원으로 가입',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          '매장, 상품, 예약과 리뷰를 관리하기 위한 사업자 계정을 신청합니다.',
                          style: TextStyle(
                            fontSize: 13.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 24.0),

        TextButton(
          onPressed: () {
            setState(() {
              _viewMode = AuthViewMode.login;
            });
          },
          child: const Text('이미 계정이 있으신가요? 로그인'),
        ),
      ],
    );
  }

  List<Widget> _buildFormFields() {
    final isSignup = _viewMode != AuthViewMode.login;
    final isBusiness = _viewMode == AuthViewMode.businessSignup;

    return [
      // Section Header for Business Account
      if (isBusiness) ...[
        const Text(
          '[계정 정보]',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
        ),
        const SizedBox(height: 12.0),
      ],

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
          if (value == null || value.trim().isEmpty || !value.contains('@')) {
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
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
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

      if (isSignup) ...[
        // Password Confirmation
        TextFormField(
          controller: _passwordConfirmController,
          obscureText: !_isConfirmPasswordVisible,
          decoration: InputDecoration(
            labelText: '비밀번호 확인',
            prefixIcon: const Icon(Icons.lock_reset_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
        const SizedBox(height: 16.0),
      ],

      // Additional Business Info
      if (isBusiness) ...[
        const Divider(height: 32.0),
        const Text(
          '[사업자 정보]',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B)),
        ),
        const SizedBox(height: 12.0),

        TextFormField(
          controller: _businessNameController,
          decoration: const InputDecoration(
            labelText: '상호명 (매장명)',
            prefixIcon: Icon(Icons.store),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '상호명을 입력해 주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: _regNumController,
          decoration: const InputDecoration(
            labelText: '사업자등록번호 (예: 123-45-67890)',
            prefixIcon: Icon(Icons.assignment_ind_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '사업자등록번호를 입력해 주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: _repNameController,
          decoration: const InputDecoration(
            labelText: '대표자명',
            prefixIcon: Icon(Icons.badge_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '대표자명을 입력해 주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),

        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: '연락처 (전화번호)',
            prefixIcon: Icon(Icons.phone_outlined),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '연락처를 입력해 주세요.';
            }
            return null;
          },
        ),
        const SizedBox(height: 16.0),
      ],
    ];
  }
}
