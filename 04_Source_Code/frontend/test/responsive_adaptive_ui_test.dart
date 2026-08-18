import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/widgets/mission_card.dart';
import 'package:frontend/widgets/review_card_widget.dart';
import 'package:frontend/models/mission.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final now = DateTime(2026, 8, 9);

  final sampleMission = Mission(
    id: 'm_resp_001',
    storeId: 'store_001',
    title: 'BIFF Square Ssiat Hotteok Verification Mission',
    description: 'Visit BIFF Square in Nampo-dong, take a photo of delicious Ssiat Hotteok, and verify your visit to earn reward points!',
    category: 'PHOTO',
    authType: 'PHOTO_VERIFICATION',
    points: 100,
    reward: 'Ssiat Hotteok Coupon',
    createdAt: now,
  );

  final sampleReview = Review(
    id: 'rev_resp_001',
    storeId: 'store_001',
    userId: 'user_001',
    rating: 5,
    content: '안녕하세요 후기샘플 3회작성완료 BIFF Square Ssiat Hotteok is extremely delicious and authentic!',
    user: User(
      id: 'user_001',
      email: 'tester@nampogogo.com',
      nickname: 'NampoGourmetExplorer123',
      role: 'USER',
      status: 'ACTIVE',
      createdAt: now,
      updatedAt: now,
    ),
    verificationBadge: 'QR认证',
    verificationMethod: 'BUSINESS_QR',
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );

  final widths = [320.0, 360.0, 390.0, 430.0];
  final locales = [
    const Locale('ko'),
    const Locale('en'),
    const Locale('ja'),
    const Locale('zh', 'Hans'),
  ];
  final textScalers = [
    TextScaler.noScaling,
    const TextScaler.linear(1.15),
    const TextScaler.linear(1.30),
    const TextScaler.linear(1.50),
  ];

  group('Major-05A-R2 Responsive & Adaptive Viewport & TextScaler Tests', () {
    for (final width in widths) {
      for (final locale in locales) {
        for (final scaler in textScalers) {
          testWidgets(
            'MissionCard renders cleanly without overflow on ${width}dp, locale=${locale.languageCode}, textScaler=${scaler.scale(1.0)}',
            (WidgetTester tester) async {
              tester.view.physicalSize = Size(width * 2, 800 * 2);
              tester.view.devicePixelRatio = 2.0;

              await tester.pumpWidget(
                MaterialApp(
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: MediaQuery(
                      data: MediaQueryData(
                        size: Size(width, 800),
                        textScaler: scaler,
                      ),
                      child: SingleChildScrollView(
                        child: MissionCard(mission: sampleMission),
                      ),
                    ),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(MissionCard), findsOneWidget);
            },
          );

          testWidgets(
            'ReviewCardWidget renders cleanly without overflow on ${width}dp, locale=${locale.languageCode}, textScaler=${scaler.scale(1.0)}',
            (WidgetTester tester) async {
              tester.view.physicalSize = Size(width * 2, 800 * 2);
              tester.view.devicePixelRatio = 2.0;

              await tester.pumpWidget(
                MaterialApp(
                  locale: locale,
                  localizationsDelegates: const [
                    AppLocalizations.delegate,
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: MediaQuery(
                      data: MediaQueryData(
                        size: Size(width, 800),
                        textScaler: scaler,
                      ),
                      child: SingleChildScrollView(
                        child: ReviewCardWidget(
                          review: sampleReview,
                          isMyReview: true,
                        ),
                      ),
                    ),
                  ),
                ),
              );

              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull);
              expect(find.byType(ReviewCardWidget), findsOneWidget);
            },
          );
        }
      }
    }
  });
}
