import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/personalization_provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/app_localizations.dart';

class RecommendationFeedbackWidget extends StatefulWidget {
  final String storeId;

  const RecommendationFeedbackWidget({super.key, required this.storeId});

  @override
  State<RecommendationFeedbackWidget> createState() =>
      _RecommendationFeedbackWidgetState();
}

class _RecommendationFeedbackWidgetState
    extends State<RecommendationFeedbackWidget> {
  String? _currentFeedback; // 'LIKE' or 'DISMISS'

  Future<void> _submitFeedback(String type) async {
    final l10n = AppLocalizations.of(context);
    final token = context.read<AuthProvider>().accessToken;
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n?.loginRequiredFeedbackMsg ?? '로그인 후 피드백을 제출할 수 있습니다.')));
      return;
    }

    final success = await context.read<PersonalizationProvider>().sendFeedback(
      token: token,
      targetType: 'PLACE',
      targetId: widget.storeId,
      feedbackType: type,
    );

    if (success) {
      if (!mounted) return;
      setState(() {
        _currentFeedback = type;
      });
      final msg = type == 'LIKE'
          ? (l10n?.recommendFeedbackLikeMsg ?? '추천 장소가 마음에 듭니다!')
          : (l10n?.recommendFeedbackDismissMsg ?? '관심 없는 장소로 분류되었습니다.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          l10n?.recommendFeedbackTitle ?? '추천 결과 피드백:',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            Icons.thumb_up,
            size: 16,
            color: _currentFeedback == 'LIKE' ? Colors.blue : Colors.grey,
          ),
          onPressed: () => _submitFeedback('LIKE'),
          tooltip: l10n?.tooltipLike ?? '좋아요',
        ),
        IconButton(
          icon: Icon(
            Icons.thumb_down,
            size: 16,
            color: _currentFeedback == 'DISMISS' ? Colors.red : Colors.grey,
          ),
          onPressed: () => _submitFeedback('DISMISS'),
          tooltip: l10n?.tooltipNotInterested ?? '관심 없음',
        ),
      ],
    );
  }
}
