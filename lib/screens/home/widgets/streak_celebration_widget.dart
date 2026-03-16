import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pet_ai/core/constants.dart';

class StreakCelebrationWidget extends StatelessWidget {
  final int streakDays;
  final int? rewardPoints;
  final String? rewardType; // 'badge', 'premium_trial', 'points'

  const StreakCelebrationWidget({
    super.key,
    required this.streakDays,
    this.rewardPoints,
    this.rewardType,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingXL),
        decoration: BoxDecoration(
          gradient: AppConstants.modernGradient,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: AppConstants.modalShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            const Icon(
              Icons.local_fire_department_rounded,
              size: 80,
              color: Colors.white,
            )
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 1000.ms),
            
            const SizedBox(height: AppConstants.spacingLG),
            
            // Title
            Text(
              '🎉 TEBRİKLER! 🎉',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms)
                .slideY(begin: -0.2, end: 0, duration: 400.ms, delay: 200.ms),
            
            const SizedBox(height: AppConstants.spacingSM),
            
            // Streak message
            Text(
              '$streakDays günlük seri başardın!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
              ),
              textAlign: TextAlign.center,
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms)
                .slideY(begin: -0.2, end: 0, duration: 400.ms, delay: 400.ms),
            
            // Reward display
            if (rewardPoints != null || rewardType != null) ...[
              const SizedBox(height: AppConstants.spacingLG),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.spacingMD,
                  vertical: AppConstants.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (rewardPoints != null) ...[
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '+$rewardPoints Pati Puanı',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                    if (rewardType == 'badge') ...[
                      const Icon(Icons.military_tech, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Yeni Rozet Kazandın!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 600.ms)
                  .scale(duration: 400.ms, delay: 600.ms),
            ],
            
            const SizedBox(height: AppConstants.spacingXL),
            
            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: Text(
                  'Harika!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 800.ms),
          ],
        ),
      ),
    );
  }

  static void show(BuildContext context, {
    required int streakDays,
    int? rewardPoints,
    String? rewardType,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StreakCelebrationWidget(
        streakDays: streakDays,
        rewardPoints: rewardPoints,
        rewardType: rewardType,
      ),
    );
  }
}
