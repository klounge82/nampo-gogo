import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/admin_service.dart';
import '../../services/admin_point_gift_service.dart';
import '../../themes/admin_theme.dart';

class AdminPointGiftMonitorScreen extends StatefulWidget {
  final String? initialUserId;

  const AdminPointGiftMonitorScreen({super.key, this.initialUserId});

  @override
  State<AdminPointGiftMonitorScreen> createState() =>
      _AdminPointGiftMonitorScreenState();
}

class _AdminPointGiftMonitorScreenState
    extends State<AdminPointGiftMonitorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  final AdminPointGiftService _pointGiftService = AdminPointGiftService();

  // User search & selection
  List<User> _userList = [];
  bool _isLoadingUsers = false;
  User? _selectedUser;
  String? _selectedUserId;

  // Tab 0: Point Overview
  bool _isLoadingSummary = false;
  Map<String, dynamic>? _pointSummary;
  String? _summaryError;

  // Tab 1: Point Ledger
  bool _isLoadingLedger = false;
  Map<String, dynamic>? _ledgerData;
  String? _ledgerError;
  int _ledgerOffset = 0;
  static const int _ledgerLimit = 20;

  // Tab 2: Lot / FEFO
  bool _isLoadingLots = false;
  Map<String, dynamic>? _lotsData;
  String? _lotsError;
  int _lotsOffset = 0;
  static const int _lotsLimit = 50;
  String _lotStatusFilter = 'ALL';

  // Tab 3: Gift Audit
  bool _isLoadingGifts = false;
  Map<String, dynamic>? _giftsData;
  String? _giftsError;
  int _giftOffset = 0;
  static const int _giftLimit = 20;
  String _giftStatusFilter = 'ALL';
  final TextEditingController _giftUserFilterController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadUsers();

    if (widget.initialUserId != null && widget.initialUserId!.isNotEmpty) {
      _selectedUserId = widget.initialUserId;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _giftUserFilterController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 0) {
      _fetchPointSummary();
    } else if (_tabController.index == 1) {
      _fetchLedger();
    } else if (_tabController.index == 2) {
      _fetchLots();
    } else if (_tabController.index == 3) {
      _fetchGifts();
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final rawList = await _adminService.fetchAdminUsers(
        limit: 50,
      );
      final users = rawList.map((j) => User.fromJson(Map<String, dynamic>.from(j as Map))).toList();
      if (mounted) {
        setState(() {
          _userList = users;
          _isLoadingUsers = false;
          if (_selectedUserId != null && _selectedUser == null) {
            _selectedUser = users.cast<User?>().firstWhere(
                  (u) => u?.id == _selectedUserId,
                  orElse: () => null,
                );
          }
        });
        if (_selectedUserId != null) {
          _refreshCurrentTab();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    }
  }

  void _selectUser(User user) {
    setState(() {
      _selectedUser = user;
      _selectedUserId = user.id;
      _ledgerOffset = 0;
      _lotsOffset = 0;
    });
    _refreshCurrentTab();
  }

  void _refreshCurrentTab() {
    if (_tabController.index == 0) {
      _fetchPointSummary();
    } else if (_tabController.index == 1) {
      _fetchLedger();
    } else if (_tabController.index == 2) {
      _fetchLots();
    } else if (_tabController.index == 3) {
      _fetchGifts();
    }
  }

  // --- TAB 0: Summary ---
  Future<void> _fetchPointSummary() async {
    final uid = _selectedUserId;
    if (uid == null || uid.isEmpty) return;

    setState(() {
      _isLoadingSummary = true;
      _summaryError = null;
    });

    try {
      final data = await _pointGiftService.getUserSummary(uid);
      if (mounted) {
        setState(() {
          _pointSummary = data;
          _isLoadingSummary = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _summaryError = e.toString().replaceAll('Exception: ', '');
          _isLoadingSummary = false;
        });
      }
    }
  }

  // --- TAB 1: Ledger ---
  Future<void> _fetchLedger() async {
    final uid = _selectedUserId;
    if (uid == null || uid.isEmpty) return;

    setState(() {
      _isLoadingLedger = true;
      _ledgerError = null;
    });

    try {
      final data = await _pointGiftService.getUserHistory(
        uid,
        limit: _ledgerLimit,
        offset: _ledgerOffset,
      );
      if (mounted) {
        setState(() {
          _ledgerData = data;
          _isLoadingLedger = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _ledgerError = e.toString().replaceAll('Exception: ', '');
          _isLoadingLedger = false;
        });
      }
    }
  }

  // --- TAB 2: Lots ---
  Future<void> _fetchLots() async {
    final uid = _selectedUserId;
    if (uid == null || uid.isEmpty) return;

    setState(() {
      _isLoadingLots = true;
      _lotsError = null;
    });

    try {
      final data = await _pointGiftService.getUserLots(
        uid,
        limit: _lotsLimit,
        offset: _lotsOffset,
        statusFilter: _lotStatusFilter == 'ALL' ? null : _lotStatusFilter,
      );
      if (mounted) {
        setState(() {
          _lotsData = data;
          _isLoadingLots = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lotsError = e.toString().replaceAll('Exception: ', '');
          _isLoadingLots = false;
        });
      }
    }
  }

  // --- TAB 3: Gifts ---
  Future<void> _fetchGifts() async {
    setState(() {
      _isLoadingGifts = true;
      _giftsError = null;
    });

    try {
      final userFilter = _giftUserFilterController.text.trim();
      final data = await _pointGiftService.listGifts(
        limit: _giftLimit,
        offset: _giftOffset,
        statusFilter: _giftStatusFilter == 'ALL' ? null : _giftStatusFilter,
        userId: userFilter.isEmpty ? null : userFilter,
      );
      if (mounted) {
        setState(() {
          _giftsData = data;
          _isLoadingGifts = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _giftsError = e.toString().replaceAll('Exception: ', '');
          _isLoadingGifts = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminTheme.darkBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildScreenHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLedgerTab(),
                _buildLotsTab(),
                _buildGiftAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      decoration: const BoxDecoration(
        color: AdminTheme.sidebarBg,
        border: Border(bottom: BorderSide(color: Color(0xFF334155), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.card_giftcard, color: AdminTheme.primaryBlue, size: 24),
                  SizedBox(width: 10),
                  Text(
                    '포인트 / 선물 관리',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AdminTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, color: AdminTheme.textSecondary),
                tooltip: '새로고침',
                onPressed: _refreshCurrentTab,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildUserSelectionHeader(),
        ],
      ),
    );
  }

  Widget _buildUserSelectionHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        children: [
          const Icon(Icons.person_search, color: AdminTheme.primaryBlue, size: 20),
          const SizedBox(width: 8),
          const Text(
            '대상 회원:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AdminTheme.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _selectedUser != null
                ? Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AdminTheme.primaryBlue.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AdminTheme.primaryBlue.withAlpha(120)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedUser!.nickname} (${_selectedUser!.email})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'ID: ${_selectedUser!.id}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AdminTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _showUserSearchDialog,
                        child: const Text('회원 변경', style: TextStyle(fontSize: 12, color: AdminTheme.primaryBlue)),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: _showUserSearchDialog,
                    icon: _isLoadingUsers
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 16, color: AdminTheme.primaryBlue),
                    label: const Text(
                      '조회할 회원을 검색하여 선택하세요',
                      style: TextStyle(fontSize: 13, color: AdminTheme.primaryBlue),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _showUserSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        String search = '';
        List<User> filtered = List.from(_userList);

        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: AdminTheme.cardBg,
              title: const Text('대상 회원 검색 및 선택', style: TextStyle(color: Colors.white, fontSize: 16)),
              content: SizedBox(
                width: 480,
                height: 400,
                child: Column(
                  children: [
                    TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '닉네임, 이메일, ID 검색',
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (val) {
                        search = val.trim().toLowerCase();
                        setDialogState(() {
                          filtered = _userList.where((u) {
                            return u.nickname.toLowerCase().contains(search) ||
                                u.email.toLowerCase().contains(search) ||
                                u.id.toLowerCase().contains(search);
                          }).toList();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(child: Text('검색 결과가 없습니다.', style: TextStyle(color: Colors.grey)))
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, index) => const Divider(color: Color(0xFF334155), height: 1),
                              itemBuilder: (c, idx) {
                                final u = filtered[idx];
                                final isCur = u.id == _selectedUserId;
                                return ListTile(
                                  selected: isCur,
                                  selectedTileColor: AdminTheme.primaryBlue.withAlpha(40),
                                  title: Text(u.nickname, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  subtitle: Text('${u.email}  |  ID: ${u.id}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  trailing: Text('${u.currentPoints} P', style: const TextStyle(color: AdminTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                  onTap: () {
                                    Navigator.pop(ctx);
                                    _selectUser(u);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('닫기', style: TextStyle(color: Colors.grey)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AdminTheme.sidebarBg,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicatorColor: AdminTheme.primaryBlue,
        labelColor: AdminTheme.primaryBlue,
        unselectedLabelColor: AdminTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(icon: Icon(Icons.pie_chart, size: 18), text: '포인트 현황'),
          Tab(icon: Icon(Icons.receipt_long, size: 18), text: '포인트 원장'),
          Tab(icon: Icon(Icons.layers, size: 18), text: 'Lot / FEFO'),
          Tab(icon: Icon(Icons.card_giftcard, size: 18), text: '선물 감사'),
        ],
      ),
    );
  }

  Widget _buildSelectUserPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: Colors.grey[700]),
          const SizedBox(height: 16),
          const Text(
            '상단에서 조회할 대상을 먼저 선택해 주세요.',
            style: TextStyle(color: AdminTheme.textSecondary, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _showUserSearchDialog,
            icon: const Icon(Icons.search, size: 18),
            label: const Text('회원 검색'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryBlue),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 0: POINT OVERVIEW
  // ==========================================
  Widget _buildOverviewTab() {
    if (_selectedUserId == null) return _buildSelectUserPrompt();
    if (_isLoadingSummary) return const Center(child: CircularProgressIndicator());
    if (_summaryError != null) {
      return _buildErrorView(_summaryError!, _fetchPointSummary);
    }
    if (_pointSummary == null) {
      return const Center(child: Text('데이터가 없습니다.', style: TextStyle(color: Colors.grey)));
    }

    final authoritative = _pointSummary!['authoritative_usable_points'] ?? 0;
    final cached = _pointSummary!['cached_current_points'] ?? 0;
    final lifetime = _pointSummary!['lifetime_earned_points'] ?? 0;
    final isDivergent = authoritative != cached;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reconciliation Banner
          if (isDivergent)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AdminTheme.errorRose.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AdminTheme.errorRose, width: 1.5),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AdminTheme.errorRose, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '잔액 불일치 감지 (Reconciliation Divergence Warning)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AdminTheme.errorRose,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '원장 Lot 기준 잔액과 사용자 캐시 잔액의 차이가 발생했습니다: '
                          '기준 잔액: $authoritative P vs 캐시 잔액: $cached P (차이: ${authoritative - cached} P)',
                          style: const TextStyle(fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AdminTheme.accentEmerald.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AdminTheme.accentEmerald.withAlpha(100)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AdminTheme.accentEmerald, size: 20),
                  SizedBox(width: 10),
                  Text(
                    '잔액 일치 (정상 동기화 상태: Lot 기준 잔액과 캐시 잔액이 일치합니다)',
                    style: TextStyle(fontSize: 13, color: AdminTheme.accentEmerald, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

          // Balance Cards
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMetricCard(
                title: '기준 가용 잔액 (Authoritative Usable)',
                value: '$authoritative P',
                subtitle: '유효 PointLot 잔여-예약분 합산 (결제/선물 기준)',
                color: AdminTheme.primaryBlue,
                icon: Icons.account_balance_wallet,
              ),
              _buildMetricCard(
                title: '캐시 잔액 (Cached Current Points)',
                value: '$cached P',
                subtitle: 'User 테이블 current_points 캐시값',
                color: isDivergent ? AdminTheme.errorRose : AdminTheme.textSecondary,
                icon: Icons.storage,
              ),
              _buildMetricCard(
                title: '누적 획득 포인트 (Lifetime Earned)',
                value: '$lifetime P',
                subtitle: '가입 이후 총 획득 포인트 누적치',
                color: Colors.amber,
                icon: Icons.emoji_events,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // User Meta Info
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AdminTheme.cardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('회원 정보 요약', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 16),
                _buildInfoRow('회원 고유 ID', _selectedUser?.id ?? _selectedUserId ?? '-'),
                _buildInfoRow('닉네임', _selectedUser?.nickname ?? '-'),
                _buildInfoRow('이메일', _selectedUser?.email ?? '-'),
                _buildInfoRow('계정 상태', _selectedUser?.status ?? 'ACTIVE'),
                _buildInfoRow('역할 권한', _selectedUser?.roles.join(', ') ?? _selectedUser?.role ?? 'CUSTOMER'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AdminTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(100), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AdminTheme.textSecondary)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: AdminTheme.textSecondary, fontSize: 13))),
          Expanded(child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 1: POINT LEDGER
  // ==========================================
  Widget _buildLedgerTab() {
    if (_selectedUserId == null) return _buildSelectUserPrompt();
    if (_isLoadingLedger) return const Center(child: CircularProgressIndicator());
    if (_ledgerError != null) return _buildErrorView(_ledgerError!, _fetchLedger);

    final total = _ledgerData?['total_count'] ?? 0;
    final list = (_ledgerData?['history'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '포인트 원장 내역 (총 $total건)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              _buildPaginationControls(
                offset: _ledgerOffset,
                limit: _ledgerLimit,
                total: total,
                onPrev: () {
                  setState(() => _ledgerOffset = (_ledgerOffset - _ledgerLimit).clamp(0, total).toInt());
                  _fetchLedger();
                },
                onNext: () {
                  setState(() => _ledgerOffset += _ledgerLimit);
                  _fetchLedger();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('포인트 변동 내역이 없습니다.', style: TextStyle(color: Colors.grey)))
                : Container(
                    decoration: BoxDecoration(
                      color: AdminTheme.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF334155)),
                    ),
                    child: ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, index) => const Divider(color: Color(0xFF334155), height: 1),
                      itemBuilder: (ctx, idx) {
                        final item = list[idx] as Map<String, dynamic>;
                        final amount = item['amount'] ?? 0;
                        final isPositive = amount > 0;
                        final act = item['activity'] ?? '-';
                        final txType = item['transaction_type'] ?? '-';
                        final createdAt = item['created_at'] != null
                            ? item['created_at'].toString().substring(0, 19).replaceAll('T', ' ')
                            : '-';
                        final histId = item['id'] ?? '-';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isPositive
                                ? AdminTheme.accentEmerald.withAlpha(40)
                                : AdminTheme.errorRose.withAlpha(40),
                            child: Icon(
                              isPositive ? Icons.add : Icons.remove,
                              color: isPositive ? AdminTheme.accentEmerald : AdminTheme.errorRose,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                '${isPositive ? "+" : ""}$amount P',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isPositive ? AdminTheme.accentEmerald : AdminTheme.errorRose,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  txType,
                                  style: const TextStyle(fontSize: 11, color: AdminTheme.textSecondary),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            '$act  |  $createdAt\nID: $histId',
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LOT / FEFO
  // ==========================================
  Widget _buildLotsTab() {
    if (_selectedUserId == null) return _buildSelectUserPrompt();
    if (_isLoadingLots) return const Center(child: CircularProgressIndicator());
    if (_lotsError != null) return _buildErrorView(_lotsError!, _fetchLots);

    final total = _lotsData?['total_count'] ?? 0;
    final list = (_lotsData?['lots'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'PointLot FEFO 현황 (총 $total개)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<String>(
                    value: _lotStatusFilter,
                    dropdownColor: AdminTheme.cardBg,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: const [
                      DropdownMenuItem(value: 'ALL', child: Text('전체 상태')),
                      DropdownMenuItem(value: 'ACTIVE', child: Text('ACTIVE (유효)')),
                      DropdownMenuItem(value: 'EXHAUSTED', child: Text('EXHAUSTED (소진)')),
                      DropdownMenuItem(value: 'EXPIRED', child: Text('EXPIRED (만료)')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _lotStatusFilter = val;
                          _lotsOffset = 0;
                        });
                        _fetchLots();
                      }
                    },
                  ),
                ],
              ),
              _buildPaginationControls(
                offset: _lotsOffset,
                limit: _lotsLimit,
                total: total,
                onPrev: () {
                  setState(() => _lotsOffset = (_lotsOffset - _lotsLimit).clamp(0, total).toInt());
                  _fetchLots();
                },
                onNext: () {
                  setState(() => _lotsOffset += _lotsLimit);
                  _fetchLots();
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '* FEFO 소진 순서: 유효기간이 가까운 Lot부터 우선 차감되며, 무기한 Lot(NO EXPIRY)은 가장 마지막에 소진됩니다.',
            style: TextStyle(color: AdminTheme.primaryBlue, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('보유 중인 PointLot이 없습니다.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, idx) {
                      final lot = list[idx] as Map<String, dynamic>;
                      final lotId = lot['lot_id'] ?? '-';
                      final src = lot['source_type'] ?? '-';
                      final orig = lot['original_points'] ?? 0;
                      final rem = lot['remaining_points'] ?? 0;
                      final res = lot['reserved_points'] ?? 0;
                      final usable = lot['usable_points'] ?? 0;
                      final isTrans = lot['is_transferable'] == true;
                      final st = lot['status'] ?? 'ACTIVE';
                      final exp = lot['expires_at']?.toString().substring(0, 10);
                      final isNoExpiry = exp == null;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isNoExpiry
                                ? Colors.purple.withAlpha(100)
                                : const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isNoExpiry
                                    ? Colors.purple.withAlpha(40)
                                    : AdminTheme.primaryBlue.withAlpha(40),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '#${idx + 1 + _lotsOffset}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isNoExpiry ? Colors.purpleAccent : AdminTheme.primaryBlue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F172A),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(src, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 8),
                                      if (isNoExpiry)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.purple.withAlpha(40),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.purpleAccent.withAlpha(120)),
                                          ),
                                          child: const Text('만료 기한 없음 (NO EXPIRY)', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                        )
                                      else
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber.withAlpha(30),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text('만료일: $exp', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                        ),
                                      const SizedBox(width: 8),
                                      if (isTrans)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AdminTheme.primaryBlue.withAlpha(30),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('선물가능', style: TextStyle(color: AdminTheme.primaryBlue, fontSize: 10)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '원금: $orig P  |  잔여: $rem P  |  예약(선물중): $res P  |  가용: $usable P',
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('Lot ID: $lotId', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: st == 'ACTIVE'
                                    ? AdminTheme.accentEmerald.withAlpha(30)
                                    : Colors.grey.withAlpha(30),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                st,
                                style: TextStyle(
                                  color: st == 'ACTIVE' ? AdminTheme.accentEmerald : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 3: GIFT AUDIT
  // ==========================================
  Widget _buildGiftAuditTab() {
    if (_isLoadingGifts) return const Center(child: CircularProgressIndicator());
    if (_giftsError != null) return _buildErrorView(_giftsError!, _fetchGifts);

    final total = _giftsData?['total_count'] ?? 0;
    final list = (_giftsData?['gifts'] as List<dynamic>?) ?? [];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '선물 거래 감사 (총 $total건)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _giftStatusFilter,
                dropdownColor: AdminTheme.cardBg,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('전체 상태')),
                  DropdownMenuItem(value: 'PENDING', child: Text('PENDING (대기중)')),
                  DropdownMenuItem(value: 'ACCEPTED', child: Text('ACCEPTED (수령완료)')),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED (취소됨)')),
                  DropdownMenuItem(value: 'EXPIRED', child: Text('EXPIRED (만료됨)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _giftStatusFilter = val;
                      _giftOffset = 0;
                    });
                    _fetchGifts();
                  }
                },
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 180,
                height: 36,
                child: TextField(
                  controller: _giftUserFilterController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: '회원 ID 필터',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                    filled: true,
                    fillColor: const Color(0xFF0F172A),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  onSubmitted: (_) {
                    setState(() => _giftOffset = 0);
                    _fetchGifts();
                  },
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 20, color: AdminTheme.primaryBlue),
                onPressed: () {
                  setState(() => _giftOffset = 0);
                  _fetchGifts();
                },
              ),
              const SizedBox(width: 8),
              _buildPaginationControls(
                offset: _giftOffset,
                limit: _giftLimit,
                total: total,
                onPrev: () {
                  setState(() => _giftOffset = (_giftOffset - _giftLimit).clamp(0, total).toInt());
                  _fetchGifts();
                },
                onNext: () {
                  setState(() => _giftOffset += _giftLimit);
                  _fetchGifts();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('선물 거래 내역이 없습니다.', style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (ctx, idx) {
                      final g = list[idx] as Map<String, dynamic>;
                      final giftId = g['gift_id'] ?? '-';
                      final sender = g['sender_id'] ?? '-';
                      final recipient = g['recipient_id'] ?? '(미지정 / 링크발송)';
                      final gross = g['gross_points'] ?? 0;
                      final net = g['net_points'] ?? 0;
                      final fee = g['fee_points'] ?? 0;
                      final status = g['status'] ?? 'PENDING';
                      final createdAt = g['created_at'] != null
                          ? g['created_at'].toString().substring(0, 16).replaceAll('T', ' ')
                          : '-';
                      final expiresAt = g['expires_at'] != null
                          ? g['expires_at'].toString().substring(0, 16).replaceAll('T', ' ')
                          : '-';

                      Color statusColor;
                      switch (status) {
                        case 'ACCEPTED':
                          statusColor = AdminTheme.accentEmerald;
                          break;
                        case 'PENDING':
                          statusColor = Colors.amber;
                          break;
                        case 'CANCELLED':
                          statusColor = Colors.grey;
                          break;
                        case 'EXPIRED':
                          statusColor = AdminTheme.errorRose;
                          break;
                        default:
                          statusColor = Colors.white;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AdminTheme.cardBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: statusColor.withAlpha(40),
                              child: Icon(Icons.card_giftcard, color: statusColor, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$gross P (실수령: $net P / 수수료: $fee P)',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withAlpha(30),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '발신: $sender  ->  수신: $recipient',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '생성: $createdAt  |  만료: $expiresAt  |  선물 ID: $giftId',
                                    style: const TextStyle(color: Colors.grey, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls({
    required int offset,
    required int limit,
    required int total,
    required VoidCallback onPrev,
    required VoidCallback onNext,
  }) {
    final page = (offset / limit).floor() + 1;
    final maxPage = (total / limit).ceil();
    final hasPrev = offset > 0;
    final hasNext = offset + limit < total;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: Colors.white),
          onPressed: hasPrev ? onPrev : null,
          tooltip: '이전 페이지',
        ),
        Text(
          '$page / ${maxPage > 0 ? maxPage : 1}',
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: Colors.white),
          onPressed: hasNext ? onNext : null,
          tooltip: '다음 페이지',
        ),
      ],
    );
  }

  Widget _buildErrorView(String err, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AdminTheme.errorRose),
          const SizedBox(height: 12),
          Text(err, style: const TextStyle(color: Colors.white, fontSize: 14)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('다시 시도'),
            style: ElevatedButton.styleFrom(backgroundColor: AdminTheme.primaryBlue),
          ),
        ],
      ),
    );
  }
}
