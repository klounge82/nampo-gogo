import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

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
          print('LocationService: Location services are disabled. Using fallback (Busan Station).');
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
          print('LocationService: Location permission is denied. Using fallback (Busan Station).');
        }
        return _getFallbackPosition('위치 정보 접근 권한이 거절되었습니다.');
      }

      // 3. 현재 위치 수집 (Timeout 5초 지정)
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );

      return position;
    } catch (e) {
      if (kDebugMode) {
        print('LocationService: Exception caught: $e. Returning fallback (Busan Station).');
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
}
