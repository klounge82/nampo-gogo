import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final auth = context.read<AuthProvider>();
    final currentLang = localeProvider.locale.languageCode;
    final l10n = AppLocalizations.of(context)!;

    final languages = [
      {'code': 'ko', 'label': '한국어'},
      {'code': 'en', 'label': 'English'},
      {'code': 'ja', 'label': '日本語'},
      {'code': 'zh', 'label': '简体中文'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FC),
      appBar: AppBar(
        title: Text(
          l10n.languageSetting,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: const BackButton(color: Colors.black87),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected =
              (lang['code'] == currentLang) ||
              (lang['code'] == 'zh' && currentLang.startsWith('zh'));

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.01),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              title: Text(
                lang['label']!,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.blueAccent : Colors.black87,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check_circle, color: Colors.blueAccent)
                  : const Icon(Icons.circle_outlined, color: Colors.grey),
              onTap: () {
                localeProvider.setLocale(
                  Locale(lang['code']!),
                  userId: auth.currentUser?.id,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
