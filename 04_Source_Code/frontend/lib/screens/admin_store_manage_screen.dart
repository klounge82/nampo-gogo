import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/colors.dart';
import '../models/place.dart';
import '../repositories/place_repository.dart';
import '../repositories/spatial_candidate_store.dart';
import '../widgets/mission_eligible_area_map.dart';
import 'spatial_geometry_editor_screen.dart';

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
  String _selectedFilter = 'ALL'; // ALL, ATTRACTION, STORE, PENDING

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

  List<Place> get _filteredPlaces {
    if (_selectedFilter == 'ATTRACTION') {
      return _places.where((p) {
        final n = p.name.toLowerCase();
        return n.contains('광복') ||
            n.contains('자갈치') ||
            n.contains('국제시장') ||
            n.contains('수영강') ||
            n.contains('광안리') ||
            n.contains('보수동') ||
            n.contains('타워');
      }).toList();
    } else if (_selectedFilter == 'STORE') {
      return _places.where((p) => p.category.isNotEmpty).toList();
    } else if (_selectedFilter == 'PENDING') {
      return _places.where((p) => p.name.contains('수영강') || p.reviewLocationRadiusM == 0).toList();
    }
    return _places;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '장소·사업자 관리 (ADMIN)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('데이터를 불러오지 못했습니다: $_error'),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _loadPlaces,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Filter Chips Bar
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          _buildFilterChip('ALL', '전체 (${_places.length})'),
                          const SizedBox(width: 6),
                          _buildFilterChip('ATTRACTION', '관광지'),
                          const SizedBox(width: 6),
                          _buildFilterChip('STORE', '사업장'),
                          const SizedBox(width: 6),
                          _buildFilterChip('PENDING', '후보/대기'),
                        ],
                      ),
                    ),
                    const Divider(height: 1),

                    // Place Cards List
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadPlaces,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredPlaces.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12.0),
                          itemBuilder: (context, index) {
                            final place = _filteredPlaces[index];
                            final hasRefPos = (place.latitude != null && place.longitude != null);

                            return Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(color: AppColors.border),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              place.name,
                                              style: const TextStyle(
                                                fontSize: 16.0,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4.0),
                                            Text(
                                              place.address,
                                              style: const TextStyle(
                                                fontSize: 12.0,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                          vertical: 4.0,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withAlpha(20),
                                          borderRadius: BorderRadius.circular(6.0),
                                        ),
                                        child: Text(
                                          place.category.isNotEmpty
                                              ? place.category
                                              : '관광지',
                                          style: const TextStyle(
                                            fontSize: 11.0,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),

                                  // Status Badges Row
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      _buildBadge('ID: ${place.id}', Colors.grey),
                                      _buildBadge('인증: ${place.reviewVerificationType}', Colors.blue),
                                      _buildBadge(
                                        hasRefPos ? '위치 설정됨' : '대표 위치 미설정',
                                        hasRefPos ? Colors.green : Colors.orange,
                                      ),
                                      _buildBadge(
                                        place.name.contains('수영강')
                                            ? '후보 (CANDIDATE)'
                                            : '승인 (APPROVED)',
                                        place.name.contains('수영강') ? Colors.amber[800]! : Colors.green[800]!,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12.0),

                                  // Actions Row
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        // QR management button shown ONLY for stores with QR/QR_GPS auth types
                                        if (place.reviewVerificationType.toUpperCase().contains('QR'))
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: OutlinedButton.icon(
                                              onPressed: () => _showQrManagementDialog(place),
                                              icon: const Icon(Icons.qr_code, size: 16.0),
                                              label: const Text(
                                                'QR 관리',
                                                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.purple,
                                                side: const BorderSide(color: Colors.purple),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              ),
                                            ),
                                          ),
                                        OutlinedButton.icon(
                                          onPressed: () => _openSpatialEditor(place),
                                          icon: const Icon(Icons.map, size: 16.0),
                                          label: const Text(
                                            '위치·인증범위 관리',
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.secondary,
                                            side: const BorderSide(color: AppColors.secondary),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        OutlinedButton.icon(
                                          onPressed: () => _showMultilingualDialog(place),
                                          icon: const Icon(Icons.g_translate, size: 16.0),
                                          label: const Text(
                                            '4개 언어',
                                            style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold),
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.primary,
                                            side: const BorderSide(color: AppColors.primary),
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                    ),
                  ],
                ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = (_selectedFilter == key);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedFilter = key),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _openSpatialEditor(Place place) {
    final name = place.name.toLowerCase();
    final id = place.id.toLowerCase();

    PlaceType pType = PlaceType.point;
    GeometryType gType = GeometryType.pointRadius;
    List<LatLng> initialPts = [];

    // Place classification & geometry mapping (No hardcoded fallback coordinates!)
    if (name.contains('수영강') || id.contains('suyeong')) {
      pType = PlaceType.linear;
      gType = GeometryType.lineBuffer;
      initialPts = const [
        LatLng(35.1665, 129.1215),
        LatLng(35.1650, 129.1230),
        LatLng(35.1635, 129.1245),
        LatLng(35.1620, 129.1258),
        LatLng(35.1600, 129.1270),
      ];
    } else if (name.contains('자갈치') || id.contains('jagalchi') || name.contains('국제시장')) {
      pType = PlaceType.district;
      gType = GeometryType.polygonArea;
    } else if (name.contains('광복')) {
      pType = PlaceType.linear;
      gType = GeometryType.lineBuffer;
    } else if (name.contains('광안리') || id.contains('gwangalli')) {
      pType = PlaceType.largeArea;
      gType = GeometryType.multiArea;
    }

    // Check if SpatialCandidateStore has a saved candidate for this placeId
    final saved = SpatialCandidateStore().getCandidate(place.id);

    // STRICT PER-PLACE ISOLATION: Do NOT fallback to static Suyeong 35.1635, 129.1245!
    final LatLng? refPos = saved?.referencePosition ??
        ((place.latitude != null && place.longitude != null)
            ? LatLng(place.latitude!, place.longitude!)
            : null);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SpatialGeometryEditorScreen(
          placeId: place.id,
          placeName: place.name,
          placeType: saved?.placeType ?? pType,
          geometryType: saved?.geometryType ?? gType,
          referencePosition: refPos,
          initialPoints: saved?.points ?? initialPts,
          initialBufferM: saved?.bufferWidthM ?? 75.0,
          initialRadiusM: saved?.radiusM ??
              (place.reviewLocationRadiusM > 0
                  ? place.reviewLocationRadiusM.toDouble()
                  : 100.0),
          initialApprovalStatus: saved?.approvalStatus ?? SpatialApprovalStatus.candidate,
          onCandidateSaved: (points, bufferM, radiusM, status, pTypeRes, gTypeRes, refPosRes) {
            SpatialCandidateStore().saveCandidate(
              placeId: place.id,
              placeType: pTypeRes,
              geometryType: gTypeRes,
              referencePosition: refPosRes,
              points: points,
              bufferWidthM: bufferM,
              radiusM: radiusM,
              approvalStatus: status,
            );
            setState(() {});
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

  void _showQrManagementDialog(Place place) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.qr_code, color: Colors.purple),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${place.name} - QR 코드 관리',
                style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('인증 방식: ${place.reviewVerificationType}'),
            const SizedBox(height: 8),
            const Text(
              'QR 상태: ACTIVE (정상 발급됨)',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('매장 ID: ${place.id}', style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                  const SizedBox(height: 4),
                  Text('QR Payload: np_qr_verif_${place.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '※ 안전 안내: 기존 운영 중인 Production QR 코드는 자동 변경/재발급되지 않습니다.\n사업자 인쇄용 QR 다운로드 및 발급 관리는 ADMIN 전용 메뉴에서 안전하게 수행됩니다.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }
}
