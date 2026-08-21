import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../screens/spatial_geometry_editor_screen.dart';
import '../widgets/mission_eligible_area_map.dart';

class SpatialCandidateRecord {
  final String placeId;
  final PlaceType placeType;
  final GeometryType geometryType;
  final LatLng? referencePosition;
  final List<LatLng> points;
  final double bufferWidthM;
  final double radiusM;
  final SpatialApprovalStatus approvalStatus;
  final DateTime updatedAt;

  const SpatialCandidateRecord({
    required this.placeId,
    required this.placeType,
    required this.geometryType,
    this.referencePosition,
    this.points = const [],
    this.bufferWidthM = 75.0,
    this.radiusM = 100.0,
    this.approvalStatus = SpatialApprovalStatus.candidate,
    required this.updatedAt,
  });

  SpatialCandidateRecord copyWith({
    PlaceType? placeType,
    GeometryType? geometryType,
    LatLng? referencePosition,
    bool updateReferencePositionToNull = false,
    List<LatLng>? points,
    double? bufferWidthM,
    double? radiusM,
    SpatialApprovalStatus? approvalStatus,
  }) {
    return SpatialCandidateRecord(
      placeId: placeId,
      placeType: placeType ?? this.placeType,
      geometryType: geometryType ?? this.geometryType,
      referencePosition: updateReferencePositionToNull
          ? null
          : (referencePosition ?? this.referencePosition),
      points: points ?? List.from(this.points),
      bufferWidthM: bufferWidthM ?? this.bufferWidthM,
      radiusM: radiusM ?? this.radiusM,
      approvalStatus: approvalStatus ?? this.approvalStatus,
      updatedAt: DateTime.now(),
    );
  }
}

class SpatialCandidateStore {
  static final SpatialCandidateStore _instance = SpatialCandidateStore._internal();
  factory SpatialCandidateStore() => _instance;
  SpatialCandidateStore._internal();

  final Map<String, SpatialCandidateRecord> _records = {};

  /// Save candidate record keyed strictly by placeId
  void saveCandidate({
    required String placeId,
    required PlaceType placeType,
    required GeometryType geometryType,
    LatLng? referencePosition,
    required List<LatLng> points,
    required double bufferWidthM,
    required double radiusM,
    SpatialApprovalStatus approvalStatus = SpatialApprovalStatus.candidate,
  }) {
    _records[placeId] = SpatialCandidateRecord(
      placeId: placeId,
      placeType: placeType,
      geometryType: geometryType,
      referencePosition: referencePosition,
      points: List.from(points),
      bufferWidthM: bufferWidthM,
      radiusM: radiusM,
      approvalStatus: approvalStatus,
      updatedAt: DateTime.now(),
    );
  }

  /// Get saved candidate record for specific placeId (Returns null if not saved)
  SpatialCandidateRecord? getCandidate(String placeId) {
    return _records[placeId];
  }

  /// Update reference position ONLY without modifying or resetting verification geometry points
  void updateReferencePosition(String placeId, LatLng? newRefPos) {
    final existing = _records[placeId];
    if (existing != null) {
      _records[placeId] = existing.copyWith(
        referencePosition: newRefPos,
        updateReferencePositionToNull: newRefPos == null,
      );
    }
  }

  /// Clear candidate for specific placeId
  void clearCandidate(String placeId) {
    _records.remove(placeId);
  }

  /// Reset all stored candidates (for testing)
  void resetAll() {
    _records.clear();
  }
}
