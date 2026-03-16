import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/models/subscription_plan_model.dart';

class PlanCardWidget extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isYearly;
  final bool isCurrentPlan;
  final VoidCallback onSelect;

  const PlanCardWidget({
    super.key,
    required this.plan,
    required this.isYearly,
    required this.isCurrentPlan,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isPremium = plan.name == 'premium';
    final isPro = plan.name == 'pro';
    
    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: isCurrentPlan
              ? AppConstants.primaryColor
              : isPremium || isPro
                  ? AppConstants.primaryColor.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.06),
          width: isCurrentPlan ? 2 : isPremium || isPro ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          if (isPremium || isPro)
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Stack(
        children: [
          if (isPremium || isPro)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
                  gradient: LinearGradient(
                    colors: [
                      (isPremium ? AppConstants.primaryColor : AppConstants.accentColor)
                          .withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLG),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.displayName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppConstants.darkTextColor,
                            ),
                          ),
                          if (plan.description != null)
                            const SizedBox(height: 4),
                          if (plan.description != null)
                            Text(
                              plan.description!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (isPremium || isPro)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: isPremium
                              ? AppConstants.primaryGradient
                              : AppConstants.luxeGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPremium ? 'Popüler' : 'Pro',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: AppConstants.spacingLG),
                
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isYearly
                          ? plan.priceYearly == 0
                              ? 'Ücretsiz'
                              : '₺${(plan.priceYearly / 12).toStringAsFixed(0)}'
                          : plan.priceMonthly == 0
                              ? 'Ücretsiz'
                              : '₺${plan.priceMonthly.toStringAsFixed(0)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        isYearly ? '/ay' : '/ay',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                if (isYearly && plan.priceYearly > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Yıllık: ₺${plan.priceYearly.toStringAsFixed(0)} (₺${(plan.priceYearly / 12).toStringAsFixed(1)}/ay)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppConstants.successColor,
                      ),
                    ),
                  ),
                
                const SizedBox(height: AppConstants.spacingLG),
                
                ..._buildFeatureList(),
                
                const SizedBox(height: AppConstants.spacingLG),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isCurrentPlan ? null : onSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentPlan
                          ? AppConstants.surfaceColorAlt
                          : isPremium || isPro
                              ? AppConstants.primaryColor
                              : AppConstants.surfaceColorAlt,
                      foregroundColor: isCurrentPlan
                          ? AppConstants.lightTextColor
                          : isPremium || isPro
                              ? const Color(0xFF0F172A)
                              : AppConstants.darkTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isCurrentPlan
                          ? 'Mevcut Plan'
                          : plan.isFree
                              ? 'Ücretsiz Kullan'
                              : 'Hemen Başla',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureList() {
    final features = <Widget>[];

    features.add(_buildFeatureItem(
      Icons.auto_awesome,
      plan.hasUnlimitedAI
          ? 'Sınırsız AI Analizi'
          : '${plan.aiAnalysesPerMonth} AI Analizi/Ay',
      plan.hasUnlimitedAI,
    ));

    features.add(_buildFeatureItem(
      Icons.pets,
      plan.hasUnlimitedPets
          ? 'Sınırsız Pet Profili'
          : '${plan.maxPets} Pet Profili',
      plan.hasUnlimitedPets,
    ));

    if (plan.hasPdfExports) {
      features.add(_buildFeatureItem(
        Icons.insert_drive_file,
        'PDF Rapor Export',
        true,
      ));
    }

    if (plan.hasAdvancedAnalytics) {
      features.add(_buildFeatureItem(
        Icons.analytics,
        'Gelişmiş Analitik',
        true,
      ));
    }

    if (plan.isAdFree) {
      features.add(_buildFeatureItem(
        Icons.block,
        'Reklamsız Deneyim',
        true,
      ));
    }

    if (plan.hasPriorityAIProcessing) {
      features.add(_buildFeatureItem(
        Icons.flash_on,
        'Öncelikli AI İşleme',
        true,
      ));
    }

    if (plan.hasCustomThemes) {
      features.add(_buildFeatureItem(
        Icons.palette,
        'Özel Temalar',
        true,
      ));
    }

    if (plan.hasPrioritySupport) {
      features.add(_buildFeatureItem(
        Icons.support_agent,
        'Öncelikli Destek',
        true,
      ));
    }

    return features;
  }

  Widget _buildFeatureItem(IconData icon, String text, bool isAvailable) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Row(
        children: [
          Icon(
            isAvailable ? Icons.check_circle : Icons.cancel,
            color: isAvailable
                ? AppConstants.primaryColor
                : AppConstants.lightTextColor.withValues(alpha: 0.5),
            size: 20,
          ),
          const SizedBox(width: AppConstants.spacingSM),
          Icon(
            icon,
            color: isAvailable
                ? AppConstants.primaryColor.withValues(alpha: 0.7)
                : AppConstants.lightTextColor.withValues(alpha: 0.5),
            size: 18,
          ),
          const SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isAvailable
                    ? AppConstants.darkTextColor
                    : AppConstants.lightTextColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
