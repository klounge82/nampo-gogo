import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Top-level background message handler required by FCM SDK
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print(
      'NotificationService: Handling a background message: ${message.messageId}',
    );
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _isFirebaseInitialized = false;

  Future<void> initialize() async {
    try {
      // 1. Local notifications configuration
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          // Trigger when foreground local notification clicked
          if (kDebugMode) {
            print(
              'NotificationService: Foreground local notification clicked with payload: ${response.payload}',
            );
          }
        },
      );

      // Create Android channel
      if (Platform.isAndroid) {
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          'high_importance_channel',
          '주요 알림 채널',
          description: '남포 GoGo 주요 푸시 알림 수신 채널입니다.',
          importance: Importance.max,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(channel);
      }

      // 2. Initialize Firebase Core safely
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;

      // Bind background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Bind foreground message handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _showLocalNotification(message);
      });

      if (kDebugMode) {
        print('NotificationService: FCM successfully initialized.');
      }
    } catch (e) {
      if (kDebugMode) {
        print(
          'NotificationService: Failed to initialize Firebase/FCM ($e). Running in Mock fallback mode.',
        );
      }
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isFirebaseInitialized) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      if (kDebugMode) {
        print('NotificationService: Error requesting permission ($e)');
      }
      return false;
    }
  }

  Future<String?> getFCMToken() async {
    if (!_isFirebaseInitialized)
      return 'mock_fcm_token_${DateTime.now().millisecondsSinceEpoch}';
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (e) {
      if (kDebugMode) {
        print(
          'NotificationService: Error fetching FCM token ($e). Returning mock token.',
        );
      }
      return 'mock_fcm_token_error_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      '주요 알림 채널',
      channelDescription: '남포 GoGo 주요 푸시 알림 수신 채널입니다.',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }
}
