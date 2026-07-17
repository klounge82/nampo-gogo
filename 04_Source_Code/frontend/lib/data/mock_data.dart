import '../models/recommendation.dart';
import '../models/mission.dart';

class MockData {
  MockData._();

  static const List<Recommendation> recommendations = [
    Recommendation(
      id: 'rec_01',
      name: 'BIFF 광장 씨앗호떡',
      category: '먹거리',
      rating: 4.8,
      address: '부산 중구 구덕로 58-1',
      description: '남포동의 필수 코스! 바삭하게 튀겨낸 호떡에 견과류가 가득 차 있어 달콤하고 고소합니다.',
      tags: ['길거리음식', '견과류가득', '백종원추천'],
    ),
    Recommendation(
      id: 'rec_02',
      name: '용두산공원 부산타워',
      category: '볼거리',
      rating: 4.6,
      address: '부산 중구 용두산길 37-55',
      description: '남포동 한가운데 우뚝 솟은 부산의 상징입니다. 전망대에서 보는 부산항과 영도대교의 뷰가 아름답습니다.',
      tags: ['전망대', '야경명소', '부산랜드마크'],
    ),
    Recommendation(
      id: 'rec_03',
      name: '자갈치시장 신선한 횟집',
      category: '맛집',
      rating: 4.7,
      address: '부산 중구 자갈치해안로 52',
      description: '부산에서 가장 큰 어시장인 자갈치시장에서 갓 잡아 올린 신선한 회와 매운탕을 즐길 수 있습니다.',
      tags: ['활어회', '바다전망', '해산물'],
    ),
    Recommendation(
      id: 'rec_04',
      name: '국제시장 꽃분이네',
      category: '볼거리',
      rating: 4.4,
      address: '부산 중구 신창동4가 국제시장 내',
      description: '영화 "국제시장"의 실제 배경지로, 추억의 물건들과 포토존이 마련되어 있습니다.',
      tags: ['영화촬영지', '추억여행', '레트로'],
    ),
  ];

  static const List<Mission> missions = [
    Mission(
      id: 'mis_01',
      title: 'BIFF 광장 호떡 인증!',
      description: 'BIFF 광장 씨앗호떡을 구매하고 사진을 촬영하여 방문을 인증해 보세요.',
      reward: '씨앗호떡 10% 할인 쿠폰',
      points: 500,
      category: '사진인증',
    ),
    Mission(
      id: 'mis_02',
      title: '용두산공원 부산타워 정복',
      description: '용두산공원 부산타워 전망대 근처에 도달한 후 GPS 위치를 인증해 보세요.',
      reward: '전망대 입장 1,000원 할인권',
      points: 1000,
      category: 'GPS인증',
    ),
    Mission(
      id: 'mis_03',
      title: '자갈치시장 맛집 방문하기',
      description: '자갈치시장 내 제휴 매장에서 식사하고 사장님 앱의 QR코드를 촬영해 인증받으세요.',
      reward: '제휴매장 음료 무료 쿠폰',
      points: 800,
      category: 'QR인증',
    ),
  ];
}
