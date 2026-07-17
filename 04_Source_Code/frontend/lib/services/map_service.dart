import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class MapService {
  /// 구글 지도 길찾기 앱 인텐트 또는 웹 브라우저 네비게이션 실행
  /// mode: 'w' (도보), 'd' (자동차), 'r' (대중교통)
  Future<void> launchGoogleMapRoute({
    required double destLat,
    required double destLng,
    required String destName,
    String mode = 'w',
  }) async {
    // google.navigation:q=lat,lng&mode=d(드라이브), w(도보), b(대중교통)
    final String modeParam = mode == 'w' ? 'w' : (mode == 'r' ? 'b' : 'd');
    final String googleAppUrl = 'google.navigation:q=$destLat,$destLng&mode=$modeParam';
    final String googleWebUrl = 'https://www.google.com/maps/dir/?api=1&destination=$destLat,$destLng&travelmode=${mode == 'w' ? 'walking' : (mode == 'r' ? 'transit' : 'driving')}';

    try {
      final Uri appUri = Uri.parse(googleAppUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('MapService: Google Maps app launch failed: $e. Using web fallback.');
      }
    }

    // Web Fallback
    final Uri webUri = Uri.parse(googleWebUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('구글 지도를 실행할 수 없습니다.');
    }
  }

  /// 네이버 지도 길찾기 딥링크 인텐트 실행
  /// mode: 'walk' (도보), 'car' (자동차), 'pub' (대중교통)
  Future<void> launchNaverMapRoute({
    required double destLat,
    required double destLng,
    required String destName,
    String mode = 'walk',
  }) async {
    // nmap://route/walk?dlat=..&dlng=..&dname=..
    final String naverAppUrl = 'nmap://route/$mode?dlat=$destLat&dlng=$destLng&dname=${Uri.encodeComponent(destName)}&appname=com.nampogogo.app';
    final String naverWebUrl = 'https://map.naver.com/v5/directions/-/-/${destLat},${destLng},${Uri.encodeComponent(destName)},-/-/walk';

    try {
      final Uri appUri = Uri.parse(naverAppUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('MapService: Naver Map app launch failed: $e. Using web fallback.');
      }
    }

    // Web Fallback
    final Uri webUri = Uri.parse(naverWebUrl);
    if (await canLaunchUrl(webUri)) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    } else {
      throw Exception('네이버 지도를 실행할 수 없습니다.');
    }
  }
}
