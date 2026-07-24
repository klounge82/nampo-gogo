import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/mission.dart';
import '../repositories/mission_repository.dart';
import 'place_detail_screen.dart';
import 'qr_scanner_screen.dart';

class MissionDetailScreen extends StatefulWidget {
  final String missionId;

  const MissionDetailScreen({super.key, required this.missionId});

  @override
  State<MissionDetailScreen> createState() => _MissionDetailScreenState();
}

class _MissionDetailScreenState extends State<MissionDetailScreen> {
  final MissionRepository _missionRepository = MissionRepository();

  Mission? _mission;
  bool _isLoading = true;
  bool _isAuthenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMissionDetail();
  }

  Future<void> _loadMissionDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mission = await _missionRepository.getMissionDetail(
        widget.missionId,
      );
      setState(() {
        _mission = mission;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _triggerAuth(Mission mission) async {
    if (mission.authType == 'QR') {
      final scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      );
      if (scannedCode != null && scannedCode.isNotEmpty) {
        _performQRVerification(mission, scannedCode);
      }
      return;
    }

    // Default mock auth for GPS and PHOTO in MVP
    setState(() => _isAuthenticating = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isAuthenticating = false);

    _showSuccessDialog(context, mission.points);
  }

  Future<void> _performQRVerification(Mission mission, String qrCode) async {
    setState(() => _isAuthenticating = true);
    try {
      final res = await _missionRepository.verifyMission(mission.id, qrCode);
      if (!mounted) return;

      setState(() => _isAuthenticating = false);
      if (res['success'] == true) {
        _showSuccessDialog(context, res['points_awarded'] as int);
      } else {
        _showErrorDialog('인증 실패', res['message'] as String? ?? '검증 오류');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);

      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('인증 실패', cleanMsg);
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showSuccessDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '🎉 미션 완료!',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('남포 GoGo 미션 인증에 성공했습니다!'),
            const SizedBox(height: 20.0),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.2, end: 1.0),
              duration: const Duration(milliseconds: 1000),
              curve: Curves.elasticOut,
              builder: (context, scale, child) {
                return Transform.scale(scale: scale, child: child);
              },
              child: Text(
                '+$points P',
                style: const TextStyle(
                  fontSize: 36.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ),
            const SizedBox(height: 10.0),
            const Text(
              '포인트 지급이 완료되었습니다.',
              style: TextStyle(fontSize: 11.0, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: const Text(
                '확인',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _mission?.title ?? '미션 상세',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48.0,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadMissionDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: const Text(
                        '다시 시도',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _buildContent(context, _mission!),
    );
  }

  Widget _buildContent(BuildContext context, Mission mission) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Simulated Trophy Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 36.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  size: 72.0,
                  color: AppColors.secondary,
                ),
                const SizedBox(height: 14.0),
                Text(
                  mission.title,
                  style: const TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildBadge(
                      AppColors.secondary.withAlpha(26),
                      AppColors.secondary,
                      '${mission.points} P 지급',
                    ),
                    const SizedBox(width: 8.0),
                    _buildBadge(
                      AppColors.primary.withAlpha(26),
                      AppColors.primary,
                      _getAuthTypeText(mission.authType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Mission Specs Detail Card
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '미션 수행 방법',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  mission.description,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18.0),

                const Text(
                  '참고 사항',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6.0),
                const Text(
                  '• 한 번 완료한 미션은 당일 재도전이 불가능합니다.\n• 허위 사진 업로드 및 부당한 방법으로 인증 시 포인트가 회수될 수 있습니다.',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textHint,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

          // Related Store Navigation Card
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 0,
            color: AppColors.surface,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.store,
                  color: AppColors.primary,
                  size: 28.0,
                ),
                title: const Text(
                  '관련 매장 정보 보기',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: const Text(
                  '미션을 수행할 매장의 상세 위치 및 주소를 확인합니다.',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textSecondary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaceDetailScreen(placeId: mission.storeId),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 28.0),

          // Perform Authenticate Trigger Button
          ElevatedButton(
            onPressed: _isAuthenticating ? null : () => _triggerAuth(mission),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: _isAuthenticating
                ? const SizedBox(
                    width: 24.0,
                    height: 24.0,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    _getActionButtonLabel(mission.authType),
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(Color bgColor, Color textColor, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _getAuthTypeText(String authType) {
    switch (authType) {
      case 'GPS':
        return '위치(GPS) 인증';
      case 'QR':
        return 'QR 스캔 인증';
      case 'PHOTO':
        return '사진 업로드 인증';
      default:
        return '인증 수행';
    }
  }

  String _getActionButtonLabel(String authType) {
    switch (authType) {
      case 'GPS':
        return '📍 현재 위치 인증하기';
      case 'QR':
        return '🔍 QR 코드 촬영하기';
      case 'PHOTO':
        return '📸 인증 사진 업로드하기';
      default:
        return '🎉 미션 완료 인증하기';
    }
  }
}
