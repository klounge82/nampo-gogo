import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';
import 'review_edit_screen.dart';

class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  List<Review> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMyReviews();
  }

  Future<void> _loadMyReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      final list = await _reviewRepository.getMyReviews(userId: userId);
      setState(() {
        _reviews = list;
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
    // Show indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    try {
      final success = await _reviewRepository.deleteReview(reviewId);
      Navigator.of(context).pop(); // Dismiss indicator

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🛑 리뷰가 정상적으로 삭제되었습니다.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadMyReviews();
      } else {
        _showErrorDialog('삭제 실패', '리뷰 삭제 중 서버 에러가 발생했습니다.');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Dismiss indicator
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showErrorDialog('삭제 실패', cleanMsg);
    }
  }

  void _confirmDelete(String reviewId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          '리뷰 삭제',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        content: const Text(
          '정말로 이 후기를 삭제하시겠습니까?\n삭제된 후기는 일반 목록에 더 이상 노출되지 않습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('유지하기', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteReview(reviewId);
            },
            child: const Text(
              '삭제하기',
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '내가 작성한 리뷰',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
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
          : _reviews.isEmpty
          ? const Center(
              child: Text(
                '작성한 매장 후기가 없습니다.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadMyReviews,
              color: AppColors.primary,
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _reviews.length,
                itemBuilder: (context, index) {
                  final item = _reviews[index];
                  return _buildReviewCard(item);
                },
              ),
            ),
    );
  }

  Widget _buildReviewCard(Review review) {
    final dateStr =
        '${review.createdAt.year}.${review.createdAt.month.toString().padLeft(2, '0')}.${review.createdAt.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 6.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Store Name & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  review.store?.name ?? '매장 후기',
                  style: const TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),

            // Stars
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: index < review.rating
                      ? Colors.amber
                      : Colors.grey.shade300,
                  size: 16.0,
                );
              }),
            ),
            if (review.verificationBadge != null &&
                review.verificationBadge!.isNotEmpty) ...[
              const SizedBox(height: 6.0),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6.0,
                  vertical: 2.0,
                ),
                decoration: BoxDecoration(
                  color: review.verificationMethod == 'BUSINESS_QR'
                      ? Colors.green.shade50
                      : (review.verificationMethod == 'ATTRACTION_GPS'
                            ? Colors.blue.shade50
                            : Colors.grey.shade100),
                  borderRadius: BorderRadius.circular(4.0),
                  border: Border.all(
                    color: review.verificationMethod == 'BUSINESS_QR'
                        ? Colors.green.shade300
                        : (review.verificationMethod == 'ATTRACTION_GPS'
                              ? Colors.blue.shade300
                              : Colors.grey.shade300),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      review.verificationMethod == 'BUSINESS_QR'
                          ? Icons.verified
                          : (review.verificationMethod == 'ATTRACTION_GPS'
                                ? Icons.location_on
                                : Icons.article),
                      size: 11.0,
                      color: review.verificationMethod == 'BUSINESS_QR'
                          ? Colors.green.shade700
                          : (review.verificationMethod == 'ATTRACTION_GPS'
                                ? Colors.blue.shade700
                                : Colors.grey.shade700),
                    ),
                    const SizedBox(width: 3.0),
                    Text(
                      review.verificationBadge!,
                      style: TextStyle(
                        fontSize: 10.0,
                        fontWeight: FontWeight.bold,
                        color: review.verificationMethod == 'BUSINESS_QR'
                            ? Colors.green.shade800
                            : (review.verificationMethod == 'ATTRACTION_GPS'
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12.0),

            // Content
            Text(
              review.content,
              style: const TextStyle(
                fontSize: 13.0,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16.0),
            const Divider(height: 1.0, thickness: 1.0, color: AppColors.border),
            const SizedBox(height: 8.0),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final needRefresh = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ReviewEditScreen(review: review),
                      ),
                    );
                    if (needRefresh == true) {
                      _loadMyReviews();
                    }
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14.0),
                  label: const Text('수정', style: TextStyle(fontSize: 12.0)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8.0),
                TextButton.icon(
                  onPressed: () => _confirmDelete(review.id),
                  icon: const Icon(Icons.delete_outline, size: 14.0),
                  label: const Text('삭제', style: TextStyle(fontSize: 12.0)),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
