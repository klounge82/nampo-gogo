import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';
import 'review_edit_screen.dart';
import 'review_write_screen.dart';

import '../l10n/app_localizations.dart';
import '../widgets/review_card_widget.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen>
    with SingleTickerProviderStateMixin {
  final ReviewRepository _reviewRepository = ReviewRepository();
  late TabController _tabController;

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
    final l10n = AppLocalizations.of(context);
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
      if (mounted) Navigator.of(context).pop(); // Dismiss indicator

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.myReviewsDeleteSuccess ?? 'Review deleted.'),
              backgroundColor: Colors.black87,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: l10n?.undoAction ?? 'Undo',
                textColor: AppColors.primary,
                onPressed: () => _restoreReview(reviewId),
              ),
            ),
          );
        }
        _loadMyReviews();
      } else {
        if (mounted) {
          _showErrorDialog(
            l10n?.dialogErrorTitle ?? '오류',
            l10n?.myReviewsDeleteFailed ?? 'Failed to delete review.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(
          l10n?.dialogErrorTitle ?? '오류',
          l10n?.myReviewsDeleteFailed ?? 'Failed to delete review.',
        );
      }
    }
  }

  Future<void> _restoreReview(String reviewId) async {
    final l10n = AppLocalizations.of(context);
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
      if (mounted) Navigator.of(context).pop(); // Dismiss indicator

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.myReviewsRestoreSuccess ?? 'Review restored.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      _loadMyReviews();
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(
          l10n?.dialogErrorTitle ?? '오류',
          l10n?.myReviewsRestoreFailed ?? 'Failed to restore review.',
        );
      }
    }
  }

  void _confirmDelete(String reviewId) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.deleteReviewConfirmTitle ?? 'Delete review?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: Text(
          l10n?.deleteReviewConfirmContent ?? 'Deleted reviews will be hidden from public.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReview(reviewId);
            },
            child: Text(
              l10n?.confirm ?? 'Confirm',
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          l10n?.myReviewsRestoreConfirmTitle ?? 'Restore review?',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: Text(
          l10n?.myReviewsRestoreConfirmBody ?? 'The original review content and badge will be restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n?.cancel ?? 'Cancel', style: const TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _restoreReview(reviewId);
            },
            child: Text(
              l10n?.myReviewsRestoreAction ?? 'Restore',
              style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
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
            child: Text(l10n?.confirm ?? 'OK', style: const TextStyle(color: AppColors.primary)),
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
          l10n?.reviews ?? 'Reviews',
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
            Tab(text: l10n?.myReviewsTabActiveFormat(_activeReviews.length) ?? 'Active (${_activeReviews.length})'),
            Tab(text: l10n?.myReviewsTabDeletedFormat(_deletedReviews.length) ?? 'Deleted (${_deletedReviews.length})'),
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
                  Text(l10n?.myReviewsLoadFailed ?? 'Failed to load reviews.'),
                  const SizedBox(height: 16.0),
                  ElevatedButton(
                    onPressed: _loadMyReviews,
                    child: Text(l10n?.retry ?? 'Retry'),
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
    final l10n = AppLocalizations.of(context);
    if (list.isEmpty) {
      return Center(
        child: Text(
          isDeletedTab
              ? (l10n?.myReviewsDeletedEmpty ?? 'No deleted reviews.')
              : (l10n?.myReviewsActiveEmpty ?? 'No reviews written yet.'),
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
