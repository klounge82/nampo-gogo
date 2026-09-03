import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../providers/auth_provider.dart';
import '../repositories/point_repository.dart';
import '../l10n/app_localizations.dart';

class PointGiftScreen extends StatefulWidget {
  const PointGiftScreen({super.key});

  @override
  State<PointGiftScreen> createState() => _PointGiftScreenState();
}

class _PointGiftScreenState extends State<PointGiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PointRepository _pointRepository = PointRepository();

  // Create Form State
  final TextEditingController _amountController = TextEditingController();
  bool _isCreating = false;
  Map<String, dynamic>? _createdGiftResult;

  // Claim Form State
  final TextEditingController _tokenController = TextEditingController();
  bool _isClaiming = false;

  // History State
  List<dynamic> _sentGifts = [];
  List<dynamic> _receivedGifts = [];
  bool _isLoadingHistory = false;
  int _offset = 0;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGiftHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadGiftHistory({bool refresh = true}) async {
    if (refresh) {
      _offset = 0;
    }
    setState(() => _isLoadingHistory = true);
    try {
      final res = await _pointRepository.listGifts(limit: _limit, offset: _offset);
      final List<dynamic> allGifts = res['gifts'] as List<dynamic>? ?? [];

      setState(() {
        if (refresh) {
          _sentGifts = allGifts.where((g) => g['direction'] == 'SENT').toList();
          _receivedGifts = allGifts.where((g) => g['direction'] == 'RECEIVED').toList();
        } else {
          _sentGifts.addAll(allGifts.where((g) => g['direction'] == 'SENT'));
          _receivedGifts.addAll(allGifts.where((g) => g['direction'] == 'RECEIVED'));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _refreshUserBalance() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;
    try {
      final pointsData = await _pointRepository.getUserPointsData(userId: userId);
      final currentPts = pointsData['current_points'] ?? 0;
      final lifetimePts = pointsData['lifetime_earned_points'] ?? 0;
      authProvider.updatePoints(currentPts, newLifetimeEarnedPoints: lifetimePts);
    } catch (_) {}
  }

  Future<void> _handleCreateGift() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _amountController.text.trim();
    final amount = int.tryParse(text);

    if (amount == null || amount < 100 || amount > 5000 || amount % 10 != 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pointGiftInvalidAmount)),
      );
      return;
    }

    setState(() {
      _isCreating = true;
      _createdGiftResult = null;
    });

    try {
      final result = await _pointRepository.createGift(amount);
      setState(() {
        _createdGiftResult = result;
        _amountController.clear();
      });
      await _loadGiftHistory(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pointGiftCreatedSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Future<void> _handleClaimGift() async {
    final l10n = AppLocalizations.of(context)!;
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pointGiftEmptyToken)),
      );
      return;
    }

    setState(() => _isClaiming = true);

    try {
      final res = await _pointRepository.claimGift(token);
      final netPoints = res['net_points'] ?? 0;
      _tokenController.clear();
      await _refreshUserBalance();
      await _loadGiftHistory(refresh: true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pointGiftClaimSuccess(netPoints.toString()))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isClaiming = false);
    }
  }

  Future<void> _handleCancelGift(String giftId) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.pointGiftCancelButton),
        content: Text(l10n.pointGiftCancelConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('아니오'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('예, 취소합니다', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _pointRepository.cancelGift(giftId);
      await _refreshUserBalance();
      await _loadGiftHistory(refresh: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pointGiftCancelSuccess)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n.pointGiftTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.pointGiftSendTab),
            Tab(text: l10n.pointGiftReceiveTab),
            Tab(text: l10n.pointGiftSentListTab),
            Tab(text: l10n.pointGiftReceivedListTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSendTab(l10n),
          _buildReceiveTab(l10n),
          _buildSentListTab(l10n),
          _buildReceivedListTab(l10n),
        ],
      ),
    );
  }

  Widget _buildSendTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildNoticeCard(l10n),
          const SizedBox(height: 24.0),
          Text(
            l10n.pointGiftAmountLabel,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              hintText: l10n.pointGiftAmountHint,
              suffixText: 'P',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _isCreating ? null : _handleCreateGift,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _isCreating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    l10n.pointGiftSendButton,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
          if (_createdGiftResult != null) ...[
            const SizedBox(height: 24.0),
            _buildTokenDisplayCard(_createdGiftResult!, l10n),
          ],
        ],
      ),
    );
  }

  Widget _buildReceiveTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.pointGiftTokenLabel,
            style: const TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _tokenController,
            decoration: InputDecoration(
              hintText: l10n.pointGiftTokenHint,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16.0),
          ElevatedButton(
            onPressed: _isClaiming ? null : _handleClaimGift,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _isClaiming
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    l10n.pointGiftClaimButton,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSentListTab(AppLocalizations l10n) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_sentGifts.isEmpty) {
      return Center(
        child: Text(
          l10n.pointGiftEmptySent,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadGiftHistory(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _sentGifts.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 12.0),
        itemBuilder: (ctx, idx) {
          final item = _sentGifts[idx];
          return _buildGiftItemCard(item, isSent: true, l10n: l10n);
        },
      ),
    );
  }

  Widget _buildReceivedListTab(AppLocalizations l10n) {
    if (_isLoadingHistory) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_receivedGifts.isEmpty) {
      return Center(
        child: Text(
          l10n.pointGiftEmptyReceived,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => _loadGiftHistory(refresh: true),
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: _receivedGifts.length,
        separatorBuilder: (ctx, idx) => const SizedBox(height: 12.0),
        itemBuilder: (ctx, idx) {
          final item = _receivedGifts[idx];
          return _buildGiftItemCard(item, isSent: false, l10n: l10n);
        },
      ),
    );
  }

  Widget _buildNoticeCard(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.pointGiftRuleTitle,
            style: const TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            l10n.pointGiftRule1,
            style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
          ),
          Text(
            l10n.pointGiftRule2,
            style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
          ),
          Text(
            l10n.pointGiftRule3,
            style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
          ),
          Text(
            l10n.pointGiftRule4,
            style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenDisplayCard(Map<String, dynamic> result, AppLocalizations l10n) {
    final token = result['gift_token'] as String? ?? '';
    final gross = result['gross_points'] ?? 0;
    final net = result['net_points'] ?? 0;
    final fee = result['fee_points'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '총 $gross P (수령: $net P / 수수료: $fee P)',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: AppColors.primary),
                tooltip: l10n.pointGiftCopyToken,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: token));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.pointGiftTokenCopied)),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          SelectableText(
            token,
            style: const TextStyle(
              fontSize: 13.0,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftItemCard(dynamic item, {required bool isSent, required AppLocalizations l10n}) {
    final status = item['status'] as String? ?? 'PENDING';
    final gross = item['gross_points'] ?? 0;
    final net = item['net_points'] ?? 0;
    final giftId = item['gift_id'] as String? ?? '';
    final created = item['created_at'] as String? ?? '';

    String statusText;
    Color statusColor;
    switch (status) {
      case 'ACCEPTED':
        statusText = l10n.pointGiftStatusAccepted;
        statusColor = Colors.green;
        break;
      case 'CANCELLED':
        statusText = l10n.pointGiftStatusCancelled;
        statusColor = Colors.grey;
        break;
      case 'EXPIRED':
        statusText = l10n.pointGiftStatusExpired;
        statusColor = Colors.redAccent;
        break;
      case 'PENDING':
      default:
        statusText = l10n.pointGiftStatusPending;
        statusColor = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSent ? '$gross P 발송' : '$net P 수령',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (created.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    created.length > 10 ? created.substring(0, 10) : created,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (isSent && status == 'PENDING')
            OutlinedButton(
              onPressed: () => _handleCancelGift(giftId),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                l10n.pointGiftCancelButton,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
