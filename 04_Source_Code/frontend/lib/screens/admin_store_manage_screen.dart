import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../repositories/place_repository.dart';
import '../widgets/common_components.dart';

class AdminStoreManageScreen extends StatefulWidget {
  const AdminStoreManageScreen({super.key});

  @override
  State<AdminStoreManageScreen> createState() => _AdminStoreManageScreenState();
}

class _AdminStoreManageScreenState extends State<AdminStoreManageScreen> {
  final PlaceRepository _placeRepository = PlaceRepository();
  List<Place> _places = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _placeRepository.getPlaces();
      setState(() {
        _places = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '장소 및 사업자 관리 (베타 9개 거점)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlaces,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('오류 발생: $_error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _loadPlaces,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _places.isEmpty
                  ? const EmptyStateWidget(message: '등록된 장소가 없습니다.')
                  : RefreshIndicator(
                      onRefresh: _loadPlaces,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: _places.length,
                        itemBuilder: (context, index) {
                          final place = _places[index];
                          final isAttraction = place.isAttraction ||
                              place.reviewVerificationType == 'ATTRACTION_LOCATION';
                          final tier = place.tier;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12.0),
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            isAttraction
                                                ? Icons.museum_outlined
                                                : Icons.storefront_rounded,
                                            size: 20,
                                            color: isAttraction
                                                ? AppColors.primary
                                                : AppColors.secondary,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              place.name,
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      label: isAttraction ? '관광지 5곳' : '사업장 4곳',
                                      color: isAttraction
                                          ? AppColors.primary
                                          : AppColors.secondary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8.0),
                                Text(
                                  place.address,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10.0),
                                Wrap(
                                  spacing: 6.0,
                                  runSpacing: 6.0,
                                  children: [
                                    StatusBadge.fromStatus(tier),
                                    StatusBadge.fromStatus(place.status),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 4.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(6.0),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: Text(
                                        '인증: ${place.reviewVerificationType}',
                                        style: const TextStyle(
                                          fontSize: 11.0,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12.0),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showMultilingualDialog(place),
                                    icon: const Icon(Icons.g_translate, size: 16.0),
                                    label: const Text(
                                      '4개 언어 데이터 확인',
                                      style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  void _showMultilingualDialog(Place place) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.language, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${place.name} - 4개 언어',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLangSection('🇰🇷 한국어 (KO)', place.name, place.address, place.description),
              const Divider(height: 24),
              _buildLangSection('🇺🇸 English (EN)', place.nameTranslations['en'] ?? place.name, place.address, place.descriptionTranslations['en'] ?? place.description),
              const Divider(height: 24),
              _buildLangSection('🇯🇵 日本語 (JA)', place.nameTranslations['ja'] ?? place.name, place.address, place.descriptionTranslations['ja'] ?? place.description),
              const Divider(height: 24),
              _buildLangSection('🇨🇳 中文 (ZH_Hans)', place.nameTranslations['zh'] ?? place.name, place.address, place.descriptionTranslations['zh'] ?? place.description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildLangSection(String title, String name, String address, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text('• 이름: $name', style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('• 주소: $address', style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text('• 설명: $description', style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary), maxLines: 3, overflow: TextOverflow.ellipsis),
      ],
    );
  }
}
