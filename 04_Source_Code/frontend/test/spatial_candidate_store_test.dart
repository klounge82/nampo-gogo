import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../lib/repositories/spatial_candidate_store.dart';
import '../lib/screens/spatial_geometry_editor_screen.dart';
import '../lib/widgets/mission_eligible_area_map.dart';

void main() {
  setUp(() {
    SpatialCandidateStore().resetAll();
  });

  test('SpatialCandidateStore saves and restores candidate per placeId cleanly', () {
    const placeIdA = 'store_001';
    const placeIdB = 'store_002';

    final pointsA = [
      const LatLng(35.100, 129.030),
      const LatLng(35.101, 129.031),
    ];

    SpatialCandidateStore().saveCandidate(
      placeId: placeIdA,
      placeType: PlaceType.linear,
      geometryType: GeometryType.lineBuffer,
      referencePosition: const LatLng(35.100, 129.030),
      points: pointsA,
      bufferWidthM: 80.0,
      radiusM: 100.0,
      approvalStatus: SpatialApprovalStatus.candidate,
    );

    final restoredA = SpatialCandidateStore().getCandidate(placeIdA);
    expect(restoredA, isNotNull);
    expect(restoredA!.placeId, equals(placeIdA));
    expect(restoredA.points.length, equals(2));
    expect(restoredA.bufferWidthM, equals(80.0));

    // Place B must be completely isolated and return null
    final restoredB = SpatialCandidateStore().getCandidate(placeIdB);
    expect(restoredB, isNull);
  });

  test('SpatialCandidateStore preserves 2 independent lines structure for multi-line LINE_BUFFER', () {
    const placeId = 'qa-store-suyeong-river-photo-004';
    final line1 = [
      const LatLng(35.1665, 129.1215),
      const LatLng(35.1650, 129.1230),
      const LatLng(35.1635, 129.1245),
      const LatLng(35.1620, 129.1258),
    ];
    final line2 = [
      const LatLng(35.1600, 129.1270),
      const LatLng(35.1590, 129.1280),
      const LatLng(35.1580, 129.1290),
    ];
    final allPoints = [...line1, ...line2];

    SpatialCandidateStore().saveCandidate(
      placeId: placeId,
      placeType: PlaceType.linear,
      geometryType: GeometryType.lineBuffer,
      referencePosition: const LatLng(35.1635, 129.1245),
      points: allPoints,
      lines: [line1, line2],
      bufferWidthM: 50.0,
      radiusM: 100.0,
      approvalStatus: SpatialApprovalStatus.candidate,
    );

    final restored = SpatialCandidateStore().getCandidate(placeId);
    expect(restored, isNotNull);
    expect(restored!.lines.length, equals(2));
    expect(restored.lines[0].length, equals(4));
    expect(restored.lines[1].length, equals(3));
    expect(restored.points.length, equals(7));
    expect(restored.bufferWidthM, equals(50.0));
  });

  test('SpatialCandidateRecord JSON serialization roundtrip preserves 3+4 points per-line breakdown', () {
    const placeId = 'qa-store-suyeong-river-photo-004';
    final lineA = [
      const LatLng(35.1665, 129.1215),
      const LatLng(35.1650, 129.1230),
      const LatLng(35.1635, 129.1245),
    ]; // Line A: 3 points
    final lineB = [
      const LatLng(35.1620, 129.1258),
      const LatLng(35.1600, 129.1270),
      const LatLng(35.1590, 129.1280),
      const LatLng(35.1580, 129.1290),
    ]; // Line B: 4 points
    final allPoints = [...lineA, ...lineB]; // Total: 7 points

    final record = SpatialCandidateRecord(
      placeId: placeId,
      placeType: PlaceType.linear,
      geometryType: GeometryType.lineBuffer,
      referencePosition: const LatLng(35.1635, 129.1245),
      points: allPoints,
      lines: [lineA, lineB],
      bufferWidthM: 50.0,
      radiusM: 100.0,
      approvalStatus: SpatialApprovalStatus.candidate,
      updatedAt: DateTime.now(),
    );

    // Serialize to JSON
    final jsonMap = record.toJson();
    expect(jsonMap['lines'], isA<List>());
    expect((jsonMap['lines'] as List).length, equals(2));

    // Deserialize fresh from JSON (Simulate app restart & reload)
    final deserialized = SpatialCandidateRecord.fromJson(jsonMap);
    expect(deserialized.lines.length, equals(2));
    expect(deserialized.lines[0].length, equals(3)); // LINE_1_POINT_COUNT = 3
    expect(deserialized.lines[1].length, equals(4)); // LINE_2_POINT_COUNT = 4
    expect(deserialized.points.length, equals(7));   // TOTAL_POINT_COUNT = 7
    expect(deserialized.bufferWidthM, equals(50.0));
  });

  test('Updating reference position preserves LINE_BUFFER and POLYGON_AREA points', () {
    const placeId = 'suyeong_river';
    final points = [
      const LatLng(35.1665, 129.1215),
      const LatLng(35.1650, 129.1230),
      const LatLng(35.1635, 129.1245),
    ];

    SpatialCandidateStore().saveCandidate(
      placeId: placeId,
      placeType: PlaceType.linear,
      geometryType: GeometryType.lineBuffer,
      referencePosition: const LatLng(35.1635, 129.1245),
      points: points,
      bufferWidthM: 75.0,
      radiusM: 100.0,
    );

    // Update reference position
    SpatialCandidateStore().updateReferencePosition(
      placeId,
      const LatLng(35.1670, 129.1220),
    );

    final updated = SpatialCandidateStore().getCandidate(placeId);
    expect(updated, isNotNull);
    expect(updated!.referencePosition, equals(const LatLng(35.1670, 129.1220)));
    // Points must remain 100% intact!
    expect(updated.points.length, equals(3));
    expect(updated.points.first, equals(const LatLng(35.1665, 129.1215)));
  });
}
