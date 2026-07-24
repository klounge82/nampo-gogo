import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/coupon.dart';
import '../repositories/coupon_repository.dart';
import '../providers/auth_provider.dart';

class UserCouponScreen extends StatefulWidget {
  const UserCouponScreen({super.key});

  @override
  State<UserCouponScreen> createState() => _UserCouponScreenState();
}

class _UserCouponScreenState extends State<UserCouponScreen>
    with SingleTickerProviderStateMixin {
  final CouponRepository _couponRepository = CouponRepository();
  late TabController _tabController;

  List<UserCoupon> _unusedCoupons = [];
  List<UserCoupon> _usedCoupons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final unused = await _couponRepository.getUserCoupons(
        userId: userId,
        status: 'unused',
      );
      final used = await _couponRepository.getUserCoupons(userId: userId);

      // Filter out used / expired for secondary tab
      final usedFiltered = used
          .where((uc) => uc.status == 'used' || uc.status == 'expired')
          .toList();

      setState(() {
        _unusedCoupons = unused;
        _usedCoupons = usedFiltered;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useCoupon(UserCoupon userCoupon) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    // Show processing indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final success = await _couponRepository.useUserCoupon(
        userCoupon.id,
        userId: userId,
      );
      Navigator.of(context).pop(); // Dismiss processing indicator

      if (success) {
        // Show success and refresh lists
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🏷️ 쿠폰 사용이 완료되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadUserCoupons();
      } else {
        _showErrorDialog('사용 실패', '쿠폰 사용 처리 중 예기치 못한 에러가 발생했습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss processing indicator
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('사용 실패', cleanMsg);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showBarcodeModal(UserCoupon userCoupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              userCoupon.coupon.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16.0,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8.0),
            Text(
              '유효기간: ~ ${userCoupon.expiresAt.year}.${userCoupon.expiresAt.month.toString().padLeft(2, '0')}.${userCoupon.expiresAt.day.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 11.0,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24.0),

            // Fake Barcode Image Placeholder
            Container(
              width: double.infinity,
              height: 90.0,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(24, (index) {
                      final isWide = index % 3 == 0 || index % 7 == 0;
                      return Container(
                        width: isWide ? 4.0 : 1.5,
                        height: 55.0,
                        color: Colors.black87,
                      );
                    }),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${userCoupon.id.replaceAll('-', '').substring(0, 16).toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 10.0,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24.0),

            const Text(
              '매장 직원에게 위 바코드를 보여주세요.',
              style: TextStyle(fontSize: 11.0, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),

            // Staff complete button
            SizedBox(
              width: double.infinity,
              height: 40.0,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _useCoupon(userCoupon);
                },
                icon: const Icon(Icons.check_circle_outline, size: 18.0),
                label: const Text('사용 완료 처리하기 (직원전용)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '내 쿠폰함',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: '사용 가능한 쿠폰'),
            Tab(text: '사용 완료 / 만료'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('쿠폰을 로딩하지 못했습니다: $_errorMessage'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadUserCoupons,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCouponTabList(_unusedCoupons, isUnused: true),
                _buildCouponTabList(_usedCoupons, isUnused: false),
              ],
            ),
    );
  }

  Widget _buildCouponTabList(List<UserCoupon> list, {required bool isUnused}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isUnused ? '사용 가능한 쿠폰이 없습니다.' : '지난 쿠폰 내역이 없습니다.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final item = list[index];
        return _buildCouponCard(item, isUnused);
      },
    );
  }

  Widget _buildCouponCard(UserCoupon userCoupon, bool isUnused) {
    final expStr =
        '${userCoupon.expiresAt.year}.${userCoupon.expiresAt.month.toString().padLeft(2, '0')}.${userCoupon.expiresAt.day.toString().padLeft(2, '0')}';
    final isUsed = userCoupon.status == 'used';

    return GestureDetector(
      onTap: isUnused ? () => _showBarcodeModal(userCoupon) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
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
            // Thumbnail Emoji
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: isUnused
                    ? AppColors.primary.withAlpha(13)
                    : Colors.grey.shade200,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16.0),
                ),
              ),
              child: Center(
                child: Text(
                  userCoupon.coupon.title.contains('호떡')
                      ? '🥞'
                      : userCoupon.coupon.title.contains('커피')
                      ? '☕'
                      : '🐟',
                  style: const TextStyle(fontSize: 32.0),
                ),
              ),
            ),
            const SizedBox(width: 16.0),

            // Detail info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12.0,
                  horizontal: 4.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userCoupon.coupon.title,
                      style: TextStyle(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: isUnused ? AppColors.textPrimary : Colors.grey,
                        decoration: isUnused
                            ? null
                            : TextDecoration.lineThrough,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '만료일: ~ $expStr',
                      style: TextStyle(
                        fontSize: 11.0,
                        color: isUnused
                            ? AppColors.textSecondary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status tag
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: isUnused
                      ? AppColors.secondary.withAlpha(26)
                      : isUsed
                      ? Colors.grey.withAlpha(26)
                      : Colors.red.withAlpha(26),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  isUnused
                      ? '사용하기'
                      : isUsed
                      ? '사용완료'
                      : '기간만료',
                  style: TextStyle(
                    fontSize: 10.0,
                    fontWeight: FontWeight.bold,
                    color: isUnused
                        ? AppColors.secondary
                        : isUsed
                        ? Colors.grey
                        : Colors.red,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
