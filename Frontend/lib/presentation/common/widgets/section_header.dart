// lib/presentation/common/widgets/section_header.dart
import 'package:flutter/material.dart';
import '../../../core/theme/theme_extensions.dart'; // ✅ ADD THEME EXTENSION

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final VoidCallback? onSeeAll;
  final bool showSeeAll;

  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.onSeeAll,
    this.showSeeAll = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: context.primaryColor, size: 20),
              const SizedBox(width: 8),
            ],
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.primaryText,
              ),
            ),
          ],
        ),
        if (showSeeAll && onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              'See All',
              style: TextStyle(
                color: context.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}