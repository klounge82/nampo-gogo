import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../widgets/mission_eligible_area_map.dart';

class SpatialValidationResult {
  final bool isValid;
  final String errorMessage;
  final String? warningMessage;

  const SpatialValidationResult({
    required this.isValid,
    this.errorMessage = '',
    this.warningMessage,
  });
}

class SpatialValidator {
  /// Validates compatibility between PlaceType and GeometryType
  static SpatialValidationResult validateCompatibility(
      PlaceType placeType, GeometryType geometryType) {
    switch (placeType) {
      case PlaceType.point:
        if (geometryType != GeometryType.pointRadius) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'POINT 장소는 POINT_RADIUS 지오메트리만 선택할 수 있습니다.',
          );
        }
        break;

      case PlaceType.linear:
        if (geometryType == GeometryType.pointRadius) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'LINEAR(산책로/강변) 장소는 단순 POINT_RADIUS 지오메트리를 사용할 수 없습니다. LINE_BUFFER를 사용하세요.',
          );
        }
        break;

      case PlaceType.district:
        if (geometryType == GeometryType.pointRadius) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'DISTRICT(상권/문화) 구역은 단순 POINT_RADIUS를 사용할 수 없습니다. POLYGON_AREA를 사용하세요.',
          );
        }
        break;

      case PlaceType.largeArea:
        if (geometryType == GeometryType.pointRadius) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'LARGE_AREA(해변/대형구역)는 단순 POINT_RADIUS를 사용할 수 없습니다. POLYGON_AREA를 사용하세요.',
          );
        }
        break;

      case PlaceType.site:
        if (geometryType != GeometryType.pointRadius &&
            geometryType != GeometryType.polygonArea) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'SITE(공원/사찰) 장소는 POINT_RADIUS 또는 POLYGON_AREA만 지원합니다.',
          );
        }
        break;
    }

    return const SpatialValidationResult(isValid: true);
  }

  /// Validates actual coordinate geometry content
  static SpatialValidationResult validateGeometryContent({
    required GeometryType geometryType,
    LatLng? referencePosition,
    double radiusM = 0.0,
    List<LatLng> corridorCoordinates = const [],
    double bufferWidthM = 0.0,
    List<LatLng> polygonCoordinates = const [],
  }) {
    // 1. Reference position coordinate range check
    if (referencePosition != null) {
      final lat = referencePosition.latitude;
      final lng = referencePosition.longitude;
      if (lat.isNaN || lng.isNaN || lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        return const SpatialValidationResult(
          isValid: false,
          errorMessage: '대표 위치 좌표 범위가 올바르지 않습니다. (위도: -90~90, 경도: -180~180)',
        );
      }
    }

    // Combine effective points for polygon validation if polygonCoordinates was passed as corridorCoordinates
    final effectivePolyPoints = polygonCoordinates.isNotEmpty
        ? polygonCoordinates
        : corridorCoordinates;

    // 2. Geometry Type specific checks
    switch (geometryType) {
      case GeometryType.pointRadius:
        if (referencePosition == null) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'POINT_RADIUS 지오메트리는 중심 대표 위치가 필수입니다. 지도에서 위치를 설정하세요.',
          );
        }
        if (radiusM <= 0) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: '인증 반경(radius)은 0m보다 커야 합니다.',
          );
        }
        break;

      case GeometryType.lineBuffer:
        if (corridorCoordinates.length < 2) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'LINE_BUFFER 지오메트리는 최소 2개 이상의 산책로 제어 포인트가 필요합니다.',
          );
        }
        if (bufferWidthM <= 0) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: '산책로 인증 폭(bufferWidth)은 0m보다 커야 합니다.',
          );
        }

        // Check for identical coordinates repetition
        bool allIdentical = true;
        final p0 = corridorCoordinates.first;
        for (final p in corridorCoordinates) {
          if (p.latitude != p0.latitude || p.longitude != p0.longitude) {
            allIdentical = false;
            break;
          }
        }
        if (allIdentical) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: '동일한 좌표만 반복 지정할 수 없습니다. 산책로 동선을 따라 다른 위치를 선택하세요.',
          );
        }
        break;

      case GeometryType.polygonArea:
        if (effectivePolyPoints.length < 3) {
          return SpatialValidationResult(
            isValid: false,
            errorMessage: 'POLYGON_AREA 지오메트리는 최소 3개 이상의 다각형 꼭짓점이 필요합니다. (현재 ${effectivePolyPoints.length}개)',
          );
        }
        break;

      case GeometryType.multiArea:
        if (corridorCoordinates.isEmpty && polygonCoordinates.isEmpty) {
          return const SpatialValidationResult(
            isValid: false,
            errorMessage: 'MULTI_AREA 지오메트리에 유효한 하위 구역이 지정되지 않았습니다.',
          );
        }
        break;
    }

    return const SpatialValidationResult(isValid: true);
  }
}
