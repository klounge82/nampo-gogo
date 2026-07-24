import 'package:flutter/material.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';

class BusinessStoreScreen extends StatefulWidget {
  const BusinessStoreScreen({super.key});

  @override
  State<BusinessStoreScreen> createState() => _BusinessStoreScreenState();
}

class _BusinessStoreScreenState extends State<BusinessStoreScreen> {
  final BusinessService _businessService = BusinessService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _membershipRole = 'OWNER';
  String _operatingStatus = '영업중';
  String? _imageUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _businessService.getManagedStore();
      final store = res['store'] as Map<String, dynamic>;
      final role = res['membership_role'] as String? ?? 'OWNER';

      if (mounted) {
        setState(() {
          _membershipRole = role;
          _nameController.text = store['name'] as String? ?? '';
          _descController.text = store['description'] as String? ?? '';
          _phoneController.text = store['phone_number'] as String? ?? '';
          _addressController.text = store['address'] as String? ?? '';
          _hoursController.text = store['operating_hours'] as String? ?? '';
          _operatingStatus = store['status'] as String? ?? '영업중';
          _imageUrl = store['image_url'] as String?;
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

  Future<void> _saveStoreData() async {
    if (_membershipRole == 'STAFF') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('매장 정보 수정 권한이 없습니다. (OWNER 또는 MANAGER 권한 필요)'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _businessService.updateManagedStore({
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'phone_number': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'operating_hours': _hoursController.text.trim(),
        'status': _operatingStatus,
        if (_imageUrl != null) 'image_url': _imageUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('매장 정보가 정상적으로 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool get _canEdit =>
      _membershipRole == 'OWNER' || _membershipRole == 'MANAGER';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 매장 관리'),
        actions: [
          if (_canEdit && !_isLoading)
            IconButton(
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save),
              onPressed: _isSaving ? null : _saveStoreData,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    Text(_errorMessage!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadStoreData,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Role badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '매장 기본 정보',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: BusinessTheme.darkSlate,
                          ),
                        ),
                        Chip(
                          label: Text(
                            '권한: $_membershipRole',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _canEdit
                              ? BusinessTheme.primaryTeal
                              : Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Store Image Placeholder
                    Container(
                      width: double.infinity,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        image: _imageUrl != null && _imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(_imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: Stack(
                        children: [
                          if (_imageUrl == null || _imageUrl!.isEmpty)
                            const Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.store,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '대표 이미지가 없습니다.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: ElevatedButton.icon(
                              onPressed: _canEdit
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('이미지 업로드 기능 준비 중입니다.'),
                                        ),
                                      );
                                    }
                                  : null,
                              icon: const Icon(Icons.photo_camera, size: 18),
                              label: const Text('이미지 변경'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black87,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Operating Status Dropdown
                    DropdownButtonFormField<String>(
                      value: ['영업중', '곧 마감', '휴무'].contains(_operatingStatus)
                          ? _operatingStatus
                          : '영업중',
                      decoration: const InputDecoration(
                        labelText: '운영 상태',
                        prefixIcon: Icon(Icons.schedule),
                        border: OutlineInputBorder(),
                      ),
                      items: ['영업중', '곧 마감', '휴무']
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: _canEdit
                          ? (val) {
                              if (val != null) {
                                setState(() => _operatingStatus = val);
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Store Name
                    TextFormField(
                      controller: _nameController,
                      enabled: _canEdit,
                      decoration: const InputDecoration(
                        labelText: '매장명',
                        prefixIcon: Icon(Icons.storefront),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return '매장명을 입력해 주세요.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      enabled: _canEdit,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: '전화번호',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Address
                    TextFormField(
                      controller: _addressController,
                      enabled: _canEdit,
                      decoration: const InputDecoration(
                        labelText: '주소',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours
                    TextFormField(
                      controller: _hoursController,
                      enabled: _canEdit,
                      decoration: const InputDecoration(
                        labelText: '영업시간 (예: 09:00 - 22:00)',
                        prefixIcon: Icon(Icons.access_time),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descController,
                      enabled: _canEdit,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: '매장 소개 글',
                        prefixIcon: Icon(Icons.description),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    if (_canEdit)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text(
                            '매장 정보 저장',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BusinessTheme.primaryTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSaving ? null : _saveStoreData,
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
