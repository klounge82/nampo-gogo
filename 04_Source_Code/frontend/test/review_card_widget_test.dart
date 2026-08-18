import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/widgets/review_card_widget.dart';
import 'package:frontend/l10n/app_localizations.dart';
import 'package:frontend/providers/locale_provider.dart';

void main() {
  final now = DateTime(2026, 8, 8);
  final dummyReview = Review(
    id: 'rev_test_001',
    storeId: 'store_001',
    userId: 'usr_jazzbj',
    user: User(
      id: 'usr_jazzbj',
      email: 'jazzbj@example.com',
      nickname: 'jazzbj',
      role: 'USER',
      status: 'ACTIVE',
      createdAt: now,
      updatedAt: now,
    ),
    rating: 4,
    content: '안녕하세요 후기샘플 3회작성완료',
    verificationBadge: 'QR认证',
    verificationMethod: 'BUSINESS_QR',
    isDeleted: false,
    createdAt: now,
    updatedAt: now,
  );

  Widget createWidgetUnderTest({required Locale locale, required bool isMyReview}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleProvider>(
          create: (_) => LocaleProvider()..setLocale(locale),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ko'),
          Locale('en'),
          Locale('ja'),
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
        ],
        locale: locale,
        home: Scaffold(
          body: ReviewCardWidget(
            review: dummyReview,
            isMyReview: isMyReview,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('ReviewCardWidget displays Owner Badge, Edit/Delete, and Translate Button for zh_Hans locale', (WidgetTester tester) async {
    const zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    await tester.pumpWidget(createWidgetUnderTest(locale: zhHans, isMyReview: true));
    await tester.pumpAndSettle();

    // Verify nickname
    expect(find.text('jazzbj'), findsOneWidget);

    // Verify Owner Badge (zh_Hans: 我的评价)
    expect(find.text('我的评价'), findsOneWidget);

    // Verify Edit (zh_Hans: 编辑) & Delete (zh_Hans: 删除)
    expect(find.text('编辑'), findsOneWidget);
    expect(find.text('删除'), findsOneWidget);

    // Verify Review Content
    expect(find.text('안녕하세요 후기샘플 3회작성완료'), findsOneWidget);

    // Verify Translate Button (zh_Hans: 翻译)
    expect(find.text('翻译'), findsOneWidget);
  });

  testWidgets('ReviewCardWidget displays User Nickname and Translate Button for General Review in zh_Hans locale', (WidgetTester tester) async {
    const zhHans = Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
    await tester.pumpWidget(createWidgetUnderTest(locale: zhHans, isMyReview: false));
    await tester.pumpAndSettle();

    // Verify nickname
    expect(find.text('jazzbj'), findsOneWidget);

    // Verify Owner Badge is NOT shown for general review
    expect(find.text('我的评价'), findsNothing);

    // Verify Translate Button (zh_Hans: 翻译) is shown
    expect(find.text('翻译'), findsOneWidget);
  });
}
