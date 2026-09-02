import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/activity_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/repositories/activity_repository.dart';
import 'package:frontend/screens/travel_log_screen.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/widgets/activity_card.dart';
import 'package:frontend/l10n/app_localizations.dart';

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
    test(
      'T1: Unauthenticated user (token null) yields empty activities with zero synthetic records',
      () async {
        final fakeRepo = FakeActivityRepository(
          responseList: [
            {'id': 'unexpected-item'},
          ],
        );
        final provider = ActivityProvider(repository: fakeRepo);

        await provider.loadActivities(token: null);

        expect(provider.isLoading, false);
        expect(provider.activities.isEmpty, true);
        expect(provider.activities, isEmpty);
      },
    );

    test(
      'T2: API returning empty list yields empty activities without fallback injection',
      () async {
        final fakeRepo = FakeActivityRepository(responseList: []);
        final provider = ActivityProvider(repository: fakeRepo);

        await provider.loadActivities(token: 'valid-test-token');

        expect(provider.isLoading, false);
        expect(provider.activities.isEmpty, true);
        expect(provider.errorMessage.isEmpty, true);
      },
    );

    test(
      'T3: API throwing exception yields empty activities and sets error message without fake records',
      () async {
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
      },
    );

    test(
      'T4: Real API activity record is preserved exactly without mapping regression',
      () async {
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
      },
    );
  });

  group('TravelLogScreen Real Data & Empty State Widget Tests', () {
    const testLocalizationsDelegates = [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ];

    testWidgets(
      'T1: Empty activity list renders 0 completed mission entries and empty state message',
      (tester) async {
        final fakeRepo = FakeActivityRepository(responseList: []);
        final actProvider = ActivityProvider(repository: fakeRepo);
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ActivityProvider>.value(
                value: actProvider,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ko'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TravelLogScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('표시할 데이터가 없습니다.'), findsOneWidget);
        expect(find.byType(ActivityCard), findsNothing);
        expect(find.textContaining('1,800P'), findsNothing);
        expect(find.textContaining('용두산공원 산책'), findsNothing);
        expect(find.textContaining('K-Lounge'), findsNothing);
      },
    );

    testWidgets(
      'T2: Signup bonus only in activity log does not generate fake mission completions',
      (tester) async {
        final fakeRepo = FakeActivityRepository(
          responseList: [
            {
              'id': 'signup-act-1',
              'user_id': 'user-123',
              'activity_type': 'SIGNUP',
              'title': '회원가입 축하',
              'description': '가입 축하 300P가 적립되었습니다.',
              'target_type': 'POINT',
              'target_id': 'signup-pt',
              'icon': 'person_add',
              'color': 'blue',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        );
        final actProvider = ActivityProvider(repository: fakeRepo);
        final authProvider = AuthProvider();

        await actProvider.loadActivities(token: 'valid-test-token');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ActivityProvider>.value(
                value: actProvider,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ko'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TravelLogScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('표시할 데이터가 없습니다.'), findsOneWidget);
        expect(find.byType(ActivityCard), findsNothing);
      },
    );

    testWidgets(
      'T3: Exactly one real completed mission renders exactly one corresponding entry',
      (tester) async {
        final fakeRepo = FakeActivityRepository(
          responseList: [
            {
              'id': 'mission-act-1',
              'user_id': 'user-123',
              'activity_type': 'MISSION_COMPLETE',
              'title': '자갈치시장 맛집 탐방',
              'description': '자갈치시장 미션 완료! 500P 적립',
              'target_type': 'MISSION',
              'target_id': 'mission-jagalchi-1',
              'icon': 'emoji_events',
              'color': 'green',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        );
        final actProvider = ActivityProvider(repository: fakeRepo);
        final authProvider = AuthProvider();

        await actProvider.loadActivities(token: 'valid-test-token');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ActivityProvider>.value(
                value: actProvider,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ko'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TravelLogScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('완료한 미션이 없습니다.'), findsNothing);
        expect(find.byType(ActivityCard), findsOneWidget);
        expect(find.text('자갈치시장 맛집 탐방'), findsOneWidget);
      },
    );

    testWidgets(
      'T4: Multiple real completed missions render only actual completions',
      (tester) async {
        final fakeRepo = FakeActivityRepository(
          responseList: [
            {
              'id': 'mission-act-1',
              'user_id': 'user-123',
              'activity_type': 'MISSION_COMPLETE',
              'title': '실제 미션 1',
              'description': '100P 적립',
              'target_type': 'MISSION',
              'target_id': 'mission-1',
              'icon': 'emoji_events',
              'color': 'green',
              'created_at': DateTime.now().toIso8601String(),
            },
            {
              'id': 'mission-act-2',
              'user_id': 'user-123',
              'activity_type': 'MISSION_COMPLETE',
              'title': '실제 미션 2',
              'description': '200P 적립',
              'target_type': 'MISSION',
              'target_id': 'mission-2',
              'icon': 'emoji_events',
              'color': 'green',
              'created_at': DateTime.now().toIso8601String(),
            },
          ],
        );
        final actProvider = ActivityProvider(repository: fakeRepo);
        final authProvider = AuthProvider();

        await actProvider.loadActivities(token: 'valid-test-token');

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ActivityProvider>.value(
                value: actProvider,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ko'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TravelLogScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ActivityCard), findsNWidgets(2));
        expect(find.text('실제 미션 1'), findsOneWidget);
        expect(find.text('실제 미션 2'), findsOneWidget);
      },
    );

    testWidgets(
      'T5: No hardcoded 용두산/남포토스트/K-Lounge/1,800P/500P synthetic runtime history remains',
      (tester) async {
        final fakeRepo = FakeActivityRepository(responseList: []);
        final actProvider = ActivityProvider(repository: fakeRepo);
        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<ActivityProvider>.value(
                value: actProvider,
              ),
            ],
            child: const MaterialApp(
              locale: Locale('ko'),
              localizationsDelegates: testLocalizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: TravelLogScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('용두산공원 산책'), findsNothing);
        expect(find.textContaining('남포토스트 방문'), findsNothing);
        expect(find.textContaining('남포돼지국밥'), findsNothing);
        expect(find.textContaining('K-Lounge 힐링 마사지'), findsNothing);
        expect(find.textContaining('고유 QR 방문 인증'), findsNothing);
        expect(find.textContaining('1,800P'), findsNothing);
        expect(find.textContaining('500P 보너스'), findsNothing);
      },
    );
  });
}
