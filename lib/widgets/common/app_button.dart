import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  double get _height {
    switch (size) {
      case AppButtonSize.small:
        return 40;
      case AppButtonSize.medium:
        return 52;
      case AppButtonSize.large:
        return 60;
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 15;
      case AppButtonSize.large:
        return 17;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;

    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimary(disabled);
      case AppButtonVariant.secondary:
        return _buildSecondary(disabled);
      case AppButtonVariant.ghost:
        return _buildGhost(disabled);
      case AppButtonVariant.danger:
        return _buildDanger(disabled);
    }
  }

  Widget _buildPrimary(bool disabled) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled ? null : AppConstants.primaryGradient,
          color: disabled ? AppConstants.mutedColor : null,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          boxShadow: disabled ? null : AppConstants.shadowGlow,
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: const Color(0xFF0F172A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            ),
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: _fontSize,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: _buildChild(const Color(0xFF0F172A)),
        ),
      ),
    );
  }

  Widget _buildSecondary(bool disabled) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.accentColor,
          side: BorderSide(
            color: disabled
                ? AppConstants.mutedColor
                : AppConstants.accentColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: _buildChild(AppConstants.accentColor),
      ),
    );
  }

  Widget _buildGhost(bool disabled) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.lightTextColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: _fontSize,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: _buildChild(AppConstants.lightTextColor),
      ),
    );
  }

  Widget _buildDanger(bool disabled) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: _height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.errorColor,
          side: BorderSide(
            color: disabled
                ? AppConstants.mutedColor
                : AppConstants.errorColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: _fontSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        child: _buildChild(AppConstants.errorColor),
      ),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _fontSize + 4),
          const SizedBox(width: 8),
          Text(text),
        ],
      );
    }

    return Text(text);
  }
}
