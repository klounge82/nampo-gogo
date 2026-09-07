import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/point_history.dart';
import '../repositories/point_repository.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import 'payment_screen.dart';
import 'point_gift_screen.dart';
import 'coupon_list_screen.dart';

class PointHistoryScreen extends StatefulWidget {
  const PointHistoryScreen({super.key});

  @override
  State<PointHistoryScreen> createState() => _PointHistoryScreenState();
}

class _PointHistoryScreenState extends State<PointHistoryScreen> {
  final PointRepository _pointRepository = PointRepository();
  List<PointHistory> _histories = [];
  int _currentPoints = 0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPointsAndHistory();
  }

  Future<void> _loadPointsAndHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = '로그인이 필요한 서비스입니다.';
      });
      return;
    }

    try {
      final points = await _pointRepository.getUserPoints(userId: user.id);
      final histories = await _pointRepository.getPointHistory(userId: user.id);

      setState(() {
        _currentPoints = points;
        _histories = histories;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = '포인트 내역을 불러오는데 실패했습니다.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n?.pointHistoryTitle ?? '포인트 이용 내역',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadPointsAndHistory,
                    child: Text(l10n?.retryButton ?? '다시 시도'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Point Summary Card
                  _buildPointsCard(l10n),
                  const SizedBox(height: 24.0),

                  // 2. Timeline Title
                  Text(
                    l10n?.pointDetailHistory ?? '상세 이용 내역',
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12.0),

                  // 3. Point History Timeline List
                  if (_histories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Center(
                        child: Text(
                          l10n?.pointNoTransactions ?? '아직 포인트 거래 내역이 없습니다.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._histories.map((item) => _buildHistoryItem(item, l10n)),
                ],
              ),
            ),
    );
  }

  Widget _buildPointsCard(AppLocalizations? l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(77),
            blurRadius: 12.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.pointAvailableBalance ?? '사용 가능한 포인트',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_currentPoints P',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child: const Text('🪙', style: TextStyle(fontSize: 28.0)),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CouponListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.storefront, color: Colors.white, size: 18),
                label: Text(
                  AppLocalizations.of(context)?.profilePointStore ?? '포인트 교환소',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PointGiftScreen(),
                    ),
                  ).then((_) => _loadPointsAndHistory());
                },
                icon: const Icon(Icons.card_giftcard, color: Colors.white, size: 18),
                label: Text(
                  AppLocalizations.of(context)?.pointGiftTitle ?? '포인트 선물',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  final user = context.read<AuthProvider>().currentUser;
                  if (user == null) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => PaymentScreen(
                        amount: 10000,
                        targetType: 'POINT_CHARGE',
                        targetId: user.id,
                        targetName: '남포 GoGo 10,000 포인트 충전',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.add_circle, color: Colors.white, size: 18),
                label: Text(
                  l10n?.pointChargeButton ?? '포인트 충전하기',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withAlpha(40),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PointHistory item, AppLocalizations? l10n) {
    final isEarn = item.points > 0;

    // Formatting date
    final dateStr =
        '${item.createdAt.year}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

    final localizedActivity = l10n != null
        ? L10nMappers.mapPointHistoryActivity(l10n, item.activity)
        : item.activity;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side colored indicator
          Container(
            width: 4.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: isEarn ? Colors.green : AppColors.secondary,
              borderRadius: BorderRadius.circular(2.0),
            ),
          ),
          const SizedBox(width: 12.0),

          // Mid info section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizedActivity,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$dateStr  $timeStr',
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Right points change
          Text(
            isEarn ? '+${item.points} P' : '${item.points} P',
            style: TextStyle(
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
              color: isEarn ? Colors.green : AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
