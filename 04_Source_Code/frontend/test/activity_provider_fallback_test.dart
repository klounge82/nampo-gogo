import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/providers/activity_provider.dart';
import 'package:frontend/repositories/activity_repository.dart';

class FakeActivityRepository extends ActivityRepository {
  List<dynamic>? responseList;
  Exception? exceptionToThrow;

  FakeActivityRepository({this.responseList, this.exceptionToThrow});

  @override
  Future<List<dynamic>> getActivities({
    String? type,
    int page = 1,
    int size = 20,
    required String token,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return responseList ?? [];
  }
}

void main() {
  group('ActivityProvider Fallback & Empty State Tests (FINDING-P7-UI-02)', () {
    test('T1: Unauthenticated user (token null) yields empty activities with zero synthetic records', () async {
      final fakeRepo = FakeActivityRepository(responseList: [
        {'id': 'unexpected-item'}
      ]);
      final provider = ActivityProvider(repository: fakeRepo);

      await provider.loadActivities(token: null);

      expect(provider.isLoading, false);
      expect(provider.activities.isEmpty, true);
      expect(provider.activities, isEmpty);
    });

    test('T2: API returning empty list yields empty activities without fallback injection', () async {
      final fakeRepo = FakeActivityRepository(responseList: []);
      final provider = ActivityProvider(repository: fakeRepo);

      await provider.loadActivities(token: 'valid-test-token');

      expect(provider.isLoading, false);
      expect(provider.activities.isEmpty, true);
      expect(provider.errorMessage.isEmpty, true);
    });

    test('T3: API throwing exception yields empty activities and sets error message without fake records', () async {
      final fakeRepo = FakeActivityRepository(
        exceptionToThrow: Exception('Network connection timeout'),
      );
      final provider = ActivityProvider(repository: fakeRepo);

      await provider.loadActivities(token: 'valid-test-token');

      expect(provider.isLoading, false);
      expect(provider.activities.isEmpty, true);
      expect(provider.activities, isEmpty);
      expect(provider.errorMessage.isNotEmpty, true);
      expect(provider.errorMessage, contains('활동 내역을 불러오지 못했습니다'));
    });

    test('T4: Real API activity record is preserved exactly without mapping regression', () async {
      final realRecord = {
        'id': 'real-act-101',
        'user_id': 'user-123',
        'activity_type': 'MISSION',
        'title': 'Real Mission Completed',
        'description': 'Real reward 100P earned.',
        'target_type': 'MISSION',
        'target_id': 'mission-55',
        'icon': 'emoji_events',
        'color': 'green',
        'created_at': DateTime.now().toIso8601String(),
      };
      final fakeRepo = FakeActivityRepository(responseList: [realRecord]);
      final provider = ActivityProvider(repository: fakeRepo);

      await provider.loadActivities(token: 'valid-test-token');

      expect(provider.isLoading, false);
      expect(provider.activities.length, 1);
      expect(provider.activities.first['id'], 'real-act-101');
      expect(provider.activities.first['title'], 'Real Mission Completed');
    });
  });
}
