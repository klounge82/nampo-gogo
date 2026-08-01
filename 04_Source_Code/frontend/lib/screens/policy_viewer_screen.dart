import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'jazzbj@naver.com',
      queryParameters: {
        'subject': '[남포고고] $title 관련 문의',
      },
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이메일 앱을 열 수 없습니다. jazzbj@naver.com 으로 직접 문의해 주세요.')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('jazzbj@naver.com 으로 문의 내용을 보내 주세요.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '시행 예정일: 2026년 8월 20일 | 버전: v1.0',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '남포고고 (Nampo GoGo) 공식 정책 안내',
                            style: TextStyle(fontSize: 12, color: Colors.black87),
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
                  label: const Text('담당자에게 이메일 문의하기'),
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
- 사업자등록번호: [사업자등록 완료 후 공개 예정]
- 통신판매업 신고번호: [신고 완료 후 공개 예정]
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
