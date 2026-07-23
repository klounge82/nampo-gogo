import 'package:flutter/material.dart';

class DashboardWidgetDefinition {
  final String widgetKey;
  final String title;
  final IconData icon;
  final bool available;
  final String statusText;

  const DashboardWidgetDefinition({
    required this.widgetKey,
    required this.title,
    required this.icon,
    this.available = true,
    this.statusText = '정상',
  });
}

class DashboardWidgetRegistry {
  static const List<DashboardWidgetDefinition> businessWidgets = [
    DashboardWidgetDefinition(
      widgetKey: 'today_reservations',
      title: '오늘 예약',
      icon: Icons.today,
      available: true,
      statusText: '데이터 수집 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'pending_reservations',
      title: '처리 대기 예약',
      icon: Icons.pending_actions,
      available: true,
      statusText: '데이터 수집 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'average_rating',
      title: '평균 평점',
      icon: Icons.star,
      available: true,
      statusText: '실시간 반영',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'total_reviews',
      title: '손님 리뷰 수',
      icon: Icons.comment,
      available: true,
      statusText: '실시간 반영',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'registered_products',
      title: '등록 상품 수',
      icon: Icons.inventory_2,
      available: false,
      statusText: '준비 중',
    ),
    DashboardWidgetDefinition(
      widgetKey: 'recommendation_count',
      title: 'AI 노출 횟수',
      icon: Icons.auto_awesome,
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
      title: '등록 매장 수',
      icon: Icons.store,
      available: true,
    ),
  ];
}
