import 'package:flutter/material.dart';
import '../../core/constants.dart';

enum AppCardVariant { standard, elevated, subtle, glass }

class AppCard extends StatelessWidget {
  final Widget child;
  final AppCardVariant variant;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? borderColor;

  const AppCard({
    super.key,
    required this.child,
    this.variant = AppCardVariant.standard,
    this.padding,
    this.margin,
    this.onTap,
    this.borderRadius,
    this.gradient,
    this.borderColor,
  });

  BoxDecoration _buildDecoration() {
    final radius = borderRadius ?? AppConstants.cardBorderRadius;
    final br = BorderRadius.circular(radius);

    switch (variant) {
      case AppCardVariant.elevated:
        return BoxDecoration(
          color: gradient == null ? AppConstants.surfaceColor : null,
          gradient: gradient,
          borderRadius: br,
          border: Border.all(
            color: borderColor ?? AppConstants.primaryColor.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: AppConstants.elevatedShadow,
        );
      case AppCardVariant.subtle:
        return BoxDecoration(
          color: gradient == null ? AppConstants.surfaceColor : null,
          gradient: gradient,
          borderRadius: br,
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
          boxShadow: AppConstants.softShadow,
        );
      case AppCardVariant.glass:
        return BoxDecoration(
          gradient: gradient ?? AppConstants.glassGradient,
          borderRadius: br,
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: AppConstants.cardShadow,
        );
      case AppCardVariant.standard:
        return BoxDecoration(
          color: gradient == null ? AppConstants.surfaceColor : null,
          gradient: gradient,
          borderRadius: br,
          border: Border.all(
            color: borderColor ?? Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: AppConstants.cardShadow,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = _buildDecoration();
    final radius = borderRadius ?? AppConstants.cardBorderRadius;

    Widget card = Container(
      margin: margin,
      decoration: decoration,
      child: Padding(
        padding: padding ?? AppConstants.cardPadding,
        child: child,
      ),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          splashColor: AppConstants.primaryColor.withValues(alpha: 0.08),
          highlightColor: AppConstants.primaryColor.withValues(alpha: 0.04),
          child: card,
        ),
      );
    }

    return card;
  }
}
