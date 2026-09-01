import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../lib/repositories/spatial_candidate_store.dart';
import '../lib/widgets/mission_eligible_area_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SPATIAL-SHARED-JUNCTION-001 & Cross-Line Endpoint Support Tests', () {
    test('Shared Endpoint Across Lines: Allows same LatLng for Line 1 end point and Line 2 start point', () {
      final sharedPt = const LatLng(35.1234, 129.5678);
      final line1 = [
        const LatLng(35.1000, 129.5000),
        const LatLng(35.1100, 129.5100),
        sharedPt,
      ];
      final line2 = [
        sharedPt,
        const LatLng(35.1300, 129.5700),
      ];

      final rec = SpatialCandidateRecord(
        placeId: 'qa-store-suyeong-river-photo-004',
        placeType: PlaceType.site,
        geometryType: GeometryType.lineBuffer,
        bufferWidthM: 50.0,
        points: [...line1, ...line2],
        lines: [line1, line2],
        updatedAt: DateTime.now(),
      );

      final json = rec.toJson();
      final restored = SpatialCandidateRecord.fromJson(json);

      expect(restored.lines.length, equals(2));
      expect(restored.lines[0].last, equals(restored.lines[1].first));
      expect(restored.lines[0].last, equals(sharedPt));
      expect(restored.points.length, equals(5));
    });

    test('JSON Serialization Roundtrip preserves multi-line breakdown with shared junction', () {
      final junction = const LatLng(35.1500, 129.1100);
      final l1 = [const LatLng(35.1400, 129.1000), junction];
      final l2 = [junction, const LatLng(35.1600, 129.1200)];
      final l3 = [junction, const LatLng(35.1700, 129.1300)];

      final rec = SpatialCandidateRecord(
        placeId: 'test_junction_store',
        placeType: PlaceType.site,
        geometryType: GeometryType.lineBuffer,
        bufferWidthM: 50.0,
        points: [...l1, ...l2, ...l3],
        lines: [l1, l2, l3],
        updatedAt: DateTime.now(),
      );

      final json = rec.toJson();
      final restored = SpatialCandidateRecord.fromJson(json);

      expect(restored.lines.length, equals(3));
      expect(restored.lines[0].length, equals(2));
      expect(restored.lines[1].length, equals(2));
      expect(restored.lines[2].length, equals(2));
      expect(restored.lines[0][1], equals(junction));
      expect(restored.lines[1][0], equals(junction));
      expect(restored.lines[2][0], equals(junction));
    });
  });
}
