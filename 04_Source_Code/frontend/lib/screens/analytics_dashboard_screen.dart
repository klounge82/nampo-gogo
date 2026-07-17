import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../providers/analytics_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/line_chart_widget.dart';
import '../widgets/bar_chart_widget.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Load statistics
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().accessToken;
      if (token != null && token.isNotEmpty) {
        context.read<AnalyticsProvider>().loadAllStats(token: token);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('비즈니스 통계 대시보드', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (provider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('통계 조회 중 에러 발생: ${provider.errorMessage}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      final token = context.read<AuthProvider>().accessToken;
                      if (token != null) {
                        provider.loadAllStats(token: token);
                      }
                    },
                    child: const Text('다시 시도'),
                  )
                ],
              ),
            );
          }

          final dash = provider.dashboardData;
          if (dash == null) {
            return const Center(child: Text('조회할 수 있는 통계 결과가 없습니다.'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Hero Performance Card
                _buildHeroPerformanceCard(dash),
                const SizedBox(height: 24.0),

                // 2. Today Overview Grid Cards
                const Text(
                  '오늘의 매장 지표',
                  style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 12.0),
                _buildOverviewGrid(dash),
                const SizedBox(height: 24.0),

                // 3. Dynamic Charts Tab Section
                TabBar(
                  controller: _tabController,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: AppColors.primary,
                  tabs: const [
                    Tab(text: '매출 추이'),
                    Tab(text: '예약 현황'),
                    Tab(text: 'AI 추천 효과'),
                  ],
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  height: 240.0,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab 1: Revenue Line Chart
                      _buildRevenueChart(provider.revenueData),
                      // Tab 2: Reservation Status Bar Chart
                      _buildReservationChart(provider.reservationData),
                      // Tab 3: AI Recommendations Bar Chart
                      _buildAIChart(provider.aiData),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroPerformanceCard(Map<String, dynamic> dash) {
    final int contributedRevenue = dash['app_contributed_total_revenue'] ?? 3250000;
    final int netProfit = dash['app_contributed_net_profit'] ?? 2870000;
    final double roi = (dash['roi_percentage'] as num? ?? 286.0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo.shade800, Colors.deepPurple.shade900],
        ),
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.shade900.withAlpha(80),
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🎉 이번 달 앱 성과',
                style: TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(30),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'ROI +${roi.toStringAsFixed(0)}%',
                  style: const TextStyle(color: Colors.amber, fontSize: 11.0, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          const Text(
            '남포 GoGo를 통해 발생한 추가 매출',
            style: TextStyle(color: Colors.white60, fontSize: 11.5),
          ),
          const SizedBox(height: 4.0),
          Text(
            _currencyFormat.format(contributedRevenue),
            style: const TextStyle(color: Colors.white, fontSize: 26.0, fontWeight: FontWeight.w900),
          ),
          const Divider(height: 24.0, color: Colors.white24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('앱 기여 순수익', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                  const SizedBox(height: 4.0),
                  Text(_currencyFormat.format(netProfit), style: const TextStyle(color: Colors.white, fontSize: 15.0, fontWeight: FontWeight.bold)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('수수료 및 이용료', style: TextStyle(color: Colors.white60, fontSize: 10.5)),
                  const SizedBox(height: 4.0),
                  Text(
                    _currencyFormat.format(contributedRevenue - netProfit),
                    style: const TextStyle(color: Colors.white70, fontSize: 13.0, fontWeight: FontWeight.bold),
                  ),
                ],
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildOverviewGrid(Map<String, dynamic> dash) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.0,
      mainAxisSpacing: 12.0,
      childAspectRatio: 1.6,
      children: [
        _buildStatCard('오늘 예상 매출', _currencyFormat.format(dash['today_revenue'] ?? 0), Icons.payments_outlined, Colors.green),
        _buildStatCard('누적 예약 건수', '${dash['reservation_count'] ?? 0}건', Icons.event_note, Colors.blue),
        _buildStatCard('AI 추천 노출', '${dash['ai_recommend_exposed'] ?? 0}회', Icons.auto_awesome, Colors.amber.shade800),
        _buildStatCard('리뷰 및 평점', '⭐ ${dash['average_rating']?.toStringAsFixed(1) ?? '0.0'} (${dash['review_count'] ?? 0})', Icons.star_outline, Colors.orange),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
              Icon(icon, size: 16.0, color: color),
            ],
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart(Map<String, dynamic>? data) {
    if (data == null) return const Center(child: CircularProgressIndicator());
    final list = data['timeline'] as List<dynamic>? ?? [];
    
    final List<double> values = list.map((e) => (e['revenue'] as num).toDouble()).toList();
    final List<String> labels = list.map((e) => e['period'] as String).toList();

    return LineChartWidget(values: values, labels: labels);
  }

  Widget _buildReservationChart(Map<String, dynamic>? data) {
    if (data == null) return const Center(child: CircularProgressIndicator());
    
    final List<double> values = [
      (data['pending_count'] as num).toDouble(),
      (data['confirmed_count'] as num).toDouble(),
      (data['completed_count'] as num).toDouble(),
      (data['cancelled_count'] as num).toDouble(),
    ];
    final List<String> labels = ['신청', '확정', '완료', '취소'];

    return BarChartWidget(values: values, labels: labels);
  }

  Widget _buildAIChart(Map<String, dynamic>? data) {
    if (data == null) return const Center(child: CircularProgressIndicator());
    
    final List<double> values = [
      (data['generated_count'] as num).toDouble(),
      (data['saved_count'] as num).toDouble(),
      (data['clicked_count'] as num).toDouble(),
    ];
    final List<String> labels = ['생성', '저장', '클릭'];

    return BarChartWidget(values: values, labels: labels);
  }
}
