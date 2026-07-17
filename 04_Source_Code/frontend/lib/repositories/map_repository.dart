import '../models/place.dart';
import '../repositories/place_repository.dart';

class MapRepository {
  final PlaceRepository _placeRepository;

  // Offline Fallback Mock Places with Coordinates (MAP-001 requirements)
  static final List<Place> _mockPlaces = [
    Place(
      id: 'store_mock_1',
      name: '남포 숯불갈비',
      category: '먹거리',
      rating: 4.8,
      address: '부산 중구 남포길 12-1',
      description: '숯불로 구워내 더욱 풍미 깊은 양념갈비 맛집입니다.',
      imageUrl: '',
      latitude: 35.0991, // Near BIFF Square
      longitude: 129.0285,
      createdAt: DateTime.now(),
    ),
    Place(
      id: 'store_mock_2',
      name: '용두산 모카 카페',
      category: '카페',
      rating: 4.5,
      address: '부산 중구 광복중앙로 24',
      description: '용두산 공원 인근에 위치한 아늑하고 경치 좋은 루프탑 카페입니다.',
      imageUrl: '',
      latitude: 35.1011,
      longitude: 129.0310,
      createdAt: DateTime.now(),
    ),
    Place(
      id: 'store_mock_3',
      name: '자갈치 꼼장어 빌리지',
      category: '쇼핑',
      rating: 4.2,
      address: '부산 중구 자갈치해안로 44',
      description: '쫄깃한 식감의 양념 꼼장어 구이를 즐길 수 있는 부산 대표 어시장 맛집입니다.',
      imageUrl: '',
      latitude: 35.0963,
      longitude: 129.0298,
      createdAt: DateTime.now(),
    ),
    Place(
      id: 'store_mock_4',
      name: '영도대교 역사 체험관',
      category: '체험',
      rating: 4.6,
      address: '부산 중구 태종로 2',
      description: '영도대교의 도개 역사와 부산 피난민들의 애환이 서린 역사를 기록한 박물관입니다.',
      imageUrl: '',
      latitude: 35.0975,
      longitude: 129.0360,
      createdAt: DateTime.now(),
    ),
  ];

  MapRepository({PlaceRepository? placeRepository})
      : _placeRepository = placeRepository ?? PlaceRepository();

  /// 지도 상에 노출할 주변 장소들을 조회합니다.
  /// API 실패 시, 로컬 모의 장소 4종(위경도 포함)을 리턴해 오프라인 폴백을 지원합니다.
  Future<List<Place>> getMapPlaces() async {
    try {
      final list = await _placeRepository.getPlaces();
      // Only return places that have coordinates defined
      final validList = list.where((p) => p.latitude != null && p.longitude != null).toList();
      
      if (validList.isEmpty) {
        return _mockPlaces;
      }
      return validList;
    } catch (_) {
      return _mockPlaces;
    }
  }
}
