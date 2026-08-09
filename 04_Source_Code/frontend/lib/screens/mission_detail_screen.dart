import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/mission.dart';
import '../repositories/mission_repository.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
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
  String? _lastLocaleCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLoc = context.watch<LocaleProvider>().currentLocaleCode;
    if (_lastLocaleCode != currentLoc) {
      _lastLocaleCode = currentLoc;
      _loadMissionDetail();
    }
  }

  Future<void> _loadMissionDetail() async {
    final localeCode = context.read<LocaleProvider>().currentLocaleCode;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final mission = await _missionRepository.getMissionDetail(
        widget.missionId,
        locale: localeCode,
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

    // Server-enforced verification for GPS & PHOTO missions
    _performServerVerification(mission);
  }

  Future<void> _performServerVerification(Mission mission) async {
    setState(() => _isAuthenticating = true);
    try {
      final token = mission.authType == 'GPS' ? 'GPS_VERIFIED_TOKEN' : 'PHOTO_VERIFIED_TOKEN';
      final res = await _missionRepository.verifyMission(mission.id, token);
      if (!mounted) return;

      setState(() => _isAuthenticating = false);
      if (res['success'] == true) {
        _showSuccessDialog(context, res['points_awarded'] as int);
      } else {
        _showErrorDialog('인증 실패', res['message'] as String? ?? '서버 검증 오류');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isAuthenticating = false);

      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('인증 실패', cleanMsg);
    }
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
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.confirmOk),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, int points) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🎉 미션 완료!', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('축하합니다! 미션을 완수하여 $points P가 지급되었습니다.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.confirmOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _mission?.title ?? l10n.missionDetailTitle,
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
                      l10n.mapLoadFail,
                      style: const TextStyle(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _loadMissionDetail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      child: Text(
                        l10n.btnRetry,
                        style: const TextStyle(color: Colors.white),
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                      '+${mission.points} P',
                    ),
                    const SizedBox(width: 8.0),
                    _buildBadge(
                      AppColors.primary.withAlpha(26),
                      AppColors.primary,
                      L10nMappers.mapMissionAuthType(l10n, mission.authType),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

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
                Text(
                  l10n.missionHowTo,
                  style: const TextStyle(
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

                Text(
                  l10n.missionNotes,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  l10n.missionNotesDesc,
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textHint,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),

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
                title: Text(
                  l10n.missionRelatedStore,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  l10n.missionRelatedStoreSub,
                  style: const TextStyle(
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
                    _getActionButtonLabel(l10n, mission.authType),
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

  String _getActionButtonLabel(AppLocalizations l10n, String authType) {
    switch (authType) {
      case 'GPS':
        return '📍 ${l10n.missionAuthActionGps}';
      case 'QR':
        return '🔍 ${l10n.missionAuthActionQr}';
      case 'PHOTO':
        return '📸 ${l10n.missionAuthActionPhoto}';
      default:
        return '🎉 ${l10n.missionStartAction}';
    }
  }
}
