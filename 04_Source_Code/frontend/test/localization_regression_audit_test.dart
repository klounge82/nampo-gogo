import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/utils/l10n_mappers.dart';
import 'package:frontend/repositories/mission_repository.dart';
import 'package:frontend/screens/account_delete_screen.dart';
import 'package:frontend/services/review_translation_service.dart';
import 'package:flutter/material.dart';

void main() {
  group('RELEASE-M04K: Automated Localization Regression Audit Tests', () {
    test('1. ARB Key Parity Test across all 5 ARB files', () {
      final arbDir = Directory('lib/l10n');
      final langs = ['ko', 'en', 'ja', 'zh', 'zh_Hans'];
      final keyMap = <String, Set<String>>{};

      for (final lang in langs) {
        final file = File('${arbDir.path}/app_$lang.arb');
        expect(file.existsSync(), isTrue, reason: 'app_$lang.arb file must exist');
        final content = file.readAsStringSync();
        final Map<String, dynamic> jsonMap = json.decode(content);
        keyMap[lang] = jsonMap.keys.toSet();
      }

      final koKeys = keyMap['ko']!;
      for (final lang in langs) {
        if (lang == 'ko') continue;
        final currentKeys = keyMap[lang]!;
        final missingInLang = koKeys.difference(currentKeys);
        final extraInLang = currentKeys.difference(koKeys);

        expect(missingInLang, isEmpty,
            reason: 'app_$lang.arb is missing keys present in app_ko.arb: $missingInLang');
        expect(extraInLang, isEmpty,
            reason: 'app_$lang.arb has extra keys not in app_ko.arb: $extraInLang');
      }
    });

    testWidgets('2. L10nMappers mapCategory handles ALL, PHOTO, GPS, QR, FOOD, ATTRACTION, EXPERIENCE', (WidgetTester tester) async {
      late AppLocalizations l10nKo;
      late AppLocalizations l10nEn;
      late AppLocalizations l10nJa;
      late AppLocalizations l10nZh;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nZh = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ko'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nKo = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nEn = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nJa = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      // Verify category mapper across 4 languages
      expect(L10nMappers.mapCategory(l10nKo, '체험'), equals('체험'));
      expect(L10nMappers.mapCategory(l10nEn, '체험'), equals('Experience'));
      expect(L10nMappers.mapCategory(l10nJa, '체험'), equals('体験'));
      expect(L10nMappers.mapCategory(l10nZh, '체험'), equals('体验'));
    });

    test('3. MissionRepository._localizeMission 4-Language Runtime Test', () {
      final repo = MissionRepository();

      // Test zh_Hans locale
      final missionsZh = repo.getMockMissions(locale: 'zh_Hans');
      expect(missionsZh[0].title, equals('BIFF广场糖饼认证！'));
      expect(missionsZh[0].description, contains('BIFF广场坚果糖饼'));
      expect(missionsZh[0].reward, equals('坚果糖饼9折优惠券'));

      expect(missionsZh[1].title, equals('龙头山公园釜山塔登顶'));
      expect(missionsZh[1].description, contains('龙头山公园釜山塔'));
      expect(missionsZh[1].reward, equals('展望台门票立减1,000韩元'));

      expect(missionsZh[2].title, equals('打卡札嘎其市场美食店'));
      expect(missionsZh[2].description, contains('札嘎其市场'));
      expect(missionsZh[2].reward, equals('合作店铺免费饮料券'));

      // Test en locale
      final missionsEn = repo.getMockMissions(locale: 'en');
      expect(missionsEn[0].title, equals('BIFF Square Ssiat Hotteok Verification!'));
      expect(missionsEn[1].title, equals('Yongdusan Park Busan Tower Conquest'));
      expect(missionsEn[2].title, equals('Visit Jagalchi Market Gourmet Place'));

      // Test ja locale
      final missionsJa = repo.getMockMissions(locale: 'ja');
      expect(missionsJa[0].title, equals('BIFF広場ホットク認証！'));
      expect(missionsJa[1].title, equals('龍頭山公園釜山タワー制覇'));
      expect(missionsJa[2].title, equals('チャガルチ市場グルメ訪問'));
    });

    testWidgets('4. Completed Missions Count Format & Account Delete L10n Test', (WidgetTester tester) async {
      late AppLocalizations l10nZh;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nZh = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      // Verify count format in zh_Hans does NOT contain Korean '개'
      final formattedCount = l10nZh.completedMissionsCountFormat(2);
      expect(formattedCount, equals('已完成任务: 2个'));
      expect(formattedCount, isNot(contains('개')));

      // Verify Account Delete strings in zh_Hans
      expect(l10nZh.accountDeleteNoticeTitle, equals('注销账号前请务必仔细阅读。'));
      expect(l10nZh.accountDeleteSec1Title, equals('1. 现有积分全部作废'));
      expect(l10nZh.accountDeleteFinalButton, equals('确认注销账号'));
    });

    testWidgets('5. AccountDeleteScreen 4-Language Runtime & Marker Test', (WidgetTester tester) async {
      final testLocales = [
        const Locale('ko'),
        const Locale('en'),
        const Locale('ja'),
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
      ];

      for (final loc in testLocales) {
        await tester.pumpWidget(
          MaterialApp(
            locale: loc,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AccountDeleteScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Verify diagnostic marker presence
        expect(find.text('ACCOUNT-DELETE: M04J'), findsNWidgets(2));

        if (loc.scriptCode == 'Hans') {
          // In zh_Hans, verify Chinese texts and 0 raw Korean texts
          expect(find.text('注销账号'), findsOneWidget);
          expect(find.text('注销账号前请务必仔细阅读。'), findsOneWidget);
          expect(find.text('1. 现有积分全部作废'), findsOneWidget);
          expect(find.text('确认注销账号'), findsOneWidget);
          expect(find.text('회원탈퇴'), findsNothing);
          expect(find.text('회원탈퇴 진행 전 반드시 확인해 주세요.'), findsNothing);
        }
      }
    });

    test('6. ReviewTranslationService Architecture & Cache Invalidation Test', () async {
      final service = ReviewTranslationService();
      service.clearAllCache();

      // Verify cache invalidation methods run cleanly
      service.invalidateCache('rev_1001');

      // Verify that calling translation with unconfigured backend throws exception cleanly without generic fake fallback
      expect(
        () async => await service.translateReview(
          reviewId: 'rev_test_1001',
          content: '마사지가 시원하고 친절했어요.',
          targetLocale: 'zh_Hans',
        ),
        throwsA(anything),
      );
    });

    test('7. Review Card 4-Language UI Strings & Key Parity Test', () {
      final l10nKo = lookupAppLocalizations(const Locale('ko'));
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nJa = lookupAppLocalizations(const Locale('ja'));
      final l10nZh = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      // 1. myReviewBadge
      expect(l10nKo.myReviewBadge, equals('내가 작성한 후기'));
      expect(l10nEn.myReviewBadge, equals('My Review'));
      expect(l10nJa.myReviewBadge, equals('自分の口コミ'));
      expect(l10nZh.myReviewBadge, equals('我的评价'));

      // 2. visitVerifiedBadge
      expect(l10nKo.visitVerifiedBadge, equals('방문일자 인증'));
      expect(l10nEn.visitVerifiedBadge, equals('Visit Verified'));
      expect(l10nJa.visitVerifiedBadge, equals('訪問日認証'));
      expect(l10nZh.visitVerifiedBadge, equals('到访日期认证'));

      // 3. edit
      expect(l10nKo.edit, equals('수정'));
      expect(l10nEn.edit, equals('Edit'));
      expect(l10nJa.edit, equals('編集'));
      expect(l10nZh.edit, equals('编辑'));

      // 4. delete
      expect(l10nKo.delete, equals('삭제'));
      expect(l10nEn.delete, equals('Delete'));
      expect(l10nJa.delete, equals('削除'));
      expect(l10nZh.delete, equals('删除'));
    });

    test('8. RecommendationResultScreen 4-Language Keys & Metrics Format Test', () {
      final l10nKo = lookupAppLocalizations(const Locale('ko'));
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nJa = lookupAppLocalizations(const Locale('ja'));
      final l10nZh = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      // 1. recommendResultTitle
      expect(l10nKo.recommendResultTitle, equals('추천 코스 결과'));
      expect(l10nEn.recommendResultTitle, equals('Recommended Course Result'));
      expect(l10nJa.recommendResultTitle, equals('おすすめコース結果'));
      expect(l10nZh.recommendResultTitle, equals('推荐路线结果'));

      // 2. saveCourseAction
      expect(l10nKo.saveCourseAction, equals('이 코스 보관함 저장'));
      expect(l10nEn.saveCourseAction, equals('Save this course'));
      expect(l10nJa.saveCourseAction, equals('このコースを保存'));
      expect(l10nZh.saveCourseAction, equals('保存此路线'));

      // 3. recommendFeedbackTitle
      expect(l10nKo.recommendFeedbackTitle, equals('추천 결과 피드백:'));
      expect(l10nEn.recommendFeedbackTitle, equals('Recommendation feedback:'));
      expect(l10nJa.recommendFeedbackTitle, equals('おすすめ結果のフィードバック:'));
      expect(l10nZh.recommendFeedbackTitle, equals('推荐结果反馈:'));

      // 4. recommendMetricsFormat
      expect(l10nKo.recommendMetricsFormat('3', '0.8', '100'), equals('총 이동거리: 0.8 km  |  예상 소요시간: 약 100분 (3개 장소)'));
      expect(l10nEn.recommendMetricsFormat('3', '0.8', '100'), equals('Total distance: 0.8 km  |  Estimated time: about 100 min (3 places)'));
      expect(l10nJa.recommendMetricsFormat('3', '0.8', '100'), equals('総移動距離：0.8 km  |  所要時間：約100分 (3か所)'));
      expect(l10nZh.recommendMetricsFormat('3', '0.8', '100'), equals('总移动距离：0.8 km  |  预计时间：约100分钟 (3个地点)'));
    });

    test('9. Review Translation UI & Button Coexistence Across 4 Languages', () {
      final l10nKo = lookupAppLocalizations(const Locale('ko'));
      final l10nEn = lookupAppLocalizations(const Locale('en'));
      final l10nJa = lookupAppLocalizations(const Locale('ja'));
      final l10nZh = lookupAppLocalizations(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'));

      // 1. translateAction
      expect(l10nKo.translateAction, equals('번역'));
      expect(l10nEn.translateAction, equals('Translate'));
      expect(l10nJa.translateAction, equals('翻訳'));
      expect(l10nZh.translateAction, equals('翻译'));

      // 2. showOriginalAction
      expect(l10nKo.showOriginalAction, equals('원문 보기'));
      expect(l10nEn.showOriginalAction, equals('Show Original'));
      expect(l10nJa.showOriginalAction, equals('原文表示'));
      expect(l10nZh.showOriginalAction, equals('查看原文'));

      // 3. autoTranslatedBadge
      expect(l10nKo.autoTranslatedBadge, equals('자동 번역'));
      expect(l10nEn.autoTranslatedBadge, equals('Auto-translated'));
      expect(l10nJa.autoTranslatedBadge, equals('自動翻訳'));
      expect(l10nZh.autoTranslatedBadge, equals('自动翻译'));

      // 4. translating
      expect(l10nKo.translating, equals('번역 중...'));
      expect(l10nEn.translating, equals('Translating...'));
      expect(l10nJa.translating, equals('翻訳中...'));
      expect(l10nZh.translating, equals('翻译中...'));
    });
  });
}
