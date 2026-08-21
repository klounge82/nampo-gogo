import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:math' as math;

class LocationService {
  // 부산역 기본 Fallback 좌표 (MAP-001 요구사항)
  static const double fallbackLatitude = 35.1152;
  static const double fallbackLongitude = 129.0422;

  /// 현재 위치 정보를 반환합니다.
  /// 권한 거부, GPS OFF, 기기 단절 등의 문제 발생 시 부산역 디폴트 Fallback 좌표를 리턴합니다.
  Future<Position> getCurrentLocation() async {
    try {
      // 1. GPS 하드웨어 및 서비스 활성화 여부 체크
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          print(
            'LocationService: Location services are disabled. Using fallback (Busan Station).',
          );
        }
        return _getFallbackPosition('위치 서비스가 비활성화되어 있습니다.');
      }

      // 2. 실시간 위치 권한 확인 및 요청
      PermissionStatus status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied || status.isDenied) {
        if (kDebugMode) {
          print(
            'LocationService: Location permission is denied. Using fallback (Busan Station).',
          );
        }
        return _getFallbackPosition('위치 정보 접근 권한이 거절되었습니다.');
      }

      // 3. 현재 위치 수집 (Accuracy medium, Timeout 4초 지정 후 lastKnown fallback)
      try {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 4),
        );
        return position;
      } catch (posErr) {
        // Fallback: try getting last known location
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          if (kDebugMode) {
            print('LocationService: Using last known position fallback.');
          }
          return lastKnown;
        }
        rethrow;
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'LocationService: Exception caught: $e. Returning fallback (Busan Station).',
        );
      }
      return _getFallbackPosition(e.toString());
    }
  }

  /// 부산역 Fallback Position 객체를 생성하여 반환하는 헬퍼 메서드
  Position _getFallbackPosition(String reason) {
    return Position(
      latitude: fallbackLatitude,
      longitude: fallbackLongitude,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      isMocked: true,
    );
  }

  /// Geometry-Aware Spatial Evaluator for Frontend
  static Map<String, dynamic> evaluateSpatialPosition({
    required double userLat,
    required double userLng,
    required String? geometryType,
    required String? geometryData,
    required double? placeLat,
    required double? placeLng,
    required int? radiusM,
  }) {
    final type = (geometryType ?? 'POINT_RADIUS').toUpperCase();
    final allowedRadius = (radiusM != null && radiusM > 0) ? radiusM : 50;

    if (type == 'LINE_BUFFER' && geometryData != null && geometryData.isNotEmpty) {
      try {
        final data = json.decode(geometryData);
        if (data is Map && data.containsKey('points') && data['points'] is List) {
          final ptsList = (data['points'] as List);
          if (ptsList.isNotEmpty) {
            double minDist = double.infinity;
            final bufM = (data['buffer_m'] != null) ? (data['buffer_m'] as num).toDouble() : allowedRadius.toDouble();

            for (int i = 0; i < ptsList.length - 1; i++) {
              final p1 = ptsList[i];
              final p2 = ptsList[i + 1];
              final lat1 = (p1['lat'] as num).toDouble();
              final lng1 = (p1['lng'] as num).toDouble();
              final lat2 = (p2['lat'] as num).toDouble();
              final lng2 = (p2['lng'] as num).toDouble();

              final d = _distancePointToSegmentM(userLat, userLng, lat1, lng1, lat2, lng2);
              if (d < minDist) minDist = d;
            }

            final inside = minDist <= bufM;
            final outsideByM = inside ? 0 : (minDist - bufM).round();
            return {
              'inside': inside,
              'distance_m': minDist.round(),
              'allowed_radius_m': bufM.round(),
              'outside_by_m': outsideByM,
              'geometry_type': 'LINE_BUFFER',
            };
          }
        }
      } catch (_) {}
    }

    // Default POINT_RADIUS legacy fallback
    final targetLat = placeLat ?? userLat;
    final targetLng = placeLng ?? userLng;
    final dist = Geolocator.distanceBetween(userLat, userLng, targetLat, targetLng);
    final inside = dist <= allowedRadius;
    final outsideByM = inside ? 0 : (dist - allowedRadius).round();

    return {
      'inside': inside,
      'distance_m': dist.round(),
      'allowed_radius_m': allowedRadius,
      'outside_by_m': outsideByM,
      'geometry_type': 'POINT_RADIUS',
    };
  }

  static double _distancePointToSegmentM(double plat, double plng, double lat1, double lng1, double lat2, double lng2) {
    final latRad = (lat1 + lat2) / 2.0 * (3.141592653589793 / 180.0);
    final kx = 111320.0 * math.cos(latRad);
    final ky = 110574.0;

    final vx = (lng2 - lng1) * kx;
    final vy = (lat2 - lat1) * ky;
    final wx = (plng - lng1) * kx;
    final wy = (plat - lat1) * ky;

    final vLenSq = vx * vx + vy * vy;
    if (vLenSq == 0) return Geolocator.distanceBetween(plat, plng, lat1, lng1);

    double t = (wx * vx + wy * vy) / vLenSq;
    t = t.clamp(0.0, 1.0);

    final projLat = lat1 + t * (lat2 - lat1);
    final projLng = lng1 + t * (lng2 - lng1);

    return Geolocator.distanceBetween(plat, plng, projLat, projLng);
  }
}
