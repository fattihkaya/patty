import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../core/app_strings.dart';
import '../screens/subscription/subscription_screen.dart';
import '../providers/locale_provider.dart';
import 'package:provider/provider.dart';

/// Reusable premium paywall overlay.
/// Wraps [child] and shows a blurred lock overlay when [isLocked] is true.
class PremiumGate extends StatelessWidget {
  final bool isLocked;
  final Widget child;
  final String? featureTitle;
  final String? featureDescription;
  final IconData featureIcon;

  const PremiumGate({
    super.key,
    required this.isLocked,
    required this.child,
    this.featureTitle,
    this.featureDescription,
    this.featureIcon = Icons.lock_rounded,
  });

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    final s = S.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: IgnorePointer(child: child),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            onTap: () => showPremiumSheet(context,
                title: featureTitle, description: featureDescription),
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(AppConstants.cardBorderRadius),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0F172A).withValues(alpha: 0.5),
                    const Color(0xFF0F172A).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppConstants.surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppConstants.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(featureIcon,
                          color: AppConstants.primaryColor, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        s.upgradeToPremium,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppConstants.primaryColor),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).scale(
                      begin: const Offset(0.9, 0.9),
                      end: const Offset(1, 1),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Shows a premium upsell bottom sheet.
void showPremiumSheet(
  BuildContext context, {
  String? title,
  String? description,
}) {
  final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
  final s = S.ofLang(locale.languageCode);
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Container(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: AppConstants.surfaceColorAlt,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppConstants.luxeGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.diamond_rounded,
                color: Colors.white, size: 36),
          ).animate().scale(
                duration: 600.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
              ),
          const SizedBox(height: 24),

          Text(
            title ?? s.upgradeToPremium,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkTextColor,
            ),
          ),
          const SizedBox(height: 10),

          Text(
            description ??
                (s.languageCode == 'en'
                    ? 'Unlock all features with Premium. Unlimited AI analysis, charts, PDF export and more!'
                    : 'Premium ile tüm özelliklerin kilidini aç. Sınırsız AI analizi, grafikler, PDF dışa aktarma ve daha fazlası!'),
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppConstants.lightTextColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          _PremiumFeatureRow(icon: Icons.auto_awesome, text: s.unlimitedAI),
          _PremiumFeatureRow(icon: Icons.pets_rounded, text: s.unlimitedPets),
          _PremiumFeatureRow(
              icon: Icons.analytics_rounded, text: s.advancedAnalytics),
          _PremiumFeatureRow(
              icon: Icons.picture_as_pdf_rounded, text: s.pdfExport),
          _PremiumFeatureRow(icon: Icons.block_rounded, text: s.adFree),
          const SizedBox(height: 32),

          Container(
            width: double.infinity,
            height: 58,
            decoration: BoxDecoration(
              gradient: AppConstants.luxeGradient,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              boxShadow: [
                BoxShadow(
                  color: AppConstants.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    s.freeTrial,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).moveY(begin: 10, end: 0),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              s.cancel,
              style: GoogleFonts.plusJakartaSans(
                color: AppConstants.lightTextColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PremiumFeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PremiumFeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppConstants.primaryColor, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppConstants.darkTextColor,
              ),
            ),
          ),
          const Icon(Icons.check_circle_rounded,
              color: AppConstants.primaryColor, size: 20),
        ],
      ),
    );
  }
}
