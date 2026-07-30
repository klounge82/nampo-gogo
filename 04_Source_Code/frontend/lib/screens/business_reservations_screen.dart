import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';

class BusinessReservationsScreen extends StatefulWidget {
  const BusinessReservationsScreen({super.key});

  @override
  State<BusinessReservationsScreen> createState() => _BusinessReservationsScreenState();
}

class _BusinessReservationsScreenState extends State<BusinessReservationsScreen> with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  final BusinessService _businessService = BusinessService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _storeId;
  String? _errorMessage;

  Map<String, dynamic>? _settings;
  List<dynamic> _blackouts = [];
  List<dynamic> _reservations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final store = await _businessService.getManagedStore();
      final storeId = store['id'] as String;
      _storeId = storeId;

      final settings = await _reservationService.getBusinessReservationSettings(storeId);
      final blackouts = await _reservationService.getBusinessReservationBlackouts(storeId);
      final reservations = await _reservationService.getBusinessStoreReservations(storeId);

      if (mounted) {
        setState(() {
          _settings = settings;
          _blackouts = blackouts;
          _reservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleReservationsEnabled(bool val) async {
    if (_storeId == null || _settings == null) return;
    try {
      final updated = await _reservationService.updateBusinessReservationSettings(
        _storeId!,
        {'reservations_enabled': val},
      );
      setState(() => _settings = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(val ? '예약 기능이 활성화되었습니다.' : '예약 기능이 비활성화되었습니다.'),
          backgroundColor: val ? Colors.green : Colors.grey,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('설정 변경 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _actionReservation(String resId, String action, {String? reason}) async {
    try {
      if (action == 'approve') {
        await _reservationService.approveBusinessReservation(resId);
      } else if (action == 'reject') {
        await _reservationService.rejectBusinessReservation(resId, reason: reason);
      } else if (action == 'complete') {
        await _reservationService.completeBusinessReservation(resId);
      } else if (action == 'no-show') {
        await _reservationService.noShowBusinessReservation(resId);
      }
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('예약 상태가 변경되었습니다.'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 실패: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('예약 관리'),
        backgroundColor: BusinessTheme.primaryTeal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '예약 목록'),
            Tab(text: '예약 설정'),
            Tab(text: '피크타임 차단'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReservationsListTab(),
                    _buildSettingsTab(),
                    _buildBlackoutsTab(),
                  ],
                ),
    );
  }

  Widget _buildReservationsListTab() {
    if (_reservations.isEmpty) {
      return const Center(child: Text('접수된 예약 내역이 없습니다.'));
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _reservations.length,
        itemBuilder: (ctx, idx) {
          final res = _reservations[idx] as Map<String, dynamic>;
          final resId = res['id'] as String;
          final status = res['status'] as String;
          final dateStr = res['reservation_date'] ?? '';
          final timeStr = res['start_time'] ?? '';
          final partySize = res['party_size'] ?? 1;
          final note = res['customer_note'] as String?;

          Color statusColor = Colors.grey;
          String statusText = status;
          if (status == 'PENDING') {
            statusColor = Colors.orange;
            statusText = '승인 대기';
          } else if (status == 'APPROVED') {
            statusColor = Colors.green;
            statusText = '승인 완료';
          } else if (status == 'REJECTED') {
            statusColor = Colors.red;
            statusText = '거절됨';
          } else if (status == 'COMPLETED') {
            statusColor = Colors.blue;
            statusText = '이용 완료';
          } else if (status == 'NO_SHOW') {
            statusColor = Colors.purple;
            statusText = '노쇼';
          } else if (status.contains('CANCEL')) {
            statusColor = Colors.grey;
            statusText = '취소됨';
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$dateStr $timeStr',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: statusColor),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('인원: $partySize명', style: const TextStyle(fontSize: 14)),
                  if (note != null && note.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('요청사항: $note', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                  ],
                  const SizedBox(height: 12),
                  if (status == 'PENDING') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _actionReservation(resId, 'reject'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('거절'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _actionReservation(resId, 'approve'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          child: const Text('승인'),
                        ),
                      ],
                    ),
                  ] else if (status == 'APPROVED') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => _actionReservation(resId, 'no-show'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.purple),
                          child: const Text('노쇼'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _actionReservation(resId, 'complete'),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('이용 완료'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsTab() {
    if (_settings == null) return const SizedBox();

    final isEnabled = _settings!['reservations_enabled'] as bool? ?? false;
    final minAdvance = _settings!['minimum_advance_minutes'] as int? ?? 120;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile(
          title: const Text('선택형 예약 기능 사용', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          subtitle: Text(isEnabled ? '손님에게 예약 버튼이 표시됩니다.' : '예약 버튼이 숨겨집니다.'),
          value: isEnabled,
          activeColor: BusinessTheme.primaryTeal,
          onChanged: _toggleReservationsEnabled,
        ),
        const Divider(),
        ListTile(
          title: const Text('최소 사전 예약 시간'),
          subtitle: Text('${minAdvance ~/ 60}시간 전 사전 예약 필요'),
          trailing: const Icon(Icons.timer_outlined),
        ),
        const Divider(),
        ListTile(
          title: const Text('운영 시간'),
          subtitle: Text('${_settings!['operating_start_time']} ~ ${_settings!['operating_end_time']}'),
        ),
      ],
    );
  }

  Widget _buildBlackoutsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ElevatedButton.icon(
          onPressed: () => _showAddBlackoutDialog(),
          icon: const Icon(Icons.add),
          label: const Text('피크타임 차단 시간 추가'),
          style: ElevatedButton.styleFrom(
            backgroundColor: BusinessTheme.primaryTeal,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        if (_blackouts.isEmpty)
          const Center(child: Text('등록된 피크타임 차단 시간이 없습니다.'))
        else
          ..._blackouts.map((bo) {
            final boId = bo['id'] as String;
            return Card(
              child: ListTile(
                title: Text('${bo['start_time']} ~ ${bo['end_time']}'),
                subtitle: Text(bo['reason'] ?? '피크타임 예약 중지'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    if (_storeId != null) {
                      await _reservationService.deleteBusinessReservationBlackout(_storeId!, boId);
                      _loadData();
                    }
                  },
                ),
              ),
            );
          }),
      ],
    );
  }

  void _showAddBlackoutDialog() {
    String startTime = "11:30";
    String endTime = "14:00";
    String reason = "점심 피크타임";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('피크타임 예약 차단 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: '시작 시간 (HH:MM)'),
              controller: TextEditingController(text: startTime),
              onChanged: (val) => startTime = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: '종료 시간 (HH:MM)'),
              controller: TextEditingController(text: endTime),
              onChanged: (val) => endTime = val,
            ),
            TextField(
              decoration: const InputDecoration(labelText: '차단 사유'),
              controller: TextEditingController(text: reason),
              onChanged: (val) => reason = val,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
          ElevatedButton(
            onPressed: () async {
              if (_storeId != null) {
                try {
                  await _reservationService.createBusinessReservationBlackout(
                    _storeId!,
                    {
                      'start_time': startTime,
                      'end_time': endTime,
                      'reason': reason,
                    },
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('추가 실패: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );
  }
}
