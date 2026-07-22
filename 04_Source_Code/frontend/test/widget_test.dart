import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/constants/strings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend/repositories/recommendation_repository.dart';
import 'package:frontend/models/place.dart';

import 'package:frontend/screens/recommendation_result_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  test('Guest Course Local Save & Duplication Protection Unit Test', () async {
    final repo = RecommendationRepository();
    final dummyStore = Place(
      id: 'store_test_1',
      name: '테스트 추천 장소',
      category: '맛집',
      rating: 4.8,
      address: '부산 중구 테스트로 1',
      description: '테스트용 매장 설명입니다.',
      createdAt: DateTime.now(),
    );

    final testCourse = RecommendationModel(
      id: 'rec_dummy_unit_test_123',
      travelType: 'SOLO',
      travelDuration: 'HALF_DAY',
      transportMode: 'WALK',
      startLatitude: 35.1,
      startLongitude: 129.0,
      isSaved: false,
      createdAt: DateTime.now(),
      items: [
        CourseItemModel(
          storeId: 'store_test_1',
          visitOrder: 1,
          recommendReasonCode: 'REASON_CLOSE',
          store: dummyStore,
        ),
      ],
    );

    // Test guest save
    final saved = await repo.saveCourse(
      testCourse,
      isSaved: true,
      userId: null,
    );
    expect(saved.isSaved, isTrue);

    // Test duplication check on saved history
    final history = await repo.getSavedHistory(userId: null);
    final count = history
        .where((c) => c.id == 'rec_dummy_unit_test_123')
        .length;
    expect(count, equals(1));

    // Cleanup
    await repo.deleteCourse('rec_dummy_unit_test_123');
  });

  test(
    'Guest Course JSON Serialization & Deserialization & Legacy Guard Test',
    () {
      final Map<String, dynamic> sampleJson = {
        'id': 'rec_dummy_9999',
        'travel_type': 'COUPLE',
        'travel_duration': 'TWO_HOURS',
        'transport_mode': 'WALK',
        'start_latitude': 35.0987,
        'start_longitude': 129.0289,
        'is_saved': true,
        'created_at': '2026-07-23T00:00:00.000',
        'items': [
          {
            'store_id': 'store_1',
            'visit_order': 1,
            'recommend_reason_code': 'REASON_CATEGORY',
            'store': {
              'id': 'store_1',
              'name': 'BIFF 광장 씨앗호떡',
              'category': '맛집',
              'rating': 4.8,
              'address': '부산 중구 구덕로 58-1',
              'description': '남포동 명물 씨앗호떡',
              'created_at': '2026-07-23T00:00:00.000',
            },
          },
        ],
      };

      // 1. Deserialization test
      final model = RecommendationModel.fromJson(sampleJson);
      expect(model.id, equals('rec_dummy_9999'));
      expect(model.travelType, equals('COUPLE'));
      expect(model.items.length, equals(1));
      expect(model.items.first.store.name, equals('BIFF 광장 씨앗호떡'));

      // 2. Serialization test
      final toJson = model.toJson();
      expect(toJson['id'], equals('rec_dummy_9999'));
      expect(toJson['items'], isA<List>());

      // 3. Legacy missing fields guard test
      final legacyJson = {'id': 'legacy_1'};
      final legacyModel = RecommendationModel.fromJson(legacyJson);
      expect(legacyModel.id, equals('legacy_1'));
      expect(legacyModel.travelType, equals('SOLO'));
      expect(legacyModel.items, isEmpty);
    },
  );

  testWidgets(
    'RecommendationResultScreen InitialCourse Restoration Test (No userId requirement)',
    (WidgetTester tester) async {
      final dummyStore = Place(
        id: 'store_biff',
        name: 'BIFF 광장 씨앗호떡',
        category: '맛집',
        rating: 4.8,
        address: '부산 중구 구덕로 58-1',
        description: '남포동 명물 씨앗호떡',
        createdAt: DateTime.now(),
      );

      final initialCourse = RecommendationModel(
        id: 'rec_dummy_test_restoration',
        travelType: 'SOLO',
        travelDuration: 'HALF_DAY',
        transportMode: 'WALK',
        startLatitude: 35.1,
        startLongitude: 129.0,
        isSaved: true,
        createdAt: DateTime.now(),
        items: [
          CourseItemModel(
            storeId: 'store_biff',
            visitOrder: 1,
            recommendReasonCode: 'REASON_CLOSE',
            store: dummyStore,
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: RecommendationResultScreen(
            userId: null,
            travelType: 'SOLO',
            travelDuration: 'HALF_DAY',
            categories: const ['맛집'],
            transportMode: 'WALK',
            initialCourse: initialCourse,
          ),
        ),
      );

      await tester.pump();
      expect(find.text('BIFF 광장 씨앗호떡'), findsOneWidget);
      expect(find.text('보관함 저장됨'), findsOneWidget);
    },
  );

  testWidgets('Nampo GoGo Basic Widget Smoke Test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text(AppStrings.appName))),
    );
    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
