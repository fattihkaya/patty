import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppConstants {
  // ─── Premium Dark Color Palette ───
  static const Color primaryColor = Color(0xFFF6C857); // Gold
  static const Color accentColor = Color(0xFFA78BFA); // Violet 400
  static const Color secondaryColor = Color(0xFF34D399); // Emerald 400
  static const Color backgroundColor = Color(0xFF0F172A); // Slate 900
  static const Color surfaceColor = Color(0xFF1E293B); // Slate 800
  static const Color surfaceColorAlt = Color(0xFF334155); // Slate 700
  static const Color darkTextColor = Color(0xFFF1F5F9); // Slate 50
  static const Color lightTextColor = Color(0xFF94A3B8); // Slate 400
  static const Color mutedColor = Color(0xFF334155); // Slate 700
  static const Color borderColor = Color(0xFF475569); // Slate 600

  // Status Colors
  static const Color successColor = Color(0xFF34D399); // Emerald 400
  static const Color errorColor = Color(0xFFF87171); // Red 400
  static const Color warningColor = Color(0xFFFBBF24); // Amber 400

  // Primary Color Variants
  static const Color primaryLight = Color(0x26F6C857); // Gold 15% opacity
  static const Color primaryDark = Color(0xFFD4A843); // Darker gold

  // Dark palette aliases (kept for backward compat)
  static const Color darkBackgroundColor = backgroundColor;
  static const Color darkSurfaceColor = surfaceColor;
  static const Color darkMutedColor = mutedColor;
  static const Color darkTextColorOnDark = darkTextColor;
  static const Color darkTextMutedOnDark = lightTextColor;

  // ─── Premium Gradients ───
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFF6C857), Color(0xFFD4A843)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient luxeGradient = LinearGradient(
    colors: [Color(0xFFF6C857), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient modernGradient = LinearGradient(
    colors: [Color(0xFFA78BFA), Color(0xFFF6C857)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient subtleGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFF6C857), Color(0xFFFB923C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF34D399), Color(0xFF6EE7B7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient surfaceGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Background Gradients ───
  static LinearGradient get appBarGradient => const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get loginScreenGradient => const LinearGradient(
        colors: [
          Color(0xFF0F172A),
          Color(0xFF1E293B),
          Color(0xFF0F172A),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        stops: [0.0, 0.5, 1.0],
      );

  static LinearGradient get cardOverlayGradient => LinearGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.15)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get storyGradient => const LinearGradient(
        colors: [Color(0xFFF6C857), Color(0xFFA78BFA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get instagramGradient => storyGradient;

  static LinearGradient get modernCardGradient => const LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get glassGradient => LinearGradient(
        colors: [
          Colors.white.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.03),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ─── Status / Semantic Colors ───
  static Color get statusSuccess => successColor;
  static Color get statusError => errorColor;
  static Color get statusWarning => warningColor;
  static Color get statusInfo => accentColor;

  static Color get textPrimary => darkTextColor;
  static Color get textSecondary => lightTextColor;
  static Color get textMuted => lightTextColor.withValues(alpha: 0.6);
  static Color get divider => mutedColor;
  static Color get border => borderColor;
  static Color get overlay => Colors.black.withValues(alpha: 0.6);

  // ─── Spacing System ───
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double defaultPadding = 20.0;

  // ─── Mobile Responsive Spacing ───
  static const double mobilePadding = 16.0;
  static const double mobileCardPadding = 16.0;
  static const double mobileSectionSpacing = 16.0;
  static const double bottomNavHeight = 70.0;
  static const double bottomNavMargin = 16.0;
  static const double fabBottomMargin = 90.0;

  // ─── Consistent EdgeInsets ───
  static EdgeInsets get paddingXS => const EdgeInsets.all(spacingXS);
  static EdgeInsets get paddingSM => const EdgeInsets.all(spacingSM);
  static EdgeInsets get paddingMD => const EdgeInsets.all(spacingMD);
  static EdgeInsets get paddingLG => const EdgeInsets.all(spacingLG);
  static EdgeInsets get paddingXL => const EdgeInsets.all(spacingXL);

  static EdgeInsets get paddingHorizontalMD =>
      const EdgeInsets.symmetric(horizontal: spacingMD);
  static EdgeInsets get paddingHorizontalLG =>
      const EdgeInsets.symmetric(horizontal: spacingLG);
  static EdgeInsets get paddingVerticalMD =>
      const EdgeInsets.symmetric(vertical: spacingMD);
  static EdgeInsets get paddingVerticalLG =>
      const EdgeInsets.symmetric(vertical: spacingLG);

  static EdgeInsets get cardPadding => const EdgeInsets.all(spacingMD);
  static EdgeInsets get screenPadding =>
      const EdgeInsets.all(defaultPadding);
  static EdgeInsets get screenPaddingMobile =>
      const EdgeInsets.all(mobilePadding);

  // ─── Border Radius ───
  static const double borderRadius = 16.0;
  static const double cardBorderRadius = 20.0;
  static const double smallBorderRadius = 12.0;
  static const double cardElevation = 0.0;

  // ─── Shadow System (Dark-optimized) ───
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0xFFF6C857).withValues(alpha: 0.15),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.15),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get shadowMedium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowLarge => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 16,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get shadowGlow => [
        BoxShadow(
          color: const Color(0xFFF6C857).withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get instagramShadow => shadowGlow;
  static List<BoxShadow> get storyShadow => shadowGlow;
  static List<BoxShadow> get modernCardShadow => [
        BoxShadow(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.2),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ];

  // ─── Icon & Avatar Sizes ───
  static const double iconXS = 16.0;
  static const double iconSM = 20.0;
  static const double iconMD = 24.0;
  static const double iconLG = 32.0;
  static const double iconXL = 48.0;

  static const double avatarSM = 32.0;
  static const double avatarMD = 48.0;
  static const double avatarLG = 64.0;
  static const double avatarXL = 96.0;

  // ─── Icon Container Styles ───
  static BoxDecoration iconContainer({Color? color}) => BoxDecoration(
        color: (color ?? primaryColor).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(smallBorderRadius),
      );

  static BoxDecoration iconContainerCircle({Color? color}) => BoxDecoration(
        color: (color ?? primaryColor).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      );

  // ─── Typography ───
  static const double letterSpacingBold = -0.6;
  static const double letterSpacingNormal = 0.1;

  // ─── Animation Durations ───
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 500);
  static const Duration extraSlowDuration = Duration(milliseconds: 800);

  static const Duration instagramBounce = Duration(milliseconds: 600);
  static const Duration instagramSlide = Duration(milliseconds: 400);
  static const Duration instagramFade = Duration(milliseconds: 300);
  static const Duration instagramScale = Duration(milliseconds: 250);
  static const Duration storyTransition = Duration(milliseconds: 350);
  static const Duration cardHover = Duration(milliseconds: 200);
  static const Duration modalAppear = Duration(milliseconds: 400);

  // ─── Card Decorations ───
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: cardShadow,
      );

  static BoxDecoration get elevatedCardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: elevatedShadow,
      );

  static BoxDecoration get subtleCardDecoration => BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 1,
        ),
        boxShadow: softShadow,
      );

  static BoxDecoration get glassCardDecoration => BoxDecoration(
        gradient: glassGradient,
        borderRadius: BorderRadius.circular(cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: cardShadow,
      );

  static BoxDecoration get instagramCardDecoration => elevatedCardDecoration;
  static BoxDecoration get storyCardDecoration => elevatedCardDecoration;
  static BoxDecoration get modernGlassDecoration => glassCardDecoration;

  // ─── Text Styles ───
  static TextStyle get headlineLarge => GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: darkTextColor,
        letterSpacing: letterSpacingBold,
      );

  static TextStyle get headlineMedium => GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: darkTextColor,
        letterSpacing: letterSpacingBold,
      );

  static TextStyle get titleLarge => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkTextColor,
      );

  static TextStyle get titleMedium => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: darkTextColor,
      );

  static TextStyle get bodyLarge => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: darkTextColor,
      );

  static TextStyle get bodyMedium => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: lightTextColor,
      );

  static TextStyle get labelLarge => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      );

  static TextStyle get labelMedium => GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: lightTextColor,
      );

  static TextStyle get instagramHeadline => GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: primaryColor,
        letterSpacing: -0.5,
      );

  static TextStyle get instagramSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: lightTextColor,
      );

  static TextStyle get storyTitle => GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        letterSpacing: 0.2,
      );

  static TextStyle get modernCardTitle => GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Colors.white,
      );

  static TextStyle get modernCardSubtitle => GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.8),
      );
}
