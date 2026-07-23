import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../repositories/review_repository.dart';
import '../providers/auth_provider.dart';

class ReviewWriteScreen extends StatefulWidget {
  final String storeId;
  final String storeName;
  final String? verificationId;
  final String? guestId;

  const ReviewWriteScreen({
    super.key,
    required this.storeId,
    required this.storeName,
    this.verificationId,
    this.guestId,
  });

  @override
  State<ReviewWriteScreen> createState() => _ReviewWriteScreenState();
}

class _ReviewWriteScreenState extends State<ReviewWriteScreen> {
  final ReviewRepository _reviewRepository = ReviewRepository();
  final TextEditingController _contentController = TextEditingController();

  int _rating = 5;
  bool _isSubmitting = false;
  String _inputText = '';

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitReview() async {
    final cleanContent = _contentController.text.trim();
    if (cleanContent.length < 10) {
      _showWarningDialog('글자 수 부족', '리뷰 내용은 최소 10자 이상 작성해야 제출할 수 있습니다.');
      return;
    }

    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.currentUser?.id;

    try {
      await _reviewRepository.createReview(
        storeId: widget.storeId,
        rating: _rating,
        content: cleanContent,
        userId: userId,
        guestId: widget.guestId,
        verificationId: widget.verificationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✍️ 리뷰가 정상적으로 등록되었습니다.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(
          context,
        ).pop(true); // Return true to trigger refresh on list
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      final rawStr = e.toString();
      final is409 = rawStr.contains('409') || rawStr.contains('이미');
      final title = is409 ? '이미 등록된 리뷰입니다.' : '제출 실패';
      final message = is409
          ? '이 매장에 작성된 방문 후기가 이미 존재합니다.\n중복 리뷰는 등록되지 않았습니다.'
          : rawStr
                .replaceAll('Exception:', '')
                .replaceAll('DioException', '')
                .trim();
      _showWarningDialog(
        title,
        message.isEmpty ? '리뷰를 등록하지 못했습니다. 잠시 후 다시 시도해 주세요.' : message,
      );
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
          '리뷰 작성',
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
            // Store Title Info
            Text(
              '${widget.storeName}',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4.0),
            const Text(
              '매장에 대한 신뢰할 수 있는 소중한 후기를 남겨주세요.',
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
                hintText:
                    '리뷰 내용은 최소 10자 이상 작성해야 합니다. 광고성이나 악의적인 허위 사실 유포 시 리뷰가 삭제될 수 있습니다.',
                hintStyle: const TextStyle(
                  fontSize: 12.0,
                  color: AppColors.textHint,
                ),
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
                onPressed: canSubmit ? _submitReview : null,
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
                        '리뷰 등록 완료',
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
