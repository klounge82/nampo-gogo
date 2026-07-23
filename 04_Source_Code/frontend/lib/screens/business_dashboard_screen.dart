import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../registries/dashboard_widget_registry.dart';
import '../services/business_service.dart';
import '../theme/business_theme.dart';
import 'business_store_screen.dart';
import 'business_products_screen.dart';
import 'business_reviews_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
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

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final storeRes = await _businessService.getManagedStore().catchError((_) => <String, dynamic>{});
      final store = (storeRes['store'] as Map<String, dynamic>?) ?? {};

      final products = await _businessService.getProducts().catchError((_) => <Map<String, dynamic>>[]);

      final reviewsRes = await _businessService.getReviews().catchError((_) => <String, dynamic>{});

      if (mounted) {
        setState(() {
          _storeName = store['name'] as String? ?? '매장';
          _storeStatus = store['status'] as String? ?? '영업중';
          _totalProducts = products.length;
          _activeProducts = products.where((p) => p['status'] == 'ACTIVE').length;
          _totalReviews = reviewsRes['total_count'] as int? ?? 0;
          _avgRating = (reviewsRes['average_rating'] as num?)?.toDouble() ?? 0.0;
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
    }

    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen!),
      ).then((_) => _fetchDashboardData());
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
      default:
        return '준비 중';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final modeProvider = Provider.of<AppModeProvider>(context);
    final user = authProvider.currentUser;

    final memberships = user?.businessMemberships ?? [];
    final activeStoreId = memberships.isNotEmpty
        ? memberships.first['store_id']
        : '미연결 매장';

    return Scaffold(
      appBar: AppBar(
        title: const Text('사업자 관리 대시보드'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDashboardData,
          ),
          TextButton.icon(
            onPressed: () {
              modeProvider.switchMode(AppMode.customer, user);
            },
            icon: const Icon(Icons.swap_horiz, color: Colors.white),
            label: const Text(
              '이용자 모드',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Header Card
              Card(
                color: BusinessTheme.primaryTeal,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.store, color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _storeName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${user?.nickname ?? '대표'}님 (승인 사업자)',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _storeStatus,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '관리 매장 ID: $activeStoreId',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                '운영 정보 현황',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Dashboard Widgets Grid
              _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
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
                      itemCount: DashboardWidgetRegistry.businessWidgets.length,
                      itemBuilder: (context, index) {
                        final widgetDef =
                            DashboardWidgetRegistry.businessWidgets[index];
                        final displayVal =
                            _getWidgetDisplayValue(widgetDef.widgetKey);

                        return Card(
                          elevation: widgetDef.available ? 2 : 0.5,
                          color: widgetDef.available
                              ? Colors.white
                              : Colors.grey[100],
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _onWidgetTap(widgetDef),
                            child: Padding(
                              padding: const EdgeInsets.all(14.0),
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
                                      fontSize: 18,
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
            ],
          ),
        ),
      ),
    );
  }
}
