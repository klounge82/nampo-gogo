import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/point_history.dart';
import '../repositories/point_repository.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';

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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final points = await _pointRepository.getUserPoints(userId: userId);
      final history = await _pointRepository.getPointHistory(userId: userId);

      // Sync AuthProvider status
      authProvider.updatePoints(points);

      setState(() {
        _currentPoints = points;
        _histories = history;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('포인트 이용 내역', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPointsAndHistory,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('에러가 발생했습니다: $_errorMessage'),
                      const SizedBox(height: 16.0),
                      ElevatedButton(
                        onPressed: _loadPointsAndHistory,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPointsAndHistory,
                  color: AppColors.primary,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      // 1. Current Points Card Dashboard
                      _buildPointsCard(),
                      const SizedBox(height: 24.0),
                      
                      // 2. Timeline Title
                      const Text(
                        '상세 이용 내역',
                        style: TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      
                      // 3. Point History Timeline List
                      if (_histories.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 48.0),
                          child: Center(
                            child: Text(
                              '아직 포인트 거래 내역이 없습니다.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        ..._histories.map((item) => _buildHistoryItem(item)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildPointsCard() {
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
          const Text(
            '사용 가능한 포인트',
            style: TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.w500),
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
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
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
              label: const Text('포인트 충전하기', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(40),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(PointHistory item) {
    final isEarn = item.points > 0;
    
    // Formatting date
    final dateStr = '${item.createdAt.year}.${item.createdAt.month.toString().padLeft(2, '0')}.${item.createdAt.day.toString().padLeft(2, '0')}';
    final timeStr = '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}';

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
                  item.activity,
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
