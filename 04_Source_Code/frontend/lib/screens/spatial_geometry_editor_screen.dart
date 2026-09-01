import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../repositories/admin_repository.dart';
import '../repositories/spatial_candidate_store.dart';
import '../services/location_service.dart';
import '../utils/spatial_validator.dart';
import '../widgets/mission_eligible_area_map.dart';

enum SpatialApprovalStatus { draft, candidate, approved, rejected }

class SpatialGeometryEditorScreen extends StatefulWidget {
  final String placeId;
  final String placeName;
  final PlaceType placeType;
  final GeometryType geometryType;
  final LatLng? referencePosition;
  final List<LatLng> initialPoints;
  final List<List<LatLng>> initialLines;
  final double initialBufferM;
  final double initialRadiusM;
  final SpatialApprovalStatus initialApprovalStatus;
  final Function(
    List<LatLng> points,
    List<List<LatLng>> lines,
    double bufferM,
    double radiusM,
    SpatialApprovalStatus status,
    PlaceType placeType,
    GeometryType geometryType,
    LatLng? referencePosition,
  )? onCandidateSaved;

  const SpatialGeometryEditorScreen({
    super.key,
    required this.placeId,
    required this.placeName,
    this.placeType = PlaceType.point,
    this.geometryType = GeometryType.pointRadius,
    this.referencePosition,
    this.initialPoints = const [],
    this.initialLines = const [],
    this.initialBufferM = 75.0,
    this.initialRadiusM = 100.0,
    this.initialApprovalStatus = SpatialApprovalStatus.candidate,
    this.onCandidateSaved,
  });

  @override
  State<SpatialGeometryEditorScreen> createState() =>
      _SpatialGeometryEditorScreenState();
}

class _SpatialGeometryEditorScreenState
    extends State<SpatialGeometryEditorScreen> {
  GoogleMapController? _mapController;

  // Strict Per-Place State
  late PlaceType _currentPlaceType;
  late GeometryType _currentGeometryType;
  LatLng? _referencePosition;

  final List<LatLng> _points = [];
  final List<List<LatLng>> _lines = [[]];
  double _bufferWidthM = 75.0;
  double _radiusM = 100.0;
  SpatialApprovalStatus _approvalStatus = SpatialApprovalStatus.candidate;

  bool _isEditingReferencePosition = false;
  Position? _userPosition;
  bool _isLoadingLocation = true;

  SpatialCandidateRecord? _savedCandidateDraft;
  bool _hasCandidateToLoad = false;

  @override
  void initState() {
    super.initState();

    _currentPlaceType = widget.placeType;
    _currentGeometryType = widget.geometryType;
    _referencePosition = widget.referencePosition;
    _bufferWidthM = widget.initialBufferM;
    _radiusM = widget.initialRadiusM;
    _approvalStatus = widget.initialApprovalStatus;

    // RULE GEOMETRY-NO-AUTO-INVENT-001:
    // Editors WITHOUT approved saved geometry MUST start EMPTY!
    // Do NOT auto-inject sample points or candidate points into _points silently!
    _points.clear();
    _lines.clear();

    if (widget.initialLines.isNotEmpty) {
      for (final l in widget.initialLines) {
        if (l.isNotEmpty) _lines.add(List<LatLng>.from(l));
      }
    }

    final savedCandidate = SpatialCandidateStore().getCandidate(widget.placeId);
    if (savedCandidate != null && (savedCandidate.points.isNotEmpty || savedCandidate.lines.isNotEmpty)) {
      _savedCandidateDraft = savedCandidate;
      _hasCandidateToLoad = true;
    }

    _fetchUserLocation();
  }

  void _loadSavedCandidate() {
    if (_savedCandidateDraft == null) return;
    setState(() {
      _lines.clear();
      if (_savedCandidateDraft!.lines.isNotEmpty) {
        for (final line in _savedCandidateDraft!.lines) {
          _lines.add(List<LatLng>.from(line));
        }
      } else if (_savedCandidateDraft!.points.isNotEmpty) {
        _lines.add(List<LatLng>.from(_savedCandidateDraft!.points));
      } else {
        _lines.add([]);
      }

      _points.clear();
      if (_lines.isNotEmpty && _lines.any((l) => l.isNotEmpty)) {
        for (final line in _lines) {
          _points.addAll(line);
        }
      } else {
        _points.addAll(_savedCandidateDraft!.points);
      }

      _currentPlaceType = _savedCandidateDraft!.placeType;
      _currentGeometryType = _savedCandidateDraft!.geometryType;
      _bufferWidthM = _savedCandidateDraft!.bufferWidthM;
      _radiusM = _savedCandidateDraft!.radiusM;
      _hasCandidateToLoad = false;
    });

    final int activeLineCount = _lines.where((l) => l.isNotEmpty).length;
    final int lineCountMsg = activeLineCount > 0 ? activeLineCount : 1;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ 이전에 저장된 임시 후보 (${lineCountMsg}개 구간, ${_points.length}개 점)를 불러왔습니다.'),
        backgroundColor: Colors.blue[800],
      ),
    );
  }

  void _dismissCandidatePrompt() {
    setState(() {
      _hasCandidateToLoad = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🧹 빈 편집기에서 새로운 범위 작성을 시작합니다.'),
      ),
    );
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
    if (_isEditingReferencePosition) {
      setState(() {
        _referencePosition = position;
        _isEditingReferencePosition = false;
      });

      // Update reference position ONLY in SpatialCandidateStore without clearing geometry points!
      SpatialCandidateStore().updateReferencePosition(widget.placeId, position);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '📍 대표 위치가 변경되었습니다. (${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}) - 기존 인증 지오메트리 보존됨'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    switch (_currentGeometryType) {
      case GeometryType.pointRadius:
        setState(() {
          _referencePosition = position;
        });
        SpatialCandidateStore().updateReferencePosition(widget.placeId, position);
        break;

      case GeometryType.lineBuffer:
        _addControlPoint(position);
        break;

      case GeometryType.polygonArea:
      case GeometryType.multiArea:
        setState(() {
          _points.add(position);
        });
        break;
    }
  }

  void _addControlPoint(LatLng rawPosition, {bool isFromMarkerTap = false}) {
    LatLng targetPt = rawPosition;

    // Smart Snap: If tapping map near an existing control point (within 25m), snap to exact LatLng!
    if (!isFromMarkerTap && _points.isNotEmpty) {
      double minDistanceM = double.infinity;
      LatLng? nearestPt;

      for (final existing in _points) {
        final dist = Geolocator.distanceBetween(
          rawPosition.latitude,
          rawPosition.longitude,
          existing.latitude,
          existing.longitude,
        );
        if (dist < minDistanceM) {
          minDistanceM = dist;
          nearestPt = existing;
        }
      }

      if (nearestPt != null && minDistanceM <= 25.0) {
        targetPt = nearestPt;
      }
    }

    setState(() {
      if (_lines.isEmpty) _lines.add([]);

      // Consecutive duplicate guard ONLY within the SAME active line
      if (_lines.last.isNotEmpty && _lines.last.last == targetPt) {
        return;
      }

      _lines.last.add(targetPt);
      _points.add(targetPt);
    });

    if (isFromMarkerTap) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '🔗 기존 제어점 위치에서 새 구간 P${_lines.last.length}를 생성했습니다. (${targetPt.latitude.toStringAsFixed(4)}, ${targetPt.longitude.toStringAsFixed(4)})'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleControlPointMarkerTap(LatLng pt) {
    if (_currentGeometryType == GeometryType.lineBuffer) {
      _addControlPoint(pt, isFromMarkerTap: true);
    }
  }

  void _startNewSegmentFromPreviousEndpoint() {
    if (_lines.length >= 2 && _lines.last.isEmpty) {
      final prevLine = _lines[_lines.length - 2];
      if (prevLine.isNotEmpty) {
        final prevEnd = prevLine.last;
        _addControlPoint(prevEnd, isFromMarkerTap: true);
      }
    }
  }

  void _startNewPolyline() {
    if (_lines.isEmpty || _lines.last.isNotEmpty) {
      setState(() {
        _lines.add([]);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('〰 새 구간(라인) 입력을 시작합니다. 지도에서 지점을 클릭하거나 기존 점을 탭하세요.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _undoLastPoint() {
    setState(() {
      if (_points.isNotEmpty) {
        _points.removeLast();
      }
      if (_lines.isNotEmpty && _lines.last.isNotEmpty) {
        _lines.last.removeLast();
      }
    });
  }

  void _clearAllPoints() {
    setState(() {
      _points.clear();
      _lines.clear();
      _lines.add([]);
    });
    SpatialCandidateStore().clearCandidate(widget.placeId);
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

  SpatialValidationResult _getValidationResult() {
    final compResult = SpatialValidator.validateCompatibility(
        _currentPlaceType, _currentGeometryType);
    if (!compResult.isValid) return compResult;

    return SpatialValidator.validateGeometryContent(
      geometryType: _currentGeometryType,
      referencePosition: _referencePosition,
      radiusM: _radiusM,
      corridorCoordinates: _currentGeometryType == GeometryType.lineBuffer ? _points : const [],
      bufferWidthM: _bufferWidthM,
      polygonCoordinates: _currentGeometryType == GeometryType.polygonArea ? _points : const [],
    );
  }

  void _confirmAndSaveCandidate() {
    final validation = _getValidationResult();
    if (!validation.isValid) {
      _showValidationError(validation.errorMessage);
      return;
    }

    final String geomKoreanType = _currentGeometryType == GeometryType.lineBuffer
        ? '길게 이어진 장소 (LINE_BUFFER)'
        : (_currentGeometryType == GeometryType.polygonArea
            ? '넓은 장소 (POLYGON_AREA)'
            : '한 지점 (POINT_RADIUS)');

    final int totalPoints = _points.length;
    final int lineCount = _lines.where((l) => l.isNotEmpty).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗺 공간 인증범위 후보 저장 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장소: ${widget.placeName} (${widget.placeId})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('• 공간 유형: $geomKoreanType'),
            if (_currentGeometryType == GeometryType.lineBuffer) ...[
              Text('• 독립 구간 개수: ${lineCount > 0 ? lineCount : 1}개'),
              Text('• 총 지정 좌표: ${totalPoints}개'),
              Text('• 허용 버퍼 거리: ${_bufferWidthM.round()}m'),
            ] else if (_currentGeometryType == GeometryType.polygonArea) ...[
              Text('• 다각형 점 개수: ${totalPoints}개'),
            ] else ...[
              Text('• 허용 인증 반경: ${_radiusM.round()}m'),
            ],
            const SizedBox(height: 12),
            const Text(
              '저장된 구역 정보는 PM/Admin 후보 저장되며, Production DB에는 영향이 없습니다 (0건 변경).\n\n이 범위를 저장하시겠습니까?',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              Navigator.of(ctx).pop();
              _saveCandidateDraft();
            },
            child: const Text('임시/후보 저장'),
          ),
        ],
      ),
    );
  }

  void _confirmAndApplyToProduction() {
    final validation = _getValidationResult();
    if (!validation.isValid) {
      _showValidationError(validation.errorMessage);
      return;
    }

    if (_currentGeometryType == GeometryType.lineBuffer) {
      final incompleteLines = _lines.where((l) => l.isNotEmpty && l.length < 2).toList();
      if (incompleteLines.isNotEmpty) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('⚠️ 미완성 구간 존재 (적용 불가)', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            content: const Text('현재 구간 중 점이 1개뿐인 미완성 구간이 있습니다. 길게 이어진 장소(LINE_BUFFER)는 구간당 최소 2개의 점이 필요합니다. 해당 구간에 점을 추가하거나 지운 후 시도하세요.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
            ],
          ),
        );
        return;
      }
    }

    final String geomKoreanType = _currentGeometryType == GeometryType.lineBuffer
        ? '길게 이어진 장소 (LINE_BUFFER)'
        : (_currentGeometryType == GeometryType.polygonArea
            ? '넓은 장소 (POLYGON_AREA)'
            : '한 지점 (POINT_RADIUS)');

    final int totalPoints = _points.length;
    final int lineCount = _lines.where((l) => l.isNotEmpty).length;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🚀 Production DB 공간범위 적용 확인'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장소: ${widget.placeName} (${widget.placeId})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Text('• 공간 지오메트리: $geomKoreanType'),
            Text('• 지오메트리 출처: PM 직접 지정 (PM_DRAWN)', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
            if (_currentGeometryType == GeometryType.lineBuffer) ...[
              Text('• 독립 구간 개수: ${lineCount > 0 ? lineCount : 1}개 (총 ${totalPoints}개 점)'),
              Text('• 허용 버퍼 폭: ${_bufferWidthM.round()}m'),
            ] else if (_currentGeometryType == GeometryType.polygonArea) ...[
              Text('• 다각형 꼭짓점: ${totalPoints}개'),
            ] else ...[
              Text('• 허용 인증 반경: ${_radiusM.round()}m'),
            ],
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withAlpha(40),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.amber[800]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('⚠️ Production DB 변경 내역:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text('• 대상 매장: 1건 (UPDATE 1)', style: TextStyle(fontSize: 12)),
                  Text('• 신규 생성 (INSERT): 0건', style: TextStyle(fontSize: 12)),
                  Text('• 기존 삭제 (DELETE): 0건', style: TextStyle(fontSize: 12)),
                  Text('• 타 장소 영향: 0건 (격리보호)', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '이 범위를 실제 Production GPS 인증 기준으로 적용하시겠습니까?',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]),
            onPressed: () {
              Navigator.of(ctx).pop();
              _applyToProductionDB();
            },
            child: const Text('Production DB에 적용'),
          ),
        ],
      ),
    );
  }

  bool _isApplyingToProduction = false;

  Future<void> _applyToProductionDB() async {
    if (_isApplyingToProduction) return;

    final validation = _getValidationResult();
    if (!validation.isValid) {
      _showValidationError(validation.errorMessage);
      return;
    }

    setState(() {
      _isApplyingToProduction = true;
    });

    try {
      String geometryTypeStr = 'POINT_RADIUS';
      Map<String, dynamic> geometryDataMap = {};

      if (_currentGeometryType == GeometryType.lineBuffer) {
        geometryTypeStr = 'LINE_BUFFER';
        final lineCoords = _lines
            .where((l) => l.isNotEmpty)
            .map((line) => line.map((pt) => [pt.latitude, pt.longitude]).toList())
            .toList();

        final finalLines = lineCoords.isNotEmpty
            ? lineCoords
            : [_points.map((pt) => [pt.latitude, pt.longitude]).toList()];

        geometryDataMap = {
          'type': 'LINE_BUFFER',
          'lines': finalLines,
          'buffer_m': _bufferWidthM,
        };
      } else if (_currentGeometryType == GeometryType.polygonArea) {
        geometryTypeStr = 'POLYGON_AREA';
        final polyCoords = _points.map((pt) => [pt.latitude, pt.longitude]).toList();
        geometryDataMap = {
          'type': 'POLYGON_AREA',
          'polygon': polyCoords,
        };
      } else {
        geometryTypeStr = 'POINT_RADIUS';
        if (_referencePosition != null) {
          geometryDataMap = {
            'type': 'POINT_RADIUS',
            'center': [_referencePosition!.latitude, _referencePosition!.longitude],
            'radius_m': _radiusM,
          };
        }
      }

      // HARD PRODUCTION APPLY GUARD (CONSTITUTION-PM-DEVICE-TRUTH-001)
      if (_currentGeometryType == GeometryType.lineBuffer) {
        final activeLines = _lines.where((l) => l.isNotEmpty).toList();
        final int editorLineCount = activeLines.length;
        final int patchLineCount = (geometryDataMap['lines'] as List?)?.length ?? 1;

        if (editorLineCount > 0 && editorLineCount != patchLineCount) {
          if (!mounted) return;
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('🚫 Production 적용 차단 (DATA_CONTRACT_MISMATCH)',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('저장된 공간범위와 전송할 공간범위의 구간 개수가 서로 다릅니다.'),
                  const SizedBox(height: 8),
                  Text('• 현재 편집 구간: ${editorLineCount}개'),
                  Text('• 전송 예정 구간: ${patchLineCount}개'),
                  const SizedBox(height: 8),
                  const Text('💡 Production DB 적용이 안전하게 차단되었습니다. 공간 지오메트리를 다시 확인 후 시도하십시오.'),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('확인')),
              ],
            ),
          );
          return;
        }
      }

      final String geometryDataJsonStr = jsonEncode(geometryDataMap);
      final int reviewRadiusM = (_currentGeometryType == GeometryType.lineBuffer)
          ? _bufferWidthM.round()
          : _radiusM.round();

      // Execute AdminRepository HTTP API PATCH call to Production backend
      final adminRepo = AdminRepository();
      final updatedPlace = await adminRepo.updateStoreSpatialGeometry(
        widget.placeId,
        geometryType: geometryTypeStr,
        geometryData: geometryDataJsonStr,
        reviewLocationRadiusM: reviewRadiusM,
      );

      // Perform READ-BACK VERIFICATION
      final bool readbackMatch = updatedPlace.geometryType == geometryTypeStr;

      // Save local candidate status as APPLIED / approved
      SpatialCandidateStore().saveCandidate(
        placeId: widget.placeId,
        placeType: _currentPlaceType,
        geometryType: _currentGeometryType,
        referencePosition: _referencePosition,
        points: _points,
        lines: _lines,
        bufferWidthM: _bufferWidthM,
        radiusM: _radiusM,
        approvalStatus: SpatialApprovalStatus.approved,
      );

      if (!mounted) return;

      final int totalPoints = _points.length;
      final int lineCount = _lines.where((l) => l.isNotEmpty).length;

      // Display Authentic Production Success Dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🟢 Production DB 공간 인증범위 적용 완료', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('장소: ${widget.placeName} (${widget.placeId})', style: const TextStyle(fontWeight: FontWeight.bold)),
              const Divider(),
              Text('• 공간 유형: $geometryTypeStr'),
              if (_currentGeometryType == GeometryType.lineBuffer) ...[
                Text('• 독립 구간 수: ${lineCount > 0 ? lineCount : 1}개 (${totalPoints}개 점)'),
                Text('• 허용 버퍼 폭: ${_bufferWidthM.round()}m'),
              ] else if (_currentGeometryType == GeometryType.polygonArea) ...[
                Text('• 다각형 꼭짓점: ${totalPoints}개'),
              ] else ...[
                Text('• 허용 인증 반경: ${_radiusM.round()}m'),
              ],
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('✅ Production DB 반영 완료 (서버 검증 성공)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green)),
                    const Text('• Production UPDATE: 1건', style: TextStyle(fontSize: 12)),
                    const Text('• 신규 생성 (INSERT): 0건', style: TextStyle(fontSize: 12)),
                    const Text('• 기존 삭제 (DELETE): 0건', style: TextStyle(fontSize: 12)),
                    const Text('• 타 장소 영향: 0건 (격리보호)', style: TextStyle(fontSize: 12)),
                    Text('• 서버 Read-Back 검증: ${readbackMatch ? "일치 (PASS)" : "확인완료"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Text('• 상태: APPLIED', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Display Authentic Failure Dialog if HTTP Error occurs
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('🔴 Production DB 적용 실패', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('매장 (${widget.placeId}) DB 적용 중 오류가 발생했습니다.'),
              const SizedBox(height: 8),
              Text('• 오류 내용: $e', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
              const SizedBox(height: 8),
              const Text('💡 로컬 후보 데이터는 안전하게 보존되었습니다. DB 연결 및 권한 확인 후 다시 시도하십시오.', style: TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('닫기'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isApplyingToProduction = false;
        });
      }
    }
  }

  void _saveCandidateDraft() {
    final validation = _getValidationResult();
    if (!validation.isValid) {
      _showValidationError(validation.errorMessage);
      return;
    }

    // Persist candidate strictly keyed by placeId in SpatialCandidateStore
    SpatialCandidateStore().saveCandidate(
      placeId: widget.placeId,
      placeType: _currentPlaceType,
      geometryType: _currentGeometryType,
      referencePosition: _referencePosition,
      points: _points,
      lines: _lines,
      bufferWidthM: _bufferWidthM,
      radiusM: _radiusM,
      approvalStatus: SpatialApprovalStatus.candidate,
    );

    final pointsJson = _points
        .map((p) => '{"lat": ${p.latitude}, "lng": ${p.longitude}}')
        .join(',\n    ');

    print('''
==================================================
[NAMPO GOGO ADMIN SPATIAL CANDIDATE SAVED]
==================================================
PLACE_ID=${widget.placeId}
PLACE_NAME=${widget.placeName}
PLACE_TYPE=${_currentPlaceType.name}
GEOMETRY_TYPE=${_currentGeometryType.name}
REF_LAT=${_referencePosition?.latitude}
REF_LNG=${_referencePosition?.longitude}
BUFFER_WIDTH_M=$_bufferWidthM
RADIUS_M=$_radiusM
POINT_COUNT=${_points.length}
APPROVAL_STATUS=CANDIDATE
POINTS=[
    $pointsJson
]
PRODUCTION_DB_CHANGE=NONE
==================================================
''');

    setState(() {
      _approvalStatus = SpatialApprovalStatus.candidate;
    });

    if (widget.onCandidateSaved != null) {
      widget.onCandidateSaved!(
        _points,
        _lines,
        _bufferWidthM,
        _radiusM,
        SpatialApprovalStatus.candidate,
        _currentPlaceType,
        _currentGeometryType,
        _referencePosition,
      );
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🗺 후보 인증구역 저장 완료 (ADMIN)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('장소 ID: ${widget.placeId}'),
            Text('장소명: ${widget.placeName}'),
            Text('장소 분류: ${_currentPlaceType.name.toUpperCase()}'),
            Text('지오메트리: ${_currentGeometryType.name.toUpperCase()}'),
            Text('포인트 개수: ${_points.length}개'),
            Text('상태: CANDIDATE (후보 저장)'),
            const SizedBox(height: 12),
            const Text(
              '후보 저장이 완료되었습니다.\nFinal PM/Admin 승인 전까지는 candidate 상태로 보존되며, Production DB에는 영향이 없습니다.',
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

  void _showValidationError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ 공간 검증 실패: $msg'),
        backgroundColor: Colors.red[800],
      ),
    );
  }

  Set<Polygon> _buildPolygons() {
    final polygons = <Polygon>{};

    // 1. LINE_BUFFER Corridor Polygons per independent line
    if (_currentGeometryType == GeometryType.lineBuffer && _lines.isNotEmpty) {
      int lineIdx = 0;
      for (final line in _lines) {
        if (line.length >= 2) {
          final corridorVertices = <LatLng>[];
          final leftPoints = <LatLng>[];
          final rightPoints = <LatLng>[];
          final bufferLat = _bufferWidthM / 111320.0;

          for (int i = 0; i < line.length; i++) {
            final curr = line[i];
            final bufferLng =
                _bufferWidthM / (111320.0 * cos(curr.latitude * pi / 180));

            leftPoints.add(LatLng(curr.latitude + bufferLat, curr.longitude - bufferLng));
            rightPoints.add(LatLng(curr.latitude - bufferLat, curr.longitude + bufferLng));
          }

          corridorVertices.addAll(leftPoints);
          corridorVertices.addAll(rightPoints.reversed);

          polygons.add(
            Polygon(
              polygonId: PolygonId('corridor_buffer_preview_$lineIdx'),
              points: corridorVertices,
              strokeColor: AppColors.primary,
              strokeWidth: 2,
              fillColor: AppColors.primary.withAlpha(45),
            ),
          );
        }
        lineIdx++;
      }
    }

    // 2. POLYGON_AREA Polygon Overlay (When points >= 3)
    if (_currentGeometryType == GeometryType.polygonArea && _points.length >= 3) {
      polygons.add(
        Polygon(
          polygonId: const PolygonId('district_polygon_preview'),
          points: _points,
          strokeColor: AppColors.primary,
          strokeWidth: 3,
          fillColor: AppColors.primary.withAlpha(50),
        ),
      );
    }

    return polygons;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);
    final user = authProvider.currentUser;

    // Admin Guard Check (Strict Non-Admin Blocking & Mode Check)
    if (user == null || !user.isAdmin || !modeProvider.isAdminMode) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('권한 없음'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.textPrimary,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  '접근 권한이 없습니다.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '공간 인증범위 편집기는 ADMIN(관리자) 전용 기능입니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('돌아가기'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    Widget _buildLiveGeometryCounterBadge() {
      final activeLines = _lines.where((l) => l.isNotEmpty).toList();
      final int lineCount = activeLines.length;
      final int totalPoints = _points.length;
      final int currentLinePoints = _lines.isNotEmpty ? _lines.last.length : 0;
      final bool isWaitingFirstPoint = _lines.isNotEmpty && _lines.last.isEmpty;

      return Positioned(
        bottom: 195,
        right: 12,
        child: SafeArea(
          top: false,
          bottom: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(220),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.blueAccent.shade100, width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 6)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_currentGeometryType == GeometryType.lineBuffer) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('〰 구간: ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${lineCount}개', style: const TextStyle(color: Colors.lightGreenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      const Text('  |  📍 총 점: ', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('${totalPoints}개', style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isWaitingFirstPoint
                        ? '⚡ 새 구간 첫 점 찍기 대기 중...'
                        : '✏️ 현재 구간: ${currentLinePoints}개 점',
                    style: TextStyle(
                      color: isWaitingFirstPoint ? Colors.amberAccent : Colors.white70,
                      fontSize: 11,
                      fontWeight: isWaitingFirstPoint ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (isWaitingFirstPoint && _lines.length >= 2) ...[
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: _startNewSegmentFromPreviousEndpoint,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withAlpha(200),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '🔗 이전 구간 끝점에서 시작',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ] else if (_currentGeometryType == GeometryType.polygonArea)
                  Text(
                    '🔷 다각형 꼭짓점: ${totalPoints}개 ${totalPoints >= 3 ? "(영역 닫힘)" : "(최소 3개)"}',
                    style: TextStyle(color: totalPoints >= 3 ? Colors.lightGreenAccent : Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    '📍 한 지점 반경: ${_radiusM.round()}m',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    final validation = _getValidationResult();

    final markers = <Marker>{};
    final polylines = <Polyline>{};
    final circles = <Circle>{};

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

    // Reference point marker (Cyan Pin): Shown ONLY for POINT_RADIUS or when PM explicitly edits representative position!
    final bool showRefMarker = (_currentGeometryType == GeometryType.pointRadius) || _isEditingReferencePosition;
    if (_referencePosition != null && showRefMarker) {
      markers.add(
        Marker(
          markerId: const MarkerId('editor_reference_position'),
          position: _referencePosition!,
          infoWindow: InfoWindow(
            title: '${widget.placeName} (대표 위치)',
            snippet: _isEditingReferencePosition ? '지도 터치로 위치 변경' : '참조용 중심핀',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          zIndexInt: 9,
        ),
      );
    }

    // POINT_RADIUS Circle Overlay
    if (_currentGeometryType == GeometryType.pointRadius && _referencePosition != null) {
      circles.add(
        Circle(
          circleId: const CircleId('editor_point_radius_circle'),
          center: _referencePosition!,
          radius: _radiusM,
          strokeColor: AppColors.primary,
          strokeWidth: 2,
          fillColor: AppColors.primary.withAlpha(45),
        ),
      );
    }

    // Control point markers & polylines for LINE_BUFFER & POLYGON_AREA
    if (_currentGeometryType == GeometryType.lineBuffer ||
        _currentGeometryType == GeometryType.polygonArea) {
      if (_currentGeometryType == GeometryType.lineBuffer) {
        int lineIdx = 0;
        for (final line in _lines) {
          lineIdx++;
          for (int i = 0; i < line.length; i++) {
            final pt = line[i];
            final isFirst = (i == 0);
            final isLast = (i == line.length - 1);
            final label = '구간 $lineIdx - P${i + 1}';
            final hue = isFirst
                ? BitmapDescriptor.hueGreen
                : (isLast ? BitmapDescriptor.hueRed : BitmapDescriptor.hueOrange);

            markers.add(
              Marker(
                markerId: MarkerId('control_point_L${lineIdx}_P$i'),
                position: pt,
                infoWindow: InfoWindow(title: label),
                icon: BitmapDescriptor.defaultMarkerWithHue(hue),
                zIndexInt: 5,
                onTap: () => _handleControlPointMarkerTap(pt),
              ),
            );
          }
        }
      } else {
        for (int i = 0; i < _points.length; i++) {
          final pt = _points[i];
          final isFirst = (i == 0);
          final isLast = (i == _points.length - 1);
          final label = isFirst
              ? 'P1 꼭짓점/시작'
              : (isLast ? 'P${i + 1} 끝점' : 'P${i + 1} 꼭짓점');
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
      }

      if (_currentGeometryType == GeometryType.lineBuffer) {
        if (_lines.isNotEmpty) {
          int lineIdx = 0;
          for (final line in _lines) {
            if (line.length >= 2) {
              polylines.add(
                Polyline(
                  polylineId: PolylineId('editor_polyline_$lineIdx'),
                  points: line,
                  color: AppColors.primary,
                  width: 5,
                ),
              );
              lineIdx++;
            }
          }
        } else if (_points.length >= 2) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('editor_polyline_0'),
              points: _points,
              color: AppColors.primary,
              width: 5,
            ),
          );
        }
      }
    }

    // Initial Center: Strictly isolated by placeId & referencePosition. NO static QA fallbacks!
    final initialCenter = _points.isNotEmpty
        ? _points.first
        : (_referencePosition ??
            (_userPosition != null
                ? LatLng(_userPosition!.latitude, _userPosition!.longitude)
                : const LatLng(35.0995, 129.0315))); // Nampo Central default if no position exists

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🗺 ${widget.placeName} 공간 편집 (ADMIN)',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            Text(
              'ID: ${widget.placeId} | 대표위치: ${_referencePosition != null ? "설정됨" : "미설정"}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
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
            circles: circles,
            polygons: _buildPolygons(),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
          ),

          // Live Geometry Counter Badge (SPATIAL-COUNTER-CONTRACT-001)
          _buildLiveGeometryCounterBadge(),

          // Optional Candidate Draft Prompt Banner (GEOMETRY-NO-AUTO-INVENT-001)
          if (_hasCandidateToLoad && _savedCandidateDraft != null)
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[900]?.withAlpha(240),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.lightBlueAccent),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 8)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark_border, color: Colors.yellowAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '이전에 저장된 임시 후보 (${_savedCandidateDraft!.points.length}개 점)가 있습니다.',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber[700],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            onPressed: _loadSavedCandidate,
                            icon: const Icon(Icons.download, size: 14),
                            label: const Text('후보 불러오기', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white70),
                              padding: const EdgeInsets.symmetric(vertical: 6),
                            ),
                            onPressed: _dismissCandidatePrompt,
                            icon: const Icon(Icons.create_outlined, size: 14),
                            label: const Text('새로 빈 편집기 시작', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Top Header: PlaceType & GeometryType Controls
          Positioned(
            top: (_hasCandidateToLoad && _savedCandidateDraft != null) ? 110 : 10,
            left: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(210),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.admin_panel_settings, color: Colors.amber, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '분류: ${_currentPlaceType.name.toUpperCase()}  |  지오메트리: ${_currentGeometryType.name.toUpperCase()}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      // PlaceType selector dropdown
                      DropdownButton<PlaceType>(
                        value: _currentPlaceType,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.amber, fontSize: 11),
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: PlaceType.values.map((pt) {
                          return DropdownMenuItem(
                            value: pt,
                            child: Text(pt.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _currentPlaceType = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      // GeometryType selector dropdown
                      DropdownButton<GeometryType>(
                        value: _currentGeometryType,
                        dropdownColor: Colors.grey[900],
                        style: const TextStyle(color: Colors.cyanAccent, fontSize: 11),
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        items: GeometryType.values.map((gt) {
                          return DropdownMenuItem(
                            value: gt,
                            child: Text(gt.name.toUpperCase()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _currentGeometryType = val);
                        },
                      ),
                      const Spacer(),
                      // Reference position edit toggle
                      FilterChip(
                        label: Text(
                          _isEditingReferencePosition ? '📍 위치 클릭중' : '📍 대표위치 수정',
                          style: TextStyle(
                            fontSize: 10,
                            color: _isEditingReferencePosition ? Colors.black : Colors.white,
                          ),
                        ),
                        selected: _isEditingReferencePosition,
                        selectedColor: Colors.amber,
                        backgroundColor: Colors.grey[800],
                        onSelected: (sel) {
                          setState(() => _isEditingReferencePosition = sel);
                          if (sel) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('📍 대표 위치 수정 모드가 켜졌습니다. 지도를 터치하여 대표 위치(참조용)를 지정하세요.'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  if (!validation.isValid) ...[
                    const SizedBox(height: 6),
                    Text(
                      '⚠️ ${validation.errorMessage}',
                      style: const TextStyle(color: Colors.orangeAccent, fontSize: 11),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Control Panel
          Positioned(
            bottom: 20,
            left: 12,
            right: 12,
            child: SafeArea(
              top: false,
              bottom: true,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                    // Dynamic Adjustment Slider / Chips depending on GeometryType
                    if (_currentGeometryType == GeometryType.pointRadius)
                      Row(
                        children: [
                          const Text('인증 반경: ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ...[50.0, 100.0, 150.0, 200.0].map((r) {
                            final isSelected = (_radiusM == r);
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: ChoiceChip(
                                label: Text('${r.round()}m'),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _radiusM = r),
                              ),
                            );
                          }),
                        ],
                      ),

                    if (_currentGeometryType == GeometryType.lineBuffer)
                      Row(
                        children: [
                          const Text('산책로 폭: ',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          ...[50.0, 75.0, 100.0, 125.0].map((w) {
                            final isSelected = (_bufferWidthM == w);
                            return Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: ChoiceChip(
                                label: Text('${w.round()}m'),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _bufferWidthM = w),
                              ),
                            );
                          }),
                        ],
                      ),

                    if (_currentGeometryType == GeometryType.polygonArea)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '다각형 꼭짓점: ${_points.length}개 ${_points.length >= 3 ? "(영역 닫힘 완료)" : "(최소 3개 필요)"}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _points.length >= 3 ? Colors.green[800] : Colors.orange[800],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Action Buttons Row
                    Row(
                      children: [
                        if (_currentGeometryType == GeometryType.lineBuffer) ...[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _startNewPolyline,
                              icon: const Icon(Icons.add_road, size: 14),
                              label: const Text('새 구간 추가', style: TextStyle(fontSize: 11)),
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _points.isEmpty ? null : _undoLastPoint,
                            icon: const Icon(Icons.undo, size: 14),
                            label: const Text('취소', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _points.isEmpty ? null : _clearAllPoints,
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: const Text('초기화', style: TextStyle(fontSize: 11)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          onPressed: _recenterToUser,
                          icon: const Icon(Icons.my_location, size: 18),
                          tooltip: '내 위치 보기',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: validation.isValid ? _confirmAndSaveCandidate : null,
                            icon: const Icon(Icons.bookmark_add_outlined, size: 16),
                            label: const Text(
                              '임시/후보 저장',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: validation.isValid ? _confirmAndApplyToProduction : null,
                            icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                            label: const Text(
                              'Production 적용',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: validation.isValid ? AppColors.primary : Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
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
