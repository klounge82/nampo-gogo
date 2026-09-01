import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/mission.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/widgets/mission_card.dart';
import 'package:frontend/screens/auth_choice_screen.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/l10n_mappers.dart';

void main() {
  group('VC74 FULL-CLOSURE CUSTOMER I18N RENDERED WIDGET TESTS', () {
    final Map<String, dynamic> sampleMissionJson = {
      'id': 'mission_yongdusan_001',
      'store_id': 'store_yongdusan_001',
      'title': '[QA] 용두산공원 GPS 방문 미션',
      'description': '용두산공원 100m 반경 내에서 GPS 위치를 인증하세요. (100P 적립)',
      'title_en': '[QA] Yongdusan Park GPS Visit Mission',
      'description_en': 'Verify your GPS location within 100m of Yongdusan Park.',
      'title_ja': '[QA] 龍頭山公園 GPS 訪問ミッション',
      'description_ja': '龍頭山公園の 100m 以内で GPS 位置を検証します。',
      'title_zh_hans': '[QA] 龙头山公园 GPS 访问任务',
      'description_zh_hans': '在龙头山公园 100m 范围内验证 GPS 位置。',
      'category': '일반',
      'auth_type': 'PHOTO_GPS',
      'points': 100,
      'reward': '100P',
    };

    final Mission realMission = Mission.fromJson(sampleMissionJson);

    testWidgets('TEST ENTRY SCREEN EN: AuthChoiceScreen renders localized English subtitles without Korean contamination', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SizedBox(
                width: 1080,
                height: 2400,
                child: AuthChoiceScreen(),
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Travel recommendations · Reservations · Reviews · Points'), findsOneWidget);
      expect(find.text('Store registration · Reservations · Recommendations · Customer management'), findsOneWidget);
      expect(find.text('여행지 추천 · 예약 · 리뷰 · 포인트 이용'), findsNothing);
      expect(find.text('매장 등록 · 예약 · 추천 · 고객 관리'), findsNothing);
    });

    testWidgets('TEST MISSION CARD ZH_HANS: MissionCard renders Simplified Chinese title, description, category, test badge, auth badge without Hangul', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MissionCard(mission: realMission),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Assert Chinese Title & Description & Source Match
      expect(find.text('[QA] 龙头山公园 GPS 访问任务'), findsOneWidget);
      expect(find.text('在龙头山公园 100m 范围内验证 GPS 位置。'), findsOneWidget);

      // Assert Chinese Category, Test Badge, and Auth Badge
      expect(find.text('常规'), findsOneWidget);
      expect(find.text('测试用'), findsOneWidget);
      expect(find.text('图片 + GPS 验证'), findsOneWidget);

      // Assert NO Korean Leakage on ZH Screen
      expect(find.text('일반'), findsNothing);
      expect(find.text('테스트용'), findsNothing);
      expect(find.text('현장사진 인증'), findsNothing);
      expect(find.text('[QA] 용두산공원 GPS 방문 미션'), findsNothing);
    });

    testWidgets('TEST MISSION CARD JA: MissionCard renders Japanese title, description, category, test badge, auth badge without Hangul', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MissionCard(mission: realMission),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      // Assert Japanese Title & Description & Source Match
      expect(find.text('[QA] 龍頭山公園 GPS 訪問ミッション'), findsOneWidget);
      expect(find.text('龍頭山公園の 100m 以内で GPS 位置を検証します。'), findsOneWidget);

      // Assert Japanese Category, Test Badge, and Auth Badge
      expect(find.text('一般'), findsOneWidget);
      expect(find.text('テスト用'), findsOneWidget);
      expect(find.text('写真 + GPS 認証'), findsOneWidget);

      // Assert NO Korean Leakage on JA Screen
      expect(find.text('일반'), findsNothing);
      expect(find.text('테스트용'), findsNothing);
    });

    testWidgets('TEST MISSION CARD EN: MissionCard renders English title, description, category, test badge, auth badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: MissionCard(mission: realMission),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      expect(find.text('[QA] Yongdusan Park GPS Visit Mission'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Test'), findsOneWidget);
      expect(find.text('Photo + GPS Verification'), findsOneWidget);
    });

    testWidgets('TEST SPATIAL ARB STRINGS ZH_HANS: AppLocalizations renders Simplified Chinese spatial map strings without Korean fallback', (WidgetTester tester) async {
      late AppLocalizations l10n;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10n = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      expect(l10n.spatialMapTitleSuyeong, '水营江边可认证散步区域 Map');
      expect(l10n.spatialMapApprovedTrail, '散步路正式区域');
      expect(l10n.spatialMapCandidateTrail, '候选散步路 (PM待批准)');
      expect(l10n.spatialMapInsideNotice, '当前位置在可认证区域内。');
      expect(l10n.spatialMapOutsideNotice, '当前位置在可认证区域外。');
      expect(l10n.spatialMapCanVerifyImmediately, '可立即进行任务认证。');
    });

    testWidgets('TEST CATEGORY TAXONOMY & PLACE DYNAMIC I18N: Category mapping has zero collisions and Place names translate dynamically', (WidgetTester tester) async {
      late AppLocalizations l10nZh;
      late AppLocalizations l10nKo;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              l10nZh = AppLocalizations.of(context)!;
              return const SizedBox();
            },
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      final foodCat = L10nMappers.mapCategory(l10nZh, '먹거리');
      final sightsCat = L10nMappers.mapCategory(l10nZh, '볼거리');
      final attractionCat = L10nMappers.mapCategory(l10nZh, '관광');
      final marketCat = L10nMappers.mapCategory(l10nZh, 'MARKET');

      // Assert simplified category labels (Food, Attractions, Shopping are distinct; sights/관광 unified to 景点)
      expect(foodCat, isNot(equals(attractionCat)));
      expect(sightsCat, equals(attractionCat)); // Both map to '景点'
      expect(attractionCat, isNot(equals(marketCat)));

      // Assert Place dynamic localization
      final gwangalliPlace = Place(
        id: 'place_gwangalli_001',
        name: 'QA 광안리해수욕장',
        category: '관광',
        rating: 4.8,
        address: '부산 수영구 광안해변로 219',
        description: '광안리 해변',
        createdAt: DateTime.now(),
      );

      expect(gwangalliPlace.localizedName('zh'), contains('广安里'));
      expect(gwangalliPlace.localizedName('en'), contains('Gwangalli'));
      expect(gwangalliPlace.localizedName('ja'), contains('広安里'));
    });
  });
}
