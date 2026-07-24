import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';

class ReviewEditScreen extends StatefulWidget {
  final Review review;

  const ReviewEditScreen({super.key, required this.review});

  @override
  State<ReviewEditScreen> createState() => _ReviewEditScreenState();
}

class _ReviewEditScreenState extends State<ReviewEditScreen> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  late TextEditingController _contentController;

  late int _rating;
  bool _isSubmitting = false;
  String _inputText = '';

  @override
  void initState() {
    super.initState();
    _rating = widget.review.rating;
    _contentController = TextEditingController(text: widget.review.content);
    _inputText = widget.review.content;

    _contentController.addListener(() {
      setState(() {
        _inputText = _contentController.text;
      });
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _updateReview() async {
    final cleanContent = _contentController.text.trim();
    if (cleanContent.length < 10) {
      _showWarningDialog('글자 수 부족', '리뷰 내용은 최소 10자 이상 작성해야 수정할 수 있습니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reviewRepository.updateReview(
        widget.review.id,
        rating: _rating,
        content: cleanContent,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✍️ 리뷰가 성공적으로 수정되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // Return true to trigger refresh on lists
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      final cleanMsg = e.toString().replaceAll('Exception:', '').trim();
      _showWarningDialog('수정 실패', cleanMsg);
    }
  }

  void _showWarningDialog(String title, String message) {
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
    final canSubmit = _inputText.trim().length >= 10 && !_isSubmitting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          '리뷰 수정',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.review.store?.name ?? '매장 후기 수정',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              '수정할 평점과 본문 내용을 기입해 주세요.',
              style: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24.0),

            // Star Input Widget
            const Text(
              '별점 평가',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  final starVal = index + 1;
                  final isFilled = starVal <= _rating;
                  return IconButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => setState(() => _rating = starVal),
                    icon: Icon(
                      isFilled ? Icons.star : Icons.star_border,
                      color: isFilled ? Colors.amber : Colors.grey.shade400,
                      size: 40.0,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 24.0),

            // Content Area
            const Text(
              '리뷰 본문',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            TextField(
              controller: _contentController,
              maxLines: 6,
              maxLength: 300,
              enabled: !_isSubmitting,
              style: const TextStyle(fontSize: 13.0),
              decoration: InputDecoration(
                fillColor: AppColors.surface,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16.0),
              ),
            ),

            // Text count info
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '${_inputText.trim().length} / 최소 10자',
                  style: TextStyle(
                    fontSize: 11.0,
                    color: _inputText.trim().length >= 10
                        ? Colors.green
                        : AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32.0),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48.0,
              child: ElevatedButton(
                onPressed: canSubmit ? _updateReview : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.0,
                        ),
                      )
                    : const Text(
                        '수정 완료',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.0,
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
