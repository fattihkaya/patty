import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/providers/affiliate_provider.dart';
import 'package:pet_ai/widgets/product_recommendation_card.dart';

class ProductRecommendationsWidget extends StatefulWidget {
  final String? petId;
  final String? category;
  final String source; // 'health_screen', 'finance_screen', etc.
  final int? limit;

  const ProductRecommendationsWidget({
    super.key,
    this.petId,
    this.category,
    required this.source,
    this.limit,
  });

  @override
  State<ProductRecommendationsWidget> createState() => _ProductRecommendationsWidgetState();
}

class _ProductRecommendationsWidgetState extends State<ProductRecommendationsWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecommendations();
    });
  }

  Future<void> _loadRecommendations() async {
    final affiliateProvider = context.read<AffiliateProvider>();
    
    if (widget.petId != null) {
      await affiliateProvider.getRecommendationsForPet(widget.petId!);
    } else {
      await affiliateProvider.fetchRecommendations(
        category: widget.category,
        limit: widget.limit ?? 5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final affiliateProvider = context.watch<AffiliateProvider>();
    final recommendations = affiliateProvider.recommendations;

    if (affiliateProvider.isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppConstants.spacingLG),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: AppConstants.cardShadow,
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (recommendations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.shopping_bag_rounded,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: AppConstants.spacingSM),
              Text(
                'Önerilen Ürünler',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // Recommendations List
          ...recommendations.take(widget.limit ?? 5).map((recommendation) {
            return ProductRecommendationCard(
              recommendation: recommendation,
              source: widget.source,
              petId: widget.petId,
            );
          }),
        ],
      ),
    );
  }
}
