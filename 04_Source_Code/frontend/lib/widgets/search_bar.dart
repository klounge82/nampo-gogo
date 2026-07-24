import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';

class NampoSearchBar extends StatelessWidget {
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;

  const NampoSearchBar({super.key, this.onChanged, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10), // 0.04 opacity equivalent
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        onTap: onTap,
        decoration: InputDecoration(
          hintText: AppStrings.homeSearchHint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14.0),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: const Icon(Icons.mic_none, color: AppColors.textSecondary),
            onPressed: () {},
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(28.0),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 14.0,
          ),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}
