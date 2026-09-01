import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../services/location_service.dart';

class SuyeongSpatialEditorScreen extends StatefulWidget {
  final List<LatLng> initialPoints;
  final double initialBufferM;
  final Function(List<LatLng> points, double bufferM)? onCandidateSaved;

  const SuyeongSpatialEditorScreen({
    super.key,
    this.initialPoints = const [],
    this.initialBufferM = 75.0,
    this.onCandidateSaved,
  });

  @override
  State<SuyeongSpatialEditorScreen> createState() =>
      _SuyeongSpatialEditorScreenState();
}

class _SuyeongSpatialEditorScreenState
    extends State<SuyeongSpatialEditorScreen> {
  GoogleMapController? _mapController;
  final List<LatLng> _points = [];
  double _bufferWidthM = 75.0;

  Position? _userPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialPoints.isNotEmpty) {
      _points.addAll(widget.initialPoints);
    }
    _bufferWidthM = widget.initialBufferM;
    _fetchUserLocation();
  }

  Future<void> _fetchUserLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final pos = await LocationService().getCurrentLocation();
      if (!pos.isMocked) {
        _userPosition = pos;
      }
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _points.add(position);
    });
  }

  void _undoLastPoint() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.removeLast();
      });
    }
  }

  void _clearAllPoints() {
    if (_points.isNotEmpty) {
      setState(() {
        _points.clear();
      });
    }
  }

  void _recenterToUser() {
    if (_userPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userPosition!.latitude, _userPosition!.longitude),
          16.5,
        ),
      );
    }
  }

  void _confirmCandidate() {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지도 위를 터치하여 최소 1개 이상의 산책로 포인트를 지정하세요.')),
      );
      return;
    }

    // Print PM Review Structured Summary
    final pointsJson = _points
        .map((p) => '{"lat": ${p.latitude}, "lng": ${p.longitude}}')
        .join(',\n    ');

    print('''
==================================================
[NAMPO GOGO PM SPATIAL EDITOR CANDIDATE CONFIRMED]
==================================================
PLACE=Suyeong River Promenade
PLACE_TYPE=LINEAR
GEOMETRY_TYPE=LINE_BUFFER
BUFFER_WIDTH_M=$_bufferWidthM
POINT_COUNT=${_points.length}
POINTS=[
    $pointsJson
]
PM_APPROVED=false (Local QA Candidate Only)
PRODUCTION_DB_CHANGE=NONE
==================================================
''');

    if (widget.onCandidateSaved != null) {
      widget.onCandidateSaved!(_points, _bufferWidthM);
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗺 수영강변 후보 인증구역 확정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('선택된 산책로 포인트: ${_points.length}개'),
            Text('설정된 인증 폭: ${_bufferWidthM.round()}m'),
            const SizedBox(height: 12),
            const Text(
              '이 설정은 로컬 QA 테스트 전용 후보(Candidate)로 적용됩니다.\nProduction DB에는 변경이 반영되지 않으며, PM 정식 승인 후 백엔드 저장이 진행됩니다.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('확인 (편집 종료)'),
          ),
        ],
      ),
    );
  }

  Set<Polygon> _buildCorridorPolygons() {
    final polygons = <Polygon>{};
    if (_points.length < 2) return polygons;

    // Approximate corridor polygon for polyline buffer visualization
    final corridorVertices = <LatLng>[];
    final leftPoints = <LatLng>[];
    final rightPoints = <LatLng>[];

    final bufferLat = _bufferWidthM / 111320.0;

    for (int i = 0; i < _points.length; i++) {
      final curr = _points[i];
      final bufferLng =
          _bufferWidthM / (111320.0 * cos(curr.latitude * pi / 180));

      leftPoints.add(LatLng(curr.latitude + bufferLat, curr.longitude - bufferLng));
      rightPoints.add(LatLng(curr.latitude - bufferLat, curr.longitude + bufferLng));
    }

    corridorVertices.addAll(leftPoints);
    corridorVertices.addAll(rightPoints.reversed);

    polygons.add(
      Polygon(
        polygonId: const PolygonId('corridor_buffer_preview'),
        points: corridorVertices,
        strokeColor: AppColors.primary,
        strokeWidth: 2,
        fillColor: AppColors.primary.withAlpha(45),
      ),
    );

    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    final polylines = <Polyline>{};

    // User location marker
    if (_userPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('editor_user_location'),
          position: LatLng(_userPosition!.latitude, _userPosition!.longitude),
          infoWindow: const InfoWindow(title: '내 위치'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          zIndexInt: 10,
        ),
      );
    }

    // Control point markers
    for (int i = 0; i < _points.length; i++) {
      final pt = _points[i];
      final isFirst = (i == 0);
      final isLast = (i == _points.length - 1);
      final label = isFirst
          ? '시작점 P1'
          : (isLast ? '끝점 P${i + 1}' : '중간점 P${i + 1}');
      final hue = isFirst
          ? BitmapDescriptor.hueGreen
          : (isLast ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange);

      markers.add(
        Marker(
          markerId: MarkerId('control_point_$i'),
          position: pt,
          infoWindow: InfoWindow(title: label),
          icon: BitmapDescriptor.defaultMarkerWithHue(hue),
          zIndexInt: 5,
        ),
      );
    }

    // Connect control points with polyline
    if (_points.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('editor_polyline'),
          points: _points,
          color: AppColors.primary,
          width: 5,
        ),
      );
    }

    final initialCenter = _points.isNotEmpty
        ? _points.first
        : (_userPosition != null
            ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
            : const LatLng(35.1635, 129.1245));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🗺 수영강변 인증 범위 편집기 (QA/PM)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAllPoints,
            tooltip: '전체 초기화',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Full-Screen Interactive GoogleMap
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialCenter,
              zoom: 16.5,
            ),
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
            scrollGesturesEnabled: true,
            zoomGesturesEnabled: true,
            rotateGesturesEnabled: true,
            tiltGesturesEnabled: true,
            myLocationEnabled: _userPosition != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            polylines: polylines,
            polygons: _buildCorridorPolygons(),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
          ),

          // Top Info Status Bar
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: Colors.amber, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '지도를 터치하여 산책로 포인트를 지정하세요.\n포인트: ${_points.length}개 | 인증폭: ${_bufferWidthM.round()}m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 24,
            left: 14,
            right: 14,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Buffer width selector
                    Row(
                      children: [
                        const Text('인증 가능 폭: ',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ...[50.0, 75.0, 100.0, 125.0].map((w) {
                          final isSelected = (_bufferWidthM == w);
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: ChoiceChip(
                              label: Text('${w.round()}m'),
                              selected: isSelected,
                              onSelected: (_) =>
                                  setState(() => _bufferWidthM = w),
                            ),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Action Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _points.isEmpty ? null : _undoLastPoint,
                            icon: const Icon(Icons.undo, size: 16),
                            label: const Text('취소', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _points.isEmpty ? null : _clearAllPoints,
                            icon: const Icon(Icons.delete_outline, size: 16),
                            label: const Text('초기화', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _recenterToUser,
                          icon: const Icon(Icons.my_location),
                          tooltip: '현재 위치로 이동',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Confirm Candidate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _confirmCandidate,
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: const Text('후보 인증구역 확정 (QA/PM)',
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
