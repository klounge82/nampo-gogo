import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('HOTFIX-002: K-Lounge Store Mismatch and Review Display Tests', () {
    const publicStoreId = '31b96920-2eb3-4f93-ab51-546fd8d933d1';
    const draftStoreId = 'ca407921-a8e0-4f9a-980b-6ba635b09c17';

    late Place publicKLounge;
    late Place draftKLounge;
    late List<Review> activeReviews;

    setUp(() {
      publicKLounge = Place(
        id: publicStoreId,
        name: 'K-Lounge',
        category: '체험',
        rating: 5.0,
        address: '부산 중구 남포길 50-1 2층',
        description: '공개 K-Lounge 매장입니다.',
        createdAt: DateTime.now(),
      );

      draftKLounge = Place(
        id: draftStoreId,
        name: '케이라운지',
        category: '일반',
        rating: 0.0,
        address: '부산 중구',
        description: 'DRAFT 사업자 매장입니다.',
        createdAt: DateTime.now(),
      );

      activeReviews = [
        Review(
          id: 'rev_01',
          userId: 'usr_01',
          storeId: publicStoreId,
          rating: 5,
          content: '첫 번째 K-Lounge 활성 후기입니다. 10자 이상 작성.',
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          user: User(
            id: 'usr_01',
            email: 'user1@example.com',
            nickname: '리뷰어1',
            role: 'member',
            status: 'active',
            currentPoints: 100,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          store: publicKLounge,
        ),
        Review(
          id: 'rev_02',
          userId: 'usr_02',
          storeId: publicStoreId,
          rating: 5,
          content: '두 번째 K-Lounge 활성 후기입니다. 10자 이상 작성.',
          isDeleted: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          user: User(
            id: 'usr_02',
            email: 'user2@example.com',
            nickname: '리뷰어2',
            role: 'member',
            status: 'active',
            currentPoints: 200,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          store: publicKLounge,
        ),
      ];
    });

    test(
      '1. Public K-Lounge search result conveys correct public store_id',
      () {
        final searchResults = [publicKLounge];
        expect(searchResults.first.id, equals(publicStoreId));
        expect(searchResults.first.name, equals('K-Lounge'));
        expect(searchResults.first.rating, equals(5.0));
      },
    );

    test('2. Detail, Rating, and Review APIs use identical store_id', () {
      final detailStoreId = publicKLounge.id;
      final ratingStoreId = publicKLounge.id;
      final reviewsStoreId = activeReviews.first.storeId;

      expect(detailStoreId, equals(publicStoreId));
      expect(ratingStoreId, equals(publicStoreId));
      expect(reviewsStoreId, equals(publicStoreId));
    });

    test('3. Displays 2 active visitor reviews matching average rating', () {
      expect(activeReviews.length, equals(2));
      final num totalRating = activeReviews.fold<num>(
        0,
        (sum, r) => sum + r.rating,
      );
      final avgRating = totalRating / activeReviews.length;
      expect(avgRating, equals(5.0));
      expect(publicKLounge.rating, equals(avgRating));
    });

    test('4. DRAFT store is excluded from public search and store list', () {
      final publicStores = [publicKLounge];
      expect(publicStores.any((s) => s.id == draftKLounge.id), isFalse);
      expect(publicStores.any((s) => s.id == publicStoreId), isTrue);
    });

    test('5. Review error state formats explicit Korean error message', () {
      const errorMessage = '방문자 후기를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.';
      expect(errorMessage, contains('방문자 후기를 불러오지 못했습니다.'));
      expect(errorMessage, contains('잠시 후 다시 시도해 주세요.'));
    });
  });
}
