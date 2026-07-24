import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import 'notification_router.dart';

class NotificationHistoryScreen extends StatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  State<NotificationHistoryScreen> createState() =>
      _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends State<NotificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().fetchNotifications(
        userId: auth.currentUser?.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final list = notifProvider.notifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text(
          '알림 센터',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
        actions: [
          if (list.any((n) => !n.isRead))
            TextButton.icon(
              onPressed: () {
                notifProvider.markAllAsRead(userId: auth.currentUser?.id);
              },
              icon: const Icon(
                Icons.done_all,
                size: 18,
                color: Colors.blueAccent,
              ),
              label: const Text(
                '모두 읽음',
                style: TextStyle(color: Colors.blueAccent, fontSize: 13),
              ),
            ),
        ],
      ),
      body: notifProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '새로운 알림이 없습니다.',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: list.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                final item = list[index];
                return GestureDetector(
                  onTap: () async {
                    // Mark read
                    if (!item.isRead) {
                      await notifProvider.markAsRead(item.id);
                    }

                    // Route transition
                    if (mounted) {
                      NotificationRouter.routeToScreen(
                        context,
                        item.type,
                        item.data,
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: item.isRead
                          ? Colors.white
                          : const Color(0xFFEBF3FF),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getIconBgColor(item.type),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(item.type),
                            color: _getIconColor(item.type),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getTypeLabel(item.type),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getIconColor(item.type),
                                    ),
                                  ),
                                  Text(
                                    _formatTime(item.createdAt),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: item.isRead
                                      ? FontWeight.w500
                                      : FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.body,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  IconData _getIconData(String type) {
    switch (type) {
      case 'RESERVATION':
        return Icons.event_available;
      case 'MISSION':
        return Icons.military_tech;
      case 'POINT':
        return Icons.monetization_on;
      case 'COUPON':
        return Icons.local_offer;
      case 'AI':
        return Icons.auto_awesome;
      case 'MARKETING':
        return Icons.campaign;
      default:
        return Icons.notifications;
    }
  }

  Color _getIconBgColor(String type) {
    switch (type) {
      case 'RESERVATION':
        return const Color(0xFFE8F5E9);
      case 'MISSION':
        return const Color(0xFFFFF8E1);
      case 'POINT':
        return const Color(0xFFE1F5FE);
      case 'COUPON':
        return const Color(0xFFFCE4EC);
      case 'AI':
        return const Color(0xFFEDE7F6);
      default:
        return const Color(0xFFECEFF1);
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'RESERVATION':
        return Colors.green;
      case 'MISSION':
        return Colors.orange;
      case 'POINT':
        return Colors.blue;
      case 'COUPON':
        return Colors.pink;
      case 'AI':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'RESERVATION':
        return '예약';
      case 'MISSION':
        return '미션';
      case 'POINT':
        return '포인트';
      case 'COUPON':
        return '쿠폰';
      case 'AI':
        return 'AI 추천';
      case 'MARKETING':
        return '이벤트/마케팅';
      default:
        return '공지';
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${dt.month}월 ${dt.day}일';
    }
  }
}
