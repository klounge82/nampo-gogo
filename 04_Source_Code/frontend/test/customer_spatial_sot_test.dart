import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import '../lib/models/place.dart';
import '../lib/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SPATIAL-CUSTOMER-SOT-001 Customer Production Spatial SOT Tests', () {
    test('LocationService.verifyLocationMatch parses Production API JSON string with [lat, lng] array lists', () {
      final jsonGeometry = jsonEncode({
        'type': 'LINE_BUFFER',
        'lines': [
          [
            [35.1658, 129.1251],
            [35.1693, 129.1230],
            [35.1739, 129.1199],
          ]
        ],
        'buffer_m': 50.0,
      });

      // User right on the line segment (35.1658, 129.1251)
      final res = LocationService.evaluateSpatialPosition(
        userLat: 35.1658,
        userLng: 129.1251,
        geometryType: 'LINE_BUFFER',
        geometryData: jsonGeometry,
        placeLat: 35.1658,
        placeLng: 129.1251,
        radiusM: 50,
      );

      expect(res['inside'], equals(true));
      expect(res['geometry_type'], equals('LINE_BUFFER'));
      expect(res['allowed_radius_m'], equals(50));
      expect(res['distance_m'], equals(0));
    });

    test('LocationService.evaluateSpatialPosition calculates distance to line segment correctly for outside user', () {
      final jsonGeometry = jsonEncode({
        'type': 'LINE_BUFFER',
        'lines': [
          [
            [35.1658, 129.1251],
            [35.1693, 129.1230],
          ]
        ],
        'buffer_m': 50.0,
      });

      // User far away from Suyeong River line (e.g. 35.0995, 129.0315 - Nampo)
      final res = LocationService.evaluateSpatialPosition(
        userLat: 35.0995,
        userLng: 129.0315,
        geometryType: 'LINE_BUFFER',
        geometryData: jsonGeometry,
        placeLat: 35.1658,
        placeLng: 129.1251,
        radiusM: 50,
      );

      expect(res['inside'], equals(false));
      expect(res['geometry_type'], equals('LINE_BUFFER'));
      expect(res['distance_m'], greaterThan(1000));
      expect(res['outside_by_m'], greaterThan(950));
    });

    test('Place model parses geometryType and geometryData from Production API JSON', () {
      final storeJson = {
        'id': 'qa-store-suyeong-river-photo-004',
        'name': 'QA 수영강변 현장사진 장소',
        'category': 'ATTRACTION',
        'address': '부산 해운대구 수영강변대로',
        'description': '수영강 산책로',
        'latitude': 35.1658,
        'longitude': 129.1251,
        'geometry_type': 'LINE_BUFFER',
        'geometry_data': jsonEncode({
          'type': 'LINE_BUFFER',
          'lines': [
            [
              [35.1658, 129.1251],
              [35.1693, 129.1230],
            ]
          ],
          'buffer_m': 50.0,
        }),
      };

      final place = Place.fromJson(storeJson);

      expect(place.id, equals('qa-store-suyeong-river-photo-004'));
      expect(place.geometryType, equals('LINE_BUFFER'));
      expect(place.geometryData, contains('LINE_BUFFER'));
    });
  });
}
