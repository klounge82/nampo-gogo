import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/models/mission.dart';
import 'package:frontend/widgets/mission_card.dart';
import 'package:frontend/providers/locale_provider.dart';
import 'package:frontend/providers/auth_provider.dart';
import 'package:frontend/utils/l10n_mappers.dart';

void main() {
  group('MISSION DISPLAY TITLE UNIFICATION TESTS', () {
    test('L10nMappers.cleanMissionDisplayTitle removes redundant trailing auth suffixes', () {
      // Korean examples
      expect(
        L10nMappers.cleanMissionDisplayTitle('자갈치시장 수산물 탐방 인증'),
        '자갈치시장 수산물 탐방',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('국제시장 아리랑거리 탐방 인증'),
        '국제시장 아리랑거리 탐방',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('용두산공원 부산타워 방문 인증'),
        '용두산공원 부산타워 방문',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('BIFF광장 씨앗호떡 사진 인증'),
        'BIFF광장 씨앗호떡 사진',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('K-Lounge QR 방문 인증!'),
        'K-Lounge QR 방문',
      );

      // Multilingual examples
      expect(
        L10nMappers.cleanMissionDisplayTitle('Jagalchi Market Tour Verification'),
        'Jagalchi Market Tour',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('Jagalchi Market Tour Verification!'),
        'Jagalchi Market Tour',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('チャガルチ市場 探索 認証'),
        'チャガルチ市場 探索',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('札嘎其市场 探索 认证'),
        '札嘎其市场 探索',
      );

      // Non-suffix titles preserved
      expect(
        L10nMappers.cleanMissionDisplayTitle('자갈치시장 수산물 탐방'),
        '자갈치시장 수산물 탐방',
      );
      expect(
        L10nMappers.cleanMissionDisplayTitle('국제시장 아리랑거리 탐방'),
        '국제시장 아리랑거리 탐방',
      );
    });

    testWidgets('MissionCard renders clean display title without redundant auth suffix', (WidgetTester tester) async {
      const sampleMission = Mission(
        id: 'mission_jagalchi_002',
        storeId: 'jagalchi-market-002',
        title: '자갈치시장 수산물 탐방 인증',
        description: '자갈치시장에서 수산물을 탐방하고 인증을 완료하세요.',
        category: 'ATTRACTION',
        authType: 'GPS_VERIFICATION',
        points: 100,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LocaleProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
          ],
          child: const MaterialApp(
            locale: Locale('ko'),
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MissionCard(mission: sampleMission),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify MissionCard displays cleaned title without '인증'
      expect(find.text('자갈치시장 수산물 탐방'), findsOneWidget);
      expect(find.text('자갈치시장 수산물 탐방 인증'), findsNothing);

      // Verify clean title equals L10nMappers output
      final expectedCleanTitle = L10nMappers.cleanMissionDisplayTitle(sampleMission.localizedTitle('ko'));
      expect(expectedCleanTitle, '자갈치시장 수산물 탐방');
    });
  });
}
