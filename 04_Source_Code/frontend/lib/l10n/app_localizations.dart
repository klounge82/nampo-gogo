import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  /// No description provided for @accountDelete.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴'**
  String get accountDelete;

  /// No description provided for @activityTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 활동 내역'**
  String get activityTitle;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'관리자 대시보드'**
  String get adminDashboardTitle;

  /// No description provided for @aiCategoryCafe.
  ///
  /// In ko, this message translates to:
  /// **'감성 카페'**
  String get aiCategoryCafe;

  /// No description provided for @aiCategoryCulture.
  ///
  /// In ko, this message translates to:
  /// **'로컬 체험'**
  String get aiCategoryCulture;

  /// No description provided for @aiCategoryMarket.
  ///
  /// In ko, this message translates to:
  /// **'시장/쇼핑'**
  String get aiCategoryMarket;

  /// No description provided for @aiCategoryMeal.
  ///
  /// In ko, this message translates to:
  /// **'맛있는 식사'**
  String get aiCategoryMeal;

  /// No description provided for @aiCategorySights.
  ///
  /// In ko, this message translates to:
  /// **'주요 볼거리'**
  String get aiCategorySights;

  /// No description provided for @aiCompanionCouple.
  ///
  /// In ko, this message translates to:
  /// **'연인/배우자'**
  String get aiCompanionCouple;

  /// No description provided for @aiCompanionFamily.
  ///
  /// In ko, this message translates to:
  /// **'가족'**
  String get aiCompanionFamily;

  /// No description provided for @aiCompanionFriends.
  ///
  /// In ko, this message translates to:
  /// **'친구'**
  String get aiCompanionFriends;

  /// No description provided for @aiCompanionSolo.
  ///
  /// In ko, this message translates to:
  /// **'혼자'**
  String get aiCompanionSolo;

  /// No description provided for @aiGenerateButton.
  ///
  /// In ko, this message translates to:
  /// **'맞춤 코스 생성하기'**
  String get aiGenerateButton;

  /// No description provided for @aiRecommendTitle.
  ///
  /// In ko, this message translates to:
  /// **'AI 추천 장소'**
  String get aiRecommendTitle;

  /// No description provided for @aiReselectButton.
  ///
  /// In ko, this message translates to:
  /// **'다시 선택'**
  String get aiReselectButton;

  /// No description provided for @aiSaveCourse.
  ///
  /// In ko, this message translates to:
  /// **'코스 저장'**
  String get aiSaveCourse;

  /// No description provided for @aiStepCategoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 활동에 관심이 있으신가요?'**
  String get aiStepCategoryTitle;

  /// No description provided for @aiStepCompanionTitle.
  ///
  /// In ko, this message translates to:
  /// **'누구와 함께 여행하시나요?'**
  String get aiStepCompanionTitle;

  /// No description provided for @aiStepTimeTitle.
  ///
  /// In ko, this message translates to:
  /// **'얼마나 머무르실 예정인가요?'**
  String get aiStepTimeTitle;

  /// No description provided for @aiStepTransitTitle.
  ///
  /// In ko, this message translates to:
  /// **'어떤 이동수단을 이용하시나요?'**
  String get aiStepTransitTitle;

  /// No description provided for @aiTime2Hours.
  ///
  /// In ko, this message translates to:
  /// **'2시간 (짧은 코스)'**
  String get aiTime2Hours;

  /// No description provided for @aiTimeFullDay.
  ///
  /// In ko, this message translates to:
  /// **'하루 종일 (8시간 이상)'**
  String get aiTimeFullDay;

  /// No description provided for @aiTimeHalfDay.
  ///
  /// In ko, this message translates to:
  /// **'반나절 (4시간)'**
  String get aiTimeHalfDay;

  /// No description provided for @aiTransitCar.
  ///
  /// In ko, this message translates to:
  /// **'차량/택시'**
  String get aiTransitCar;

  /// No description provided for @aiTransitPublic.
  ///
  /// In ko, this message translates to:
  /// **'대중교통'**
  String get aiTransitPublic;

  /// No description provided for @aiTransitWalk.
  ///
  /// In ko, this message translates to:
  /// **'도보'**
  String get aiTransitWalk;

  /// No description provided for @allCategory.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get allCategory;

  /// No description provided for @apiChecking.
  ///
  /// In ko, this message translates to:
  /// **'서버 상태 확인 중...'**
  String get apiChecking;

  /// No description provided for @cameraGrantPermission.
  ///
  /// In ko, this message translates to:
  /// **'권한 허용'**
  String get cameraGrantPermission;

  /// No description provided for @cameraOpenSettings.
  ///
  /// In ko, this message translates to:
  /// **'설정으로 이동'**
  String get cameraOpenSettings;

  /// No description provided for @cameraPermissionPermanentlyDenied.
  ///
  /// In ko, this message translates to:
  /// **'카메라 권한이 거부되어 있습니다. 설정에서 권한을 허용해 주세요.'**
  String get cameraPermissionPermanentlyDenied;

  /// No description provided for @cameraPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'QR 스캔을 위해 카메라 권한이 필요합니다.'**
  String get cameraPermissionRequired;

  /// No description provided for @cameraPreparing.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 준비 중입니다. 잠시 후 다시 시도해 주세요.'**
  String get cameraPreparing;

  /// No description provided for @cameraReconnecting.
  ///
  /// In ko, this message translates to:
  /// **'카메라 다시 연결 중...'**
  String get cameraReconnecting;

  /// No description provided for @cameraRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get cameraRetry;

  /// No description provided for @cameraStartFailed.
  ///
  /// In ko, this message translates to:
  /// **'카메라를 시작할 수 없습니다. 다른 앱에서 카메라를 사용 중인지 확인하거나 다시 시도해 주세요.'**
  String get cameraStartFailed;

  /// No description provided for @cameraUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기에서는 QR 스캔을 지원하지 않습니다.'**
  String get cameraUnsupported;

  /// No description provided for @apiConnected.
  ///
  /// In ko, this message translates to:
  /// **'🟢 API 연결됨'**
  String get apiConnected;

  /// No description provided for @apiDisconnected.
  ///
  /// In ko, this message translates to:
  /// **'🔴 서버 연결 실패'**
  String get apiDisconnected;

  /// No description provided for @apiRunning.
  ///
  /// In ko, this message translates to:
  /// **'Nampo GoGo API가 정상 작동 중입니다'**
  String get apiRunning;

  /// No description provided for @appName.
  ///
  /// In ko, this message translates to:
  /// **'남포 GoGo'**
  String get appName;

  /// No description provided for @attractionCategory.
  ///
  /// In ko, this message translates to:
  /// **'관광지'**
  String get attractionCategory;

  /// No description provided for @authTypeGps.
  ///
  /// In ko, this message translates to:
  /// **'GPS 인증'**
  String get authTypeGps;

  /// No description provided for @authTypeManual.
  ///
  /// In ko, this message translates to:
  /// **'방문 인증'**
  String get authTypeManual;

  /// No description provided for @authTypePhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 인증'**
  String get authTypePhoto;

  /// No description provided for @authTypeQr.
  ///
  /// In ko, this message translates to:
  /// **'QR 인증'**
  String get authTypeQr;

  /// No description provided for @btnBack.
  ///
  /// In ko, this message translates to:
  /// **'이전'**
  String get btnBack;

  /// No description provided for @btnNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get btnNext;

  /// No description provided for @btnRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get btnRetry;

  /// No description provided for @businessDashboardTitle.
  ///
  /// In ko, this message translates to:
  /// **'사업자 대시보드'**
  String get businessDashboardTitle;

  /// No description provided for @cancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get cancel;

  /// No description provided for @categoryAll.
  ///
  /// In ko, this message translates to:
  /// **'전체'**
  String get categoryAll;

  /// No description provided for @categoryAttraction.
  ///
  /// In ko, this message translates to:
  /// **'관광지'**
  String get categoryAttraction;

  /// No description provided for @categoryExperience.
  ///
  /// In ko, this message translates to:
  /// **'체험'**
  String get categoryExperience;

  /// No description provided for @categoryFood.
  ///
  /// In ko, this message translates to:
  /// **'맛집/카페'**
  String get categoryFood;

  /// No description provided for @categoryShopping.
  ///
  /// In ko, this message translates to:
  /// **'쇼핑'**
  String get categoryShopping;

  /// No description provided for @celebrationPointBody.
  ///
  /// In ko, this message translates to:
  /// **'1,000P가 적립되었습니다!'**
  String get celebrationPointBody;

  /// No description provided for @celebrationPointHeader.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 축하 포인트'**
  String get celebrationPointHeader;

  /// No description provided for @celebrationSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'남포고고 여행을 시작해 보세요.'**
  String get celebrationSubtitle;

  /// No description provided for @celebrationTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원가입을 축하합니다!'**
  String get celebrationTitle;

  /// No description provided for @challengeButton.
  ///
  /// In ko, this message translates to:
  /// **'도전'**
  String get challengeButton;

  /// No description provided for @changePassword.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get changePassword;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @comingSoon.
  ///
  /// In ko, this message translates to:
  /// **'준비 중인 기능입니다.'**
  String get comingSoon;

  /// No description provided for @confirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirm;

  /// No description provided for @confirmCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get confirmCancel;

  /// No description provided for @confirmOk.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get confirmOk;

  /// No description provided for @cultureCategory.
  ///
  /// In ko, this message translates to:
  /// **'문화/체험'**
  String get cultureCategory;

  /// No description provided for @delete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get delete;

  /// No description provided for @dialogAlertTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get dialogAlertTitle;

  /// No description provided for @dialogErrorTitle.
  ///
  /// In ko, this message translates to:
  /// **'오류'**
  String get dialogErrorTitle;

  /// No description provided for @edit.
  ///
  /// In ko, this message translates to:
  /// **'수정'**
  String get edit;

  /// No description provided for @emailAdminContact.
  ///
  /// In ko, this message translates to:
  /// **'관리자에게 이메일 보내기'**
  String get emailAdminContact;

  /// No description provided for @emailAppFail.
  ///
  /// In ko, this message translates to:
  /// **'이메일 앱을 열 수 없습니다. 주소가 복사되었습니다.'**
  String get emailAppFail;

  /// No description provided for @emailCopied.
  ///
  /// In ko, this message translates to:
  /// **'이메일 주소가 복사되었습니다.'**
  String get emailCopied;

  /// No description provided for @emailInquiry.
  ///
  /// In ko, this message translates to:
  /// **'이메일 문의'**
  String get emailInquiry;

  /// No description provided for @emptyNoData.
  ///
  /// In ko, this message translates to:
  /// **'표시할 데이터가 없습니다.'**
  String get emptyNoData;

  /// No description provided for @emptySearch.
  ///
  /// In ko, this message translates to:
  /// **'검색 결과가 없습니다.'**
  String get emptySearch;

  /// No description provided for @errorNetwork.
  ///
  /// In ko, this message translates to:
  /// **'네트워크 연결이 불안정합니다. 다시 시도해 주세요.'**
  String get errorNetwork;

  /// No description provided for @estTime.
  ///
  /// In ko, this message translates to:
  /// **'예상 소요시간'**
  String get estTime;

  /// No description provided for @exchangeStore.
  ///
  /// In ko, this message translates to:
  /// **'포인트 교환소'**
  String get exchangeStore;

  /// No description provided for @exploreTitle.
  ///
  /// In ko, this message translates to:
  /// **'탐색'**
  String get exploreTitle;

  /// No description provided for @favoritesTitle.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기'**
  String get favoritesTitle;

  /// No description provided for @guestMode.
  ///
  /// In ko, this message translates to:
  /// **'둘러보기 (게스트)'**
  String get guestMode;

  /// No description provided for @guestModeNotice.
  ///
  /// In ko, this message translates to:
  /// **'게스트 모드로 이용 중 (로그인 시 데이터 연결)'**
  String get guestModeNotice;

  /// No description provided for @guestNotice.
  ///
  /// In ko, this message translates to:
  /// **'게스트 모드로 이용 중 (로그인 시 데이터 연결)'**
  String get guestNotice;

  /// No description provided for @homeSearchHint.
  ///
  /// In ko, this message translates to:
  /// **'남포동 맛집, 볼거리를 검색해 보세요'**
  String get homeSearchHint;

  /// No description provided for @homeTitle.
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get homeTitle;

  /// No description provided for @languageSetting.
  ///
  /// In ko, this message translates to:
  /// **'언어 설정'**
  String get languageSetting;

  /// No description provided for @loginTitle.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get loginTitle;

  /// No description provided for @logout.
  ///
  /// In ko, this message translates to:
  /// **'로그인 / 회원가입'**
  String get logout;

  /// No description provided for @logoutButton.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get logoutButton;

  /// No description provided for @mapLoadFail.
  ///
  /// In ko, this message translates to:
  /// **'지도를 불러올 수 없습니다.'**
  String get mapLoadFail;

  /// No description provided for @mapLoading.
  ///
  /// In ko, this message translates to:
  /// **'장소를 불러오는 중...'**
  String get mapLoading;

  /// No description provided for @mapMyLocation.
  ///
  /// In ko, this message translates to:
  /// **'내 위치'**
  String get mapMyLocation;

  /// No description provided for @mapNearbyPlaces.
  ///
  /// In ko, this message translates to:
  /// **'주변 장소'**
  String get mapNearbyPlaces;

  /// No description provided for @mapPermissionRequired.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한이 필요합니다.'**
  String get mapPermissionRequired;

  /// No description provided for @mapRetry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get mapRetry;

  /// No description provided for @mapTitle.
  ///
  /// In ko, this message translates to:
  /// **'지도'**
  String get mapTitle;

  /// No description provided for @mapViewDetail.
  ///
  /// In ko, this message translates to:
  /// **'장소 정보 보기'**
  String get mapViewDetail;

  /// No description provided for @mapViewNearby.
  ///
  /// In ko, this message translates to:
  /// **'주변 지도 보기'**
  String get mapViewNearby;

  /// No description provided for @mapViewWithoutPermission.
  ///
  /// In ko, this message translates to:
  /// **'위치 권한 없이 지도 보기'**
  String get mapViewWithoutPermission;

  /// No description provided for @missionAllList.
  ///
  /// In ko, this message translates to:
  /// **'전체 미션 목록'**
  String get missionAllList;

  /// No description provided for @missionAuthActionGps.
  ///
  /// In ko, this message translates to:
  /// **'GPS 인증'**
  String get missionAuthActionGps;

  /// No description provided for @missionAuthActionPhoto.
  ///
  /// In ko, this message translates to:
  /// **'사진 인증'**
  String get missionAuthActionPhoto;

  /// No description provided for @missionAuthActionQr.
  ///
  /// In ko, this message translates to:
  /// **'QR 스캔'**
  String get missionAuthActionQr;

  /// No description provided for @missionCompletedCount.
  ///
  /// In ko, this message translates to:
  /// **'완료한 미션'**
  String get missionCompletedCount;

  /// No description provided for @missionDetailTitle.
  ///
  /// In ko, this message translates to:
  /// **'미션 상세'**
  String get missionDetailTitle;

  /// No description provided for @missionEmpty.
  ///
  /// In ko, this message translates to:
  /// **'진행 가능한 미션이 없습니다.'**
  String get missionEmpty;

  /// No description provided for @missionHowTo.
  ///
  /// In ko, this message translates to:
  /// **'미션 수행 방법'**
  String get missionHowTo;

  /// No description provided for @missionMyPoints.
  ///
  /// In ko, this message translates to:
  /// **'나의 획득 포인트'**
  String get missionMyPoints;

  /// No description provided for @missionNotes.
  ///
  /// In ko, this message translates to:
  /// **'참고 사항'**
  String get missionNotes;

  /// No description provided for @missionNotesDesc.
  ///
  /// In ko, this message translates to:
  /// **'• 한 번 완료한 미션은 당일 재도전이 불가능합니다.\n• 허위 사진 업로드 및 부당한 방법으로 인증 시 포인트가 회수될 수 있습니다.'**
  String get missionNotesDesc;

  /// No description provided for @missionRelatedStore.
  ///
  /// In ko, this message translates to:
  /// **'관련 매장 정보 보기'**
  String get missionRelatedStore;

  /// No description provided for @missionRelatedStoreSub.
  ///
  /// In ko, this message translates to:
  /// **'미션을 수행할 매장의 상세 위치 및 주소를 확인합니다.'**
  String get missionRelatedStoreSub;

  /// No description provided for @missionStartAction.
  ///
  /// In ko, this message translates to:
  /// **'미션 도전하기'**
  String get missionStartAction;

  /// No description provided for @missionTitle.
  ///
  /// In ko, this message translates to:
  /// **'미션'**
  String get missionTitle;

  /// No description provided for @missionTopGrade.
  ///
  /// In ko, this message translates to:
  /// **'상위 5% 탐험가'**
  String get missionTopGrade;

  /// No description provided for @more.
  ///
  /// In ko, this message translates to:
  /// **'더보기'**
  String get more;

  /// No description provided for @mySavedCourses.
  ///
  /// In ko, this message translates to:
  /// **'마이 추천 코스 보관함'**
  String get mySavedCourses;

  /// No description provided for @nickname.
  ///
  /// In ko, this message translates to:
  /// **'닉네임'**
  String get nickname;

  /// No description provided for @notificationSetting.
  ///
  /// In ko, this message translates to:
  /// **'알림 설정'**
  String get notificationSetting;

  /// No description provided for @notificationTitle.
  ///
  /// In ko, this message translates to:
  /// **'알림'**
  String get notificationTitle;

  /// No description provided for @placeUnit.
  ///
  /// In ko, this message translates to:
  /// **'개 매장'**
  String get placeUnit;

  /// No description provided for @pointHistoryTitle.
  ///
  /// In ko, this message translates to:
  /// **'포인트 내역'**
  String get pointHistoryTitle;

  /// No description provided for @pointWelcomeBonus.
  ///
  /// In ko, this message translates to:
  /// **'회원가입 축하 포인트'**
  String get pointWelcomeBonus;

  /// No description provided for @points.
  ///
  /// In ko, this message translates to:
  /// **'포인트'**
  String get points;

  /// No description provided for @policyRefundTitle.
  ///
  /// In ko, this message translates to:
  /// **'예약 및 취소 운영정책'**
  String get policyRefundTitle;

  /// No description provided for @policySupportInquiry.
  ///
  /// In ko, this message translates to:
  /// **'고객지원 문의'**
  String get policySupportInquiry;

  /// No description provided for @productManage.
  ///
  /// In ko, this message translates to:
  /// **'상품 및 메뉴 관리'**
  String get productManage;

  /// No description provided for @profileActivityLog.
  ///
  /// In ko, this message translates to:
  /// **'내 활동 기록'**
  String get profileActivityLog;

  /// No description provided for @profileBusinessApply.
  ///
  /// In ko, this message translates to:
  /// **'사업자 회원 신청'**
  String get profileBusinessApply;

  /// No description provided for @profileEdit.
  ///
  /// In ko, this message translates to:
  /// **'프로필 수정'**
  String get profileEdit;

  /// No description provided for @profileFavorites.
  ///
  /// In ko, this message translates to:
  /// **'즐겨찾기 보관함'**
  String get profileFavorites;

  /// No description provided for @profileFeedback.
  ///
  /// In ko, this message translates to:
  /// **'내 피드백 & 문의'**
  String get profileFeedback;

  /// No description provided for @profileInfoSupport.
  ///
  /// In ko, this message translates to:
  /// **'정보 및 지원'**
  String get profileInfoSupport;

  /// No description provided for @profileLogout.
  ///
  /// In ko, this message translates to:
  /// **'로그아웃'**
  String get profileLogout;

  /// No description provided for @profileMyReservations.
  ///
  /// In ko, this message translates to:
  /// **'내 예약 내역'**
  String get profileMyReservations;

  /// No description provided for @profileMyReviews.
  ///
  /// In ko, this message translates to:
  /// **'내가 작성한 리뷰'**
  String get profileMyReviews;

  /// No description provided for @profilePaymentHistory.
  ///
  /// In ko, this message translates to:
  /// **'결제 및 이용 이력'**
  String get profilePaymentHistory;

  /// No description provided for @profilePointStore.
  ///
  /// In ko, this message translates to:
  /// **'포인트 교환소'**
  String get profilePointStore;

  /// No description provided for @profilePrivacyPolicy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보처리방침'**
  String get profilePrivacyPolicy;

  /// No description provided for @profileServiceSettings.
  ///
  /// In ko, this message translates to:
  /// **'서비스 설정'**
  String get profileServiceSettings;

  /// No description provided for @profileTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get profileTerms;

  /// No description provided for @profileTitle.
  ///
  /// In ko, this message translates to:
  /// **'내 정보'**
  String get profileTitle;

  /// No description provided for @pwdChangeDesc.
  ///
  /// In ko, this message translates to:
  /// **'계정 보안을 위해 정기적으로 비밀번호를 변경해 주세요.'**
  String get pwdChangeDesc;

  /// No description provided for @pwdChangeTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경'**
  String get pwdChangeTitle;

  /// No description provided for @pwdConfirm.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호 확인'**
  String get pwdConfirm;

  /// No description provided for @pwdCurrent.
  ///
  /// In ko, this message translates to:
  /// **'현재 비밀번호'**
  String get pwdCurrent;

  /// No description provided for @pwdFail.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경에 실패했습니다.'**
  String get pwdFail;

  /// No description provided for @pwdMinLen.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호는 최소 8자 이상이어야 합니다.'**
  String get pwdMinLen;

  /// No description provided for @pwdMismatch.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호가 일치하지 않습니다.'**
  String get pwdMismatch;

  /// No description provided for @pwdNew.
  ///
  /// In ko, this message translates to:
  /// **'새 비밀번호'**
  String get pwdNew;

  /// No description provided for @pwdSuccessContent.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호가 안전하게 변경되었습니다. 다시 로그인해 주세요.'**
  String get pwdSuccessContent;

  /// No description provided for @pwdSuccessTitle.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호 변경 완료'**
  String get pwdSuccessTitle;

  /// No description provided for @recommendOptPersonalized.
  ///
  /// In ko, this message translates to:
  /// **'개인화 맞춤 코스 반영'**
  String get recommendOptPersonalized;

  /// No description provided for @recommendTitle.
  ///
  /// In ko, this message translates to:
  /// **'추천'**
  String get recommendTitle;

  /// No description provided for @reservationManage.
  ///
  /// In ko, this message translates to:
  /// **'예약 관리'**
  String get reservationManage;

  /// No description provided for @reservations.
  ///
  /// In ko, this message translates to:
  /// **'예약 내역'**
  String get reservations;

  /// No description provided for @restaurantCategory.
  ///
  /// In ko, this message translates to:
  /// **'맛집/카페'**
  String get restaurantCategory;

  /// No description provided for @retry.
  ///
  /// In ko, this message translates to:
  /// **'다시 시도'**
  String get retry;

  /// No description provided for @reviewManage.
  ///
  /// In ko, this message translates to:
  /// **'리뷰 및 평가 관리'**
  String get reviewManage;

  /// No description provided for @reviews.
  ///
  /// In ko, this message translates to:
  /// **'내가 쓴 리뷰'**
  String get reviews;

  /// No description provided for @rewardLabel.
  ///
  /// In ko, this message translates to:
  /// **'보상'**
  String get rewardLabel;

  /// No description provided for @save.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get save;

  /// No description provided for @searchHint.
  ///
  /// In ko, this message translates to:
  /// **'남포동 맛집, 볼거리를 검색해 보세요'**
  String get searchHint;

  /// No description provided for @shoppingCategory.
  ///
  /// In ko, this message translates to:
  /// **'쇼핑'**
  String get shoppingCategory;

  /// No description provided for @signupBusiness.
  ///
  /// In ko, this message translates to:
  /// **'사업자 회원가입'**
  String get signupBusiness;

  /// No description provided for @signupCustomer.
  ///
  /// In ko, this message translates to:
  /// **'일반회원 가입'**
  String get signupCustomer;

  /// No description provided for @startTripButton.
  ///
  /// In ko, this message translates to:
  /// **'여행 시작하기'**
  String get startTripButton;

  /// No description provided for @statusApproved.
  ///
  /// In ko, this message translates to:
  /// **'승인됨'**
  String get statusApproved;

  /// No description provided for @statusCancelled.
  ///
  /// In ko, this message translates to:
  /// **'취소됨'**
  String get statusCancelled;

  /// No description provided for @statusClosed.
  ///
  /// In ko, this message translates to:
  /// **'휴무'**
  String get statusClosed;

  /// No description provided for @statusClosingSoon.
  ///
  /// In ko, this message translates to:
  /// **'곧 마감'**
  String get statusClosingSoon;

  /// No description provided for @statusCompleted.
  ///
  /// In ko, this message translates to:
  /// **'완료됨'**
  String get statusCompleted;

  /// No description provided for @statusOpen.
  ///
  /// In ko, this message translates to:
  /// **'영업중'**
  String get statusOpen;

  /// No description provided for @statusPending.
  ///
  /// In ko, this message translates to:
  /// **'대기중'**
  String get statusPending;

  /// No description provided for @storeManage.
  ///
  /// In ko, this message translates to:
  /// **'매장 정보 관리'**
  String get storeManage;

  /// No description provided for @tierBeta.
  ///
  /// In ko, this message translates to:
  /// **'베타 거점'**
  String get tierBeta;

  /// No description provided for @tierOfficial.
  ///
  /// In ko, this message translates to:
  /// **'공식 거점'**
  String get tierOfficial;

  /// No description provided for @tierTest.
  ///
  /// In ko, this message translates to:
  /// **'테스트 거점'**
  String get tierTest;

  /// No description provided for @todaysMissionTitle.
  ///
  /// In ko, this message translates to:
  /// **'오늘의 미션'**
  String get todaysMissionTitle;

  /// No description provided for @totalDistance.
  ///
  /// In ko, this message translates to:
  /// **'총 이동거리'**
  String get totalDistance;

  /// No description provided for @travelLogTitle.
  ///
  /// In ko, this message translates to:
  /// **'여행로그'**
  String get travelLogTitle;

  /// No description provided for @welcomeGreeting.
  ///
  /// In ko, this message translates to:
  /// **'안녕하세요!'**
  String get welcomeGreeting;

  /// No description provided for @welcomeSlogan.
  ///
  /// In ko, this message translates to:
  /// **'당신에게 꼭 맞는 여행'**
  String get welcomeSlogan;

  /// No description provided for @welcomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'남포동 여행을 환영합니다'**
  String get welcomeTitle;

  /// No description provided for @placeDescriptionTitle.
  ///
  /// In ko, this message translates to:
  /// **'장소 소개'**
  String get placeDescriptionTitle;

  /// No description provided for @locationInfoTitle.
  ///
  /// In ko, this message translates to:
  /// **'위치 정보'**
  String get locationInfoTitle;

  /// No description provided for @visitorReviewsTitle.
  ///
  /// In ko, this message translates to:
  /// **'방문자 후기'**
  String get visitorReviewsTitle;

  /// No description provided for @writeReviewBtn.
  ///
  /// In ko, this message translates to:
  /// **'후기 남기기'**
  String get writeReviewBtn;

  /// No description provided for @naverMapBtn.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도'**
  String get naverMapBtn;

  /// No description provided for @findRouteBtn.
  ///
  /// In ko, this message translates to:
  /// **'길찾기'**
  String get findRouteBtn;

  /// No description provided for @countUnit.
  ///
  /// In ko, this message translates to:
  /// **'개'**
  String get countUnit;

  /// No description provided for @reviewLoadFail.
  ///
  /// In ko, this message translates to:
  /// **'방문자 후기를 불러오지 못했습니다.'**
  String get reviewLoadFail;

  /// No description provided for @emailInquiryBtn.
  ///
  /// In ko, this message translates to:
  /// **'담당자에게 이메일 문의하기'**
  String get emailInquiryBtn;

  /// No description provided for @recommendOptPersonalizedTitle.
  ///
  /// In ko, this message translates to:
  /// **'5. 개인화 추천 옵션'**
  String get recommendOptPersonalizedTitle;

  /// No description provided for @recommendOptPersonalizedToggle.
  ///
  /// In ko, this message translates to:
  /// **'내 활동 및 즐겨찾기 반영'**
  String get recommendOptPersonalizedToggle;

  /// No description provided for @recommendOptPersonalizedDesc.
  ///
  /// In ko, this message translates to:
  /// **'최근 검색어, 즐겨찾기, 포인트 혜택을 기반으로 우선 추천합니다.'**
  String get recommendOptPersonalizedDesc;

  /// No description provided for @recommendOptExcludeVisitedToggle.
  ///
  /// In ko, this message translates to:
  /// **'이미 방문한 곳 제외'**
  String get recommendOptExcludeVisitedToggle;

  /// No description provided for @recommendOptExcludeVisitedDesc.
  ///
  /// In ko, this message translates to:
  /// **'최근 예약하셨거나 리뷰 및 미션을 완료한 장소를 코스에서 제외합니다.'**
  String get recommendOptExcludeVisitedDesc;

  /// No description provided for @recommendOptPreferRewardsToggle.
  ///
  /// In ko, this message translates to:
  /// **'미션 완료 보상(포인트) 우선'**
  String get recommendOptPreferRewardsToggle;

  /// No description provided for @recommendOptPreferRewardsDesc.
  ///
  /// In ko, this message translates to:
  /// **'아직 완료하지 않은 보상 미션이 대기 중인 장소를 우선 배치합니다.'**
  String get recommendOptPreferRewardsDesc;

  /// No description provided for @profileTierExplorer.
  ///
  /// In ko, this message translates to:
  /// **'🔰 남포 탐험가'**
  String get profileTierExplorer;

  /// No description provided for @profileTierMania.
  ///
  /// In ko, this message translates to:
  /// **'🌟 남포 매니아'**
  String get profileTierMania;

  /// No description provided for @profileTierVeteran.
  ///
  /// In ko, this message translates to:
  /// **'🏆 남포 베테랑'**
  String get profileTierVeteran;

  /// No description provided for @profilePointsLabel.
  ///
  /// In ko, this message translates to:
  /// **'보유 포인트'**
  String get profilePointsLabel;

  /// No description provided for @profileCouponsLabel.
  ///
  /// In ko, this message translates to:
  /// **'보유 쿠폰'**
  String get profileCouponsLabel;

  /// No description provided for @profileCheckAction.
  ///
  /// In ko, this message translates to:
  /// **'확인하기'**
  String get profileCheckAction;

  /// No description provided for @mapViewModeGoogle.
  ///
  /// In ko, this message translates to:
  /// **'Google 지도'**
  String get mapViewModeGoogle;

  /// No description provided for @mapViewModeGrid.
  ///
  /// In ko, this message translates to:
  /// **'장소 목록'**
  String get mapViewModeGrid;

  /// No description provided for @policyEffectiveVersion.
  ///
  /// In ko, this message translates to:
  /// **'시행 예정일: 2026년 8월 20일 | 버전: v1.0'**
  String get policyEffectiveVersion;

  /// No description provided for @policyNoticeHeader.
  ///
  /// In ko, this message translates to:
  /// **'남포고고 (Nampo GoGo) 공식 정책 안내'**
  String get policyNoticeHeader;

  /// No description provided for @reservationAction.
  ///
  /// In ko, this message translates to:
  /// **'예약하기'**
  String get reservationAction;

  /// No description provided for @tagStreetFood.
  ///
  /// In ko, this message translates to:
  /// **'길거리음식'**
  String get tagStreetFood;

  /// No description provided for @tagNutFilled.
  ///
  /// In ko, this message translates to:
  /// **'견과류가득'**
  String get tagNutFilled;

  /// No description provided for @tagPaikPick.
  ///
  /// In ko, this message translates to:
  /// **'백종원추천'**
  String get tagPaikPick;

  /// No description provided for @tagObservatory.
  ///
  /// In ko, this message translates to:
  /// **'전망대'**
  String get tagObservatory;

  /// No description provided for @tagNightView.
  ///
  /// In ko, this message translates to:
  /// **'야경명소'**
  String get tagNightView;

  /// No description provided for @tagLandmark.
  ///
  /// In ko, this message translates to:
  /// **'부산랜드마크'**
  String get tagLandmark;

  /// No description provided for @tagRawFish.
  ///
  /// In ko, this message translates to:
  /// **'활어회'**
  String get tagRawFish;

  /// No description provided for @tagOceanView.
  ///
  /// In ko, this message translates to:
  /// **'바다전망'**
  String get tagOceanView;

  /// No description provided for @tagSeafood.
  ///
  /// In ko, this message translates to:
  /// **'해산물'**
  String get tagSeafood;

  /// No description provided for @tagFilmingSite.
  ///
  /// In ko, this message translates to:
  /// **'영화촬영지'**
  String get tagFilmingSite;

  /// No description provided for @tagMemoryTrip.
  ///
  /// In ko, this message translates to:
  /// **'추억여행'**
  String get tagMemoryTrip;

  /// No description provided for @tagRetro.
  ///
  /// In ko, this message translates to:
  /// **'레트로'**
  String get tagRetro;

  /// No description provided for @tagAiRecommend.
  ///
  /// In ko, this message translates to:
  /// **'AI 추천'**
  String get tagAiRecommend;

  /// No description provided for @tagNampoSpot.
  ///
  /// In ko, this message translates to:
  /// **'남포동 명소'**
  String get tagNampoSpot;

  /// No description provided for @tagLocalGourmet.
  ///
  /// In ko, this message translates to:
  /// **'현지맛집'**
  String get tagLocalGourmet;

  /// No description provided for @tagTouristSpot.
  ///
  /// In ko, this message translates to:
  /// **'관광명소'**
  String get tagTouristSpot;

  /// No description provided for @visitorReviewsCount.
  ///
  /// In ko, this message translates to:
  /// **'방문자 후기 ({count}개)'**
  String visitorReviewsCount(Object count);

  /// No description provided for @noLocationCoordinates.
  ///
  /// In ko, this message translates to:
  /// **'위치 좌표 없음'**
  String get noLocationCoordinates;

  /// No description provided for @detailedMapFeatureNotice.
  ///
  /// In ko, this message translates to:
  /// **'상세 지도 및 도보는 향후 활성화됩니다.'**
  String get detailedMapFeatureNotice;

  /// No description provided for @noReviewsYet.
  ///
  /// In ko, this message translates to:
  /// **'작성된 후기가 없습니다.'**
  String get noReviewsYet;

  /// No description provided for @beFirstReviewer.
  ///
  /// In ko, this message translates to:
  /// **'첫 번째 후기를 남겨보세요!'**
  String get beFirstReviewer;

  /// No description provided for @hiddenMyReviewNotice.
  ///
  /// In ko, this message translates to:
  /// **'숨겨진 내 후기가 있습니다.'**
  String get hiddenMyReviewNotice;

  /// No description provided for @customerSupportCenter.
  ///
  /// In ko, this message translates to:
  /// **'고객지원센터'**
  String get customerSupportCenter;

  /// No description provided for @deleteAccount.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴'**
  String get deleteAccount;

  /// No description provided for @deleteReviewConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'리뷰를 삭제하시겠습니까?'**
  String get deleteReviewConfirmTitle;

  /// No description provided for @deleteReviewConfirmContent.
  ///
  /// In ko, this message translates to:
  /// **'삭제한 리뷰는 다른 사용자에게 표시되지 않습니다.'**
  String get deleteReviewConfirmContent;

  /// No description provided for @reviewDeletedMsg.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 삭제되었습니다.'**
  String get reviewDeletedMsg;

  /// No description provided for @reviewRestoredMsg.
  ///
  /// In ko, this message translates to:
  /// **'리뷰가 복구되었습니다.'**
  String get reviewRestoredMsg;

  /// No description provided for @undoAction.
  ///
  /// In ko, this message translates to:
  /// **'실행 취소'**
  String get undoAction;

  /// No description provided for @guestPartyFormat.
  ///
  /// In ko, this message translates to:
  /// **'{count} 명'**
  String guestPartyFormat(Object count);

  /// No description provided for @reservationMemberOnlyNotice.
  ///
  /// In ko, this message translates to:
  /// **'예약은 회원 로그인 후 사용 가능합니다.'**
  String get reservationMemberOnlyNotice;

  /// No description provided for @profileAccountManagement.
  ///
  /// In ko, this message translates to:
  /// **'계정 관리'**
  String get profileAccountManagement;

  /// No description provided for @routeWalkBtn.
  ///
  /// In ko, this message translates to:
  /// **'도보 길찾기'**
  String get routeWalkBtn;

  /// No description provided for @routeNaverBtn.
  ///
  /// In ko, this message translates to:
  /// **'네이버 지도'**
  String get routeNaverBtn;

  /// No description provided for @completedMissionsCountFormat.
  ///
  /// In ko, this message translates to:
  /// **'완료한 미션: {count}개'**
  String completedMissionsCountFormat(Object count);

  /// No description provided for @guestCouponsZero.
  ///
  /// In ko, this message translates to:
  /// **'0개'**
  String get guestCouponsZero;

  /// No description provided for @accountDeleteNoticeTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴 진행 전 반드시 확인해 주세요.'**
  String get accountDeleteNoticeTitle;

  /// No description provided for @accountDeleteSec1Title.
  ///
  /// In ko, this message translates to:
  /// **'1. 보유 포인트 전액 소멸'**
  String get accountDeleteSec1Title;

  /// No description provided for @accountDeleteSec1Body.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 완료 즉시 현재 보유하고 계신 모든 미션 포인트는 전액 영구 소멸되며, 복구가 불가능합니다.'**
  String get accountDeleteSec1Body;

  /// No description provided for @accountDeleteSec2Title.
  ///
  /// In ko, this message translates to:
  /// **'2. 미션 및 쿠폰 내역 삭제'**
  String get accountDeleteSec2Title;

  /// No description provided for @accountDeleteSec2Body.
  ///
  /// In ko, this message translates to:
  /// **'진행 중인 미션 스탬프와 구매 후 미사용된 모든 쿠폰 또한 즉시 무효화됩니다.'**
  String get accountDeleteSec2Body;

  /// No description provided for @accountDeleteSec3Title.
  ///
  /// In ko, this message translates to:
  /// **'3. 개인 식별 정보 파기'**
  String get accountDeleteSec3Title;

  /// No description provided for @accountDeleteSec3Body.
  ///
  /// In ko, this message translates to:
  /// **'계정에 기입된 이메일 정보와 프로필 데이터 등은 개인정보 처리 방침에 의거하여 마스킹 및 물리 격리 파기됩니다.'**
  String get accountDeleteSec3Body;

  /// No description provided for @accountDeleteSec4Title.
  ///
  /// In ko, this message translates to:
  /// **'4. 예약 히스토리 보존'**
  String get accountDeleteSec4Title;

  /// No description provided for @accountDeleteSec4Body.
  ///
  /// In ko, this message translates to:
  /// **'관광 통계 및 상가 거래 증빙을 위해 예약 기록은 삭제되지 않고 익명화 보존됩니다.'**
  String get accountDeleteSec4Body;

  /// No description provided for @accountDeleteAgreeCheckbox.
  ///
  /// In ko, this message translates to:
  /// **'위 안내사항을 모두 확인하였으며, 이에 동의합니다.'**
  String get accountDeleteAgreeCheckbox;

  /// No description provided for @accountDeleteFinalButton.
  ///
  /// In ko, this message translates to:
  /// **'최종 회원탈퇴 진행'**
  String get accountDeleteFinalButton;

  /// No description provided for @accountDeleteDoneTitle.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴 완료'**
  String get accountDeleteDoneTitle;

  /// No description provided for @accountDeleteDoneBody.
  ///
  /// In ko, this message translates to:
  /// **'그동안 남포 GoGo 앱을 이용해주셔서 감사합니다. 정상적으로 회원탈퇴가 완료되었습니다.'**
  String get accountDeleteDoneBody;

  /// No description provided for @accountDeleteBlockedTitle.
  ///
  /// In ko, this message translates to:
  /// **'탈퇴 불가 안내'**
  String get accountDeleteBlockedTitle;

  /// No description provided for @accountDeleteBlockedBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 소유 중인 사업장이 있어 계정을 삭제할 수 없습니다.\n다른 관리자에게 사업장 소유권을 이전하거나 고객지원(jazzbj@naver.com)으로 문의해 주세요.'**
  String get accountDeleteBlockedBody;

  /// No description provided for @accountDeleteErrorSnackBar.
  ///
  /// In ko, this message translates to:
  /// **'회원탈퇴 처리 중 오류가 발생했습니다.\n잠시 후 다시 시도하거나 고객지원으로 문의해 주세요.'**
  String get accountDeleteErrorSnackBar;

  /// No description provided for @translateAction.
  ///
  /// In ko, this message translates to:
  /// **'번역'**
  String get translateAction;

  /// No description provided for @showOriginalAction.
  ///
  /// In ko, this message translates to:
  /// **'원문 보기'**
  String get showOriginalAction;

  /// No description provided for @translating.
  ///
  /// In ko, this message translates to:
  /// **'번역 중...'**
  String get translating;

  /// No description provided for @autoTranslatedBadge.
  ///
  /// In ko, this message translates to:
  /// **'자동 번역'**
  String get autoTranslatedBadge;

  /// No description provided for @translationFailed.
  ///
  /// In ko, this message translates to:
  /// **'번역할 수 없습니다. 다시 시도해 주세요.'**
  String get translationFailed;

  /// No description provided for @myReviewBadge.
  ///
  /// In ko, this message translates to:
  /// **'내가 작성한 후기'**
  String get myReviewBadge;

  /// No description provided for @visitVerifiedBadge.
  ///
  /// In ko, this message translates to:
  /// **'방문일자 인증'**
  String get visitVerifiedBadge;

  /// No description provided for @qrVerifiedBadge.
  ///
  /// In ko, this message translates to:
  /// **'QR 인증'**
  String get qrVerifiedBadge;

  /// No description provided for @gpsVerifiedBadge.
  ///
  /// In ko, this message translates to:
  /// **'GPS 인증'**
  String get gpsVerifiedBadge;

  /// No description provided for @photoVerifiedBadge.
  ///
  /// In ko, this message translates to:
  /// **'사진 인증'**
  String get photoVerifiedBadge;

  /// No description provided for @visitVerifiedGeneralBadge.
  ///
  /// In ko, this message translates to:
  /// **'방문 인증'**
  String get visitVerifiedGeneralBadge;

  /// No description provided for @editedBadge.
  ///
  /// In ko, this message translates to:
  /// **'수정됨'**
  String get editedBadge;

  /// No description provided for @anonymousUser.
  ///
  /// In ko, this message translates to:
  /// **'익명 사용자'**
  String get anonymousUser;

  /// No description provided for @storeReview.
  ///
  /// In ko, this message translates to:
  /// **'매장 후기'**
  String get storeReview;

  /// No description provided for @restoreAction.
  ///
  /// In ko, this message translates to:
  /// **'복구하기'**
  String get restoreAction;

  /// No description provided for @rewriteAction.
  ///
  /// In ko, this message translates to:
  /// **'다시 작성'**
  String get rewriteAction;

  /// No description provided for @recommendResultTitle.
  ///
  /// In ko, this message translates to:
  /// **'추천 코스 결과'**
  String get recommendResultTitle;

  /// No description provided for @recommendCourseFormat.
  ///
  /// In ko, this message translates to:
  /// **'{companion} 남포동 나들이'**
  String recommendCourseFormat(Object companion);

  /// No description provided for @totalDistanceLabel.
  ///
  /// In ko, this message translates to:
  /// **'총 이동거리'**
  String get totalDistanceLabel;

  /// No description provided for @estTimeLabel.
  ///
  /// In ko, this message translates to:
  /// **'예상 소요시간'**
  String get estTimeLabel;

  /// No description provided for @recommendMetricsFormat.
  ///
  /// In ko, this message translates to:
  /// **'총 이동거리: {dist} km  |  예상 소요시간: 약 {time}분 ({count}개 장소)'**
  String recommendMetricsFormat(Object count, Object dist, Object time);

  /// No description provided for @saveCourseAction.
  ///
  /// In ko, this message translates to:
  /// **'이 코스 보관함 저장'**
  String get saveCourseAction;

  /// No description provided for @savedCourseBadge.
  ///
  /// In ko, this message translates to:
  /// **'보관함 저장됨'**
  String get savedCourseBadge;

  /// No description provided for @courseSavedMsg.
  ///
  /// In ko, this message translates to:
  /// **'📂 추천 코스가 보관함에 저장되었습니다.'**
  String get courseSavedMsg;

  /// No description provided for @courseUnsavedMsg.
  ///
  /// In ko, this message translates to:
  /// **'코스 저장이 해제되었습니다.'**
  String get courseUnsavedMsg;

  /// No description provided for @courseSaveErrorMsg.
  ///
  /// In ko, this message translates to:
  /// **'코스를 저장하지 못했습니다. 잠시 후 다시 시도해 주세요.'**
  String get courseSaveErrorMsg;

  /// No description provided for @courseFetchErrorMsg.
  ///
  /// In ko, this message translates to:
  /// **'추천 코스 생성을 실패하였습니다.'**
  String get courseFetchErrorMsg;

  /// No description provided for @regenerateRecommendationAction.
  ///
  /// In ko, this message translates to:
  /// **'다시 추천받기'**
  String get regenerateRecommendationAction;

  /// No description provided for @noMatchingCourseMsg.
  ///
  /// In ko, this message translates to:
  /// **'조건에 부합하는 코스를 찾을 수 없습니다.'**
  String get noMatchingCourseMsg;

  /// No description provided for @recommendFeedbackTitle.
  ///
  /// In ko, this message translates to:
  /// **'추천 결과 피드백:'**
  String get recommendFeedbackTitle;

  /// No description provided for @recommendFeedbackLikeMsg.
  ///
  /// In ko, this message translates to:
  /// **'추천 장소가 마음에 듭니다!'**
  String get recommendFeedbackLikeMsg;

  /// No description provided for @recommendFeedbackDismissMsg.
  ///
  /// In ko, this message translates to:
  /// **'관심 없는 장소로 분류되었습니다.'**
  String get recommendFeedbackDismissMsg;

  /// No description provided for @loginRequiredFeedbackMsg.
  ///
  /// In ko, this message translates to:
  /// **'로그인 후 피드백을 제출할 수 있습니다.'**
  String get loginRequiredFeedbackMsg;

  /// No description provided for @tooltipLike.
  ///
  /// In ko, this message translates to:
  /// **'좋아요'**
  String get tooltipLike;

  /// No description provided for @tooltipNotInterested.
  ///
  /// In ko, this message translates to:
  /// **'관심 없음'**
  String get tooltipNotInterested;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hans':
            return AppLocalizationsZhHans();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
