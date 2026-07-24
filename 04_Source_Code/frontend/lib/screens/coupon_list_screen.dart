import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/coupon.dart';
import '../repositories/coupon_repository.dart';
import '../providers/auth_provider.dart';

class CouponListScreen extends StatefulWidget {
  const CouponListScreen({super.key});

  @override
  State<CouponListScreen> createState() => _CouponListScreenState();
}

class _CouponListScreenState extends State<CouponListScreen> {
  final CouponRepository _couponRepository = CouponRepository();
  List<Coupon> _coupons = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadShopCoupons();
  }

  Future<void> _loadShopCoupons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final list = await _couponRepository.getCoupons();
      setState(() {
        _coupons = list;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performExchange(Coupon coupon) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    // Fast local balance check before sending API
    final userPoints = authProvider.currentUser?.currentPoints ?? 0;
    if (userPoints < coupon.costPoints) {
      _showExchangeFailDialog('포인트 부족', '쿠폰을 교환하기에 보유 포인트가 부족합니다.');
      return;
    }

    // Show processing indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final res = await _couponRepository.exchangeCoupon(
        coupon.id,
        userId: userId,
      );
      Navigator.of(context).pop(); // Dismiss processing indicator

      if (res['success'] == true) {
        // Sync new point balance
        final newPoints = res['current_points'] as int;
        authProvider.updatePoints(newPoints);

        _showExchangeSuccessDialog(coupon);
      } else {
        _showExchangeFailDialog('교환 실패', '쿠폰 교환 중 예기치 못한 에러가 발생했습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss processing indicator
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showExchangeFailDialog('교환 실패', cleanMsg);
    }
  }

  void _showExchangeSuccessDialog(Coupon coupon) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '🎉 교환 성공!',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${coupon.title}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12.0),
            const Text(
              '쿠폰 교환이 정상 완료되었습니다.\n내 쿠폰함에서 바코드를 확인해 주세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.0),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                setState(() {}); // refresh screen view
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('확인', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showExchangeFailDialog(String title, String message) {
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

  void _showCouponDetailModal(Coupon coupon, int userPoints) {
    final canExchange = userPoints >= coupon.costPoints;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    coupon.title,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${coupon.costPoints} P',
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              coupon.description,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              '유효 기간: 발급 후 ${coupon.expiryDays}일 간 사용 가능',
              style: const TextStyle(
                fontSize: 12.0,
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24.0),
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: canExchange
                    ? () {
                        Navigator.of(ctx).pop();
                        _performExchange(coupon);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                child: Text(
                  canExchange ? '교환하기 (-${coupon.costPoints}P)' : '포인트 부족',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
    final authProvider = Provider.of<AuthProvider>(context);
    final userPoints = authProvider.currentUser?.currentPoints ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '포인트 교환소',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
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
                  Text('상점을 불러오지 못했습니다: $_errorMessage'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadShopCoupons,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Top User Point Summary
                Container(
                  color: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 16.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '보유 중인 포인트',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$userPoints P',
                        style: const TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  height: 1.0,
                  thickness: 1.0,
                  color: AppColors.border,
                ),

                // Shop Items Grid
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16.0),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 16.0,
                          mainAxisSpacing: 16.0,
                        ),
                    itemCount: _coupons.length,
                    itemBuilder: (context, index) {
                      final item = _coupons[index];
                      return _buildShopCard(item, userPoints);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildShopCard(Coupon coupon, int userPoints) {
    final canExchange = userPoints >= coupon.costPoints;

    return GestureDetector(
      onTap: () => _showCouponDetailModal(coupon, userPoints),
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder/Image Box
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.0),
                  ),
                ),
                child: Center(
                  child: Text(
                    coupon.title.contains('호떡')
                        ? '🥞'
                        : coupon.title.contains('커피')
                        ? '☕'
                        : '🐟',
                    style: const TextStyle(fontSize: 48.0),
                  ),
                ),
              ),
            ),

            // Info text
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.title,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${coupon.costPoints} P',
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: canExchange
                              ? AppColors.secondary
                              : Colors.grey,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: canExchange
                              ? AppColors.primary.withAlpha(26)
                              : Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          canExchange ? '교환가능' : '포인트부족',
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.bold,
                            color: canExchange
                                ? AppColors.primary
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
