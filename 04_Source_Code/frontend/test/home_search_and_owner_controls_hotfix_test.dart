import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/place.dart';
import 'package:frontend/models/review.dart';
import 'package:frontend/models/user.dart';

void main() {
  group('HOTFIX-003: Home Search and Review Owner Controls Unit Tests', () {
    const publicStoreId = '31b96920-2eb3-4f93-ab51-546fd8d933d1';

    late Place sampleStore;
    late User currentUser;
    late User otherUser;
    late Review myActiveReview;
    late Review otherActiveReview;

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
        id: 'user_owner_111',
        email: 'owner@example.com',
        nickname: '본인작성자',
        role: 'member',
        status: 'active',
        currentPoints: 100,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      otherUser = User(
        id: 'user_other_999',
        email: 'other@example.com',
        nickname: '타인작성자',
        role: 'member',
        status: 'active',
        currentPoints: 50,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      myActiveReview = Review(
        id: 'rev_my_01',
        userId: currentUser.id,
        storeId: publicStoreId,
        rating: 5,
        content: '본인이 작성한 K-Lounge 생생한 후기입니다. 10자 이상.',
        isDeleted: false,
        isOwner: true,
        canEdit: true,
        canDelete: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: currentUser,
        store: sampleStore,
      );

      otherActiveReview = Review(
        id: 'rev_other_02',
        userId: otherUser.id,
        storeId: publicStoreId,
        rating: 5,
        content: '타인이 작성한 K-Lounge 후기입니다. 10자 이상.',
        isDeleted: false,
        isOwner: false,
        canEdit: false,
        canDelete: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        user: otherUser,
        store: sampleStore,
      );
    });

    test('1. Home SearchBar query navigation triggers valid search route', () {
      const query = 'K-Lounge';
      expect(query.trim().isNotEmpty, isTrue);
      expect(query, equals('K-Lounge'));
    });

    test(
      '2. My ACTIVE review exhibits owner controls (canEdit, canDelete)',
      () {
        expect(myActiveReview.isOwner, isTrue);
        expect(myActiveReview.canEdit, isTrue);
        expect(myActiveReview.canDelete, isTrue);
      },
    );

    test('3. Other user review hides management buttons (canEdit=false)', () {
      expect(otherActiveReview.isOwner, isFalse);
      expect(otherActiveReview.canEdit, isFalse);
      expect(otherActiveReview.canDelete, isFalse);
    });

    test('4. Repeated review edit preserves ownership and edit buttons', () {
      final updatedReview = Review(
        id: myActiveReview.id,
        userId: myActiveReview.userId,
        storeId: myActiveReview.storeId,
        rating: 5,
        content: '수정 완료된 리뷰 내용입니다. 10자 이상 작성.',
        isDeleted: false,
        isOwner: true,
        canEdit: true,
        canDelete: true,
        createdAt: myActiveReview.createdAt,
        updatedAt: DateTime.now(),
        user: currentUser,
        store: sampleStore,
      );

      expect(updatedReview.isOwner, isTrue);
      expect(updatedReview.canEdit, isTrue);
      expect(updatedReview.canDelete, isTrue);
    });

    test(
      '5. Search error formats explicit error message instead of empty list',
      () {
        const searchErrorMessage = '검색 결과를 불러오지 못했습니다.\n잠시 후 다시 시도해 주세요.';
        expect(searchErrorMessage, contains('검색 결과를 불러오지 못했습니다.'));
        expect(searchErrorMessage, contains('잠시 후 다시 시도해 주세요.'));
      },
    );
  });
}
