import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/colors.dart';
import '../config/production_config.dart';
import '../l10n/app_localizations.dart';

enum CameraPermissionStatusState {
  checking,
  granted,
  denied,
  permanentlyDenied,
}

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> with WidgetsBindingObserver {
  late MobileScannerController _controller;
  bool _hasDetected = false;
  bool _isStarting = false;
  bool _isRetrying = false;
  bool _isDisposed = false;
  CameraPermissionStatusState _permissionState = CameraPermissionStatusState.checking;
  String? _initErrorMessage;
  MobileScannerErrorCode? _errorCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initController();
    _checkAndRequestPermission();
  }

  void _initController() {
    _controller = MobileScannerController(
      autoStart: true,
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_isDisposed) return;

    if (state == AppLifecycleState.resumed) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] APP_RESUMED, permissionState=$_permissionState');
      }
      if (_permissionState == CameraPermissionStatusState.permanentlyDenied ||
          _permissionState == CameraPermissionStatusState.denied) {
        _checkAndRequestPermission(silent: true);
      } else if (_permissionState == CameraPermissionStatusState.granted &&
          _initErrorMessage == null &&
          !_isStarting) {
        _schedulePostFrameStart();
      }
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] APP_PAUSED_OR_INACTIVE');
      }
      _stopControllerSafely();
    }
  }

  Future<void> _checkAndRequestPermission({bool silent = false}) async {
    try {
      final status = await Permission.camera.status;
      if (status.isGranted) {
        if (kDebugMode) {
          print('[QR_CAMERA_DIAGNOSTIC] CAMERA_PERMISSION_GRANTED');
        }
        if (mounted) {
          setState(() {
            _permissionState = CameraPermissionStatusState.granted;
            _initErrorMessage = null;
            _errorCode = null;
          });
        }
        _schedulePostFrameStart();
        return;
      }

      if (status.isPermanentlyDenied) {
        if (kDebugMode) {
          print('[QR_CAMERA_DIAGNOSTIC] CAMERA_PERMISSION_PERMANENTLY_DENIED');
        }
        if (mounted) {
          setState(() {
            _permissionState = CameraPermissionStatusState.permanentlyDenied;
          });
        }
        return;
      }

      if (!silent) {
        final reqResult = await Permission.camera.request();
        if (reqResult.isGranted) {
          if (kDebugMode) {
            print('[QR_CAMERA_DIAGNOSTIC] CAMERA_PERMISSION_GRANTED_AFTER_REQUEST');
          }
          if (mounted) {
            setState(() {
              _permissionState = CameraPermissionStatusState.granted;
              _initErrorMessage = null;
              _errorCode = null;
            });
          }
          _schedulePostFrameStart();
        } else if (reqResult.isPermanentlyDenied) {
          if (mounted) {
            setState(() {
              _permissionState = CameraPermissionStatusState.permanentlyDenied;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _permissionState = CameraPermissionStatusState.denied;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _permissionState = status.isDenied
                ? CameraPermissionStatusState.denied
                : CameraPermissionStatusState.permanentlyDenied;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CAMERA_PERMISSION_CHECK_FAILED: $e');
      }
      if (mounted) {
        setState(() {
          _permissionState = CameraPermissionStatusState.denied;
        });
      }
    }
  }

  void _schedulePostFrameStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        if (kDebugMode) {
          print('[QR_CAMERA_DIAGNOSTIC] SCANNER_WIDGET_ATTACHED, requesting controller start');
        }
        _startControllerSafely();
      }
    });
  }

  Future<void> _startControllerSafely() async {
    if (_isStarting || _isDisposed) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CONTROLLER_START_SKIPPED (already starting or disposed)');
      }
      return;
    }

    _isStarting = true;
    try {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CONTROLLER_START_REQUEST');
      }
      await _controller.start();
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CONTROLLER_START_SUCCESS');
      }
      if (mounted) {
        setState(() {
          _initErrorMessage = null;
          _errorCode = null;
        });
      }
    } on MobileScannerException catch (e) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CONTROLLER_START_FAILED: errorCode=${e.errorCode}, details=${e.errorDetails}');
      }
      if (mounted) {
        setState(() {
          _errorCode = e.errorCode;
          _initErrorMessage = e.errorDetails?.message ?? e.errorCode.name;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] CONTROLLER_START_FAILED_GENERIC: $e');
      }
      if (mounted) {
        setState(() {
          _initErrorMessage = e.toString();
        });
      }
    } finally {
      _isStarting = false;
    }
  }

  Future<void> _stopControllerSafely() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  Future<void> _handleRetryTapped() async {
    if (_isRetrying || _isDisposed) return;

    if (kDebugMode) {
      print('[QR_CAMERA_DIAGNOSTIC] RETRY_TAPPED');
    }

    setState(() {
      _isRetrying = true;
      _initErrorMessage = null;
      _errorCode = null;
    });

    try {
      await _stopControllerSafely();
      await _controller.dispose();

      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] RETRY_CONTROLLER_RECREATED');
      }
      _initController();

      if (mounted) {
        setState(() {});
      }

      // Allow widget tree to bind new controller before starting
      _schedulePostFrameStart();
    } catch (e) {
      if (kDebugMode) {
        print('[QR_CAMERA_DIAGNOSTIC] RETRY_FAILED: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected || _isDisposed) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrValue = barcodes.first.rawValue;
      if (qrValue != null && qrValue.isNotEmpty) {
        setState(() {
          _hasDetected = true;
        });
        _stopControllerSafely();
        Navigator.of(context).pop(qrValue);
      }
    }
  }

  void _onMockScanPressed() {
    if (!ProductionConfig.enableQrMock || ProductionConfig.isProduction) {
      if (kDebugMode) {
        print('QrScannerScreen: Mock scan rejected by production/security policy.');
      }
      return;
    }
    setState(() {
      _hasDetected = true;
    });
    _stopControllerSafely();
    Navigator.of(context).pop('QR_SUCCESS_TOKEN');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          l10n?.missionAuthActionQr ?? 'QR 코드 스캔',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Camera Preview or Fallback Error/Permission/Retry UI
          _buildCameraPreviewOrState(l10n),

          // 2. Guide Overlay UI (Only if granted & no initialization error & not retrying)
          if (_permissionState == CameraPermissionStatusState.granted &&
              _initErrorMessage == null &&
              !_isRetrying)
            Center(
              child: Container(
                width: 250.0,
                height: 250.0,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 3.0),
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.transparent,
                ),
              ),
            ),

          // 3. Instructions Text (Only if granted & no error & not retrying)
          if (_permissionState == CameraPermissionStatusState.granted &&
              _initErrorMessage == null &&
              !_isRetrying)
            Positioned(
              top: 40.0,
              left: 20.0,
              right: 20.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10.0,
                  horizontal: 16.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: const Text(
                  'K-Lounge 현장 QR을 스캔해 주세요.',
                  style: TextStyle(color: Colors.white, fontSize: 12.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          // 4. Emulator Mock Scan Button Guard
          if (ProductionConfig.enableQrMock)
            Positioned(
              bottom: 30.0,
              left: 32.0,
              right: 32.0,
              child: Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _onMockScanPressed,
                    icon: const Icon(Icons.videogame_asset_outlined),
                    label: const Text('에뮬레이터 모의 스캔 (인증성공)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  const Text(
                    '카메라 스캔이 불가능한 기기에서는 위 모의 스캔 버튼을 사용해 테스트를 진행하실 수 있습니다.',
                    style: TextStyle(color: Colors.white60, fontSize: 10.0),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraPreviewOrState(AppLocalizations? l10n) {
    if (_isRetrying) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16.0),
            Text(
              l10n?.cameraReconnecting ?? '카메라 다시 연결 중...',
              style: const TextStyle(color: Colors.white70, fontSize: 13.0),
            ),
          ],
        ),
      );
    }

    switch (_permissionState) {
      case CameraPermissionStatusState.checking:
        return const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        );

      case CameraPermissionStatusState.denied:
        return _buildErrorStateContainer(
          icon: Icons.camera_alt_outlined,
          message: l10n?.cameraPermissionRequired ?? 'QR 스캔을 위해 카메라 권한이 필요합니다.',
          buttonLabel: l10n?.cameraGrantPermission ?? '권한 허용',
          onPressed: () => _checkAndRequestPermission(),
        );

      case CameraPermissionStatusState.permanentlyDenied:
        return _buildErrorStateContainer(
          icon: Icons.no_photography_outlined,
          message: l10n?.cameraPermissionPermanentlyDenied ??
              '카메라 권한이 거부되어 있습니다. 설정에서 권한을 허용해 주세요.',
          buttonLabel: l10n?.cameraOpenSettings ?? '설정으로 이동',
          onPressed: () => openAppSettings(),
        );

      case CameraPermissionStatusState.granted:
        if (_initErrorMessage != null) {
          return _buildErrorStateContainer(
            icon: Icons.warning_amber_rounded,
            message: _resolveErrorMessage(l10n),
            buttonLabel: l10n?.cameraRetry ?? '다시 시도',
            onPressed: _handleRetryTapped,
          );
        }

        return MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            if (kDebugMode) {
              print('[QR_CAMERA_DIAGNOSTIC] MOBILE_SCANNER_ERROR_BUILDER: ${error.errorCode}, ${error.errorDetails}');
            }
            return _buildErrorStateContainer(
              icon: Icons.videocam_off_outlined,
              message: _resolveErrorMessageFromCode(l10n, error.errorCode),
              buttonLabel: l10n?.cameraRetry ?? '다시 시도',
              onPressed: _handleRetryTapped,
            );
          },
        );
    }
  }

  String _resolveErrorMessage(AppLocalizations? l10n) {
    if (_errorCode != null) {
      return _resolveErrorMessageFromCode(l10n, _errorCode!);
    }
    return l10n?.cameraStartFailed ??
        '카메라를 시작할 수 없습니다. 다른 앱에서 카메라를 사용 중인지 확인하거나 다시 시도해 주세요.';
  }

  String _resolveErrorMessageFromCode(AppLocalizations? l10n, MobileScannerErrorCode code) {
    switch (code) {
      case MobileScannerErrorCode.controllerUninitialized:
        return l10n?.cameraPreparing ?? '카메라를 준비 중입니다. 잠시 후 다시 시도해 주세요.';
      case MobileScannerErrorCode.permissionDenied:
        return l10n?.cameraPermissionRequired ?? 'QR 스캔을 위해 카메라 권한이 필요합니다.';
      case MobileScannerErrorCode.unsupported:
        return l10n?.cameraUnsupported ?? '이 기기에서는 QR 스캔을 지원하지 않습니다.';
      case MobileScannerErrorCode.controllerAlreadyInitialized:
      case MobileScannerErrorCode.controllerDisposed:
      case MobileScannerErrorCode.genericError:
      default:
        return l10n?.cameraStartFailed ??
            '카메라를 시작할 수 없습니다. 다른 앱에서 카메라를 사용 중인지 확인하거나 다시 시도해 주세요.';
    }
  }

  Widget _buildErrorStateContainer({
    required IconData icon,
    required String message,
    required String buttonLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white70, size: 48.0),
            ),
            const SizedBox(height: 20.0),
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14.0, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.refresh),
              label: Text(buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
