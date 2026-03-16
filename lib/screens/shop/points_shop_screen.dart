import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/providers/gamification_provider.dart';
import 'package:pet_ai/providers/subscription_provider.dart';
import 'package:pet_ai/models/points_shop_item_model.dart';

class PointsShopScreen extends StatefulWidget {
  const PointsShopScreen({super.key});

  @override
  State<PointsShopScreen> createState() => _PointsShopScreenState();
}

class _PointsShopScreenState extends State<PointsShopScreen> {
  int? _userPoints;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserPoints();
      context.read<GamificationProvider>().fetchShopItems();
    });
  }

  Future<void> _loadUserPoints() async {
    final points = await context.read<GamificationProvider>().getUserPoints();
    if (mounted) {
      setState(() {
        _userPoints = points;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final gamificationProvider = context.watch<GamificationProvider>();
    final shopItems = gamificationProvider.shopItems;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: const Text('Puan Marketi'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.primaryColor,
      ),
      body: gamificationProvider.isLoading && shopItems.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await gamificationProvider.fetchShopItems();
                await _loadUserPoints();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildPointsBalanceCard(),
                    const SizedBox(height: AppConstants.spacingLG),
                    if (shopItems.isEmpty)
                      _buildEmptyState()
                    else
                      ...shopItems.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppConstants.spacingMD),
                            child: _buildShopItemCard(item),
                          )),
                    const SizedBox(height: AppConstants.spacingXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPointsBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: AppConstants.modernGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pati Puanı',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _userPoints?.toString() ?? '...',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Her günlük kayıtta 10 puan kazanırsın!'),
                  backgroundColor: AppConstants.primaryColor,
                ),
              );
            },
            child: Text(
              'Nasıl kazanılır?',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemCard(PointsShopItem item) {
    final canAfford = _userPoints != null && _userPoints! >= item.pointsCost;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: canAfford
              ? AppConstants.primaryColor.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getItemIcon(item.itemType),
              color: AppConstants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.spacingMD),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppConstants.lightTextColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.stars_rounded,
                    color: AppConstants.warningColor,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.pointsCost}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: canAfford
                          ? AppConstants.darkTextColor
                          : AppConstants.lightTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: canAfford
                    ? () => _handlePurchase(item)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: canAfford
                      ? AppConstants.primaryColor
                      : AppConstants.surfaceColorAlt,
                  foregroundColor: canAfford
                      ? const Color(0xFF0F172A)
                      : AppConstants.lightTextColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius),
                  ),
                ),
                child: Text(
                  'Satın Al',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingXXL),
      child: Column(
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppConstants.primaryColor.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz ürün yok',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              color: AppConstants.lightTextColor,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(PointsItemType type) {
    switch (type) {
      case PointsItemType.premiumTrial:
        return Icons.workspace_premium;
      case PointsItemType.badge:
        return Icons.military_tech;
      case PointsItemType.customization:
        return Icons.palette;
      case PointsItemType.discount:
        return Icons.local_offer;
      case PointsItemType.theme:
        return Icons.color_lens;
    }
  }

  Future<void> _handlePurchase(PointsShopItem item) async {
    final gamificationProvider = context.read<GamificationProvider>();
    final subscriptionProvider = context.read<SubscriptionProvider>();
    
    try {
      await gamificationProvider.redeemPoints(item.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} satın alındı!'),
            backgroundColor: AppConstants.successColor,
          ),
        );
        
        await _loadUserPoints();
        
        if (item.itemType == PointsItemType.premiumTrial) {
          subscriptionProvider.refreshSubscription();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }
}
