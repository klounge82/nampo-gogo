import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../constants/colors.dart';
import '../config/production_config.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _hasDetected = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String? qrValue = barcodes.first.rawValue;
      if (qrValue != null && qrValue.isNotEmpty) {
        setState(() {
          _hasDetected = true;
        });
        Navigator.of(context).pop(qrValue); // Return QR code value
      }
    }
  }

  void _onMockScanPressed() {
    if (!ProductionConfig.enableQrMock || ProductionConfig.isProduction) {
      if (kDebugMode) {
        print(
          'QrScannerScreen: Mock scan rejected by production/security policy.',
        );
      }
      return;
    }
    setState(() {
      _hasDetected = true;
    });
    Navigator.of(context).pop('QR_SUCCESS_TOKEN');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'QR 코드 스캔',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Mobile Scanner widget
          MobileScanner(controller: _controller, onDetect: _onDetect),

          // 2. Guide Overlay UI
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

          // 3. Instructions Text
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
                '남포 GoGo 안내판의 QR 코드를 사각형 안에 맞춰주세요.',
                style: TextStyle(color: Colors.white, fontSize: 12.0),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // 4. Development-only Emulator Mock Button Guard
          if (ProductionConfig.enableQrMock)
            Positioned(
              bottom: 40.0,
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
                      padding: const EdgeInsets.symmetric(vertical: 14.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
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
}
