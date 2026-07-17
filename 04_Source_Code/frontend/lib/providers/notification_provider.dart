import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  NotificationPreferenceModel? _preferences;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  NotificationPreferenceModel? get preferences => _preferences;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({String? userId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(userId: userId);
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    final updated = await _repository.markAsRead(id);
    if (updated != null) {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = updated;
        notifyListeners();
      }
    } else {
      // Fallback local update
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        final current = _notifications[index];
        _notifications[index] = NotificationModel(
          id: current.id,
          userId: current.userId,
          type: current.type,
          priority: current.priority,
          title: current.title,
          body: current.body,
          data: current.data,
          isRead: true,
          sentStatus: current.sentStatus,
          sentAt: current.sentAt,
          readAt: DateTime.now(),
          createdAt: current.createdAt,
        );
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead({String? userId}) async {
    await _repository.markAllAsRead(userId: userId);
    
    // Update local state
    _notifications = _notifications.map((n) {
      if (n.isRead) return n;
      return NotificationModel(
        id: n.id,
        userId: n.userId,
        type: n.type,
        priority: n.priority,
        title: n.title,
        body: n.body,
        data: n.data,
        isRead: true,
        sentStatus: n.sentStatus,
        sentAt: n.sentAt,
        readAt: DateTime.now(),
        createdAt: n.createdAt,
      );
    }).toList();
    
    notifyListeners();
  }

  Future<void> fetchPreferences({String? userId}) async {
    _preferences = await _repository.getPreferences(userId: userId);
    notifyListeners();
  }

  Future<void> updatePreferences(NotificationPreferenceModel updated, {String? userId}) async {
    _preferences = await _repository.updatePreferences(updated, userId: userId);
    notifyListeners();
  }
}
