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
