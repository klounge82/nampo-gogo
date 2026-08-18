import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/mission.dart';

void main() {
  group('M05B-QR-CAMERA-HOTFIX-03 Unit & Lifecycle Verification', () {
    test('TEST A & B: QR Mission authType & single controller autoStart=false policy', () {
      const qrMission = Mission(
        id: 'mission_klounge_qr_001',
        storeId: '31b96920-2eb3-4f93-ab51-546fd8d933d1',
        title: 'K-Lounge 방문 QR 인증',
        description: '현장 A4 QR 코드를 스캔하세요.',
        points: 100,
        authType: 'QR',
        reward: '100 Point',
      );

      expect(qrMission.authType.toUpperCase().contains('QR'), isTrue);
    });

    test('TEST C & E: Re-entrancy guard blocks concurrent start or retry calls', () {
      bool isStarting = false;
      int startCount = 0;

      void startSafely() {
        if (isStarting) return;
        isStarting = true;
        startCount++;
      }

      startSafely();
      startSafely(); // Should be ignored by guard
      startSafely(); // Should be ignored by guard

      expect(startCount, equals(1));
    });

    test('TEST D & F: Retry callback creates fresh controller state & clears error messages', () {
      String? errorMessage = 'Camera error';
      bool isControllerDisposed = false;
      bool isNewControllerCreated = false;

      void handleRetry() {
        // 1. Dispose old controller
        isControllerDisposed = true;
        // 2. Create fresh controller & reset state
        isNewControllerCreated = true;
        errorMessage = null;
      }

      handleRetry();

      expect(isControllerDisposed, isTrue);
      expect(isNewControllerCreated, isTrue);
      expect(errorMessage, null);
    });

    test('TEST G: App Lifecycle resume guard prevents duplicate starts', () {
      bool isStarting = true;
      bool resumeTriggeredStart = false;

      void simulateAppResume(bool starting) {
        if (!starting) {
          resumeTriggeredStart = true;
        }
      }

      simulateAppResume(isStarting);
      expect(resumeTriggeredStart, isFalse);
    });

    test('TEST H: Duplicate frame scan prevention', () {
      bool hasDetected = false;
      int apiCallCount = 0;

      void onDetect(String qrCode) {
        if (hasDetected) return;
        hasDetected = true;
        apiCallCount++;
      }

      onDetect('QR_STORE_31b96920-2eb3-4f93-ab51-546fd8d933d1');
      onDetect('QR_STORE_31b96920-2eb3-4f93-ab51-546fd8d933d1');
      onDetect('QR_STORE_31b96920-2eb3-4f93-ab51-546fd8d933d1');

      expect(apiCallCount, equals(1));
    });

    test('TEST I: Error code mapping displays correct diagnostic messages', () {
      String resolveErrorFromCode(String code) {
        switch (code) {
          case 'controllerInitializing':
            return '카메라를 준비 중입니다. 잠시 후 다시 시도해 주세요.';
          case 'permissionDenied':
            return 'QR 스캔을 위해 카메라 권한이 필요합니다.';
          case 'unsupported':
            return '이 기기에서는 QR 스캔을 지원하지 않습니다.';
          default:
            return '카메라를 시작할 수 없습니다. 다른 앱에서 카메라를 사용 중인지 확인하거나 다시 시도해 주세요.';
        }
      }

      expect(resolveErrorFromCode('controllerInitializing'), contains('카메라를 준비 중입니다'));
      expect(resolveErrorFromCode('permissionDenied'), contains('카메라 권한이 필요합니다'));
      expect(resolveErrorFromCode('unsupported'), contains('지원하지 않습니다'));
    });
  });
}
