import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_mode_provider.dart';
import '../registries/dashboard_widget_registry.dart';
import '../theme/business_theme.dart';

class BusinessDashboardScreen extends StatelessWidget {
  const BusinessDashboardScreen({super.key});

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
      body: SingleChildScrollView(
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
                          child: Text(
                            '${user?.nickname ?? '대표'}님, 환영합니다!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            '승인 사업자',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '관리 매장 ID: $activeStoreId',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: DashboardWidgetRegistry.businessWidgets.length,
              itemBuilder: (context, index) {
                final widgetDef =
                    DashboardWidgetRegistry.businessWidgets[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              widgetDef.icon,
                              color: BusinessTheme.primaryTeal,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widgetDef.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          widgetDef.available ? '0 건' : '준비 중',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widgetDef.available
                                ? Colors.black87
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          widgetDef.statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: widgetDef.available
                                ? BusinessTheme.secondarySlate
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
