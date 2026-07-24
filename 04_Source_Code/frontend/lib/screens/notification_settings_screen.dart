import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/auth_provider.dart';
import '../models/notification_model.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<NotificationProvider>().fetchPreferences(
        userId: auth.currentUser?.id,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final pref = notifProvider.preferences;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: const Text(
          '알림 설정',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: pref == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionHeader('기본 서비스 알림'),
                _buildToggleItem(
                  title: '예약 알림',
                  subtitle: '예약 확인, 취소 및 리마인더 푸시를 전송합니다.',
                  value: pref.reservationEnabled,
                  onChanged: (val) => _updatePref(pref, 'reservation', val),
                ),
                _buildToggleItem(
                  title: '미션 알림',
                  subtitle: '미션 완료 및 리워드 획득 성공을 안내합니다.',
                  value: pref.missionEnabled,
                  onChanged: (val) => _updatePref(pref, 'mission', val),
                ),
                _buildToggleItem(
                  title: '포인트 알림',
                  subtitle: '미션 인증 및 이벤트에 따른 포인트 증감을 수신합니다.',
                  value: pref.pointEnabled,
                  onChanged: (val) => _updatePref(pref, 'point', val),
                ),
                _buildToggleItem(
                  title: '쿠폰 알림',
                  subtitle: '쿠폰 획득 및 사용, 만료 기한 경고 알림을 발송합니다.',
                  value: pref.couponEnabled,
                  onChanged: (val) => _updatePref(pref, 'coupon', val),
                ),
                _buildToggleItem(
                  title: 'AI 코스 추천 알림',
                  subtitle: '요청하신 나만의 테마 여행 코스 산출 완료 알림입니다.',
                  value: pref.aiEnabled,
                  onChanged: (val) => _updatePref(pref, 'ai', val),
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('이벤트 및 마케팅 알림'),
                _buildToggleItem(
                  title: '시스템 공지 알림',
                  subtitle: '공지사항 및 시스템 정기 점검 알림을 전송합니다.',
                  value: pref.eventEnabled,
                  onChanged: (val) => _updatePref(pref, 'event', val),
                ),
                _buildToggleItem(
                  title: '마케팅 정보 동의',
                  subtitle: '다양한 남포동 상권 할인 및 추천 맞춤 이벤트를 수신합니다.',
                  value: pref.marketingConsent,
                  onChanged: (val) => _updatePref(pref, 'marketing', val),
                ),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.blueAccent,
        ),
      ),
    );
  }

  void _updatePref(
    NotificationPreferenceModel current,
    String type,
    bool value,
  ) {
    final updated = NotificationPreferenceModel(
      userId: current.userId,
      reservationEnabled: type == 'reservation'
          ? value
          : current.reservationEnabled,
      missionEnabled: type == 'mission' ? value : current.missionEnabled,
      pointEnabled: type == 'point' ? value : current.pointEnabled,
      couponEnabled: type == 'coupon' ? value : current.couponEnabled,
      aiEnabled: type == 'ai' ? value : current.aiEnabled,
      eventEnabled: type == 'event' ? value : current.eventEnabled,
      marketingConsent: type == 'marketing' ? value : current.marketingConsent,
    );

    final auth = context.read<AuthProvider>();
    context.read<NotificationProvider>().updatePreferences(
      updated,
      userId: auth.currentUser?.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('⚙️ 알림 설정 변경사항이 저장되었습니다.'),
        duration: Duration(milliseconds: 800),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
