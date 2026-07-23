import 'package:flutter/material.dart';

class FeatureModule {
  final String featureKey;
  final String title;
  final IconData icon;
  final String route;
  final List<String> allowedModes;
  final List<String> requiredCapabilities;
  final bool enabled;
  final bool comingSoon;
  final int navigationPosition;
  final int dashboardPosition;

  const FeatureModule({
    required this.featureKey,
    required this.title,
    required this.icon,
    required this.route,
    required this.allowedModes,
    required this.requiredCapabilities,
    this.enabled = true,
    this.comingSoon = false,
    this.navigationPosition = 0,
    this.dashboardPosition = 0,
  });
}

class ModuleRegistry {
  static const List<FeatureModule> customerModules = [
    FeatureModule(
      featureKey: 'customer_explore',
      title: '탐색',
      icon: Icons.explore,
      route: '/explore',
      allowedModes: ['CUSTOMER'],
      requiredCapabilities: ['place.read'],
      navigationPosition: 1,
    ),
    FeatureModule(
      featureKey: 'customer_courses',
      title: '추천 코스',
      icon: Icons.map,
      route: '/courses',
      allowedModes: ['CUSTOMER'],
      requiredCapabilities: ['course.manage'],
      navigationPosition: 2,
    ),
    FeatureModule(
      featureKey: 'customer_favorites',
      title: '저장함',
      icon: Icons.bookmark,
      route: '/favorites',
      allowedModes: ['CUSTOMER'],
      requiredCapabilities: ['favorite.manage'],
      navigationPosition: 3,
    ),
    FeatureModule(
      featureKey: 'customer_reviews',
      title: '내 후기',
      icon: Icons.rate_review,
      route: '/reviews',
      allowedModes: ['CUSTOMER'],
      requiredCapabilities: ['review.manage'],
      navigationPosition: 4,
    ),
    FeatureModule(
      featureKey: 'customer_trip_diary',
      title: '여행 일지',
      icon: Icons.book,
      route: '/diary',
      allowedModes: ['CUSTOMER'],
      requiredCapabilities: [],
      enabled: false,
      comingSoon: true,
      navigationPosition: 5,
    ),
  ];

  static const List<FeatureModule> businessModules = [
    FeatureModule(
      featureKey: 'business_dashboard',
      title: '대시보드',
      icon: Icons.dashboard,
      route: '/business/dashboard',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: ['business.dashboard.read'],
      navigationPosition: 1,
    ),
    FeatureModule(
      featureKey: 'business_store_manage',
      title: '매장 정보',
      icon: Icons.store,
      route: '/business/store',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: ['business.dashboard.read'],
      navigationPosition: 2,
    ),
    FeatureModule(
      featureKey: 'business_products',
      title: '메뉴/상품',
      icon: Icons.restaurant_menu,
      route: '/business/products',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: ['business.dashboard.read'],
      enabled: true,
      comingSoon: false,
      navigationPosition: 3,
    ),
    FeatureModule(
      featureKey: 'business_reviews',
      title: '손님 리뷰',
      icon: Icons.reviews,
      route: '/business/reviews',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: ['business.dashboard.read'],
      navigationPosition: 4,
    ),
    FeatureModule(
      featureKey: 'business_reservations',
      title: '예약 관리',
      icon: Icons.calendar_today,
      route: '/business/reservations',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: ['business.dashboard.read'],
      enabled: false,
      comingSoon: true,
      navigationPosition: 5,
    ),
    FeatureModule(
      featureKey: 'business_recommendations',
      title: '추천 관리',
      icon: Icons.thumb_up,
      route: '/business/recommendations',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: [],
      enabled: false,
      comingSoon: true,
      navigationPosition: 6,
    ),
    FeatureModule(
      featureKey: 'business_events',
      title: '이벤트 관리',
      icon: Icons.event,
      route: '/business/events',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: [],
      enabled: false,
      comingSoon: true,
      navigationPosition: 7,
    ),
    FeatureModule(
      featureKey: 'business_settlement',
      title: '정산 관리',
      icon: Icons.account_balance_wallet,
      route: '/business/settlement',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: [],
      enabled: false,
      comingSoon: true,
      navigationPosition: 8,
    ),
    FeatureModule(
      featureKey: 'business_staff',
      title: '직원 관리',
      icon: Icons.people,
      route: '/business/staff',
      allowedModes: ['BUSINESS'],
      requiredCapabilities: [],
      enabled: false,
      comingSoon: true,
      navigationPosition: 9,
    ),
  ];

  static const List<FeatureModule> adminModules = [
    FeatureModule(
      featureKey: 'admin_business_approvals',
      title: '사업자 승인',
      icon: Icons.verified_user,
      route: '/admin/approvals',
      allowedModes: ['ADMIN'],
      requiredCapabilities: ['business.approve'],
      navigationPosition: 1,
    ),
    FeatureModule(
      featureKey: 'admin_users',
      title: '회원 관리',
      icon: Icons.people,
      route: '/admin/users',
      allowedModes: ['ADMIN'],
      requiredCapabilities: ['user.manage'],
      navigationPosition: 2,
    ),
    FeatureModule(
      featureKey: 'admin_stores',
      title: '전체 매장',
      icon: Icons.storefront,
      route: '/admin/stores',
      allowedModes: ['ADMIN'],
      requiredCapabilities: ['store.manage_all'],
      navigationPosition: 3,
    ),
  ];
}
