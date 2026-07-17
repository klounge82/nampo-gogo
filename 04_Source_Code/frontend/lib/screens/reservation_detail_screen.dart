import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/reservation.dart';
import '../repositories/reservation_repository.dart';
import '../providers/auth_provider.dart';
import 'payment_screen.dart';

class ReservationDetailScreen extends StatefulWidget {
  final String reservationId;

  const ReservationDetailScreen({super.key, required this.reservationId});

  @override
  State<ReservationDetailScreen> createState() => _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  final ReservationRepository _reservationRepository = ReservationRepository();
  Reservation? _reservation;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReservationDetail();
  }

  Future<void> _loadReservationDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _reservationRepository.getReservationDetail(widget.reservationId);
      setState(() {
        _reservation = res;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _performCancel() async {
    if (_reservation == null) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    // Show indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final success = await _reservationRepository.cancelReservation(_reservation!.id, userId: userId);
      Navigator.of(context).pop(); // Dismiss indicator

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 예약 취소가 정상 처리되었습니다.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(true); // Return to list with refresh signal
      } else {
        _showErrorDialog('취소 실패', '예약 취소 중 서버 에러가 발생했습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss indicator
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('취소 실패', cleanMsg);
    }
  }

  void _confirmCancel() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('예약 취소', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
        content: const Text('정말로 이 매장 예약을 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('유지하기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performCancel();
            },
            child: const Text('취소하기', style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary)),
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

  @override
  Widget build(BuildContext context) {
    final res = _reservation;
    final timeStr = res != null 
        ? '${res.reservationTime.year}.${res.reservationTime.month.toString().padLeft(2, '0')}.${res.reservationTime.day.toString().padLeft(2, '0')} ${res.reservationTime.hour.toString().padLeft(2, '0')}:${res.reservationTime.minute.toString().padLeft(2, '0')}'
        : '';
    final isCancellable = res != null && (res.status == 'pending' || res.status == 'confirmed');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('예약 상세 정보', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('상세를 불러오지 못했습니다: $_errorMessage'),
                      const SizedBox(height: 16.0),
                      ElevatedButton(onPressed: _loadReservationDetail, child: const Text('다시 시도')),
                    ],
                  ),
                )
              : res == null
                  ? const Center(child: Text('예약 정보가 존재하지 않습니다.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status Header Card
                          _buildStatusHeaderCard(res),
                          const SizedBox(height: 20.0),
                          
                          // Reservation Ticket Info
                          const Text('예약 명세서', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8.0),
                          _buildTicketCard(res, timeStr),
                          const SizedBox(height: 24.0),
                          
                          // Store Address Card
                          const Text('오시는 길', style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const SizedBox(height: 8.0),
                          _buildAddressCard(res),
                          const SizedBox(height: 32.0),
                          
                          // Deposit Payment Button (pending status)
                          if (res.status == 'pending') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 48.0,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => PaymentScreen(
                                        amount: 15000,
                                        targetType: 'RESERVATION_DEPOSIT',
                                        targetId: res.id,
                                        targetName: '${res.store.name} 예약 보증금 결제',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.payment, size: 18.0),
                                label: const Text('보증금 ₩15,000 결제하고 예약 확정'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                          ],

                          // Cancel Button
                          if (isCancellable)
                            SizedBox(
                              width: double.infinity,
                              height: 48.0,
                              child: ElevatedButton.icon(
                                onPressed: _confirmCancel,
                                icon: const Icon(Icons.cancel_outlined, size: 18.0),
                                label: const Text('예약 신청 취소하기'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.secondary,
                                  side: const BorderSide(color: AppColors.secondary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                                  elevation: 0,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildStatusHeaderCard(Reservation res) {
    String label;
    IconData icon;
    Color color;

    switch (res.status) {
      case 'pending':
        label = '대기 중 (매장에서 확인하고 있습니다)';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
        break;
      case 'confirmed':
        label = '예약 확정 (방문 시 예약을 확인해 주세요)';
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case 'cancelled':
        label = '취소된 예약 내역입니다';
        icon = Icons.cancel_outlined;
        color = Colors.red;
        break;
      case 'completed':
        label = '이용 완료된 매장입니다';
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      default:
        label = '대기 중';
        icon = Icons.hourglass_empty;
        color = Colors.orange;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24.0),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 13.0, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(Reservation res, String timeStr) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('매장명', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    Text(res.store.name, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('예약 일시', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    Text(timeStr, style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('예약 인원', style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary)),
                    Text('${res.partySize} 명', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          
          // Fake dotted divider line
          Row(
            children: List.generate(30, (index) {
              return Expanded(
                child: Container(
                  height: 1.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  color: Colors.grey.shade300,
                ),
              );
            }),
          ),
          
          // Fake Barcode section
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(28, (index) {
                    final isWide = index % 4 == 0 || index % 5 == 0;
                    return Container(
                      width: isWide ? 4.5 : 1.5,
                      height: 50.0,
                      color: res.status == 'cancelled' ? Colors.grey.shade400 : Colors.black87,
                    );
                  }),
                ),
                const SizedBox(height: 8.0),
                Text(
                  'RES-${res.id.replaceAll('-', '').substring(0, 12).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10.0, 
                    letterSpacing: 2.0, 
                    fontWeight: FontWeight.bold,
                    color: res.status == 'cancelled' ? Colors.grey : AppColors.textPrimary
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Reservation res) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20.0),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  res.store.address,
                  style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          const Text(
            '지하철 자갈치역 5번 출구에서 도보 약 3분 거리에 위치하고 있습니다. 방문 시 예약을 확인해 주세요.',
            style: TextStyle(fontSize: 11.0, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }
}
