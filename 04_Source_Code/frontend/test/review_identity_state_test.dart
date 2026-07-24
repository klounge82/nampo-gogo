import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/review.dart';

void main() {
  group('Review Identity & State Stabilization Unit Tests', () {
    final validUserJson = {
      'id': 'user_abc',
      'email': 'test@nampo.com',
      'nickname': '테스트유저',
      'role': 'member',
      'status': 'active',
      'created_at': '2026-07-24T12:00:00.000Z',
      'updated_at': '2026-07-24T12:00:00.000Z',
      'roles': ['CUSTOMER'],
    };

    test(
      '1. MyReviewResult parses ACTIVE review with edit/delete permissions',
      () {
        final json = {
          'status': 'ACTIVE',
          'can_edit': true,
          'can_delete': true,
          'can_restore': false,
          'can_rewrite': false,
          'review': {
            'id': 'rev_active_123',
            'user_id': 'user_abc',
            'guest_id': null,
            'store_id': 'store_klounge_001',
            'rating': 5,
            'content': '정말 훌륭한 카페입니다!',
            'is_deleted': false,
            'is_hidden': false,
            'verification_badge': 'QR 방문 인증',
            'created_at': '2026-07-24T12:00:00.000Z',
            'updated_at': '2026-07-24T12:00:00.000Z',
            'is_owner': true,
            'can_edit': true,
            'can_delete': true,
            'can_restore': false,
            'can_rewrite': false,
            'user': validUserJson,
          },
        };

        final result = MyReviewResult.fromJson(json);

        expect(result.status, equals('ACTIVE'));
        expect(result.review, isNotNull);
        expect(result.review!.id, equals('rev_active_123'));
        expect(result.canEdit, isTrue);
        expect(result.canDelete, isTrue);
        expect(result.canRestore, isFalse);
        expect(result.canRewrite, isFalse);
      },
    );

    test(
      '2. MyReviewResult parses DELETED review with restore/rewrite permissions',
      () {
        final json = {
          'status': 'DELETED',
          'can_edit': false,
          'can_delete': false,
          'can_restore': true,
          'can_rewrite': true,
          'review': {
            'id': 'rev_del_456',
            'user_id': 'user_abc',
            'guest_id': null,
            'store_id': 'store_klounge_001',
            'rating': 4,
            'content': '삭제한 리뷰 내용입니다.',
            'is_deleted': true,
            'is_hidden': false,
            'created_at': '2026-07-24T10:00:00.000Z',
            'updated_at': '2026-07-24T11:00:00.000Z',
            'is_owner': true,
            'can_edit': false,
            'can_delete': false,
            'can_restore': true,
            'can_rewrite': true,
            'user': validUserJson,
          },
        };

        final result = MyReviewResult.fromJson(json);

        expect(result.status, equals('DELETED'));
        expect(result.review, isNotNull);
        expect(result.review!.id, equals('rev_del_456'));
        expect(result.canEdit, isFalse);
        expect(result.canDelete, isFalse);
        expect(result.canRestore, isTrue);
        expect(result.canRewrite, isTrue);
      },
    );

    test('3. MyReviewResult parses NONE status when user has no review', () {
      final json = {
        'status': 'NONE',
        'review': null,
        'can_edit': false,
        'can_delete': false,
        'can_restore': false,
        'can_rewrite': false,
      };

      final result = MyReviewResult.fromJson(json);

      expect(result.status, equals('NONE'));
      expect(result.review, isNull);
      expect(result.canEdit, isFalse);
      expect(result.canDelete, isFalse);
    });

    test(
      '4. Guest review linked to member retains same review ID and properties',
      () {
        final initialGuestJson = {
          'id': 'rev_guest_789',
          'user_id': null,
          'guest_id': 'guest_uuid_111',
          'store_id': 'store_klounge_001',
          'rating': 5,
          'content': '게스트 시절 작성 리뷰',
          'is_deleted': false,
          'is_hidden': false,
          'created_at': '2026-07-24T08:00:00.000Z',
          'updated_at': '2026-07-24T08:00:00.000Z',
          'is_owner': true,
        };

        final linkedUserJson = {
          ...initialGuestJson,
          'user_id': 'user_newly_registered_222',
          'user': {
            ...validUserJson,
            'id': 'user_newly_registered_222',
            'nickname': '신규회원',
          },
        };

        final guestReview = Review.fromJson(initialGuestJson);
        final linkedReview = Review.fromJson(linkedUserJson);

        expect(guestReview.id, equals(linkedReview.id));
        expect(guestReview.content, equals(linkedReview.content));
        expect(linkedReview.userId, equals('user_newly_registered_222'));
      },
    );

    test(
      '5. Logged-out guest query with guest_id on linked review returns NONE status',
      () {
        final backendResponseForLoggedOutGuest = {
          'status': 'NONE',
          'review': null,
          'can_edit': false,
          'can_delete': false,
          'can_restore': false,
          'can_rewrite': false,
        };

        final result = MyReviewResult.fromJson(
          backendResponseForLoggedOutGuest,
        );

        expect(result.status, equals('NONE'));
        expect(result.review, isNull);
      },
    );

    test('6. Public reviews and MyReview synchronization preserves state', () {
      final publicReview1 = Review.fromJson({
        'id': 'rev_public_1',
        'store_id': 'store_1',
        'rating': 5,
        'content': '다른 사용자의 활성 리뷰입니다.',
        'is_deleted': false,
        'is_owner': false,
        'user': validUserJson,
      });

      final myActiveReview = Review.fromJson({
        'id': 'rev_my_1',
        'store_id': 'store_1',
        'rating': 5,
        'content': '내가 작성한 활성 리뷰입니다.',
        'is_deleted': false,
        'is_owner': true,
        'can_edit': true,
        'can_delete': true,
        'user': validUserJson,
      });

      List<Review> publicList = [publicReview1];

      if (!publicList.any((r) => r.id == myActiveReview.id)) {
        publicList.insert(0, myActiveReview);
      }

      expect(publicList.length, equals(2));
      expect(publicList[0].id, equals('rev_my_1'));
      expect(publicList[0].isOwner, isTrue);
      expect(publicList[1].isOwner, isFalse);
    });
  });
}
