import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/build_info.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';

import '../providers/app_mode_provider.dart';
import '../registries/dashboard_widget_registry.dart';
import '../services/business_service.dart';
import '../services/reservation_service.dart';
import '../theme/business_theme.dart';
import 'business_store_screen.dart';
import 'business_products_screen.dart';
import 'business_reviews_screen.dart';
import 'business_reservations_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final BusinessService _businessService = BusinessService();

  bool _isLoading = true;
  String _storeName = '매장';
  String _storeStatus = '영업중';
  int _totalProducts = 0;
  int _activeProducts = 0;
  int _totalReviews = 0;
  double _avgRating = 0.0;

  int _todayReservations = 0;
  int _pendingReservations = 0;
  int _completedReservations = 0;
  bool _reservationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final storeRes = await _businessService.getManagedStore().catchError(
        (_) => <String, dynamic>{},
      );
      final store = (storeRes['store'] as Map<String, dynamic>?) ?? {};

      final products = await _businessService.getProducts().catchError(
        (_) => <Map<String, dynamic>>[],
      );
      final reviewsRes = await _businessService.getReviews().catchError(
        (_) => <String, dynamic>{},
      );

      int todayCount = 0;
      int pendingCount = 0;
      int completedCount = 0;
      bool resEnabled = false;

      final storeId = store['id'] as String?;
      if (storeId != null && storeId.isNotEmpty) {
        try {
          final resList = await ReservationService()
              .getBusinessStoreReservations(storeId);
          final options = await ReservationService()
              .getBusinessReservationSettings(storeId);
          resEnabled = options['reservations_enabled'] as bool? ?? false;

          final todayStr = DateTime.now().toIso8601String().substring(0, 10);
          for (var r in resList) {
            final map = r as Map<String, dynamic>;
            final date = map['reservation_date'] as String? ?? '';
            final status = map['status'] as String? ?? '';
            final statusUpper = status.toUpperCase();

            if (date == todayStr) todayCount++;
            if (statusUpper == 'PENDING') pendingCount++;
            if (statusUpper == 'APPROVED' ||
                statusUpper == 'CONFIRMED' ||
                statusUpper == 'COMPLETED') {
              completedCount++;
            }
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _storeName = store['name'] as String? ?? '매장';
          _storeStatus = store['status'] as String? ?? '영업중';
          _totalProducts = products.length;
          _activeProducts = products
              .where((p) => p['status'] == 'ACTIVE')
              .length;
          _totalReviews = reviewsRes['total_count'] as int? ?? 0;
          _avgRating =
              (reviewsRes['average_rating'] as num?)?.toDouble() ?? 0.0;
          _todayReservations = todayCount;
          _pendingReservations = pendingCount;
          _completedReservations = completedCount;
          _reservationsEnabled = resEnabled;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onWidgetTap(DashboardWidgetDefinition widgetDef) {
    if (!widgetDef.available) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('[${widgetDef.title}] 기능은 현재 준비 중입니다.'),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    Widget? screen;
    switch (widgetDef.widgetKey) {
      case 'store_status':
        screen = const BusinessStoreScreen();
        break;
      case 'registered_products':
      case 'active_products':
        screen = const BusinessProductsScreen();
        break;
      case 'total_reviews':
      case 'average_rating':
        screen = const BusinessReviewsScreen();
        break;
      case 'today_reservations':
        screen = const BusinessReservationsScreen(initialFilter: 'TODAY');
        break;
      case 'pending_reservations':
        screen = const BusinessReservationsScreen(initialFilter: 'PENDING');
        break;
      case 'completed_reservations':
        screen = const BusinessReservationsScreen(initialFilter: 'APPROVED');
        break;
      case 'reservation_settings':
        screen = const BusinessReservationsScreen(initialTabIndex: 1);
        break;
    }

    if (screen != null) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => screen!))
          .then((_) => _fetchDashboardData());
    }
  }

  String _getWidgetDisplayValue(String key) {
    switch (key) {
      case 'store_status':
        return _storeStatus;
      case 'registered_products':
        return '$_totalProducts 개';
      case 'active_products':
        return '$_activeProducts 개';
      case 'total_reviews':
        return '$_totalReviews 개';
      case 'average_rating':
        return _avgRating > 0 ? '★ ${_avgRating.toStringAsFixed(1)}' : '0.0';
      case 'today_reservations':
        return '$_todayReservations 건';
      case 'pending_reservations':
        return '$_pendingReservations 건';
      case 'completed_reservations':
        return '$_completedReservations 건';
      case 'reservation_settings':
        return _reservationsEnabled ? '사용 중' : '꺼짐';
      default:
        return '준비 중';
    }
  }

  Widget _buildBuildInfoFooter(User? user) {
    final userRoles = user?.roles.join(', ') ?? 'GUEST';
    const currentMode = 'BUSINESS';
    final switchAvailable = user == null || user.hasRole('CUSTOMER');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            '앱 빌드: ${BuildInfo.appBuildName}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Commit: ${BuildInfo.commitHash} (${BuildInfo.appBuildName})',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Text(
            'Build time: ${BuildInfo.buildTime}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),

          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blueGrey[200]!),
            ),
            child: Column(
              children: [
                Text(
                  'Roles: $userRoles',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.blueGrey[800],
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Current mode: $currentMode',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[800]),
                ),
                Text(
                  'Mode switch available: $switchAvailable',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey[800]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);
    final user = authProvider.currentUser;

    final memberships = user?.businessMemberships ?? [];
    final activeStoreId = memberships.isNotEmpty
        ? (memberships.first as Map)['store_id']
        : null;

    final availableWidgets = DashboardWidgetRegistry.businessWidgets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('사업자 대시보드'),
        actions: [
          if (user == null || user.hasRole('CUSTOMER'))
            InkWell(
              onTap: () {
                final modeProvider = Provider.of<AppModeProvider>(
                  context,
                  listen: false,
                );
                final authProvider = Provider.of<AuthProvider>(
                  context,
                  listen: false,
                );
                modeProvider.switchMode(
                  AppMode.customer,
                  authProvider.currentUser,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.swap_horiz, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      '이용자 모드',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchDashboardData,
          ),
        ],
      ),

      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _fetchDashboardData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Card(
                elevation: 2,
                color: BusinessTheme.primaryTeal.withValues(alpha: 0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: BusinessTheme.primaryTeal,
                        radius: 24,
                        child: const Icon(Icons.store, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _storeName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '매장 ID: ${activeStoreId ?? '미연결'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                '매장 현황 및 관리',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                      itemCount: availableWidgets.length,
                      itemBuilder: (context, index) {
                        final widgetDef = availableWidgets[index];
                        final displayVal = _getWidgetDisplayValue(
                          widgetDef.widgetKey,
                        );

                        return InkWell(
                          onTap: () => _onWidgetTap(widgetDef),
                          borderRadius: BorderRadius.circular(12),
                          child: Card(
                            elevation: widgetDef.available ? 2 : 1,
                            color: widgetDef.available
                                ? Colors.white
                                : Colors.grey[100],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: widgetDef.available
                                    ? BusinessTheme.primaryTeal.withValues(
                                        alpha: 0.3,
                                      )
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        widgetDef.icon,
                                        color: widgetDef.available
                                            ? BusinessTheme.primaryTeal
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          widgetDef.title,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: widgetDef.available
                                                ? Colors.black87
                                                : Colors.grey[600],
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    widgetDef.available ? displayVal : '준비 중',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: widgetDef.available
                                          ? BusinessTheme.darkSlate
                                          : Colors.grey,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        widgetDef.statusText,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: widgetDef.available
                                              ? BusinessTheme.primaryTeal
                                              : Colors.grey,
                                          fontWeight: widgetDef.available
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (widgetDef.available)
                                        const Icon(
                                          Icons.chevron_right,
                                          size: 16,
                                          color: Colors.grey,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              _buildBuildInfoFooter(user),
            ],
          ),
        ),
      ),
    );
  }
}
