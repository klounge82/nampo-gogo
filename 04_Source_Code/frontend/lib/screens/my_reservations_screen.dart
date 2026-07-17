import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';
import '../providers/auth_provider.dart';
import 'reservation_detail_screen.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen> with SingleTickerProviderStateMixin {
  final ReservationRepository _reservationRepository = ReservationRepository();
  late TabController _tabController;

  List<Reservation> _activeReservations = [];
  List<Reservation> _pastReservations = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReservations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final list = await _reservationRepository.getUserReservations(userId: userId);
      
      // Separate active vs past
      final active = list.where((r) => r.status == 'pending' || r.status == 'confirmed').toList();
      final past = list.where((r) => r.status == 'cancelled' || r.status == 'completed').toList();

      setState(() {
        _activeReservations = active;
        _pastReservations = past;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('내 예약 내역', style: TextStyle(fontWeight: FontWeight.bold)),
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
            Tab(text: '진행 중인 예약'),
            Tab(text: '지난 예약 내역'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('예약 정보를 불러오지 못했습니다: $_errorMessage'),
                      const SizedBox(height: 16.0),
                      ElevatedButton(onPressed: _loadReservations, child: const Text('다시 시도')),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildReservationTabList(_activeReservations, isActive: true),
                    _buildReservationTabList(_pastReservations, isActive: false),
                  ],
                ),
    );
  }

  Widget _buildReservationTabList(List<Reservation> list, {required bool isActive}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isActive ? '진행 중인 예약 신청이 없습니다.' : '지난 예약 신청 내역이 없습니다.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReservations,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildReservationCard(item);
        },
      ),
    );
  }

  Widget _buildReservationCard(Reservation res) {
    final timeStr = '${res.reservationTime.year}.${res.reservationTime.month.toString().padLeft(2, '0')}.${res.reservationTime.day.toString().padLeft(2, '0')} ${res.reservationTime.hour.toString().padLeft(2, '0')}:${res.reservationTime.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () async {
        final needRefresh = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ReservationDetailScreen(reservationId: res.id),
          ),
        );
        if (needRefresh == true) {
          _loadReservations();
        }
      },
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Icon Decorator
              Container(
                width: 48.0,
                height: 48.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Center(
                  child: Icon(Icons.storefront, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 16.0),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      res.store.name,
                      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      '예약 시간: $timeStr',
                      style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2.0),
                    Text(
                      '인원수: ${res.partySize} 명',
                      style: const TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              _buildStatusBadge(res.status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pending':
        bgColor = Colors.orange.withAlpha(30);
        textColor = Colors.orange.shade700;
        label = '대기 중';
        break;
      case 'confirmed':
        bgColor = Colors.green.withAlpha(30);
        textColor = Colors.green.shade700;
        label = '예약확정';
        break;
      case 'cancelled':
        bgColor = Colors.red.withAlpha(30);
        textColor = Colors.red.shade700;
        label = '취소됨';
        break;
      case 'completed':
        bgColor = Colors.blue.withAlpha(30);
        textColor = Colors.blue.shade700;
        label = '이용완료';
        break;
      default:
        bgColor = Colors.grey.withAlpha(30);
        textColor = Colors.grey;
        label = '대기 중';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.0, fontWeight: FontWeight.bold, color: textColor),
      ),
    );
  }
}
