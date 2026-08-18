import '../l10n/app_localizations.dart';
import '../models/place.dart';

class L10nMappers {
  /// Maps mission auth type (GPS, QR, PHOTO, MANUAL) to localized string
  static String mapMissionAuthType(AppLocalizations l10n, String authType) {
    switch (authType.toUpperCase()) {
      case 'GPS':
      case 'ATTRACTION_LOCATION':
        return l10n.authTypeGps;
      case 'QR':
      case 'BUSINESS_QR':
      case 'QR_GPS':
        return l10n.authTypeQr;
      case 'PHOTO':
        return l10n.authTypePhoto;
      default:
        return l10n.authTypeManual;
    }
  }

  /// Maps place category or auth badge to localized string
  static String mapCategory(AppLocalizations l10n, String category) {
    final catUpper = category.toUpperCase();
    if (category == '전체' || catUpper == 'ALL' || catUpper == 'ALL_CATEGORIES') {
      return l10n.categoryAll;
    } else if (catUpper.contains('PHOTO') || category.contains('사진')) {
      return l10n.authTypePhoto;
    } else if (catUpper.contains('GPS') || catUpper.contains('LOCATION') || category.contains('위치')) {
      return l10n.authTypeGps;
    } else if (catUpper.contains('QR')) {
      return l10n.authTypeQr;
    } else if (category.contains('맛집') || category.contains('식사') || category.contains('카페') || catUpper == 'FOOD') {
      return l10n.categoryFood;
    } else if (category.contains('관광') || category.contains('볼거리') || catUpper == 'ATTRACTION') {
      return l10n.categoryAttraction;
    } else if (category.contains('체험') || category.contains('문화') || catUpper == 'EXPERIENCE') {
      return l10n.categoryExperience;
    } else if (category.contains('쇼핑') || category.contains('시장') || catUpper == 'SHOPPING') {
      return l10n.categoryShopping;
    }
    return category;
  }

  /// Maps hashtag string to localized hashtag label
  static String mapTag(AppLocalizations l10n, String tag) {
    final clean = tag.replaceAll('#', '').trim();
    if (clean.contains('길거리') || clean.contains('Street')) return l10n.tagStreetFood;
    if (clean.contains('견과류') || clean.contains('Nuts')) return l10n.tagNutFilled;
    if (clean.contains('백종원')) return l10n.tagPaikPick;
    if (clean.contains('전망대') || clean.contains('Observatory')) return l10n.tagObservatory;
    if (clean.contains('야경') || clean.contains('Night')) return l10n.tagNightView;
    if (clean.contains('랜드마크') || clean.contains('Landmark')) return l10n.tagLandmark;
    if (clean.contains('활어회') || clean.contains('Raw Fish')) return l10n.tagRawFish;
    if (clean.contains('바다전망') || clean.contains('Ocean')) return l10n.tagOceanView;
    if (clean.contains('해산물') || clean.contains('Seafood')) return l10n.tagSeafood;
    if (clean.contains('영화') || clean.contains('Movie')) return l10n.tagFilmingSite;
    if (clean.contains('추억') || clean.contains('Memory')) return l10n.tagMemoryTrip;
    if (clean.contains('레트로') || clean.contains('Retro')) return l10n.tagRetro;
    if (clean.contains('AI 추천') || clean.contains('AI Recommend')) return l10n.tagAiRecommend;
    if (clean.contains('남포동 명소') || clean.contains('Nampo Spot')) return l10n.tagNampoSpot;
    if (clean.contains('현지맛집') || clean.contains('Local Gourmet')) return l10n.tagLocalGourmet;
    if (clean.contains('관광명소') || clean.contains('Tourist Spot')) return l10n.tagTouristSpot;
    return tag;
  }

  /// Maps store status (영업중, 곧 마감, 휴무) to localized string
  static String mapStatus(AppLocalizations l10n, String status) {
    switch (status) {
      case '영업중':
      case 'OPEN':
        return l10n.statusOpen;
      case '곧 마감':
      case 'CLOSING_SOON':
        return l10n.statusClosingSoon;
      case '휴무':
      case 'CLOSED':
        return l10n.statusClosed;
      case '대기중':
      case 'PENDING':
        return l10n.statusPending;
      case '승인됨':
      case 'APPROVED':
        return l10n.statusApproved;
      case '취소됨':
      case 'CANCELLED':
        return l10n.statusCancelled;
      case '완료됨':
      case 'COMPLETED':
        return l10n.statusCompleted;
      default:
        return status;
    }
  }

  /// Maps tier (OFFICIAL, VERIFIED_BETA, TEST) to localized string
  static String mapTier(AppLocalizations l10n, String tier) {
    switch (tier.toUpperCase()) {
      case 'OFFICIAL':
      case '공식 거점':
        return l10n.tierOfficial;
      case 'VERIFIED_BETA':
      case '베타 거점':
        return l10n.tierBeta;
      default:
        return l10n.tierTest;
    }
  }

  /// Maps travel companion type to localized string
  static String mapCompanion(AppLocalizations l10n, String travelType) {
    switch (travelType.toUpperCase()) {
      case 'SOLO':
        return l10n.aiCompanionSolo;
      case 'COUPLE':
        return l10n.aiCompanionCouple;
      case 'FAMILY':
        return l10n.aiCompanionFamily;
      case 'FRIENDS':
        return l10n.aiCompanionFriends;
      default:
        return travelType;
    }
  }

  /// Maps transport mode to localized string
  static String mapTransport(AppLocalizations l10n, String transportMode) {
    switch (transportMode.toUpperCase()) {
      case 'WALK':
        return l10n.aiTransitWalk;
      case 'TRANSIT':
      case 'BUS':
      case 'PUBLIC':
        return l10n.aiTransitPublic;
      case 'DRIVE':
      case 'CAR':
        return l10n.aiTransitCar;
      default:
        return transportMode;
    }
  }

  /// Maps user points to localized user tier badge string
  static String mapUserTier(AppLocalizations? l10n, int points) {
    if (points >= 5000) {
      return l10n?.profileTierVeteran ?? '🏆 남포 베테랑';
    } else if (points >= 2000) {
      return l10n?.profileTierMania ?? '🌟 남포 매니아';
    }
    return l10n?.profileTierExplorer ?? '🔰 남포 탐험가';
  }

  /// Maps review verification badge string (e.g. 방문일자 인증, QR 인증, GPS 인증) to localized string
  static String mapVerificationBadge(AppLocalizations l10n, String? rawBadge, String? method) {
    if (rawBadge == null || rawBadge.isEmpty) return '';
    final methodUpper = (method ?? '').toUpperCase();

    if (rawBadge.contains('방문일자') || methodUpper == 'ATTRACTION_DATE') {
      return l10n.visitVerifiedBadge;
    } else if (rawBadge.contains('QR') || methodUpper == 'BUSINESS_QR') {
      return l10n.qrVerifiedBadge;
    } else if (rawBadge.contains('GPS') || methodUpper == 'ATTRACTION_GPS' || methodUpper == 'GPS') {
      return l10n.gpsVerifiedBadge;
    } else if (rawBadge.contains('사진') || methodUpper == 'PHOTO') {
      return l10n.photoVerifiedBadge;
    } else if (rawBadge.contains('방문')) {
      return l10n.visitVerifiedGeneralBadge;
    }
    return rawBadge;
  }

  /// Maps AI recommendation reason code to localized string
  static String mapRecommendReason(AppLocalizations l10n, String code) {
    final loc = l10n.localeName.toLowerCase();
    switch (code) {
      case 'REASON_CATEGORY':
        return loc.contains('zh')
            ? '非常符合您选择的兴趣主题类别。'
            : (loc.startsWith('en')
                ? 'Matches your selected interest category theme.'
                : (loc.startsWith('ja')
                    ? '選択された関心テーマにぴったりの場所です。'
                    : '선택하신 관심 카테고리 테마에 잘 부합하는 장소입니다.'));
      case 'REASON_CLOSE':
        return loc.contains('zh')
            ? '距离您当前位置较近，可轻松步行到达。'
            : (loc.startsWith('en')
                ? 'Easily accessible on foot from your current location.'
                : (loc.startsWith('ja')
                    ? '現在地から徒歩でアクセスしやすい場所にあります。'
                    : '현재 기준 위치에서 도보로 가깝게 접근할 수 있습니다.'));
      case 'REASON_MISSION':
        return loc.contains('zh')
            ? '拥有可获得奖励积分的活跃任务。'
            : (loc.startsWith('en')
                ? 'Active mission available to earn bonus reward points.'
                : (loc.startsWith('ja')
                    ? 'ボーナスポイントを獲得できるアクティブミッションがあります。'
                    : '보너스 포인트를 획득할 수 있는 액티브 미션이 있습니다.'));
      case 'REASON_COUPON':
        return loc.contains('zh')
            ? '提供特惠折扣的合作优惠券商家。'
            : (loc.startsWith('en')
                ? 'Affiliated partner store offering special discount coupons.'
                : (loc.startsWith('ja')
                    ? 'お得な特典を楽しめる提携クーポン店舗です。'
                    : '혜택을 누릴 수 있는 제휴 쿠폰 상점이 마련되어 있습니다.'));
      case 'REASON_MISSION_COUPON':
        return loc.contains('zh')
            ? '同时联动打卡验证任务与可兑换优惠券。'
            : (loc.startsWith('en')
                ? 'Linked with both reward verification missions and coupons.'
                : (loc.startsWith('ja')
                    ? '認証ミッションと引き換えクーポンが連携しています。'
                    : '참여 가능한 인증 미션과 교환 쿠폰이 모두 연계되어 있습니다.'));
      case 'REASON_FAVORITE':
        return loc.contains('zh')
            ? '您已收藏在收藏夹中的商家。'
            : (loc.startsWith('en')
                ? 'A store saved in your favorites list.'
                : (loc.startsWith('ja')
                    ? 'お気に入りリストに保存された店舗です。'
                    : '즐겨찾기 목록에 보관하신 매장입니다.'));
      case 'REASON_FAVORITE_CAT':
        return loc.contains('zh')
            ? '符合您收藏偏好风格的推荐商家。'
            : (loc.startsWith('en')
                ? 'Matches the style of your saved favorites.'
                : (loc.startsWith('ja')
                    ? 'お気に入りの好みに似たスタイルの店舗です。'
                    : '즐겨찾기 취향과 유사한 스타일의 매장입니다.'));
      case 'REASON_RECENT_SEARCH':
        return loc.contains('zh')
            ? '根据您近期搜索或关注的主题推荐。'
            : (loc.startsWith('en')
                ? 'Based on your recent searches or interest theme.'
                : (loc.startsWith('ja')
                    ? '最近検索または関心を示されたテーマです。'
                    : '최근 검색하시거나 관심을 보인 관심 테마입니다.'));
      case 'REASON_REWARD':
        return loc.contains('zh')
            ? '该地点尚有待挑战的奖励任务。'
            : (loc.startsWith('en')
                ? 'Unclaimed reward mission available at this location.'
                : (loc.startsWith('ja')
                    ? 'まだ挑戦していないリワードミッションがある場所です。'
                    : '아직 도전하지 않은 보상 미션이 대기 중인 장소입니다.'));
      case 'REASON_VISITED':
        return loc.contains('zh')
            ? '虽然曾经到访过，但非常值得再次游览。'
            : (loc.startsWith('en')
                ? 'A great place worth revisiting again.'
                : (loc.startsWith('ja')
                    ? '訪問済みですが、再訪する価値のある魅力的な場所です。'
                    : '이미 방문하셨으나 다시 들르기 매력적인 장소입니다.'));
      default:
        return loc.contains('zh')
            ? '符合南浦洞名胜推荐条件的优质热门地点。'
            : (loc.startsWith('en')
                ? 'Popular spot matching Nampo-dong recommendation criteria.'
                : (loc.startsWith('ja')
                    ? '南浦洞名所おすすめ条件を満たす人気の場所です。'
                    : '남포동 명소 추천 조건에 만족하는 인기 장소입니다.'));
    }
  }

  /// Maps Place Name to localized string
  static String mapPlaceName(Place place, String localeCode) {
    final loc = localeCode.toLowerCase();
    if (loc.startsWith('ko') || loc.isEmpty) return place.name;

    final nameKo = place.name;
    final nameTrans = place.nameTranslations[loc.contains('zh') ? 'zh' : (loc.startsWith('en') ? 'en' : (loc.startsWith('ja') ? 'ja' : 'ko'))];
    if (nameTrans != null && nameTrans.isNotEmpty && nameTrans != nameKo) {
      return nameTrans;
    }

    if (loc.contains('zh')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return 'K-Lounge';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return '龙头山公园 釜山塔';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return 'BIFF广场 葵花籽糖饼';
      if (nameKo.contains('자갈치')) return '札嘎其市场 新鲜海鲜刺身';
      if (nameKo.contains('국제시장')) return '国际市场 复古胡同';
      if (nameKo.contains('보수동')) return '宝水洞二手书店街';
      if (nameKo.contains('영도대교')) return '影岛大桥 开合表演';
      if (nameKo.contains('광복로')) return '光复路时尚街';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return '罐头夜市';
    } else if (loc.startsWith('en')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return 'K-Lounge';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return 'Yongdusan Park Busan Tower';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return 'BIFF Square Seed Hotteok';
      if (nameKo.contains('자갈치')) return 'Jagalchi Market Fresh Fish';
      if (nameKo.contains('국제시장')) return 'Gukje Market Vintage Alley';
      if (nameKo.contains('보수동')) return 'Bosudong Book Street';
      if (nameKo.contains('영도대교')) return 'Yeongdodaegyo Drawbridge';
      if (nameKo.contains('광복로')) return 'Gwangbok-ro Fashion Street';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return 'Bupyeong Kkangtong Night Market';
    } else if (loc.startsWith('ja')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return 'K-Lounge';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return '龍頭山公園 釜山タワー';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return 'BIFF広場 シアホットク';
      if (nameKo.contains('자갈치')) return 'チャガルチ市場 新鮮刺身店';
      if (nameKo.contains('국제시장')) return '国際市場 古着小路';
      if (nameKo.contains('보수동')) return '宝水洞古本屋街';
      if (nameKo.contains('영도대교')) return '影島大橋 跳ね橋';
      if (nameKo.contains('광복로')) return '光復路ファッション街';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return '富平カントン夜市場';
    }
    return place.name;
  }

  /// Maps Place Address to localized string
  static String mapPlaceAddress(Place place, String localeCode) {
    final loc = localeCode.toLowerCase();
    if (loc.startsWith('ko') || loc.isEmpty) return place.address;

    final addrKo = place.address;
    if (loc.contains('zh')) {
      if (addrKo.contains('광복로 50-1')) return '釜山 中区 光复路 50-1 2楼';
      if (addrKo.contains('용두산길')) return '釜山 中区 龙头山路 37-55';
      if (addrKo.contains('구덕로')) return '釜山 中区 九德路 58-1';
      if (addrKo.contains('자갈치')) return '釜山 中区 札嘎其海岸路 52';
      if (addrKo.contains('중구로')) return '釜山 中区 中九路 36';
      if (addrKo.contains('대청로')) return '釜山 中区 大厅路 67-1';
      if (addrKo.contains('태종로')) return '釜山 中区 太宗路 1';
      if (addrKo.contains('광복로')) return '釜山 中区 光复路 74';
      if (addrKo.contains('부평')) return '釜山 中区 富平1吉 48';
      return addrKo.replaceAll('부산', '釜山').replaceAll('중구', '中区');
    } else if (loc.startsWith('en')) {
      if (addrKo.contains('광복로 50-1')) return '50-1 Gwangbok-ro, Jung-gu, Busan (2F)';
      if (addrKo.contains('용두산길')) return '37-55 Yongdusan-gil, Jung-gu, Busan';
      if (addrKo.contains('구덕로')) return '58-1 Gudeok-ro, Jung-gu, Busan';
      if (addrKo.contains('자갈치')) return '52 Jagalchihaean-ro, Jung-gu, Busan';
      if (addrKo.contains('중구로')) return '36 Junggu-ro, Jung-gu, Busan';
      if (addrKo.contains('대청로')) return '67-1 Daecheong-ro, Jung-gu, Busan';
      if (addrKo.contains('태종로')) return '1 Taejong-ro, Jung-gu, Busan';
      if (addrKo.contains('광복로')) return '74 Gwangbok-ro, Jung-gu, Busan';
      if (addrKo.contains('부평')) return '48 Bupyeong 1-gil, Jung-gu, Busan';
      return addrKo;
    } else if (loc.startsWith('ja')) {
      if (addrKo.contains('광복로 50-1')) return '釜山広域市中区光復路50-1 2階';
      if (addrKo.contains('용두산길')) return '釜山広域市中区龍頭山路37-55';
      if (addrKo.contains('구덕로')) return '釜山広域市中区九徳路58-1';
      if (addrKo.contains('자갈치')) return '釜山広域市中区チャガルチ海岸路52';
      if (addrKo.contains('중구로')) return '釜山広域市中区中九路36';
      if (addrKo.contains('대청로')) return '釜山広域市中区大庁路67-1';
      if (addrKo.contains('태종로')) return '釜山広域市中区太宗路1';
      if (addrKo.contains('광복로')) return '釜山広域市中区光復路74';
      if (addrKo.contains('부평')) return '釜山広域市中区富平1吉48';
      return addrKo;
    }
    return place.address;
  }

  /// Maps Place Description to localized string
  static String mapPlaceDescription(Place place, String localeCode) {
    final loc = localeCode.toLowerCase();
    if (loc.startsWith('ko') || loc.isEmpty) return place.description;

    final descKo = place.description;
    final nameKo = place.name;
    final descTrans = place.descriptionTranslations[loc.contains('zh') ? 'zh' : (loc.startsWith('en') ? 'en' : (loc.startsWith('ja') ? 'ja' : 'ko'))];
    if (descTrans != null && descTrans.isNotEmpty && descTrans != descKo) {
      return descTrans;
    }

    if (loc.contains('zh')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return '为旅行者提供舒适休息空间与高端服务的南浦洞K-Lounge服务中心。';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return '可在观景台一览釜山市区全景的必游观光胜地。';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return '糖饼中塞满坚果香酥可口的南浦洞招牌美食。';
      if (nameKo.contains('자갈치')) return '代表釜山的活鱼海鲜市场，可品尝到新鲜的海鲜料理。';
      if (nameKo.contains('국제시장')) return '蕴含丰富复古商品与历史的釜山最大综合传统市场。';
      if (nameKo.contains('보수동')) return '旧书店云集，散发着浓郁怀旧书香与文艺气息的巷弄。';
      if (nameKo.contains('영도대교')) return '釜山首座开合桥，可观赏历史悠久的桥梁开合壮观景象。';
      if (nameKo.contains('광복로')) return '汇聚潮流购物品牌与丰富街头小吃的繁华商业街。';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return '充满各式各样夜间街头美食与热闹夜间氛围的特色夜市。';
    } else if (loc.startsWith('en')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return 'Nampo-dong K-Lounge hub offering comfortable relaxation space and premium services for travelers.';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return 'A must-visit landmark offering panoramic views of Busan from the observatory.';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return 'Famous Nampo-dong hotteok filled with crunchy seeds.';
      if (nameKo.contains('자갈치')) return 'Busan\'s representative seafood market offering fresh raw fish.';
      if (nameKo.contains('국제시장')) return 'Busan\'s largest traditional market full of history and retro items.';
      if (nameKo.contains('보수동')) return 'A cozy alley gathered with secondhand bookstores full of nostalgic charm.';
      if (nameKo.contains('영도대교')) return 'Busan\'s first drawbridge where you can watch historical bridge openings.';
      if (nameKo.contains('광복로')) return 'Trendy shopping street filled with brand stores and street food.';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return 'Vibrant night market famous for diverse night street foods.';
    } else if (loc.startsWith('ja')) {
      if (nameKo.contains('K-Lounge') || nameKo.contains('케이라운지')) return '旅行者のための快適な休憩スペースとプレミアムサービスを提供する南浦洞K-Lounge拠点です。';
      if (nameKo.contains('용두산') || nameKo.contains('부산타워')) return '展望台から釜山市内の全景が一望できる必須観光名所です。';
      if (nameKo.contains('BIFF') || nameKo.contains('씨앗호떡')) return 'ホットクの中に種がたっぷりと入った食感を楽しめる南浦洞の名物です。';
      if (nameKo.contains('자갈치')) return '釜山を代表する鮮魚市場で新鮮な海鮮を味わえます。';
      if (nameKo.contains('국제시장')) return '多様なレトロ商品と歴史를秘めた釜山最大の総合市場です。';
      if (nameKo.contains('보수동')) return '古書店が集まり温かい本のかおりと感性を楽しめる小路です。';
      if (nameKo.contains('영도대교')) return '釜山初の跳ね橋で歴史的な開閉イベントを観覧できます。';
      if (nameKo.contains('광복로')) return 'トレンディなショッピングブランドと多彩な食べ歩きグルメが並ぶ通りです。';
      if (nameKo.contains('깡통') || nameKo.contains('부평')) return '多彩な夜の食べ歩きグルメと活気あふれる夜の雰囲気を楽しめる夜市場です。';
    }
    return place.description;
  }
}
