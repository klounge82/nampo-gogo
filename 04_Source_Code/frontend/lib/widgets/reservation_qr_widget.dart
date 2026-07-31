import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/reservation_status_helper.dart';

class ReservationQrWidget extends StatelessWidget {
  final String qrData;
  final double size;

  const ReservationQrWidget({
    super.key,
    required this.qrData,
    this.size = 140.0,
  });

  @override
  Widget build(BuildContext context) {
    final cleanInput = qrData.trim();
    if (cleanInput.isEmpty) {
      return Container(
        width: size + 24.0,
        height: size + 24.0,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Text(
          '예약 확인 코드가 없습니다.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.0,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final formattedCode = ReservationStatusHelper.formatReservationCode(
      cleanInput,
    );

    return Container(
      width: size + 24.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: QrImageView(
          data: formattedCode,
          version: QrVersions.auto,
          size: size,
          backgroundColor: Colors.white,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Colors.black87,
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Colors.black87,
          ),
          errorCorrectionLevel: QrErrorCorrectLevel.M,
          padding: const EdgeInsets.all(8.0),
          errorStateBuilder: (ctx, err) => Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            child: const Text(
              '예약 확인 코드가 없습니다.',
              style: TextStyle(fontSize: 12.0, color: Colors.grey),
            ),
          ),
        ),
      ),
    );
  }
}
