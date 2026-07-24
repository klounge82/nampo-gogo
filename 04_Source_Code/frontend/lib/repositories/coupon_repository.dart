import 'package:flutter/foundation.dart';
import '../models/coupon.dart';
import '../services/coupon_service.dart';
import '../repositories/point_repository.dart';

class CouponRepository {
  final CouponService _couponService;
  final PointRepository _pointRepository = PointRepository();

  // Local state cache for offline simulation fallback
  static final List<Coupon> _mockCoupons = [
    Coupon(
      id: 'coupon_mock_1',
      title: 'BIFF 광장 씨앗호떡 1개 교환권',
      description: '남포동 BIFF 광장 협약 포장마차에서 맛있는 씨앗호떡 1개로 교환 가능합니다.',
      costPoints: 200,
      image_url: 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e',
      expiryDays: 30,
      createdAt: DateTime.now(),
    ),
    Coupon(
      id: 'coupon_mock_2',
      title: '남포동 명가 아메리카노 1잔 교환권',
      description: '남포동 골목 안쪽에 위치한 분위기 좋은 명가 카페에서 아메리카노(HOT/ICE) 1잔과 교환 가능합니다.',
      costPoints: 500,
      image_url: 'https://images.unsplash.com/photo-1541167760496-1628856ab772',
      expiryDays: 30,
      createdAt: DateTime.now(),
    ),
    Coupon(
      id: 'coupon_mock_3',
      title: '자갈치시장 신선횟집 10% 식사 할인권',
      description:
          '자갈치시장 지정 협약 식당에서 식사류 및 활어회 메뉴 주문 시 결제 금액 of 10%를 즉시 할인받을 수 있습니다.',
      costPoints: 1000,
      image_url: 'https://images.unsplash.com/photo-1534422298391-e4f8c172dddb',
      expiryDays: 30,
      createdAt: DateTime.now(),
    ),
  ];

  static final List<UserCoupon> _mockUserCoupons = [
    UserCoupon(
      id: 'user_coupon_mock_1',
      userId: 'usr_mock_999',
      couponId: 'coupon_mock_2',
      status: 'unused',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 29)),
      coupon: _mockCoupons[1],
    ),
    UserCoupon(
      id: 'user_coupon_mock_2',
      userId: 'usr_mock_999',
      couponId: 'coupon_mock_1',
      status: 'used',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      expiresAt: DateTime.now().add(const Duration(days: 25)),
      usedAt: DateTime.now().subtract(const Duration(days: 5, hours: 2)),
      coupon: _mockCoupons[0],
    ),
  ];

  CouponRepository({CouponService? couponService})
    : _couponService = couponService ?? CouponService();

  // Get exchangeable shop coupons
  Future<List<Coupon>> getCoupons() async {
    try {
      final list = await _couponService.fetchCoupons();
      return list
          .map((json) => Coupon.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'CouponRepository: Failed to load shop coupons. Falling back to local mock list. Error: $e',
        );
      }
      return List.from(_mockCoupons);
    }
  }

  // Exchange coupon
  Future<Map<String, dynamic>> exchangeCoupon(
    String couponId, {
    String? userId,
  }) async {
    try {
      final res = await _couponService.exchangeCoupon(couponId, userId: userId);
      return {
        'success': res['success'] as bool,
        'user_coupon_id': res['user_coupon_id'] as String,
        'current_points': res['current_points'] as int,
      };
    } catch (e) {
      if (kDebugMode) {
        print(
          'CouponRepository: Failed to exchange coupon. Falling back locally. Error: $e',
        );
      }
      // Offline local transaction fallback
      final targetCoupon = _mockCoupons.firstWhere(
        (c) => c.id == couponId,
        orElse: () => throw Exception('해당 쿠폰 상품이 존재하지 않습니다.'),
      );

      final currentPoints = await _pointRepository.getUserPoints(
        userId: userId,
      );
      if (currentPoints < targetCoupon.costPoints) {
        throw Exception('보유 포인트가 부족합니다. (오프라인 모드)');
      }

      // Deduct points locally
      final updatedPoints = await _pointRepository.spendPoints(
        targetCoupon.costPoints,
        '${targetCoupon.title} 쿠폰 교환',
        userId: userId,
      );

      final newUcId =
          'user_coupon_mock_${DateTime.now().millisecondsSinceEpoch}';
      final newUc = UserCoupon(
        id: newUcId,
        userId: userId ?? 'usr_mock_999',
        couponId: couponId,
        status: 'unused',
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(days: targetCoupon.expiryDays)),
        coupon: targetCoupon,
      );
      _mockUserCoupons.insert(0, newUc);

      return {
        'success': true,
        'user_coupon_id': newUcId,
        'current_points': updatedPoints,
      };
    }
  }

  // Get user owned coupons
  Future<List<UserCoupon>> getUserCoupons({
    String? userId,
    String? status,
  }) async {
    try {
      final list = await _couponService.fetchUserCoupons(
        userId: userId,
        status: status,
      );
      return list
          .map((json) => UserCoupon.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print(
          'CouponRepository: Failed to load user coupons. Falling back locally. Error: $e',
        );
      }
      var resList = List<UserCoupon>.from(_mockUserCoupons);
      if (status != null) {
        resList = resList.where((uc) => uc.status == status).toList();
      }
      return resList;
    }
  }

  // Use coupon
  Future<bool> useUserCoupon(String userCouponId, {String? userId}) async {
    try {
      final res = await _couponService.useUserCoupon(
        userCouponId,
        userId: userId,
      );
      return res['success'] as bool? ?? false;
    } catch (e) {
      if (kDebugMode) {
        print(
          'CouponRepository: Failed to use coupon. Falling back locally. Error: $e',
        );
      }
      final ucIndex = _mockUserCoupons.indexWhere(
        (uc) => uc.id == userCouponId,
      );
      if (ucIndex != -1) {
        final currentUc = _mockUserCoupons[ucIndex];
        if (currentUc.status != 'unused') {
          throw Exception('사용할 수 없는 쿠폰입니다. (오프라인 모드)');
        }
        _mockUserCoupons[ucIndex] = UserCoupon(
          id: currentUc.id,
          userId: currentUc.userId,
          couponId: currentUc.couponId,
          status: 'used',
          createdAt: currentUc.createdAt,
          expiresAt: currentUc.expiresAt,
          usedAt: DateTime.now(),
          coupon: currentUc.coupon,
        );
        return true;
      }
      throw Exception('해당 쿠폰을 소유하고 있지 않습니다.');
    }
  }
}
