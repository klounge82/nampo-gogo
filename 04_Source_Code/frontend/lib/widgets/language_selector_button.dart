import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';
import '../constants/colors.dart';

class LanguageSelectorButton extends StatelessWidget {
  final bool isDark;

  const LanguageSelectorButton({
    super.key,
    this.isDark = false,
  });

  String _getLangLabel(Locale locale) {
    if (locale.languageCode == 'en') return 'EN';
    if (locale.languageCode == 'ja') return 'JA';
    if (locale.languageCode == 'zh') return '中';
    return 'KO';
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final currentLocale = localeProvider.locale;
    final currentLabel = _getLangLabel(currentLocale);

    return PopupMenuButton<Locale>(
      onSelected: (Locale newLocale) {
        localeProvider.setLocale(newLocale);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      elevation: 4,
      tooltip: 'Language / 언어 설정',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.3)
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              size: 16.0,
              color: isDark ? Colors.white : AppColors.primary,
            ),
            const SizedBox(width: 4.0),
            Text(
              currentLabel,
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16.0,
              color: isDark ? Colors.white : AppColors.primary,
            ),
          ],
        ),
      ),
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Locale>>[
        const PopupMenuItem<Locale>(
          value: Locale('ko'),
          child: Row(
            children: [
              Text('🇰🇷 ', style: TextStyle(fontSize: 16)),
              Text('한국어', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('en'),
          child: Row(
            children: [
              Text('🇺🇸 ', style: TextStyle(fontSize: 16)),
              Text('English', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale('ja'),
          child: Row(
            children: [
              Text('🇯🇵 ', style: TextStyle(fontSize: 16)),
              Text('日本語', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        const PopupMenuItem<Locale>(
          value: Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
          child: Row(
            children: [
              Text('🇨🇳 ', style: TextStyle(fontSize: 16)),
              Text('简体中文', style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
