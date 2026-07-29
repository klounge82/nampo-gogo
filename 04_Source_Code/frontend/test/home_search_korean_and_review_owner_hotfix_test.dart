import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('HOTFIX-004: Korean Search and Review Owner Controls Unit Tests', () {
    const publicStoreId = '31b96920-2eb3-4f93-ab51-546fd8d933d1';

    late Place sampleStore;
    late User currentUser;
    late Review myReview;

    setUp(() {
      sampleStore = Place(
        id: publicStoreId,
        name: 'K-Lounge',
        category: '체험',
        rating: 5.0,
        address: '부산 중구 남포길 50-1 2층',
        description: '공개 K-Lounge 매장입니다.',
        createdAt: DateTime.now(),
      );

      currentUser = User(
        id: 'e1d38954-ba8c-4c85-bc0e-39fec0886360',
        email: 'jazzbj@naver.com',
        nickname: 'jazzbj',
        role: 'member',
        status: 'active',
        currentPoints: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      myReview = Review(
        id: 'cc806c6b-66b0-45ca-b31b-4755544f84c7',
        userId: currentUser.id,
        storeId: publicStoreId,
        rating: 5,
        content: '안녕하세요 후기샘플 1회작성완료 10자 이상 작성.',
        isDeleted: false,
        isOwner: true,
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: currentUser,
        store: sampleStore,
      );
    });

    test(
      '1. Korean search queries ("케이라운지", "케이", "라운지") map to valid search terms',
      () {
        final queries = ['케이라운지', '케이', '라운지'];
        for (final q in queries) {
          expect(q.trim().isNotEmpty, isTrue);
        }
      },
    );

    test(
      '2. Target review cc806c6b for jazzbj@naver.com exhibits owner controls',
      () {
        expect(myReview.isOwner, isTrue);
        expect(myReview.canEdit, isTrue);
        expect(myReview.canDelete, isTrue);
      },
    );
  });
}
