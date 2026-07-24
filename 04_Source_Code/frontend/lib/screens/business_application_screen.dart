import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/business_service.dart';

class BusinessApplicationScreen extends StatefulWidget {
  const BusinessApplicationScreen({super.key});

  @override
  State<BusinessApplicationScreen> createState() =>
      _BusinessApplicationScreenState();
}

class _BusinessApplicationScreenState extends State<BusinessApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _regNumController = TextEditingController();
  final _repNameController = TextEditingController();
  final _phoneController = TextEditingController();

  final BusinessService _businessService = BusinessService();
  bool _isLoading = false;
  Map<String, dynamic>? _myApplication;

  @override
  void initState() {
    super.initState();
    _fetchApplicationStatus();
  }

  Future<void> _fetchApplicationStatus() async {
    setState(() => _isLoading = true);
    try {
      final appData = await _businessService.getMyApplication();
      if (mounted) {
        setState(() {
          _myApplication = appData;
        });
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitApplication() async {
    if (_isLoading) return;
    final currentStatus = _myApplication?['status'];
    if (currentStatus == 'PENDING') {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('이미 검토 중인 사업자 신청이 있습니다.')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final res = await _businessService.applyBusinessAccount(
        businessName: _businessNameController.text.trim(),
        businessRegistrationNumber: _regNumController.text.trim(),
        representativeName: _repNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _myApplication = res;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '사업자 회원 신청이 정상적으로 접수되었습니다.\n\n관리자가 제출 내용을 검토한 후 승인 여부를 알려드리겠습니다.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Refresh Auth User -> Triggers BusinessPendingShell in RootNavigationSelector
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.autoLogin();

        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        var errText = e.toString().replaceAll('Exception: ', '').trim();
        if (errText.toLowerCase().contains('not found') ||
            errText.contains('404')) {
          errText = '신청 경로를 확인하지 못했습니다. 앱을 최신 버전으로 업데이트한 후 다시 시도해 주세요.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errText), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _myApplication?['status'] ?? 'NONE';

    return Scaffold(
      appBar: AppBar(title: const Text('사업자 회원 신청')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (status == 'PENDING') ...[
                    Card(
                      color: Colors.amber.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.amber.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.hourglass_top, color: Colors.amber),
                                SizedBox(width: 8),
                                Text(
                                  '사업자 승인 대기 중입니다.',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              '제출하신 사업자 정보는 총관리자가 검토 중입니다. 승인이 완료되면 사업자 전용 관리가 활성화됩니다.',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (status == 'APPROVED') ...[
                    Card(
                      color: Colors.green.shade50,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: Colors.green.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '사업자 승인이 완료되었습니다!\n상단 모드 전환 버튼으로 사업자 모드를 이용할 수 있습니다.',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (status == 'NONE' || status == 'REJECTED') ...[
                    const Text(
                      '남포동 파트너 매장 등록',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '사업자 정보를 입력해 주시면 확인 후 24시간 이내 승인 처리해 드립니다.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              labelText: '사업자상호 (매장명)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.store),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '상호를 입력해 주세요.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _regNumController,
                            decoration: const InputDecoration(
                              labelText: '사업자등록번호 (10자리)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.badge),
                            ),
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '사업자등록번호를 입력해 주세요.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _repNameController,
                            decoration: const InputDecoration(
                              labelText: '대표자 성명',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '대표자 성명을 입력해 주세요.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: '대표 연락처 (휴대전화)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '연락처를 입력해 주세요.'
                                : null,
                          ),
                          const SizedBox(height: 28),

                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: status == 'PENDING' || _isLoading
                                  ? null
                                  : _submitApplication,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                              child: Text(
                                status == 'PENDING'
                                    ? '승인 검토 진행 중'
                                    : '사업자 신청서 제출',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
