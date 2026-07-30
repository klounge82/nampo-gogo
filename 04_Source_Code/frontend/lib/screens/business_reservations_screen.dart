import 'package:flutter/material.dart';
import '../services/reservation_service.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';

class BusinessReservationsScreen extends StatefulWidget {
  final int initialTabIndex;
  final String initialFilter;

  const BusinessReservationsScreen({
    super.key,
    this.initialTabIndex = 0,
    this.initialFilter = 'ALL',
  });

  @override
  State<BusinessReservationsScreen> createState() =>
      _BusinessReservationsScreenState();
}

class _BusinessReservationsScreenState extends State<BusinessReservationsScreen>
    with SingleTickerProviderStateMixin {
  final ReservationService _reservationService = ReservationService();
  final BusinessService _businessService = BusinessService();

  late TabController _tabController;
  late String _currentFilter;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _storeId;
  bool _hasError = false;

  Map<String, dynamic>? _settings;
  List<dynamic> _blackouts = [];
  List<dynamic> _reservations = [];

  // Setting Controllers
  bool _reservationsEnabled = false;
  String _startHours = "09:00";
  String _endHours = "22:00";
  int _minAdvanceMins = 120;
  int _maxAdvanceDays = 30;
  int _minParty = 1;

  int _maxParty = 6;
  int _maxPerSlot = 1;
  bool _tempPauseEnabled = false;
  final TextEditingController _tempPauseReasonController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentFilter = widget.initialFilter;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tempPauseReasonController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final storeRes = await _businessService.getManagedStore();
      final storeMap = (storeRes['store'] as Map<String, dynamic>?) ?? storeRes;
      final storeId = (storeMap['id'] ?? storeRes['id'])?.toString();

      if (storeId == null || storeId.isEmpty) {
        throw Exception('Store ID missing');
      }
      _storeId = storeId;

      final settings = await _reservationService.getBusinessReservationSettings(
        storeId,
      );
      final blackouts = await _reservationService
          .getBusinessReservationBlackouts(storeId);
      final reservations = await _reservationService
          .getBusinessStoreReservations(storeId);

      if (mounted) {
        setState(() {
          _settings = settings;
          _blackouts = blackouts;
          _reservations = reservations;

          // Null-safe extraction for settings
          _reservationsEnabled =
              settings['reservations_enabled'] as bool? ?? false;
          _startHours = settings['operating_start_time']?.toString() ?? "09:00";
          _endHours = settings['operating_end_time']?.toString() ?? "22:00";
          _minAdvanceMins =
              (settings['minimum_advance_minutes'] as num?)?.toInt() ?? 120;
          _maxAdvanceDays =
              (settings['maximum_advance_days'] as num?)?.toInt() ?? 30;
          _minParty = (settings['minimum_party_size'] as num?)?.toInt() ?? 1;
          _maxParty = (settings['maximum_party_size'] as num?)?.toInt() ?? 6;
          _maxPerSlot =
              (settings['max_reservations_per_slot'] as num?)?.toInt() ?? 1;
          _tempPauseEnabled =
              settings['temporary_pause_enabled'] as bool? ?? false;
          _tempPauseReasonController.text =
              settings['temporary_pause_reason']?.toString() ?? "";

          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_storeId == null) return;

    setState(() => _isSaving = true);
    try {
      final updatePayload = {
        'reservations_enabled': _reservationsEnabled,
        'operating_start_time': _startHours,
        'operating_end_time': _endHours,
        'minimum_advance_minutes': _minAdvanceMins,
        'maximum_advance_days': _maxAdvanceDays,
        'minimum_party_size': _minParty,
        'maximum_party_size': _maxParty,
        'max_reservations_per_slot': _maxPerSlot,
        'temporary_pause_enabled': _tempPauseEnabled,
        'temporary_pause_reason': _tempPauseReasonController.text,
      };

      final updated = await _reservationService
          .updateBusinessReservationSettings(_storeId!, updatePayload);

      if (mounted) {
        setState(() {
          _settings = updated;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 설정이 성공적으로 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('설정 저장에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _actionReservation(
    String resId,
    String action, {
    String? reason,
  }) async {
    try {
      if (action == 'approve') {
        await _reservationService.approveBusinessReservation(resId);
      } else if (action == 'reject') {
        await _reservationService.rejectBusinessReservation(
          resId,
          reason: reason,
        );
      } else if (action == 'complete') {
        await _reservationService.completeBusinessReservation(resId);
      } else if (action == 'cancel') {
        await _reservationService.rejectBusinessReservation(
          resId,
          reason: reason ?? "사업자 사정으로 취소",
        );
      } else if (action == 'no-show') {
        await _reservationService.noShowBusinessReservation(resId);
      }
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('예약 상태가 변경되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('처리에 실패했습니다. 잠시 후 다시 시도해 주세요.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _maskUserId(String userId) {
    if (userId.length <= 4) return "$userId***";
    return "${userId.substring(0, 3)}***${userId.substring(userId.length - 2)}";
  }

  List<dynamic> _getFilteredReservations() {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return _reservations.where((r) {
      if (r is! Map) return false;
      final status = r['status']?.toString() ?? '';
      final date = r['reservation_date']?.toString() ?? '';

      if (_currentFilter == 'TODAY') {
        return date == todayStr;
      } else if (_currentFilter == 'PENDING') {
        return status == 'PENDING';
      } else if (_currentFilter == 'APPROVED' ||
          _currentFilter == 'COMPLETED') {
        return status == 'APPROVED' || status == 'COMPLETED';
      }
      return true; // ALL
    }).toList();
  }

  String _getEmptyMessage() {
    if (_currentFilter == 'TODAY') {
      return '오늘 예약이 없습니다.';
    } else if (_currentFilter == 'PENDING') {
      return '승인 대기 중인 예약이 없습니다.';
    } else if (_currentFilter == 'APPROVED' || _currentFilter == 'COMPLETED') {
      return '완료된 예약이 없습니다.';
    }
    return '예약이 없습니다.';
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
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
            ? _buildErrorView()
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildReservationsListTab(),
                  _buildSettingsTab(),
                  _buildBlackoutsTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              '예약 정보를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BusinessTheme.primaryTeal,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservationsListTab() {
    final filtered = _getFilteredReservations();

    return Column(
      children: [
        // 1. Off-status Notice Banner
        if (!_reservationsEnabled)
          Container(
            color: Colors.amber[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '현재 예약 기능이 꺼져 있습니다. 예약 설정에서 켤 수 있습니다.',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                TextButton(
                  onPressed: () => _tabController.animateTo(1),
                  child: const Text('설정으로 이동'),
                ),
              ],
            ),
          ),

        // 2. Filter Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('ALL', '전체'),
                const SizedBox(width: 6),
                _buildFilterChip('TODAY', '오늘 예약'),
                const SizedBox(width: 6),
                _buildFilterChip('PENDING', '승인 대기'),
                const SizedBox(width: 6),
                _buildFilterChip('APPROVED', '승인/완료'),
              ],
            ),
          ),
        ),

        // 3. Reservations List or Empty State
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child: filtered.isEmpty
                ? ListView(
                    children: [
                      const SizedBox(height: 120),
                      Center(
                        child: Text(
                          _getEmptyMessage(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final res =
                          (filtered[idx] as Map<String, dynamic>?) ?? {};
                      final resId = res['id']?.toString() ?? '';
                      final status = res['status']?.toString() ?? 'PENDING';
                      final dateStr = res['reservation_date']?.toString() ?? '';
                      final timeStr = res['start_time']?.toString() ?? '시간 미정';
                      final partySize =
                          (res['party_size'] as num?)?.toInt() ?? 1;
                      final userId = res['user_id']?.toString() ?? '손님';
                      final note = res['customer_note']?.toString();
                      final productName =
                          res['product_name']?.toString() ?? '일반 예약';

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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '$dateStr $timeStr',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    '고객: ${_maskUserId(userId)}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    '인원: $partySize명',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '상품: $productName',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[800],
                                ),
                              ),
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '요청사항: $note',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              if (status == 'PENDING') ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _actionReservation(resId, 'reject'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('거절'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _actionReservation(resId, 'approve'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: const Text('승인'),
                                    ),
                                  ],
                                ),
                              ] else if (status == 'APPROVED') ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton(
                                      onPressed: () =>
                                          _actionReservation(resId, 'cancel'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('취소'),
                                    ),
                                    const SizedBox(width: 8),
                                    OutlinedButton(
                                      onPressed: () =>
                                          _actionReservation(resId, 'no-show'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.purple,
                                      ),
                                      child: const Text('노쇼'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _actionReservation(resId, 'complete'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
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
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _currentFilter == filterKey;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: BusinessTheme.primaryTeal.withValues(alpha: 0.2),
      checkmarkColor: BusinessTheme.primaryTeal,
      onSelected: (_) {
        setState(() => _currentFilter = filterKey);
      },
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        SwitchListTile(
          title: const Text(
            '선택형 예약 기능 활성화',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            _reservationsEnabled
                ? '이용자 상세 화면에 예약하기 버튼이 표시됩니다.'
                : '이용자 상세 화면에서 예약하기 버튼이 숨겨집니다.',
          ),
          value: _reservationsEnabled,
          activeColor: BusinessTheme.primaryTeal,
          onChanged: (val) => setState(() => _reservationsEnabled = val),
        ),
        const Divider(),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '운영 시간 및 예약 시간 설정',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '운영 시작 시간',
                  hintText: '09:00',
                ),
                controller: TextEditingController(text: _startHours),
                onChanged: (val) => _startHours = val,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  labelText: '운영 종료 시간',
                  hintText: '22:00',
                ),
                controller: TextEditingController(text: _endHours),
                onChanged: (val) => _endHours = val,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        ListTile(
          title: const Text('최소 사전 예약 시간'),
          subtitle: Text('${_minAdvanceMins ~/ 60}시간 전 사전 예약 필요'),
          trailing: DropdownButton<int>(
            value: _minAdvanceMins,
            items: const [
              DropdownMenuItem(value: 30, child: Text('30분 전')),
              DropdownMenuItem(value: 60, child: Text('1시간 전')),
              DropdownMenuItem(value: 120, child: Text('2시간 전')),
              DropdownMenuItem(value: 180, child: Text('3시간 전')),
              DropdownMenuItem(value: 1440, child: Text('1일 전')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _minAdvanceMins = val);
            },
          ),
        ),
        ListTile(
          title: const Text('최대 예약 가능 기간'),
          subtitle: Text('오늘부터 $_maxAdvanceDays일 뒤까지 예약 가능'),
          trailing: DropdownButton<int>(
            value: [7, 14, 30, 60, 90].contains(_maxAdvanceDays)
                ? _maxAdvanceDays
                : 30,
            items: const [
              DropdownMenuItem(value: 7, child: Text('7일')),
              DropdownMenuItem(value: 14, child: Text('14일')),
              DropdownMenuItem(value: 30, child: Text('30일')),
              DropdownMenuItem(value: 60, child: Text('60일')),
              DropdownMenuItem(value: 90, child: Text('90일')),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _maxAdvanceDays = val);
            },
          ),
        ),
        const Divider(),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            '인원 및 수량 설정',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: ListTile(
                title: const Text('최소 인원'),
                trailing: DropdownButton<int>(
                  value: _minParty,
                  items: List.generate(10, (i) => i + 1)
                      .map(
                        (val) =>
                            DropdownMenuItem(value: val, child: Text('$val명')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _minParty = val);
                  },
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                title: const Text('최대 인원'),
                trailing: DropdownButton<int>(
                  value: _maxParty,
                  items: List.generate(20, (i) => i + 1)
                      .map(
                        (val) =>
                            DropdownMenuItem(value: val, child: Text('$val명')),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _maxParty = val);
                  },
                ),
              ),
            ),
          ],
        ),
        const Divider(),

        SwitchListTile(
          title: const Text('임시 예약 접수 중단'),
          subtitle: const Text('매장이 바쁘거나 사정이 있을 때 일시적으로 예약을 받지 않습니다.'),
          value: _tempPauseEnabled,
          activeColor: Colors.orange,
          onChanged: (val) => setState(() => _tempPauseEnabled = val),
        ),
        if (_tempPauseEnabled) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _tempPauseReasonController,
            decoration: const InputDecoration(
              labelText: '임시 중단 사유',
              hintText: '예: 재료 소진으로 오늘 예약을 받지 않습니다.',
            ),
          ),
        ],

        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: BusinessTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    '예약 설정 저장',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 32),
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
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40.0),
              child: Text(
                '등록된 피크타임 차단 시간이 없습니다.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ..._blackouts.map((bo) {
            if (bo is! Map) return const SizedBox.shrink();
            final boId = bo['id']?.toString() ?? '';
            final startTime = bo['start_time']?.toString() ?? '';
            final endTime = bo['end_time']?.toString() ?? '';
            final reason = bo['reason']?.toString() ?? '피크타임 예약 중지';

            return Card(
              child: ListTile(
                title: Text('$startTime ~ $endTime'),
                subtitle: Text(reason),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    if (_storeId != null && boId.isNotEmpty) {
                      await _reservationService
                          .deleteBusinessReservationBlackout(_storeId!, boId);
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
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
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
                } catch (_) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('추가에 실패했습니다. 다시 시도해 주세요.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
