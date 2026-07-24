import 'dart:convert';

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String priority;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final String sentStatus;
  final DateTime? sentAt;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.priority,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.sentStatus,
    this.sentAt,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedData = {};
    if (json['data_json'] != null && json['data_json'].toString().isNotEmpty) {
      try {
        parsedData = jsonDecode(json['data_json']);
      } catch (_) {}
    }
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? 'SYSTEM',
      priority: json['priority'] ?? 'NORMAL',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      data: parsedData,
      isRead: json['is_read'] ?? false,
      sentStatus: json['sent_status'] ?? 'pending',
      sentAt: json['sent_at'] != null ? DateTime.parse(json['sent_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}

class NotificationPreferenceModel {
  final String userId;
  final bool reservationEnabled;
  final bool missionEnabled;
  final bool pointEnabled;
  final bool couponEnabled;
  final bool aiEnabled;
  final bool eventEnabled;
  final bool marketingConsent;

  NotificationPreferenceModel({
    required this.userId,
    required this.reservationEnabled,
    required this.missionEnabled,
    required this.pointEnabled,
    required this.couponEnabled,
    required this.aiEnabled,
    required this.eventEnabled,
    required this.marketingConsent,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      userId: json['user_id'] ?? '',
      reservationEnabled: json['reservation_enabled'] ?? true,
      missionEnabled: json['mission_enabled'] ?? true,
      pointEnabled: json['point_enabled'] ?? true,
      couponEnabled: json['coupon_enabled'] ?? true,
      aiEnabled: json['ai_enabled'] ?? true,
      eventEnabled: json['event_enabled'] ?? true,
      marketingConsent: json['marketing_consent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reservation_enabled': reservationEnabled,
      'mission_enabled': missionEnabled,
      'point_enabled': pointEnabled,
      'coupon_enabled': couponEnabled,
      'ai_enabled': aiEnabled,
      'event_enabled': eventEnabled,
      'marketing_consent': marketingConsent,
    };
  }
}
