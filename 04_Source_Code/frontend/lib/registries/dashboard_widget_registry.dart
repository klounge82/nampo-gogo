import 'package:flutter/material.dart';

class DashboardWidgetDefinition {
  final String widgetKey;
  final String title;
  final IconData icon;
  final bool available;
  final String statusText;
  final String? targetRoute;

  const DashboardWidgetDefinition({
    required this.widgetKey,
    required this.title,
    required this.icon,
    this.available = true,
    this.statusText = '실시간 반영',
    this.targetRoute,
  });
}

class DashboardWidgetRegistry {
  static const List<DashboardWidgetDefinition> businessWidgets = [
    DashboardWidgetDefinition(
      widgetKey: 'store_status',
      title: '매장 운영 상태',
      icon: Icons.storefront,
      available: true,
      statusText: '매장 관리',
      targetRoute: '/business/store',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'registered_products',
      title: '등록 상품 수',
      icon: Icons.inventory_2,
      available: true,
      statusText: '상품 관리',
      targetRoute: '/business/products',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'active_products',
      title: '판매 중 상품 수',
      icon: Icons.shopping_bag,
      available: true,
      statusText: '상품 관리',
      targetRoute: '/business/products',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'total_reviews',
      title: '공개 리뷰 수',
      icon: Icons.rate_review,
      available: true,
      statusText: '리뷰 관리',
      targetRoute: '/business/reviews',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'average_rating',
      title: '평균 평점',
      icon: Icons.star,
      available: true,
      statusText: '리뷰 관리',
      targetRoute: '/business/reviews',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'today_reservations',
      title: '오늘 예약',
      icon: Icons.today,
      available: false,
      statusText: '준비 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'pending_reservations',
      title: '처리 대기 예약',
      icon: Icons.pending_actions,
      available: false,
      statusText: '기능 비활성화',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'recommendation_count',
      title: '추천받은 횟수',
      icon: Icons.thumb_up,
      available: false,
      statusText: '준비 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'business_events',
      title: '이벤트',
      icon: Icons.event,
      available: false,
      statusText: '준비 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'business_settlement',
      title: '정산',
      icon: Icons.account_balance_wallet,
      available: false,
      statusText: '준비 중',
    ),
  ];

  static const List<DashboardWidgetDefinition> customerWidgets = [
    DashboardWidgetDefinition(
      widgetKey: 'recent_places',
      title: '최근 본 장소',
      icon: Icons.history,
      available: true,
    ),
    DashboardWidgetDefinition(
      widgetKey: 'saved_places',
      title: '즐겨찾기 장소',
      icon: Icons.bookmark,
      available: true,
    ),
    DashboardWidgetDefinition(
      widgetKey: 'saved_courses',
      title: '저장 코스',
      icon: Icons.map,
      available: true,
    ),
  ];

  static const List<DashboardWidgetDefinition> adminWidgets = [
    DashboardWidgetDefinition(
      widgetKey: 'pending_applications',
      title: '승인 대기 사업자',
      icon: Icons.badge,
      available: true,
    ),
    DashboardWidgetDefinition(
      widgetKey: 'total_members',
      title: '전체 회원 수',
      icon: Icons.group,
      available: true,
    ),
    DashboardWidgetDefinition(
      widgetKey: 'total_stores',
      title: '전체 매장 수',
      icon: Icons.store,
      available: true,
    ),
  ];
}
