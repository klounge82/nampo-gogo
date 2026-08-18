import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/review.dart';
import '../constants/colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/review_translation_service.dart';
import '../utils/l10n_mappers.dart';

class ReviewCardWidget extends StatefulWidget {
  final Review review;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;
  final VoidCallback? onRewrite;
  final bool isMyReview;
  final bool showStoreName;

  const ReviewCardWidget({
    super.key,
    required this.review,
    this.onEdit,
    this.onDelete,
    this.onRestore,
    this.onRewrite,
    this.isMyReview = false,
    this.showStoreName = false,
  });

  @override
  State<ReviewCardWidget> createState() => _ReviewCardWidgetState();
}

class _ReviewCardWidgetState extends State<ReviewCardWidget> {
  bool _isTranslated = false;
  bool _isLoading = false;
  String? _translatedText;
  String? _errorMessage;

  final ReviewTranslationService _translationService = ReviewTranslationService();

  Future<void> _toggleTranslation(AppLocalizations l10n, String currentLocaleCode) async {
    if (_isTranslated) {
      setState(() {
        _isTranslated = false;
        _errorMessage = null;
      });
      return;
    }

    if (_translatedText != null) {
      setState(() {
        _isTranslated = true;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _translationService.translateReview(
        reviewId: widget.review.id,
        content: widget.review.content,
        targetLocale: currentLocaleCode,
      );

      if (mounted) {
        setState(() {
          _translatedText = result;
          _isTranslated = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = l10n.translationFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String currentLocaleCode = 'ko';
    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: true);
      currentLocaleCode = localeProvider.currentLocaleCode;
    } catch (_) {
      currentLocaleCode = l10n.localeName;
    }

    final rev = widget.review;
    final isoDateStr = rev.createdAt.toIso8601String();
    final dateStr = isoDateStr.length >= 10 ? isoDateStr.substring(0, 10) : isoDateStr;
    final isEdited = rev.updatedAt.isAfter(rev.createdAt);

    final locLower = currentLocaleCode.toLowerCase();
    final isSameLanguage = locLower.startsWith('ko');

    if (kDebugMode) {
      print(
        '[TRANSLATE-UI:M04O] ReviewCard built: id=${rev.id}, isMyReview=${widget.isMyReview}, locale=$currentLocaleCode, isSameLang=$isSameLanguage',
      );
    }

    final displayName = widget.showStoreName
        ? (rev.store != null
            ? L10nMappers.mapPlaceName(rev.store!, currentLocaleCode)
            : l10n.storeReview)
        : (rev.user.nickname.isNotEmpty ? rev.user.nickname : l10n.anonymousUser);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: widget.isMyReview
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.border,
          width: widget.isMyReview ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: User/Store Name, Owner Badge, Edited Badge, Edit/Delete/Restore/Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6.0,
                  runSpacing: 4.0,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.isMyReview)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6.0,
                          vertical: 2.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          l10n.myReviewBadge,
                          style: const TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    if (isEdited)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4.0,
                          vertical: 1.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                        child: Text(
                          l10n.editedBadge,
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (widget.isMyReview && (widget.onEdit != null || widget.onDelete != null)) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onEdit != null)
                      TextButton(
                        onPressed: widget.onEdit,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.edit,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (widget.onDelete != null) ...[
                      const SizedBox(width: 4.0),
                      TextButton(
                        onPressed: widget.onDelete,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 2.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (widget.onRestore != null || widget.onRewrite != null) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.onRestore != null)
                      OutlinedButton(
                        onPressed: widget.onRestore,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.restoreAction,
                          style: const TextStyle(fontSize: 11.0),
                        ),
                      ),
                    if (widget.onRewrite != null) ...[
                      const SizedBox(width: 4.0),
                      ElevatedButton(
                        onPressed: widget.onRewrite,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.rewriteAction,
                          style: const TextStyle(fontSize: 11.0),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else
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

          // Rating Stars & Verification Badge
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rev.rating ? Icons.star : Icons.star_border,
                    color: index < rev.rating ? Colors.amber : Colors.grey.shade300,
                    size: 15.0,
                  );
                }),
              ),
              if (rev.verificationBadge != null && rev.verificationBadge!.isNotEmpty) ...[
                const SizedBox(width: 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: rev.verificationMethod == 'BUSINESS_QR'
                        ? Colors.green.shade50
                        : (rev.verificationMethod == 'ATTRACTION_GPS'
                            ? Colors.blue.shade50
                            : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(4.0),
                    border: Border.all(
                      color: rev.verificationMethod == 'BUSINESS_QR'
                          ? Colors.green.shade300
                          : (rev.verificationMethod == 'ATTRACTION_GPS'
                              ? Colors.blue.shade300
                              : Colors.grey.shade300),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        rev.verificationMethod == 'BUSINESS_QR'
                            ? Icons.verified
                            : (rev.verificationMethod == 'ATTRACTION_GPS'
                                ? Icons.location_on
                                : Icons.article),
                        size: 11.0,
                        color: rev.verificationMethod == 'BUSINESS_QR'
                            ? Colors.green.shade700
                            : (rev.verificationMethod == 'ATTRACTION_GPS'
                                ? Colors.blue.shade700
                                : Colors.grey.shade700),
                      ),
                      const SizedBox(width: 3.0),
                      Text(
                        L10nMappers.mapVerificationBadge(l10n, rev.verificationBadge, rev.verificationMethod),
                        style: TextStyle(
                          fontSize: 10.0,
                          fontWeight: FontWeight.bold,
                          color: rev.verificationMethod == 'BUSINESS_QR'
                              ? Colors.green.shade800
                              : (rev.verificationMethod == 'ATTRACTION_GPS'
                                  ? Colors.blue.shade800
                                  : Colors.grey.shade800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8.0),

          // Content (Original or Translated)
          Text(
            _isTranslated ? (_translatedText ?? rev.content) : rev.content,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textPrimary,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8.0),

          // Auto-translated Badge & Translation Toggle Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (_isTranslated) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(4.0),
                        border: Border.all(color: Colors.blue.shade200, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.g_translate, size: 12.0, color: Colors.blue.shade700),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n.autoTranslatedBadge,
                            style: TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (_errorMessage != null) ...[
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 11.0,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ],
              ),
              if (!isSameLanguage)
                InkWell(
                  onTap: _isLoading ? null : () => _toggleTranslation(l10n, currentLocaleCode),
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isLoading) ...[
                          const SizedBox(
                            width: 12.0,
                            height: 12.0,
                            child: CircularProgressIndicator(strokeWidth: 1.5),
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            l10n.translating,
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: Colors.grey,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            _isTranslated ? Icons.undo : Icons.translate,
                            size: 14.0,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            _isTranslated ? l10n.showOriginalAction : l10n.translateAction,
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
