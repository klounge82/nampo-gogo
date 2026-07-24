import 'package:flutter/material.dart';
import '../constants/colors.dart';

class AdminMissionManageScreen extends StatelessWidget {
  const AdminMissionManageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '인증 미션 관리',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.construction_outlined,
                size: 64.0,
                color: AppColors.textHint,
              ),
              const SizedBox(height: 16.0),
              const Text(
                '인증 미션 설정 제어',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8.0),
              const Text(
                '유형별 GPS/QR 미션 등록 및 가시성 제어 인터페이스(Expansion) 범위입니다.',
                style: TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: const Text(
                  '돌아가기',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
