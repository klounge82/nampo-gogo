import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';

class PolicyViewerScreen extends StatelessWidget {
  final String title;
  final String content;

  const PolicyViewerScreen({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PolicyViewerScreen(title: title, content: content),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jazzbj@naver.com',
      queryParameters: {
        'subject': '[NAMPO GOGO] $title 관련 문의',
      },
    );
    try {
      final launched = await launchUrl(
        emailLaunchUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await Clipboard.setData(const ClipboardData(text: 'jazzbj@naver.com'));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.emailAppFail)),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(const ClipboardData(text: 'jazzbj@naver.com'));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.emailCopied)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.policyEffectiveVersion ?? '시행 예정일: 2026년 8월 20일 | 버전: v1.0',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.policyNoticeHeader ?? '남포고고 (Nampo GoGo) 공식 정책 안내',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SelectableText(
                      content,
                      style: const TextStyle(
                        fontSize: 14.5,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _sendEmail(context),
                  icon: const Icon(Icons.email_outlined, size: 20),
                  label: Text(l10n?.emailInquiryBtn ?? '담당자에게 이메일 문의하기'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PolicyTexts {
  static String _getLoc(String? locale) {
    final l = locale?.toLowerCase() ?? 'ko';
    if (l.contains('zh')) return 'zh_Hans';
    if (l.contains('en')) return 'en';
    if (l.contains('ja')) return 'ja';
    return 'ko';
  }

  static String getPrivacyPolicy(String? locale) {
    final loc = _getLoc(locale);
    if (loc == 'zh_Hans') {
      return '''
[NAMPO GOGO 个人信息处理方针]

生效日期：2026年8月20日 | 版本：v1.0

NAMPO GOGO（代表：黄炳俊）为了保护信息主体的个人信息，并快速顺畅地处理相关申诉，特制定并公布本个人信息处理方针。

1. 个人信息处理目的
- 会员注册及本人身份识别管理
- 店铺预约申请及批准/拒绝处理
- 到店认证（二维码扫描 / GPS 300m 范围验证）
- 客户支持及预约/评价异议处理

2. 收集的个人信息项目
- 必填：电子邮箱地址、密码哈希(bcrypt)、昵称
- 预约：预约时间、人数、客户要求事项
- 到店认证：一次性 GPS 验证（不保存移动轨迹）
- 自动生成：会话令牌、IP 地址、服务使用日志

3. 保留及销毁期限
- 注销会员时立即销毁身份识别信息或进行匿名化处理
- 依据电子商务法等相关法律法规的交易记录保留 5 年后销毁

4. 个人信息保护负责人
- 负责人及担当：黄炳俊 (NAMPO GOGO 个人信息担当)
- 电子邮箱：jazzbj@naver.com
- 运营时间：10:00 ~ 18:00 (营业时间内依次回复)
''';
    } else if (loc == 'en') {
      return '''
[NAMPO GOGO Privacy Policy]

Effective Date: August 20, 2026 | Version: v1.0

NAMPO GOGO (CEO: Byeong-jun Hwang) establishes and discloses this Privacy Policy to protect users' personal information and handle grievances smoothly and promptly.

1. Purpose of Processing Personal Information
- Member registration and identity management
- Store reservation request and approval/rejection processing
- Visit verification (QR scan / GPS 300m radius check)
- Customer support and grievance response for reservations and reviews

2. Personal Information Items Collected
- Required: Email address, Password Hash (bcrypt), Nickname
- Reservation: Date/Time, Guest count, Requests
- Visit Verification: One-time GPS verification (Movement paths are NOT tracked or saved)
- System Generated: Session token, IP address, Service logs

3. Retention and Destruction Period
- Immediate destruction or anonymization upon membership withdrawal
- Transaction records retained for 5 years under Electronic Commerce Act

4. Privacy Officer Contact
- Officer: Byeong-jun Hwang (NAMPO GOGO Privacy Team)
- Email: jazzbj@naver.com
- Support Hours: 10:00 ~ 18:00 (Mon-Fri)
''';
    } else if (loc == 'ja') {
      return '''
[NAMPO GOGO プライバシーポリシー]

施行予定日: 2026年8月20日 | バージョン: v1.0

NAMPO GOGO（代表者: ファン・ビョンジュン）は、お客様の個人情報を保護し迅速に対応するため個人情報処理方針を公開いたします。

1. 個人情報処理の目的
- 会員登録および本人識別管理
- 店舗予約申請および承認/拒否処理
- 訪問認証（QRスキャン / GPS 300m範囲検証）
- カスタマーサポートおよび予約/レビュー対応

2. 収集する個人情報項目
- 必須: メールアドレス、パスワードハッシュ(bcrypt)、ニックネーム
- 予約: 予約日時、人数、ご要望事項
- 訪問認証: 単発GPS検証（移動動線は保存されません）
- 自動生成: セッショントークン、IPアドレス、利用ログ

3. 保有および破棄期間
- 退会時、識別情報は直ちに破棄または匿名化処理
- 電子商業取引法等に基づく取引記録は5年間保管後破棄

4. 個人情報保護責任者
- 責任者: ファン・ビョンジュン (NAMPO GOGO 個人情報担当)
- メール: jazzbj@naver.com
- 営業時間: 10:00 ~ 18:00
''';
    }
    return privacyPolicy;
  }

  static String getTermsOfService(String? locale) {
    final loc = _getLoc(locale);
    if (loc == 'zh_Hans') {
      return '''
[NAMPO GOGO 服务使用条款]

生效日期：2026年8月20日 | 版本：v1.0

1. 经营者及服务信息
- 商号：NAMPO GOGO
- 代表：黄炳俊
- 电子邮箱：jazzbj@naver.com

2. 服务性质
NAMPO GOGO 是提供用户与合作店铺之间店铺信息指南及预约居间服务的平台服务。用户的预约申请在店铺批准后最终确认。

3. 预约及取消规则
用户若无法到店，须在应用内提前取消。无故未到店且未提前取消者，将被处理为未到店（No-Show）。

4. 争议受理
预约及评价相关异议或争议受理，请通过客户支持电子邮箱 (jazzbj@naver.com) 提交。
''';
    } else if (loc == 'en') {
      return '''
[NAMPO GOGO Terms of Service]

Effective Date: August 20, 2026 | Version: v1.0

1. Provider & Service Info
- Business Name: NAMPO GOGO
- CEO: Byeong-jun Hwang
- Support Email: jazzbj@naver.com

2. Nature of Service
NAMPO GOGO is a platform service providing store guidance and reservation brokerage between users and partner stores. Reservation requests are finalized upon merchant approval.

3. Reservation & Cancellation Rules
Users must cancel in advance via the app if unable to visit. Failure to visit without prior cancellation may be processed as a No-Show.

4. Dispute Handling
Please submit disputes or inquiries regarding reservations/reviews to jazzbj@naver.com.
''';
    } else if (loc == 'ja') {
      return '''
[NAMPO GOGO サービス利用規約]

施行予定日: 2026年8月20日 | バージョン: v1.0

1. 事業者およびサービス情報
- 屋号: NAMPO GOGO
- 代表者: ファン・ビョンジュン
- カスタマーサポート: jazzbj@naver.com

2. サービスの性質
NAMPO GOGOは、利用者と提携店舗間の店舗情報案内および予約仲介を提供するプラットフォームサービスです。

3. 予約およびキャンセル規定
ご来店が困難な場合は、アプリ内で事前キャンセルを行ってください。事前キャンセルなしでご来店されなかった場合、ノーショー(No-Show)として処理される場合があります。

4. 紛争受付
予約・レビューに関する異議申し立ては、カスタマーサポート(jazzbj@naver.com)までご連絡ください。
''';
    }
    return termsOfService;
  }

  static String getReservationPolicy(String? locale) {
    final loc = _getLoc(locale);
    if (loc == 'zh_Hans') {
      return '''
[NAMPO GOGO 预约及取消运营政策]

生效日期：2026年8月20日 | 版本：v1.0

1. 预约状态管理 (7种)
- 待批准 (PENDING)
- 已批准 (APPROVED)
- 已拒绝 (REJECTED)
- 用户取消 (CANCELLED_BY_CUSTOMER)
- 店铺取消 (CANCELLED_BY_BUSINESS)
- 已完成 (COMPLETED)
- 未到店 (NO_SHOW)

2. 预约限制规则
- 预约开始时间前不可处理为完成使用。
- 预约开始时间起最少经过15分钟后方可处理为未到店(No-Show)。

3. 争议咨询
电子邮箱：jazzbj@naver.com
''';
    } else if (loc == 'en') {
      return '''
[NAMPO GOGO Reservation & Cancellation Policy]

Effective Date: August 20, 2026 | Version: v1.0

1. Reservation Status Types (7 Statuses)
- Pending (PENDING)
- Approved (APPROVED)
- Rejected (REJECTED)
- Cancelled by Customer (CANCELLED_BY_CUSTOMER)
- Cancelled by Business (CANCELLED_BY_BUSINESS)
- Completed (COMPLETED)
- No-Show (NO_SHOW)

2. Time Restriction Rules
- Usage completion cannot be processed before the reservation start time.
- No-Show status can be applied only after at least 15 minutes have elapsed from the reservation start time.

3. Inquiry Email: jazzbj@naver.com
''';
    } else if (loc == 'ja') {
      return '''
[NAMPO GOGO 予約およびキャンセル運営方針]

施行予定日: 2026年8月20日 | バージョン: v1.0

1. 予約ステータス管理 (7種類)
- 承認待ち (PENDING)
- 予約承認 (APPROVED)
- 承認拒否 (REJECTED)
- ユーザーキャンセル (CANCELLED_BY_CUSTOMER)
- 店舗キャンセル (CANCELLED_BY_BUSINESS)
- 利用完了 (COMPLETED)
- ノーショー (NO_SHOW)

2. 予約制限ルール
- 予約開始時刻前には利用完了処理はできません。
- 予約開始時刻から最低15分経過後よりノーショー処理が可能です。

3. お問い合わせ: jazzbj@naver.com
''';
    }
    return reservationPolicy;
  }

  static String getReviewVisitPolicy(String? locale) {
    final loc = _getLoc(locale);
    if (loc == 'zh_Hans') {
      return '''
[NAMPO GOGO 评价及到店认证运营政策]

生效日期：2026年8月20日 | 版本：v1.0

1. 到店认证方式
- 商家店铺：二维码或小票扫描认证 (BUSINESS_QR)
- 景点/公共场所：GPS 位置半径 300m 认证或手动日期认证 (ATTRACTION_LOCATION)

2. 评价管理标准
仅限完成实际到店认证的会员方可为每次认证撰写 1 条评价。虚假撰写、恶言、诽谤评价可能会被删除。
''';
    } else if (loc == 'en') {
      return '''
[NAMPO GOGO Review & Visit Verification Policy]

Effective Date: August 20, 2026 | Version: v1.0

1. Visit Verification Methods
- Partner Stores: Merchant QR code or receipt scan (BUSINESS_QR)
- Tourist Attractions: GPS 300m radius check or manual visit date (ATTRACTION_LOCATION)

2. Review Management Standards
Only members with verified visits can submit 1 review per verification. Fraudulent, abusive, or defamatory reviews will be removed.
''';
    } else if (loc == 'ja') {
      return '''
[NAMPO GOGO レビューおよび訪問認証運営方針]

施行予定日: 2026年8月20日 | バージョン: v1.0

1. 訪問認証方式
- 加盟店舗: QRコードまたはレシートスキャン認証 (BUSINESS_QR)
- 観光地/公共場所: GPS位置半径300m認証または手動訪問日 (ATTRACTION_LOCATION)

2. レビュー管理基準
実際の訪問認証を完了した会員のみ、1回の認証につき1件のレビューを投稿できます。

3. お問い合わせ: jazzbj@naver.com
''';
    }
    return reviewVisitPolicy;
  }

  static String getLocationCameraGuide(String? locale) {
    final loc = _getLoc(locale);
    if (loc == 'zh_Hans') {
      return '''
[NAMPO GOGO 位置及相机权限指南]

生效日期：2026年8月20日 | 版本：v1.0

1. 位置权限 (Location)
- 龙头山公园等景点到店认证时，仅单次验证 300m 半径存在性，不持续追踪或保存移动轨迹。
- 即使拒绝位置权限，仍可正常搜索店铺及查看信息。

2. 相机及照片权限 (Camera & Photos)
- 扫描店铺二维码时仅短时使用相机帧，不向服务器保存视频。
- 撰写评价时仅上传用户直接选择的图片文件。
''';
    } else if (loc == 'en') {
      return '''
[NAMPO GOGO Location & Camera Permission Guide]

Effective Date: August 20, 2026 | Version: v1.0

1. Location Permission (Location)
- When verifying visits at tourist spots like Yongdusan Park, a one-time 300m radius check is performed. Movement paths are NOT continuously tracked or stored.
- Even if location permission is denied, store search and information viewing remain fully functional.

2. Camera & Photo Permissions (Camera & Photos)
- Camera frames are used temporarily only while scanning store QR codes; videos are never recorded or saved to servers.
- Only image files explicitly selected by the user during review creation are uploaded.
''';
    } else if (loc == 'ja') {
      return '''
[NAMPO GOGO 位置情報およびカメラ権限のご案内]

施行予定日: 2026年8月20日 | バージョン: v1.0

1. 位置情報権限 (Location)
- 龍頭山公園等の観光地訪問認証時、300m半径の存在確認を1回のみ行い、移動動線を継続的に追跡・保存することはありません。

2. カメラおよび写真権限 (Camera & Photos)
- 店舗QRスキャン時、カメラフレームのみを一時的に活用し動画をサーバーに保存することはありません。
''';
    }
    return locationCameraGuide;
  }

  static const String privacyPolicy = '''
[남포고고 개인정보 처리방침]

시행일자: 2026년 8월 20일
버전: v1.0

남포고고(대표자: 황병준)는 정보주체의 개인정보를 보호하고 이와 관련한 고충을 신속하고 원활하게 처리할 수 있도록 개인정보 처리방침을 수립·공개합니다.

1. 개인정보 처리 목적
- 회원 가입 및 본인 식별 관리
- 매장 예약 신청 및 승인/거절 처리
- 방문 인증(QR 스캔 / GPS 300m 범위 검증)
- 고객지원 및 예약/리뷰 이의신청 대응

2. 수집하는 개인정보 항목
- 필수: 이메일 주소, 비밀번호 해시(bcrypt), 닉네임
- 예약: 예약일시, 인원수, 고객 요청사항
- 방문 인증: 1회성 GPS 검증 (이동동선 미저장)
- 자동생성: 세션 토큰, IP 주소, 서비스 이용 로그

3. 보유 및 파기기간
- 회원 탈퇴 시 식별 정보 즉시 파기 또는 익명화 처리
- 전자상거래법 등 관계 법령에 따른 거래 기록은 5년 보관 후 파기

4. 개인정보 보호책임자
- 책임자 및 담당자: 황병준 (남포고고 개인정보 담당)
- 이메일: jazzbj@naver.com
- 운영시간: 10:00 ~ 18:00 (영업시간 내 순차 답변)
''';

  static const String termsOfService = '''
[남포고고 서비스 이용약관]

시행일자: 2026년 8월 20일
버전: v1.0

1. 사업자 및 서비스 정보
- 상호명: 남포고고
- 대표자: 황병준
- 고객지원 이메일: jazzbj@naver.com

2. 서비스의 성격
남포고고는 이용자와 제휴 매장 간의 매장 정보 안내 및 예약 중개를 제공하는 플랫폼 서비스입니다. 이용자의 예약 신청은 매장의 승인 후 최종 확정됩니다.

3. 예약 및 취소 규칙
이용자는 방문이 어려울 경우 앱 내에서 사전 취소를 진행해야 합니다. 사전 취소 없이 방문하지 않는 경우 노쇼(No-Show)로 처리될 수 있습니다.

4. 분쟁 접수
예약·리뷰 관련 이의신청 또는 분쟁 접수는 고객지원 이메일(jazzbj@naver.com)을 통해 접수해 주세요.
''';

  static const String reservationPolicy = '''
[남포고고 예약 및 취소 운영정책]

시행일자: 2026년 8월 20일
버전: v1.0

1. 예약 상태 관리 (7가지)
- 승인 대기 (PENDING)
- 예약 승인 (APPROVED)
- 승인 거절 (REJECTED)
- 이용자 취소 (CANCELLED_BY_CUSTOMER)
- 매장 취소 (CANCELLED_BY_BUSINESS)
- 이용 완료 (COMPLETED)
- 노쇼 (NO_SHOW)

2. 예약 시간 제한 규칙
- 예약 시작 시각 이전에는 이용 완료 처리가 불가능합니다.
- 예약 시작 시각 후 최소 15분이 경과한 이후부터 노쇼 처리가 가능합니다.

3. 분쟁 문의
이메일: jazzbj@naver.com
''';

  static const String reviewVisitPolicy = '''
[남포고고 리뷰 및 방문 인증 운영정책]

시행일자: 2026년 8월 20일
버전: v1.0

1. 방문 인증 방식
- 사업자 매장: QR 코드 또는 영수증 스캔 인증 (BUSINESS_QR)
- 관광지/공공장소: GPS 위치 반경 300m 인증 또는 수동 방문일자 (ATTRACTION_LOCATION)

2. 리뷰 관리 기준
실제 방문 인증을 완료한 회원만 1개 인증당 1개의 리뷰를 작성할 수 있습니다. 허위 작성, 욕설, 타인 비방 리뷰는 삭제될 수 있습니다.
''';

  static const String locationCameraGuide = '''
[남포고고 위치 및 카메라 권한 안내]

시행일자: 2026년 8월 20일

1. 위치 권한 (Location)
- 용두산공원 등 관광지 방문 인증 시 300m 반경 존재 여부를 1회 검증하며, 이동 동선을 지속 추적하거나 저장하지 않습니다.
- 위치 권한을 거부하더라도 매장 검색 및 정보 조회는 가능합니다.

2. 카메라 및 사진 권한 (Camera & Photos)
- 매장 QR 스캔 시 카메라 프레임만 단시 활용하며 동영상을 서버에 저장하지 않습니다.
- 리뷰 작성 시 이용자가 직접 선택한 이미지 파일만 서버에 업로드됩니다.
''';
}
