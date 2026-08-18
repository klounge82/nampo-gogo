import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';
import 'review_edit_screen.dart';
import 'review_write_screen.dart';

import '../services/review_translation_service.dart';
import '../providers/locale_provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/l10n_mappers.dart';
import '../widgets/review_card_widget.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewRepository _reviewRepository = ReviewRepository();
  final ReviewTranslationService _translationService = ReviewTranslationService();
  late TabController _tabController;

  final Set<String> _translatedReviewIds = {};
  final Map<String, String> _translatedTexts = {};
  final Set<String> _translatingReviewIds = {};
  final Set<String> _failedReviewIds = {};

  Future<void> _toggleReviewTranslation(
    Review rev,
    AppLocalizations l10n,
    String currentLocaleCode,
  ) async {
    final reviewId = rev.id;
    if (_translatedReviewIds.contains(reviewId)) {
      setState(() {
        _translatedReviewIds.remove(reviewId);
        _failedReviewIds.remove(reviewId);
      });
      return;
    }

    if (_translatedTexts.containsKey(reviewId)) {
      setState(() {
        _translatedReviewIds.add(reviewId);
        _failedReviewIds.remove(reviewId);
      });
      return;
    }

    setState(() {
      _translatingReviewIds.add(reviewId);
      _failedReviewIds.remove(reviewId);
    });

    try {
      final result = await _translationService.translateReview(
        reviewId: reviewId,
        content: rev.content,
        targetLocale: currentLocaleCode,
      );
      if (mounted) {
        setState(() {
          _translatedTexts[reviewId] = result;
          _translatedReviewIds.add(reviewId);
          _translatingReviewIds.remove(reviewId);
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _translatingReviewIds.remove(reviewId);
          _failedReviewIds.add(reviewId);
        });
      }
    }
  }

  List<Review> _activeReviews = [];
  List<Review> _deletedReviews = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyReviews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMyReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final allReviews = await _reviewRepository.getMyReviews(
        userId: userId,
        includeDeleted: true,
        limit: 50,
      );

      setState(() {
        _activeReviews = allReviews.where((r) => !r.isDeleted).toList();
        _deletedReviews = allReviews.where((r) => r.isDeleted).toList();
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final success = await _reviewRepository.deleteReview(
        reviewId,
        userId: userId,
      );
      Navigator.of(context).pop(); // Dismiss indicator

      if (success) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('리뷰가 삭제되었습니다.'),
            backgroundColor: Colors.black87,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: '실행 취소',
              textColor: AppColors.primary,
              onPressed: () => _restoreReview(reviewId),
            ),
          ),
        );
        _loadMyReviews();
      } else {
        _showErrorDialog('삭제 실패', '리뷰 삭제 중 오류가 발생했습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('삭제 실패', cleanMsg);
    }
  }

  Future<void> _restoreReview(String reviewId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      await _reviewRepository.restoreReview(reviewId, userId: userId);
      Navigator.of(context).pop(); // Dismiss indicator

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ 리뷰가 복구되었습니다.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadMyReviews();
    } catch (e) {
      Navigator.of(context).pop();
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('복구 실패', cleanMsg);
    }
  }

  void _confirmDelete(String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '리뷰를 삭제하시겠습니까?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: const Text(
          '삭제한 리뷰는 공개 목록에서 숨겨집니다.\n내가 작성한 리뷰에서 언제든 다시 작성하거나 복구할 수 있습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReview(reviewId);
            },
            child: const Text(
              '삭제',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmRestore(String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '리뷰를 복구하시겠습니까?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: const Text(
          '기존 리뷰 내용과 방문 인증 배지가 그대로 복구됩니다.\nQR 코드를 다시 인증할 필요가 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restoreReview(reviewId);
            },
            child: const Text(
              '복구하기',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('확인', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          l10n?.reviews ?? '내가 작성한 리뷰',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: '작성한 리뷰 (${_activeReviews.length})'),
            Tab(text: '삭제한 리뷰 (${_deletedReviews.length})'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('리뷰를 불러오지 못했습니다: $_errorMessage'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadMyReviews,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReviewList(_activeReviews, isDeletedTab: false),
                _buildReviewList(_deletedReviews, isDeletedTab: true),
              ],
            ),
    );
  }

  Widget _buildReviewList(List<Review> list, {required bool isDeletedTab}) {
    if (list.isEmpty) {
      return Center(
        child: Text(
          isDeletedTab ? '삭제한 매장 후기가 없습니다.' : '작성한 매장 후기가 없습니다.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyReviews,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final item = list[index];
          return _buildReviewCard(item, isDeletedTab: isDeletedTab);
        },
      ),
    );
  }

  Widget _buildReviewCard(Review review, {required bool isDeletedTab}) {
    final l10n = AppLocalizations.of(context);
    return ReviewCardWidget(
      key: ValueKey('my_review_card_${review.id}'),
      review: review,
      isMyReview: true,
      showStoreName: true,
      onEdit: isDeletedTab
          ? null
          : () async {
              final needRefresh = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewEditScreen(review: review),
                ),
              );
              if (needRefresh == true) {
                _loadMyReviews();
              }
            },
      onDelete: isDeletedTab ? null : () => _confirmDelete(review.id),
      onRestore: isDeletedTab ? () => _confirmRestore(review.id) : null,
      onRewrite: isDeletedTab
          ? () async {
              final needRefresh = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReviewWriteScreen(
                    storeId: review.storeId,
                    storeName: review.store?.name ?? (l10n?.storeReview ?? '매장 후기'),
                    rewriteReviewId: review.id,
                    initialRating: review.rating,
                    initialContent: review.content,
                  ),
                ),
              );
              if (needRefresh == true) {
                _loadMyReviews();
              }
            }
          : null,
    );
  }
}
