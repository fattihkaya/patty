import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/models/product_recommendation_model.dart';
import 'package:pet_ai/providers/affiliate_provider.dart';

class ProductRecommendationCard extends StatelessWidget {
  final ProductRecommendation recommendation;
  final String source; // 'health_screen', 'finance_screen', etc.
  final String? petId;

  const ProductRecommendationCard({
    super.key,
    required this.recommendation,
    required this.source,
    this.petId,
  });

  @override
  Widget build(BuildContext context) {
    final affiliateProvider = context.read<AffiliateProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: recommendation.isFeatured
            ? Border.all(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                width: 2,
              )
            : Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1,
              ),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Product Image (if available)
          if (recommendation.productImageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(AppConstants.cardBorderRadius),
                topRight: Radius.circular(AppConstants.cardBorderRadius),
              ),
              child: Image.network(
                recommendation.productImageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 180,
                    color: AppConstants.primaryLight,
                    child: const Icon(
                      Icons.shopping_bag_rounded,
                      size: 64,
                      color: AppConstants.primaryColor,
                    ),
                  );
                },
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(AppConstants.spacingMD),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Featured badge
                if (recommendation.isFeatured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AppConstants.primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Öne Çıkan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (recommendation.isFeatured)
                  const SizedBox(height: AppConstants.spacingSM),

                // Product Name
                Text(
                  recommendation.productName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),

                const SizedBox(height: AppConstants.spacingXS),

                // Recommendation Reason
                if (recommendation.recommendationReason != null)
                  Text(
                    recommendation.recommendationReason!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: AppConstants.lightTextColor,
                    ),
                  ),

                const SizedBox(height: AppConstants.spacingSM),

                // Product Description
                if (recommendation.productDescription != null)
                  Text(
                    recommendation.productDescription!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppConstants.lightTextColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                const SizedBox(height: AppConstants.spacingMD),

                // Price and Action Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Price
                    if (recommendation.productPrice != null)
                      Text(
                        '${recommendation.productPrice!.toStringAsFixed(2)} ${recommendation.currency}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppConstants.primaryColor,
                        ),
                      )
                    else
                      const SizedBox.shrink(),

                    // View Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          await affiliateProvider.openAffiliateLink(
                            recommendation: recommendation,
                            source: source,
                            petId: petId,
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Link açılamadı: $e'),
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Ürüne Git'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: const Color(0xFF0F172A),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacingMD,
                          vertical: AppConstants.spacingSM,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),

                // Dismiss button (small)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await affiliateProvider.dismissRecommendation(recommendation.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Öneri kaldırıldı'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'Gizle',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppConstants.lightTextColor,
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
}
