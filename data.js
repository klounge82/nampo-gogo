// data.js - Nampo GoGo MVP Extended Data Source with Ratings & Local Seed

window.NampoGoGoData = {
  // Translations for Multi-Language Support
  translations: {
    ko: {
      appName: "Nampo GoGo",
      tagline: "남포동 스마트 로컬 여행 상생 플랫폼",
      dashboard: "대시보드",
      explore: "매장 탐색",
      qrScanner: "QR 스캔",
      travelLog: "여행 로그",
      profile: "내 정보",
      
      // Menu Items
      menuFood: "먹거리 🍤",
      menuActivity: "체험 💆",
      menuShopping: "쇼핑 🛍️",
      menuSightseeing: "관광지 🗼",
      menuCourse: "추천코스 🗺️",
      menuBenefit: "혜택매장 🎁",
      menuLog: "내 여행로그 👣",

      // Update Panel
      updateBtn: "업데이트 내역",
      updateTitle: "최근 업데이트 소식",
      writeNoticeBtn: "공지 추가",
      noticePlaceholder: "공지할 업데이트 내용을 입력하세요.",
      
      // Auth & Roles
      loginTitle: "3초 초간단 가입 & 로그인",
      loginDesc: "아이디와 비밀번호만 입력하면 즉시 가입 및 이용이 가능합니다.",
      usernamePlaceholder: "아이디(닉네임) 입력",
      passwordPlaceholder: "비밀번호 입력",
      passwordConfirmPlaceholder: "비밀번호 확인 입력",
      authBtn: "로그인 / 가입 완료",
      logoutBtn: "로그아웃",
      welcomeUser: "님, 반갑습니다!",
      pleaseLogin: "로그인 후 QR 인증과 여행 로그를 기록해 보세요.",
      roleVisitor: "관광객 모드",
      roleMerchant: "사업자 모드",
      roleAdmin: "최고 관리자 모드",
      joinTypeVisitor: "관광객(손님)으로 가입",
      joinTypeMerchant: "사업자(상인)로 가입",
      
      // Explore & Partners
      exploreTitle: "남포동 연계 제휴 매장",
      exploreDesc: "마사지, 맛집, 카페, 쇼핑, 야경 코스까지 남포동의 베스트 파트너사입니다.",
      allCategories: "전체 카테고리",
      catMassage: "뷰티 & 마사지",
      catFood: "남포 맛집",
      catCafe: "감성 카페",
      catShopping: "쇼핑 & 패션",
      catSightseeing: "관광 & 야경",
      benefitTitle: "🎁 관광객 제휴 혜택",
      getDirection: "도보 길찾기",
      distance: "거리",
      
      // Merchant & Admin Dashboard UI
      merchantTitle: "내 매장 관리 대시보드",
      merchantDesc: "오늘 방문자 수와 스탬프 발급 건수를 체크하고 정보를 편집하세요.",
      visitorToday: "오늘 방문자 수",
      visitorTotal: "누적 방문자 수",
      qrStampsIssued: "QR 인증 횟수",
      reviewCount: "등록된 리뷰 수",
      editStoreInfo: "매장 상세 정보 수정",
      saveStoreSuccess: "매장 정보가 성공적으로 업데이트되었습니다!",
      
      adminTitle: "Nampo GoGo 통합 어드민",
      adminDesc: "새 매장 정보 등록, 업데이트 공지 관리 및 전체 리뷰 모니터링을 수행합니다.",
      addStoreBtn: "신규 제휴 매장 등록",
      storeNameLabel: "매장명 입력",
      storeCategoryLabel: "카테고리 선택",
      storeImageLabel: "대표 이미지 URL",
      storeBenefitLabel: "관광객 혜택 내용",
      storePriceLabel: "가격 정보 (예: 기본 코스 50,000원)",
      isPartnerLabel: "Nampo GoGo 공식 제휴 등록 여부",
      addStoreSuccess: "신규 매장이 리스트에 성공적으로 등록되었습니다!",
      
      // QR scanner & Verification
      qrTitle: "제휴매장 QR 인증",
      qrDesc: "매장에 비치된 Nampo GoGo QR 코드를 스캔하세요.",
      qrCameraSim: "카메라 인식 중... (가상 스캔)",
      qrScanSuccess: "Nampo GoGo 공식 제휴 인증 완료!",
      btnConfirmStamp: "직원 확인 후 혜택 받기",
      scanBtnText: "매장 QR 코드 스캔하기 📷",
      alreadyStamped: "오늘 방문 인증 완료 👣",
      stampTime: "입점 시간",
      stampDate: "방문 날짜",
      stampStaffVerify: "★ Nampo GoGo 공식 혜택 대상자임을 증명함 (직원 확인용)",
      
      // Travel Log & Timeline
      logTitle: "나의 여행 로그 카드",
      logDesc: "QR 인증으로 수집된 나만의 남포동 여행 코스 리포트입니다.",
      emptyLog: "아직 방문 인증된 매장이 없습니다. 제휴 매장을 방문하고 스탬프를 적립해 보세요!",
      logCount: "방문한 매장 수",
      snsExport: "SNS 공유용 카드 생성 📸",
      snsSuccess: "인스타그램 공유용 텍스트가 복사되었습니다! 카드를 다운로드해 올려보세요.",
      snsCopyText: "공유 텍스트 복사",
      snsDownloadImg: "스토리 카드 다운로드",
      memoLabel: "내 여행 간단 메모 작성",
      memoPlaceholder: "매장에서 느낀 생각이나 후기를 적어두세요.",
      memoSaveBtn: "메모 저장",
      memoSavedSuccess: "메모가 여행 로그에 안전하게 저장되었습니다!",
      
      // Review
      reviewTitle: "방문자 한줄 후기",
      reviewInputPlaceholder: "실제 방문객만 작성할 수 있는 정직한 후기 한줄을 적어주세요.",
      reviewBtn: "리뷰 등록",
      ratingLabel: "평점 선택",
      noReviews: "아직 작성된 한줄 후기가 없습니다. 첫 번째 리뷰어가 되어보세요!",
      reviewAuthError: "⚠️ QR 방문 인증을 완료한 회원만 후기를 작성할 수 있습니다."
    },
    en: {
      appName: "Nampo GoGo",
      tagline: "Nampo-dong Smart Local Tour Platform",
      dashboard: "Home",
      explore: "Explore",
      qrScanner: "QR Scan",
      travelLog: "Travel Log",
      profile: "Profile",
      
      // Menu Items
      menuFood: "Food 🍤",
      menuActivity: "Activity 💆",
      menuShopping: "Shopping 🛍️",
      menuSightseeing: "Sights 🗼",
      menuCourse: "Courses 🗺️",
      menuBenefit: "Benefits 🎁",
      menuLog: "My Log 👣",
      
      // Update Panel
      updateBtn: "Updates",
      updateTitle: "Recent Update Logs",
      writeNoticeBtn: "Post Notice",
      noticePlaceholder: "Enter update description to notify.",
      
      // Auth & Roles
      loginTitle: "3-Sec Quick Login",
      loginDesc: "Just enter Username & Password to instantly join and use the service.",
      usernamePlaceholder: "Enter Username",
      passwordPlaceholder: "Enter Password",
      passwordConfirmPlaceholder: "Confirm Password",
      authBtn: "Login / Join",
      logoutBtn: "Logout",
      welcomeUser: "Welcome, ",
      pleaseLogin: "Login to verify visits and record your travel log.",
      roleVisitor: "Visitor Mode",
      roleMerchant: "Merchant Mode",
      roleAdmin: "Admin Mode",
      joinTypeVisitor: "Register as Visitor",
      joinTypeMerchant: "Register as Merchant",
      
      // Explore & Partners
      exploreTitle: "Nampo-dong Partner Shops",
      exploreDesc: "From massage and diners to cafes, shopping, and scenic spots.",
      allCategories: "All Categories",
      catMassage: "Beauty & Spa",
      catFood: "Local Diners",
      catCafe: "Trendy Cafes",
      catShopping: "Shopping & Fashion",
      catSightseeing: "Sights & Night",
      benefitTitle: "🎁 Tourist Benefit",
      getDirection: "Walk Route",
      distance: "Distance",
      
      // Merchant & Admin Dashboard UI
      merchantTitle: "Merchant Manager Dashboard",
      merchantDesc: "Check today's traffic, stamps issued, and modify store info.",
      visitorToday: "Today's Visitors",
      visitorTotal: "Total Visitors",
      qrStampsIssued: "QR Stamps Claimed",
      reviewCount: "Customer Reviews",
      editStoreInfo: "Edit Store Profile",
      saveStoreSuccess: "Store profile successfully updated!",
      
      adminTitle: "Nampo GoGo Main Admin Console",
      adminDesc: "Add/delete stores, manage updates, and monitor reviews.",
      addStoreBtn: "Register New Partner",
      storeNameLabel: "Store Name",
      storeCategoryLabel: "Category",
      storeImageLabel: "Cover Image URL",
      storeBenefitLabel: "Tourist Benefits",
      storePriceLabel: "Pricing Detail (e.g. Course 50K KRW)",
      isPartnerLabel: "Nampo GoGo Certified Partner",
      addStoreSuccess: "New store successfully registered!",
      
      // QR scanner & Verification
      qrTitle: "Partner QR Stamp",
      qrDesc: "Scan the Nampo GoGo QR code placed at the store.",
      qrCameraSim: "Detecting Camera... (Virtual Scan)",
      qrScanSuccess: "Nampo GoGo Official Certification Complete!",
      btnConfirmStamp: "Claim Benefit (Staff Confirm)",
      scanBtnText: "Scan Store QR Code 📷",
      alreadyStamped: "Checked-in Today 👣",
      stampTime: "Checked-in Time",
      stampDate: "Checked-in Date",
      stampStaffVerify: "★ Proven Nampo GoGo Benefit Claimant (For Staff Verification)",
      
      // Travel Log & Timeline
      logTitle: "My Travel Log Card",
      logDesc: "Auto-generated report of your Nampo-dong journey based on QR check-ins.",
      emptyLog: "No visited shops yet. Visit partner stores and claim stamps!",
      logCount: "Visited Shops",
      snsExport: "Generate SNS Card 📸",
      snsSuccess: "Instagram caption copied! Download the card to share.",
      snsCopyText: "Copy Text Caption",
      snsDownloadImg: "Download Story Card",
      memoLabel: "Write Travel Memo",
      memoPlaceholder: "Leave your thoughts, highlights, or tips here.",
      memoSaveBtn: "Save Memo",
      memoSavedSuccess: "Memo saved securely in your travel log!",
      
      // Review
      reviewTitle: "Visitor Reviews",
      reviewInputPlaceholder: "Only verified visitors can leave a review. Write a line!",
      reviewBtn: "Submit Review",
      ratingLabel: "Choose Rating",
      noReviews: "No reviews yet. Be the first to leave a review!",
      reviewAuthError: "⚠️ Only members who completed QR visit check-in can write reviews."
    },
    zh: {
      appName: "Nampo GoGo",
      tagline: "南浦洞智能本地旅游联名相生平台",
      dashboard: "大厅",
      explore: "店铺探访",
      qrScanner: "QR扫码",
      travelLog: "旅游日志",
      profile: "我的信息",
      
      // Menu Items
      menuFood: "美食 🍤",
      menuActivity: "体验 💆",
      menuShopping: "购物 🛍️",
      menuSightseeing: "景点 🗼",
      menuCourse: "推荐路线 🗺️",
      menuBenefit: "优惠商户 🎁",
      menuLog: "我的日志 👣",
      
      // Update Panel
      updateBtn: "更新日志",
      updateTitle: "最近更新记录",
      writeNoticeBtn: "发布公告",
      noticePlaceholder: "请输入需要公告의 업데이트 로그.",
      
      // Auth & Roles
      loginTitle: "3秒极速注册 & 登录",
      loginDesc: "只需输入账号（昵称）和密码即可立即注册并使用服务。",
      usernamePlaceholder: "请输入账号",
      passwordPlaceholder: "请输入密码",
      passwordConfirmPlaceholder: "请确认密码",
      authBtn: "登录 / 注册完成",
      logoutBtn: "退出登录",
      welcomeUser: "您好，",
      pleaseLogin: "登录后即可进行QR扫码验证并记录您的旅游日志。",
      roleVisitor: "游客模式",
      roleMerchant: "商户管理模式",
      roleAdmin: "主管理员模式",
      joinTypeVisitor: "注册为游客",
      joinTypeMerchant: "注册为合作商户",
      
      // Explore & Partners
      exploreTitle: "南浦洞联名合作店铺",
      exploreDesc: "提供按摩理疗、当地美食、人气咖啡厅、潮流购物以及观光路线。",
      allCategories: "全部类别",
      catMassage: "美容与按摩",
      catFood: "南浦美食",
      catCafe: "情调咖啡厅",
      catShopping: "购物与时尚",
      catSightseeing: "观光与夜景",
      benefitTitle: "🎁 游客专享特惠",
      getDirection: "步行导航",
      distance: "距离",
      
      // Merchant & Admin Dashboard UI
      merchantTitle: "商户管理后台",
      merchantDesc: "检查今日访客、优惠发放数，并在此更新您商铺的数据。",
      visitorToday: "今日访客数",
      visitorTotal: "累计访客数",
      qrStampsIssued: "QR到店扫码量",
      reviewCount: "注册点评数",
      editStoreInfo: "修改商铺简介",
      saveStoreSuccess: "商铺信息成功更新！",
      
      adminTitle: "Nampo GoGo 主控制台",
      adminDesc: "添加/删除商户，发布全局更新，对商户进行管理。",
      addStoreBtn: "注册新联名商铺",
      storeNameLabel: "商铺名称",
      storeCategoryLabel: "分类",
      storeImageLabel: "封面图片 URL",
      storeBenefitLabel: "游客特别特惠",
      storePriceLabel: "价目表 (例如: 基本款 50,000 KRW)",
      isPartnerLabel: "Nampo GoGo 官方合作商户",
      addStoreSuccess: "新商铺注册成功！",
      
      // QR scanner & Verification
      qrTitle: "合作商家QR认证",
      qrDesc: "请扫描商家店里放置的 Nampo GoGo 二维码。",
      qrCameraSim: "正在识别摄像头... (模拟扫码)",
      qrScanSuccess: "Nampo GoGo 官方到店身份验证成功！",
      btnConfirmStamp: "店员确认并获取优惠",
      scanBtnText: "扫描商家二维码 📷",
      alreadyStamped: "今天已到店认证 👣",
      stampTime: "入店时间",
      stampDate: "验证日期",
      stampStaffVerify: "★ 已证实该用户为 Nampo GoGo 特惠受惠者 (店员确认专用)",
      
      // Travel Log & Timeline
      logTitle: "我的旅游日志卡片",
      logDesc: "根据您的QR到店验证自动生成的南浦洞旅游路线报告。",
      emptyLog: "暂无到店记录。前往联名店铺扫码赢印章吧！",
      logCount: "到店商家数",
      snsExport: "制作SNS分享卡片 📸",
      snsSuccess: "Instagram分享文案已复制！请下载卡片进行分享。",
      snsCopyText: "复制分享文本",
      snsDownloadImg: "下载快拍卡片",
      memoLabel: "撰写随手记备注",
      memoPlaceholder: "在此记录您当时的想法，有趣的点或小提示。",
      memoSaveBtn: "保存备注",
      memoSavedSuccess: "备忘便签成功保存至旅游日志！",
      
      // Review
      reviewTitle: "顾客真实点评",
      reviewInputPlaceholder: "只有实际扫码到店的顾客才能撰写点评。请写下您宝贵的一句话评语！",
      reviewBtn: "提交点评",
      ratingLabel: "选择评分",
      noReviews: "暂无点评。快来抢写第一个沙发点评吧！",
      reviewAuthError: "⚠️ 只有完成QR扫码到店验证的会员才能写点评。"
    },
    ja: {
      appName: "Nampo GoGo",
      tagline: "南浦洞スマートローカル旅行相生プラットフォーム",
      dashboard: "ホーム",
      explore: "店舗探訪",
      qrScanner: "QRスキャン",
      travelLog: "旅行ログ",
      profile: "マイ情報",
      
      // Menu Items
      menuFood: "グルメ 🍤",
      menuActivity: "体験 💆",
      menuShopping: "買い物 🛍️",
      menuSightseeing: "観光 🗼",
      menuCourse: "おすすめ 🗺️",
      menuBenefit: "特典店 🎁",
      menuLog: "マイログ 👣",
      
      // Update Panel
      updateBtn: "更新履歴",
      updateTitle: "最近のアップデート内容",
      writeNoticeBtn: "お知らせ投稿",
      noticePlaceholder: "アップデートする内容を入力してください.",
      
      // Auth & Roles
      loginTitle: "3秒簡単登録＆ログイン",
      loginDesc: "IDとパスワードを入力するだけで、すぐに会員登録して利用できます.",
      usernamePlaceholder: "ID(ニックネーム)を入力",
      passwordPlaceholder: "パスワードを入力",
      passwordConfirmPlaceholder: "確認用パスワードを入力",
      authBtn: "ログイン / 登録完了",
      logoutBtn: "ログアウト",
      welcomeUser: "様、ようこそ！",
      pleaseLogin: "ログインしてQRチェックインを行い、旅行ログを記録しましょう.",
      roleVisitor: "観光客モード",
      roleMerchant: "店舗主モード",
      roleAdmin: "最高管理者モード",
      joinTypeVisitor: "一般観光客として登録",
      joinTypeMerchant: "加盟店主として登録",
      
      // Explore & Partners
      exploreTitle: "南浦洞の提携加盟店",
      exploreDesc: "マッサージ、ローカルグルメ、おしゃれカフェ、ショッピング、夜景スポットまで.",
      allCategories: "全カテゴリー",
      catMassage: "美容＆マッサージ",
      catFood: "南浦グルメ",
      catCafe: "カフェ",
      catShopping: "ショッピング",
      catSightseeing: "観光＆夜景",
      benefitTitle: "🎁 観光客限定特典",
      getDirection: "徒歩ルート",
      distance: "距離",
      
      // Merchant & Admin Dashboard UI
      merchantTitle: "加盟店主ダッシュボード",
      merchantDesc: "本日の来客数、スタンプ発行数、店舗情報を管理します.",
      visitorToday: "今日の来客数",
      visitorTotal: "累計来客数",
      qrStampsIssued: "QRスキャン回数",
      reviewCount: "口コミ登録数",
      editStoreInfo: "店舗詳細の編集",
      saveStoreSuccess: "店舗情報が正常に保存されました！",
      
      adminTitle: "Nampo GoGo 統合アドミン",
      adminDesc: "新規提携店登録、アップデート履歴の公開、口コミ管理を行います.",
      addStoreBtn: "新規提携店舗を登録",
      storeNameLabel: "店舗名",
      storeCategoryLabel: "カテゴリー",
      storeImageLabel: "代表画像 URL",
      storeBenefitLabel: "観光客向け特典",
      storePriceLabel: "価格情報 (例: 基本コース 50,000 KRW)",
      isPartnerLabel: "Nampo GoGo 公式提携店登録",
      addStoreSuccess: "新規店舗が正常に登録されました！",
      
      // QR scanner & Verification
      qrTitle: "加盟店QRチェックイン",
      qrDesc: "店頭に置いてある Nampo GoGo QRコード를 스캔하세요.",
      qrCameraSim: "カメラ認識中... (擬似スキャン)",
      qrScanSuccess: "Nampo GoGo 公式チェックイン認証成功！",
      btnConfirmStamp: "スタッフ確認＆特典GET",
      scanBtnText: "店頭QRコードをスキャン 📷",
      alreadyStamped: "チェックイン済 👣",
      stampTime: "入店時間",
      stampDate: "チェックイン日",
      stampStaffVerify: "★ Nampo GoGo 公式特典対象であることを証明 (スタッフ確認用)",
      
      // Travel Log & Timeline
      logTitle: "マイ旅行ログカード",
      logDesc: "QRチェックインデータから自動作成された南浦洞旅行ルートカードです.",
      emptyLog: "訪問履歴がまだありません。提携店舗でQRチェックインをしてスタンプを貯めましょう！",
      logCount: "チェックイン数",
      snsExport: "SNS共有用カード作成 📸",
      snsSuccess: "Instagram共有用のテキストがコピーされました！カードを保存して投稿しましょう.",
      snsCopyText: "共有文言コピー",
      snsDownloadImg: "ストーリーカード保存",
      memoLabel: "旅行メモ作成",
      memoPlaceholder: "店舗で感じたことや、自分用メモを記録してください.",
      memoSaveBtn: "メモを保存",
      memoSavedSuccess: "旅行ログにメモが保存されました！",
      
      // Review
      reviewTitle: "口コミ評価",
      reviewInputPlaceholder: "実際にQRチェックインを完了した方のみ投稿できます。レビューを一行で記入してください.",
      reviewBtn: "レビュー登録",
      ratingLabel: "評価を選択",
      noReviews: "口コミがまだありません.最初のレビュアーになってみませんか？",
      reviewAuthError: "⚠️ QRチェックインを完了した会員様のみレビューを投稿できます."
    }
  },

  // Seed Partners Data (Enhanced with 4-dimensional Google-style sub-scores)
  partners: [
    {
      id: "partner_klounge",
      name: {
        ko: "K-Lounge Massage & Beauty Therapy",
        en: "K-Lounge Massage & Beauty Therapy",
        zh: "K-Lounge 头部美发与按摩理疗",
        ja: "K-Lounge マッサージ＆ヘッドスパ"
      },
      category: "massage",
      isPartner: true,
      image: "https://images.unsplash.com/photo-1600334089648-b0d9d3028eb2?auto=format&fit=crop&w=800&q=80",
      rating: 4.9,
      // Google-style 4 dimensional ratings
      scores: {
        hygiene: 4.9,
        taste: 4.7, // As dynamic scale, mapped generally
        service: 5.0,
        cleanliness: 4.9
      },
      posX: 52,
      posY: 45,
      mapLinkNaver: "https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14363310,35.098222,목적지,,/walk",
      mapLinkGoogle: "https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.098222,129.035789&travelmode=walking",
      distanceValue: "150m",
      address: { ko: "부산 중구 구덕로 34-1 3층", en: "3F, 34-1 Gudeok-ro, Jung-gu, Busan", zh: "釜山中区九德路34-1 3楼", ja: "釜山中区九徳路34-1 3階" },
      phone: "+82-51-123-4567",
      hours: "10:00 - 23:00 (Break: None)",
      priceList: [
        { name: { ko: "아로마 전신 힐링 마사지 (60분)", en: "Aroma Body Massage (60m)", zh: "芳香全身体疗 (60分钟)", ja: "アロマ全身マッサージ (60分)" }, price: "60,000 KRW" },
        { name: { ko: "프리미엄 헤드스파 & 모발케어 (70분)", en: "Premium Head Spa & Hair Care (70m)", zh: "高端头部水疗 & 发质调理 (70分钟)", ja: "プレミアムヘッドスパ＆ヘアケア (70分)" }, price: "80,000 KRW" }
      ],
      menuForeign: {
        en: "Aroma Body Healing (60m) - 60k KRW | Premium Head Spa & Hair Care (70m) - 80k KRW",
        zh: "芳香全身体疗 (60分) - 6万韩元 | 高端头部水疗 (70分) - 8万韩元",
        ja: "アロマ全身ケア (60分) - 6万ウォン | プレミアムヘッドスパ (70分) - 8万ウォン"
      },
      benefits: {
        ko: "전 프로그램 10% 현장 할인 및 아로마 족욕 15분 무료 서비스 제공",
        en: "10% Discount on all courses & Free 15-min Aroma Foot Soak",
        zh: "所有项目享受10%现场折扣，并赠送15分钟免费香薰足浴",
        ja: "全コース10%割引 ＆ 15分無料アロマ足湯サービス"
      },
      seoDescription: "부산 남포동 최고급 마사지 테라피 및 K-뷰티 헤드스파 전문 매장 K-Lounge. 외국인 환영, 실시간 10% 즉시 할인 혜택.",
      seoKeywords: "남포동 마사지, 남포동 헤드스파, 부산 K-뷰티, Nampodong Massage, Nampo Spa",
      reviews: [
        { username: "TravelerJohn", rating: 5, content: { ko: "마사지 실력이 엄청납니다! 남포동 걷고 피로 풀기에 최고네요.", en: "Amazing skills! Best way to relieve fatigue after walking Nampodong.", zh: "手法非常专业！逛完南浦洞来这里放松简直完美。", ja: "マッサージが本当に上手です！南浦洞を歩き回った疲れが吹っ飛びました。" } },
        { username: "Yuki_Osaka", rating: 5, content: { ko: "가게가 아주 깔끔하고 한국어, 영어가 모두 잘 통했습니다. 추천합니다.", en: "Very clean shop. Staff speaks good English. Highly recommend!", zh: "店铺干净整洁，职员服务态度极佳，支持多语言交流，强力推荐！", ja: "お店がとても清潔で日本語も少し通じました。とても癒されました。" } }
      ]
    },
    {
      id: "partner_jagalchi",
      name: {
        ko: "자갈치 원조 삼대 꼼장어",
        en: "Jagalchi Original Cauldron Hagfish",
        zh: "自札齿市场三代烤盲鳗老店",
        ja: "チャガル치元祖三代ヌタ우나기"
      },
      category: "food",
      isPartner: true,
      image: "https://images.unsplash.com/photo-1579871494447-9811cf80d66c?auto=format&fit=crop&w=800&q=80",
      rating: 4.8,
      scores: {
        hygiene: 4.5,
        taste: 5.0,
        service: 4.8,
        cleanliness: 4.6
      },
      posX: 48,
      posY: 75,
      mapLinkNaver: "https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14362795,35.096783,목적지,,/walk",
      mapLinkGoogle: "https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.096783,129.031783&travelmode=walking",
      distanceValue: "420m",
      address: { ko: "부산 중구 자갈치해안로 52 1층", en: "1F, 52 Jagalchihaean-ro, Jung-gu, Busan", zh: "釜山中区自札齿海岸路52 1楼", ja: "釜山中区チャガルチ海岸路52 1階" },
      phone: "+82-51-987-6543",
      hours: "11:00 - 24:00",
      priceList: [
        { name: { ko: "짚불 꼼장어 양념/소금구이 (소)", en: "Straw-fire Hagfish (Small)", zh: "炭火烤盲鳗 辣香/盐烤 (小)", ja: "わら焼きヌタウナギ味付け/塩焼き (小)" }, price: "40,000 KRW" },
        { name: { ko: "짚불 꼼장어 양념/소금구이 (대)", en: "Straw-fire Hagfish (Large)", zh: "炭火烤盲鳗 辣香/盐烤 (大)", ja: "わら焼きヌタウナギ味付け/塩焼き (大)" }, price: "60,000 KRW" }
      ],
      menuForeign: {
        en: "Straw-fire Hagfish (S) - 40k KRW | Hagfish (L) - 60k KRW",
        zh: "炭火烤盲鳗 (小) - 4万韩元 | 烤盲鳗 (大) - 6万韩元",
        ja: "ヌタウナギ炭火焼き (小) - 4万ウォン | 炭火焼き (大) - 6万ウォン"
      },
      benefits: {
        ko: "QR 인증 후 메인메뉴 주문 시 음료수 1캔 또는 소주 1병 무료 제공",
        en: "Free 1 Can of Soda or 1 Soju with any main dish check-in",
        zh: "完成QR认证后，下单主菜即免费赠送1罐软饮料或1瓶烧酒",
        ja: "QRチェックイン後、メインディッシュ注文でソフトドリンク1缶または焼酎1瓶サービス"
      },
      seoDescription: "자갈치 시장을 대표하는 삼대 전통 짚불 꼼장어 맛집. Nampo GoGo 스탬프 회원 음료/소주 1병 무료.",
      seoKeywords: "자갈치 꼼장어, 부산 꼼장어 맛집, 자갈치시장 먹거리, Jagalchi Hagfish, Busan Local Food",
      reviews: [
        { username: "BusanLocal", rating: 5, content: { ko: "매콤하고 불향 가득한 꼼장어가 환상적이에요! 볶음밥은 꼭 먹어야 함.", en: "Spicy hagfish with amazing charcoal aroma. Fried rice at the end is a must!", zh: "炭火香气十足的香辣烤盲鳗，极其美味！最后的炒饭绝对不能错过。", ja: "ピリ辛のヌタウナギで香ばしい香りが最高です！シメ의 볶음밥은 필수." } }
      ]
    },
    {
      id: "partner_cafe",
      name: {
        ko: "남포 레이어드 모던 카페",
        en: "Nampo Layered Modern Cafe",
        zh: "南浦 Layered 艺术感现代咖啡厅",
        ja: "南浦 レイヤード モダンカフェ"
      },
      category: "cafe",
      isPartner: false,
      image: "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&w=800&q=80",
      rating: 4.7,
      scores: {
        hygiene: 4.8,
        taste: 4.7,
        service: 4.6,
        cleanliness: 4.8
      },
      posX: 70,
      posY: 30,
      mapLinkNaver: "https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14363520,35.099120,목적지,,/walk",
      mapLinkGoogle: "https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.099120,129.036120&travelmode=walking",
      distanceValue: "280m",
      address: { ko: "부산 중구 광복중앙로 12 2층", en: "2F, 12 Gwangbokjungang-ro, Jung-gu, Busan", zh: "釜山中区光复中央路12 2楼", ja: "釜山中区光復中央路12 2階" },
      phone: "+82-51-777-8888",
      hours: "09:00 - 22:00",
      priceList: [
        { name: { ko: "시그니처 아인슈페너", en: "Signature Einspanner", zh: "招牌维也纳咖啡", ja: "アインシュペナー" }, price: "6,500 KRW" },
        { name: { ko: "수제 말차 스콘", en: "Handmade Matcha Scone", zh: "手工抹茶司康", ja: "手作り抹茶スコーン" }, price: "4,800 KRW" }
      ],
      menuForeign: {
        en: "Einspanner - 6.5k KRW | Matcha Scone - 4.8k KRW",
        zh: "维也纳咖啡 - 6.5천원 | 抹茶司康 - 4.8천원",
        ja: "アインシュペナー - 6.5kウォン | 抹茶スコーン - 4.8kウォン"
      },
      benefits: {
        ko: "음료 주문 시 컵케이크 또는 구움과자 베이커리류 10% 추가 할인",
        en: "Get 10% extra discount on bakery & cupcakes with any drink purchase",
        zh: "下单任意饮品，购买纸杯蛋糕或烘焙类甜点可享10%追加特惠",
        ja: "ドリンクご注文時、カップケーキ等のベーカリー類を10%割引"
      },
      seoDescription: "부산 남포동 광복로의 감성적인 레이어드 디저트 카페. 스콘 및 시그니처 크림 아인슈페너 전문.",
      seoKeywords: "남포동 카페, 남포동 디저트, 광복동 카페, Nampo Cafe, Busan Layered Cafe",
      reviews: []
    },
    {
      id: "partner_shopping",
      name: {
        ko: "국제시장 빈티지 스트리트 매장",
        en: "Gukje Market Vintage Street Mall",
        zh: "国际市场复古潮流服饰店",
        ja: "国際市場ヴィンテージストリート"
      },
      category: "shopping",
      isPartner: true,
      image: "https://images.unsplash.com/photo-1489987707025-afc232f7ea0f?auto=format&fit=crop&w=800&q=80",
      rating: 4.5,
      scores: {
        hygiene: 4.3,
        taste: 4.0, // Non-food, neutral score
        service: 4.8,
        cleanliness: 4.4
      },
      posX: 35,
      posY: 35,
      mapLinkNaver: "https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14362945,35.098845,목적지,,/walk",
      mapLinkGoogle: "https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.098845,129.030845&travelmode=walking",
      distanceValue: "390m",
      address: { ko: "부산 중구 중구로 28 국제시장 2공구", en: "Zone 2, Gukje Market, 28 Junggu-ro, Jung-gu, Busan", zh: "釜山中区中区路28 国际市场2공구", ja: "釜山中区中区路28 国際市場2工区" },
      phone: "+82-51-333-2222",
      hours: "10:00 - 19:50",
      priceList: [
        { name: { ko: "아메리칸 빈티지 셔츠 (유니섹스)", en: "American Vintage Shirt", zh: "美式工装复古衬衫 (男女通用)", ja: "アメリカンヴィンテージシャツ" }, price: "25,000 KRW" },
        { name: { ko: "클래식 데님 자켓 (리사이클)", en: "Classic Denim Jacket", zh: "经典单宁复古夹克", ja: "クラシックデニムジャケット" }, price: "45,000 KRW" }
      ],
      menuForeign: {
        en: "Vintage Shirt - 25k KRW | Denim Jacket - 45k KRW",
        zh: "复古衬衫 - 2.5만원 | 丹宁夹克 - 4.5만원",
        ja: "ヴィンテージシャツ - 2.5万ウォン | デニムジャケット - 4.5万ウォン"
      },
      benefits: {
        ko: "3만원 이상 구매 시 남포 고고 독점 부산 일러스트 엽서 1세트 증정",
        en: "Free 1 Set of exclusive Busan Postcards with purchases over 30,000 KRW",
        zh: "购满3万韩元以上，即可赠送Nampo GoGo定制釜山插画明信片1套",
        ja: "3万ウォン以上ご購入時、Nampo GoGo限定釜山ポストカード1セットプレゼント"
      },
      seoDescription: "국제시장 빈티지 옷 골목에 위치한 셀렉티드 구제 샵. 남포 고고 회원 전용 부산 일러스트 엽서 무료 배포.",
      seoKeywords: "국제시장 빈티지, 남포동 구제샵, 부산 빈티지 쇼핑, Gukje Market Vintage, Nampo Shopping",
      reviews: []
    },
    {
      id: "partner_tower",
      name: {
        ko: "용두산 부산타워 전망대",
        en: "Yongdusan Busan Tower Observatory",
        zh: "龙头山釜山塔展望台",
        ja: "龍頭山釜山タワー展望台"
      },
      category: "sightseeing",
      isPartner: true,
      image: "https://images.unsplash.com/photo-1540959733332-eab4deceeaf7?auto=format&fit=crop&w=800&q=80",
      rating: 4.8,
      scores: {
        hygiene: 4.9,
        taste: 4.2,
        service: 4.8,
        cleanliness: 4.9
      },
      posX: 60,
      posY: 20,
      mapLinkNaver: "https://map.naver.com/v5/directions/14363294,35.097489,내위치,,/14363610,35.100222,목적지,,/walk",
      mapLinkGoogle: "https://www.google.com/maps/dir/?api=1&origin=35.097489,129.034789&destination=35.100222,129.038222&travelmode=walking",
      distanceValue: "300m",
      address: { ko: "부산 중구 용두산길 37-55 용두산공원 내", en: "Yongdusan Park, 37-55 Yongdusan-gil, Jung-gu, Busan", zh: "釜山中区龙头山街37-55 龙头山公园内", ja: "釜山中区龍頭山ギル37-55 龍頭山公園内" },
      phone: "+82-51-666-1212",
      hours: "10:00 - 22:00",
      priceList: [
        { name: { ko: "부산타워 전망대 대인 입장권", en: "Busan Tower Ticket (Adult)", zh: "釜山塔展望台成人票", ja: "釜山タワー展望台大人入場券" }, price: "12,000 KRW" },
        { name: { ko: "전망대 대인 2인 + 시그니처 팝콘 콤보", en: "2 Tickets + Popcorn Combo", zh: "双人展望票 + 招牌爆米花套餐", ja: "入場券2人分＋シグネチャーポップコーンコンボ" }, price: "29,000 KRW" }
      ],
      menuForeign: {
        en: "Observation Ticket (Adult) - 12k KRW | Ticket 2p + Popcorn Combo - 29k KRW",
        zh: "展望台成人票 - 1.2만원 | 双人票+套餐 - 2.9만원",
        ja: "展望台大人券 - 12kウォン | ペア券＋ポップコーンコンボ - 29kウォン"
      },
      benefits: {
        ko: "QR 인증 화면 제시 시 전망대 입장료 인당 2,000원 즉시 할인",
        en: "2,000 KRW Discount on Observatory Ticket when showing QR check-in page",
        zh: "凭QR到店验证画面，展望台入门票现场立减2,000韩元/人",
        ja: "QRチェックイン画面提示で、展望台入場料が2,000ウォン割引"
      },
      seoDescription: "부산 중구 남포동 일대를 한눈에 조망하는 랜드마크 용두산 부산타워. 야경 명소 및 미디어 아트 전시 수록.",
      seoKeywords: "부산타워, 용두산공원, 남포동 야경, Busan Tower, Yongdusan Nightview",
      reviews: []
    }
  ],

  // Initial Seed Update Logs
  updateHistory: [
    { date: "2026-07-07", content: "Nampo GoGo MVP 최종 완벽 폰버전(영속성, 탭동기화, 구글식 세부평점, AI 예산 코스) 릴리즈" },
    { date: "2026-07-05", content: "K-Lounge Massage 최상단 상시 노출 정적 알고리즘 보완" },
    { date: "2026-07-01", content: "3초 로그인 및 가상 QR인증 도장 수집 오픈" }
  ]
};
