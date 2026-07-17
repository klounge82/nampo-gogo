import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/favorite_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class FavoriteButton extends StatelessWidget {
  final String targetType;
  final String targetId;
  final double size;
  final Color? color;

  const FavoriteButton({
    super.key,
    required this.targetType,
    required this.targetId,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final favProvider = context.watch<FavoriteProvider>();
    final authProvider = context.watch<AuthProvider>();
    final lang = context.read<LocaleProvider>().locale.languageCode;

    final isFav = favProvider.favoriteIds.contains(targetId);
    final token = authProvider.accessToken;

    return IconButton(
      iconSize: size,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      icon: Icon(
        isFav ? Icons.favorite : Icons.favorite_border,
        color: isFav ? Colors.redAccent : (color ?? Colors.grey),
      ),
      onPressed: () {
        favProvider.toggleFavorite(
          targetType: targetType,
          targetId: targetId,
          token: token,
          lang: lang,
          context: context,
        );
      },
    );
  }
}
