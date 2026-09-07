import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/utils/l10n_mappers.dart';
import 'package:flutter/material.dart';

void main() {
  group('Full App I18n One-Shot Recovery Unit Tests', () {
    test('ARB 5-file 100% Key Parity Test', () {
      final l10nDir = Directory('lib/l10n');
      final files = ['app_ko.arb', 'app_en.arb', 'app_ja.arb', 'app_zh.arb', 'app_zh_Hans.arb'];
      final Map<String, Set<String>> keysByFile = {};

      for (final fn in files) {
        final f = File('${l10nDir.path}/$fn');
        expect(f.existsSync(), isTrue, reason: '$fn must exist');
        final Map<String, dynamic> jsonMap = json.decode(f.readAsStringSync());
        final keys = jsonMap.keys.where((k) => !k.startsWith('@')).toSet();
        keysByFile[fn] = keys;
      }

      final baseKeys = keysByFile['app_ko.arb']!;
      for (final fn in files) {
        final currentKeys = keysByFile[fn]!;
        expect(currentKeys.length, equals(baseKeys.length), reason: '$fn key count must match app_ko.arb');
        final missing = baseKeys.difference(currentKeys);
        expect(missing, isEmpty, reason: '$fn is missing keys: $missing');
      }
    });

    test('L10nMappers Activity Log Title & Description Localized Mapping Test', () async {
      final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
      final l10nJa = await AppLocalizations.delegate.load(const Locale('ja'));
      final l10nZh = await AppLocalizations.delegate.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      // Signup
      expect(L10nMappers.mapActivityLogTitle(l10nEn, 'SIGNUP', '회원가입 완료'), equals(l10nEn.activitySignupTitle));
      expect(L10nMappers.mapActivityLogTitle(l10nJa, 'SIGNUP', '회원가입 완료'), equals(l10nJa.activitySignupTitle));
      expect(L10nMappers.mapActivityLogTitle(l10nZh, 'SIGNUP', '회원가입 완료'), equals(l10nZh.activitySignupTitle));

      // Mission
      expect(L10nMappers.mapActivityLogTitle(l10nEn, 'MISSION', '미션 완료'), equals(l10nEn.activityMissionTitle));
      expect(L10nMappers.mapActivityLogTitle(l10nJa, 'MISSION', '미션 완료'), equals(l10nJa.activityMissionTitle));

      // Coupon
      expect(L10nMappers.mapActivityLogTitle(l10nEn, 'COUPON', '쿠폰 발급'), equals(l10nEn.activityCouponTitle));
      expect(L10nMappers.mapActivityLogTitle(l10nZh, 'COUPON', '쿠폰 발급'), equals(l10nZh.activityCouponTitle));
    });

    test('L10nMappers Point History Activity Mapping Test', () async {
      final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
      final l10nJa = await AppLocalizations.delegate.load(const Locale('ja'));
      final l10nZh = await AppLocalizations.delegate.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      expect(L10nMappers.mapPointHistoryActivity(l10nEn, '신규 회원가입 축하 포인트'), equals(l10nEn.pointTxSignupBonus));
      expect(L10nMappers.mapPointHistoryActivity(l10nJa, '신규 회원가입 축하 포인트'), equals(l10nJa.pointTxSignupBonus));
      expect(L10nMappers.mapPointHistoryActivity(l10nZh, '신규 회원가입 축하 포인트'), equals(l10nZh.pointTxSignupBonus));

      expect(L10nMappers.mapPointHistoryActivity(l10nEn, '미션 완료 보상'), equals(l10nEn.pointTxMissionReward));
      expect(L10nMappers.mapPointHistoryActivity(l10nEn, '쿠폰 교환'), equals(l10nEn.pointTxCouponExchange));
    });

    test('L10nMappers Coupon Title & Description Mapping Test', () async {
      final l10nEn = await AppLocalizations.delegate.load(const Locale('en'));
      final l10nJa = await AppLocalizations.delegate.load(const Locale('ja'));
      final l10nZh = await AppLocalizations.delegate.load(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      expect(L10nMappers.mapCouponTitle(l10nEn, 'BIFF 광장 씨앗호떡 1개 교환권'), equals(l10nEn.couponBiffHotteokTitle));
      expect(L10nMappers.mapCouponTitle(l10nJa, 'BIFF 광장 씨앗호떡 1개 교환권'), equals(l10nJa.couponBiffHotteokTitle));
      expect(L10nMappers.mapCouponTitle(l10nZh, 'BIFF 광장 씨앗호떡 1개 교환권'), equals(l10nZh.couponBiffHotteokTitle));

      expect(L10nMappers.mapCouponTitle(l10nEn, '남포동 명가 아메리카노 1잔 교환권'), equals(l10nEn.couponCafeAmericanoTitle));
      expect(L10nMappers.mapCouponTitle(l10nEn, '자갈치시장 신선횟집 10% 식사 할인권'), equals(l10nEn.couponJagalchiDiscountTitle));
    });

    test('Place Model Multilingual Getter Test', () {
      final place = Place(
        id: 'plc_001',
        name: '용두산공원 부산타워',
        category: '관광',
        address: '부산 중구 용두산길 37-55',
        description: '부산의 역사와 탁 트인 조망을 자랑하는 부산의 대표 랜드마크입니다.',
        rating: 4.8,
        createdAt: DateTime.now(),
      );

      expect(place.localizedName('en'), contains('Yongdusan'));
      expect(place.localizedName('ja'), contains('龍頭山'));
      expect(place.localizedName('zh_Hans'), contains('龙头山'));

      expect(place.localizedAddress('en'), contains('Yongdusan-gil'));
      expect(place.localizedAddress('ja'), contains('龍頭山路'));
      expect(place.localizedAddress('zh_Hans'), contains('龙头山路'));

      expect(place.localizedDescription('en'), contains('observatory'));
      expect(place.localizedDescription('ja'), contains('展望台'));
      expect(place.localizedDescription('zh_Hans'), contains('观景台'));
    });
  });
}
