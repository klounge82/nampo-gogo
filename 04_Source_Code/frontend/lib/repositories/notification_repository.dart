import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final Dio _dio;

  NotificationRepository({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          baseUrl: 'http://10.0.2.2:18080',
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 3),
        ));

  Future<void> registerToken({
    required String deviceId,
    required String deviceType,
    required String fcmToken,
    String? userId,
    String language = 'ko',
  }) async {
    try {
      await _dio.post('/notifications/tokens', data: {
        'user_id': userId,
        'device_id': deviceId,
        'device_type': deviceType,
        'fcm_token': fcmToken,
        'language': language,
      });
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed registerToken: $e');
      }
    }
  }

  Future<void> deregisterToken({
    required String deviceId,
    String? userId,
  }) async {
    try {
      await _dio.delete(
        '/notifications/tokens',
        queryParameters: {
          'device_id': deviceId,
          if (userId != null) 'user_id': userId,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed deregisterToken: $e');
      }
    }
  }

  Future<List<NotificationModel>> getNotifications({String? userId, int skip = 0, int limit = 20}) async {
    try {
      final res = await _dio.get('/notifications', queryParameters: {
        if (userId != null) 'user_id': userId,
        'skip': skip,
        'limit': limit,
      });
      
      final list = res.data as List;
      return list.map((item) => NotificationModel.fromJson(item)).toList();
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed fetching notifications. Simulating offline fallback: $e');
      }
      
      // Offline fallback dummy mock
      return [
        NotificationModel(
          id: 'mock_notif_1',
          userId: userId ?? 'dummy_user',
          type: 'RESERVATION',
          priority: 'HIGH',
          title: '🛎️ 예약 완료 안내',
          body: '씨앗호떡 매장 예약이 정상적으로 접수되었습니다.',
          data: {'store_id': 'store_biff_dummy'},
          isRead: false,
          sentStatus: 'sent',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        NotificationModel(
          id: 'mock_notif_2',
          userId: userId ?? 'dummy_user',
          type: 'MISSION',
          priority: 'NORMAL',
          title: '🏆 미션 성공 알림',
          body: '부산타워 방문 GPS 인증 미션 클리어! 150 포인트 적립완료.',
          data: {'mission_id': 'mission_dummy'},
          isRead: true,
          sentStatus: 'sent',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        NotificationModel(
          id: 'mock_notif_3',
          userId: userId ?? 'dummy_user',
          type: 'COUPON',
          priority: 'NORMAL',
          title: '🎁 무료 쿠폰 지급',
          body: '자갈치 횟집 10% 신선 쿠폰이 발급되었습니다. 보관함을 확인하세요!',
          data: {'coupon_id': 'coupon_dummy'},
          isRead: false,
          sentStatus: 'sent',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
    }
  }

  Future<NotificationModel?> markAsRead(String notificationId) async {
    try {
      final res = await _dio.patch('/notifications/$notificationId/read');
      return NotificationModel.fromJson(res.data);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed markAsRead: $e');
      }
      return null;
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    try {
      await _dio.patch('/notifications/read-all', queryParameters: {
        if (userId != null) 'user_id': userId,
      });
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed markAllAsRead: $e');
      }
    }
  }

  Future<NotificationPreferenceModel> getPreferences({String? userId}) async {
    try {
      final res = await _dio.get('/notifications/preferences', queryParameters: {
        if (userId != null) 'user_id': userId,
      });
      return NotificationPreferenceModel.fromJson(res.data);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed getPreferences ($e). Returning defaults.');
      }
      return NotificationPreferenceModel(
        userId: userId ?? '',
        reservationEnabled: true,
        missionEnabled: true,
        pointEnabled: true,
        couponEnabled: true,
        aiEnabled: true,
        eventEnabled: true,
        marketingConsent: false,
      );
    }
  }

  Future<NotificationPreferenceModel> updatePreferences(
    NotificationPreferenceModel pref, {
    String? userId,
  }) async {
    try {
      final res = await _dio.patch(
        '/notifications/preferences',
        data: pref.toJson(),
        queryParameters: {
          if (userId != null) 'user_id': userId,
        },
      );
      return NotificationPreferenceModel.fromJson(res.data);
    } catch (e) {
      if (kDebugMode) {
        print('NotificationRepository: Failed updatePreferences ($e)');
      }
      return pref;
    }
  }
}
