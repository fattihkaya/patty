import 'package:flutter/material.dart';
import '../../core/constants.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? iconColor;
  final Widget? trailing;
  final VoidCallback? onActionTap;
  final String? actionText;
  final EdgeInsets? padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.iconColor,
    this.trailing,
    this.onActionTap,
    this.actionText,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(
        horizontal: AppConstants.mobilePadding,
        vertical: AppConstants.spacingSM,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppConstants.primaryColor)
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: AppConstants.spacingSM),
          ],
          Expanded(
            child: Text(
              title,
              style: AppConstants.titleMedium,
            ),
          ),
          if (trailing != null) trailing!,
          if (onActionTap != null && actionText != null)
            GestureDetector(
              onTap: onActionTap,
              child: Text(
                actionText!,
                style: AppConstants.labelLarge.copyWith(
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
