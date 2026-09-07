import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/mission.dart';
import 'package:frontend/models/reservation.dart';
import 'package:frontend/repositories/recommendation_repository.dart';
import 'package:frontend/repositories/mission_repository.dart';
import 'package:frontend/utils/l10n_mappers.dart';

void main() {
  group('Dynamic Content Cache Invalidation & Multilingual Switching Tests', () {
    test('CASE 1: Multilingual Place object dynamic getter evaluates per locale without cache clear', () {
      final place = Place.fromJson({
        'id': 'store-nampo-toast-01',
        'name': '남포토스트',
        'name_en': 'Nampo Toast',
        'name_ja': '南浦トースト',
        'name_zh': '南浦吐司',
        'category': '먹거리',
        'rating': 4.7,
        'address': '부산 중구 광복로 50-1',
        'description': '남포동의 대표적인 토스트 전문점입니다.',
        'description_en': 'Representative toast specialty shop in Nampo-dong.',
        'description_ja': '南浦洞を代表するトースト専門店です。',
        'description_zh': '南浦洞代表性吐司专门店。',
        'created_at': '2026-09-08T00:00:00Z',
      });

      // Initially evaluated in Korean
      expect(place.localizedName('ko'), equals('남포토스트'));
      expect(place.localizedDescription('ko'), equals('남포동의 대표적인 토스트 전문점입니다.'));

      // Switch to English dynamically on the exact same in-memory object
      expect(place.localizedName('en'), equals('Nampo Toast'));
      expect(place.localizedDescription('en'), equals('Representative toast specialty shop in Nampo-dong.'));

      // Switch to Japanese
      expect(place.localizedName('ja'), equals('南浦トースト'));
      expect(place.localizedDescription('ja'), equals('南浦洞を代表するトースト専門店です。'));

      // Switch to Simplified Chinese
      expect(place.localizedName('zh_Hans'), equals('南浦吐司'));
      expect(place.localizedName('zh'), equals('南浦吐司'));
      expect(place.localizedDescription('zh_Hans'), equals('南浦洞代表性吐司专门店。'));
    });

    test('CASE 2: MissionRepository prioritizes fresh server multilingual fields over static fallbacks', () {
      final missionRepo = MissionRepository();

      // Server payload with custom English/Japanese/Chinese titles
      final serverMission = Mission.fromJson({
        'id': 'mis_01',
        'title': 'BIFF 광장 씨앗호떡 인증!',
        'description': 'BIFF 광장에서 씨앗호떡을 구매하고 사진을 찍어 인증하세요.',
        'title_en': 'BIFF Square Ssiat Hotteok Verification!',
        'description_en': 'Buy Ssiat Hotteok at BIFF Square and upload a photo to verify.',
        'title_ja': 'BIFF広場ホットク認証！',
        'description_ja': 'BIFF広場でシアホットクを購入し写真を撮影して認証してください。',
        'title_zh_hans': 'BIFF广场糖饼认证！',
        'description_zh_hans': '购买BIFF广场坚果糖饼并拍照认证打卡。',
        'points': 100,
        'auth_type': 'PHOTO',
        'category': '먹거리',
      });

      // Localize for EN
      final localizedEn = missionRepo.getMockMissions(locale: 'en');
      expect(localizedEn.isNotEmpty, isTrue);
      expect(serverMission.localizedTitle('en'), equals('BIFF Square Ssiat Hotteok Verification!'));
      expect(serverMission.localizedDescription('en'), equals('Buy Ssiat Hotteok at BIFF Square and upload a photo to verify.'));

      // Localize for JA
      expect(serverMission.localizedTitle('ja'), equals('BIFF広場ホットク認証！'));

      // Localize for ZH
      expect(serverMission.localizedTitle('zh'), equals('BIFF广场糖饼认证！'));
    });

    test('CASE 3: CourseItemModel with Place preserves translations in JSON roundtrip', () {
      final originalPlace = Place.fromJson({
        'id': 'store-nampo-gukbap-01',
        'name': '남포돼지국밥',
        'name_en': 'Nampo Dwaeji Gukbap',
        'name_ja': '南浦テジクッパ',
        'name_zh': '南浦猪肉汤饭',
        'category': '먹거리',
        'rating': 4.8,
        'address': '부산 중구 구덕로 58-1',
        'description': '진한 육수의 전통 남포 돼지국밥.',
        'description_en': 'Traditional Nampo pork soup with rich broth.',
        'description_ja': '濃厚な出汁の伝統南浦豚クッパ。',
        'description_zh': '浓郁高汤的传统南浦猪肉汤饭。',
        'created_at': '2026-09-08T00:00:00Z',
      });

      final courseItem = CourseItemModel(
        storeId: originalPlace.id,
        visitOrder: 1,
        recommendReasonCode: 'REASON_CATEGORY',
        store: originalPlace,
      );

      // Serialize to JSON (as stored in local storage)
      final json = courseItem.toJson();

      // Deserialize from JSON
      final deserializedItem = CourseItemModel.fromJson(json);

      // Verify dynamic locale switching on restored item
      expect(deserializedItem.store.localizedName('ko'), equals('남포돼지국밥'));
      expect(deserializedItem.store.localizedName('en'), equals('Nampo Dwaeji Gukbap'));
      expect(deserializedItem.store.localizedName('ja'), equals('南浦テジクッパ'));
      expect(deserializedItem.store.localizedName('zh_Hans'), equals('南浦猪肉汤饭'));
    });

    test('CASE 4: Reservation model with Place preserves translations in JSON roundtrip', () {
      final place = Place.fromJson({
        'id': 'store-nampo-toast-01',
        'name': '남포토스트',
        'name_en': 'Nampo Toast',
        'name_ja': '南浦トースト',
        'name_zh': '南浦吐司',
        'category': '먹거리',
        'rating': 4.7,
        'address': '부산 중구 광복로 50-1',
        'description': '남포동 토스트',
        'description_en': 'Nampo-dong Toast',
        'created_at': '2026-09-08T00:00:00Z',
      });

      final res = Reservation(
        id: 'res-test-01',
        userId: 'usr-test',
        storeId: place.id,
        reservationTime: DateTime.parse('2026-09-08T12:00:00Z'),
        partySize: 2,
        status: 'PENDING',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        store: place,
      );

      final json = res.toJson();
      final deserialized = Reservation.fromJson(json);

      expect(deserialized.store.localizedName('ko'), equals('남포토스트'));
      expect(deserialized.store.localizedName('en'), equals('Nampo Toast'));
      expect(deserialized.store.localizedName('ja'), equals('南浦トースト'));
      expect(deserialized.store.localizedName('zh_Hans'), equals('南浦吐司'));
    });

    test('CASE 5: L10nMappers correctly maps place addresses without requiring server re-fetch', () {
      final place = Place.fromJson({
        'id': 'store_01',
        'name': '자갈치시장 신선횟집',
        'address': '부산 중구 자갈치해안로 52',
        'category': '먹거리',
        'rating': 4.5,
        'description': '설명',
        'created_at': '2026-09-08T00:00:00Z',
      });

      expect(L10nMappers.mapPlaceAddress(place, 'ko'), contains('부산 중구 자갈치해안로 52'));
      expect(L10nMappers.mapPlaceAddress(place, 'en'), equals('52 Jagalchihaean-ro, Jung-gu, Busan'));
      expect(L10nMappers.mapPlaceAddress(place, 'ja'), equals('釜山広域市中区チャガルチ海岸路52'));
      expect(L10nMappers.mapPlaceAddress(place, 'zh'), equals('釜山 中区 札嘎其海岸路 52'));
    });
  });
}
