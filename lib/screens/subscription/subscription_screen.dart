import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/providers/subscription_provider.dart';
import 'package:pet_ai/models/subscription_plan_model.dart';
import 'package:pet_ai/services/purchase_service.dart';
import 'package:pet_ai/screens/main_container.dart';
import 'widgets/plan_card_widget.dart';
import 'widgets/feature_comparison_widget.dart';
import 'package:pet_ai/core/app_strings.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isYearly = false;

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }

    // Fallback: ekran stack dışında açıldıysa ana container'a dön.
    navigator.pushReplacement(
      MaterialPageRoute(builder: (_) => const MainContainer()),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().fetchPlans();
      context.read<SubscriptionProvider>().fetchUserSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final plans = subscriptionProvider.plans;
    final currentPlan = subscriptionProvider.currentPlan;

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        leading: IconButton(
          tooltip: S.of(context).close,
          onPressed: _handleBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(S.of(context).subscriptionPlans),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.primaryColor,
      ),
      body: subscriptionProvider.isLoading && plans.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await subscriptionProvider.fetchPlans();
                await subscriptionProvider.fetchUserSubscription();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Free Trial Banner
                    _buildFreeTrialBanner(),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Current plan badge
                    if (currentPlan != null && !currentPlan.isFree)
                      _buildCurrentPlanBadge(currentPlan),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Modern Paywall Trigger
                    _buildPaywallTrigger(),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Yearly/Monthly toggle
                    _buildBillingToggle(),

                    const SizedBox(height: AppConstants.spacingXL),

                    // Plan cards
                    if (plans.isNotEmpty)
                      ...plans.map((plan) => Padding(
                            padding: const EdgeInsets.only(
                                bottom: AppConstants.spacingMD),
                            child: PlanCardWidget(
                              plan: plan,
                              isYearly: _isYearly,
                              isCurrentPlan: currentPlan?.id == plan.id,
                              onSelect: () => _handlePlanSelection(plan),
                            ),
                          )),

                    const SizedBox(height: AppConstants.spacingMD),
                    
                    // Restore & Customer Center
                    _buildSubscriptionActions(),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Feature comparison
                    const FeatureComparisonWidget(),

                    const SizedBox(height: AppConstants.spacingXL),

                    // Benefits section
                    _buildBenefitsSection(),

                    const SizedBox(height: AppConstants.spacingXXL),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentPlanBadge(SubscriptionPlan plan) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMD,
        vertical: AppConstants.spacingSM,
      ),
      decoration: BoxDecoration(
        gradient: AppConstants.modernGradient,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
          const SizedBox(width: AppConstants.spacingSM),
          Text(
            'Mevcut Plan: ${plan.displayName}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildToggleOption(
              label: S.of(context).monthly,
              isSelected: !_isYearly,
              onTap: () => setState(() => _isYearly = false),
            ),
          ),
          Expanded(
            child: _buildToggleOption(
              label: S.of(context).yearly,
              isSelected: _isYearly,
              onTap: () => setState(() => _isYearly = true),
              badge: S.of(context).savings,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    String? badge,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.surfaceColorAlt : Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius - 4),
          boxShadow: isSelected ? AppConstants.cardShadow : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppConstants.primaryColor
                    : AppConstants.lightTextColor,
              ),
            ),
            if (badge != null && isSelected)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppConstants.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppConstants.successColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
              const SizedBox(width: AppConstants.spacingSM),
              Text(
                S.of(context).premiumBenefits,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacingMD),
          _buildBenefitItem(Icons.auto_awesome, S.of(context).unlimitedAI),
          _buildBenefitItem(Icons.pets, S.of(context).unlimitedPets),
          _buildBenefitItem(Icons.insert_drive_file, S.of(context).pdfExport),
          _buildBenefitItem(Icons.analytics, S.of(context).advancedAnalytics),
          _buildBenefitItem(Icons.block, S.of(context).adFree),
          _buildBenefitItem(Icons.flash_on, S.of(context).priorityAI),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.spacingSM),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 20),
          const SizedBox(width: AppConstants.spacingSM),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePlanSelection(SubscriptionPlan plan) async {
    final subscriptionProvider = context.read<SubscriptionProvider>();
    final isCurrentPlan = subscriptionProvider.currentPlan?.id == plan.id;

    if (plan.isFree || isCurrentPlan) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Zaten ${plan.displayName} planındasınız'),
          backgroundColor: AppConstants.primaryColor,
        ),
      );
      return;
    }

    // Show loading dialog
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Initialize PurchaseService if needed
      await PurchaseService.initialize();

      // Get offerings from RevenueCat
      final offerings = await PurchaseService.getOfferings();

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (offerings == null || offerings.current == null) {
        if (!mounted) return;
        _showErrorDialog(
            'Abonelik planları şu anda kullanılamıyor. Lütfen daha sonra tekrar deneyin.');
        return;
      }

      // Find the package for this plan
      // Product ID mapping: premium_monthly, premium_yearly, pro_monthly, pro_yearly
      final productId = _getProductId(plan, _isYearly);
      final package = offerings.current!.availablePackages.firstWhere(
        (p) => p.storeProduct.identifier == productId,
        orElse: () => offerings.current!.availablePackages.first,
      );

      // Purchase the package
      await PurchaseService.purchasePackage(package);

      // Refresh subscription
      if (!mounted) return;
      await subscriptionProvider.refreshSubscription();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${plan.displayName} planına başarıyla geçiş yaptınız!'),
          backgroundColor: AppConstants.successColor,
        ),
      );
    } on PurchaseException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (e.type == PurchaseErrorType.cancelled) {
        // User cancelled, don't show error
        return;
      }

      _showErrorDialog(e.message);
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      _showErrorDialog('Satın alma işlemi başarısız oldu: $e');
    }
  }

  String _getProductId(SubscriptionPlan plan, bool isYearly) {
    final planName = plan.name; // 'premium' or 'pro'
    final period = isYearly ? 'yearly' : 'monthly';
    return '${planName}_$period';
  }

  Widget _buildPaywallTrigger() {
    return InkWell(
      onTap: () => PurchaseService.showPaywall(
        onPurchaseCompleted: (info) {
          context.read<SubscriptionProvider>().refreshSubscription();
        },
      ),
      borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacingMD),
        decoration: BoxDecoration(
          gradient: AppConstants.luxeGradient,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          boxShadow: AppConstants.elevatedShadow,
        ),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome_rounded,
                color: Colors.white, size: 28),
            const SizedBox(width: AppConstants.spacingMD),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock Patty Pro',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Get unlimited AI & features',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TextButton.icon(
          onPressed: () async {
            final info = await PurchaseService.restorePurchases();
            if (info != null && mounted) {
              context.read<SubscriptionProvider>().refreshSubscription();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Satın almalar geri yüklendi')),
              );
            }
          },
          icon: const Icon(Icons.restore_rounded, size: 16),
          label: const Text('Geri Yükle', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
              foregroundColor: AppConstants.lightTextColor),
        ),
        const SizedBox(width: AppConstants.spacingMD),
        TextButton.icon(
          onPressed: () => PurchaseService.showCustomerCenter(),
          icon: const Icon(Icons.settings_suggest_rounded, size: 16),
          label: const Text('Yönet', style: TextStyle(fontSize: 12)),
          style: TextButton.styleFrom(
              foregroundColor: AppConstants.lightTextColor),
        ),
      ],
    );
  }

  Widget _buildFreeTrialBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.accentColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: AppConstants.accentColor.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppConstants.accentColor,
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.timer_outlined, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '7 Günlük Ücretsiz Deneme',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppConstants.accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hemen başlayın, ilk 7 gün hiçbir ücret ödemeyin. İstediğiniz zaman iptal edebilirsiniz.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: AppConstants.lightTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppConstants.surfaceColor,
        title: const Text(
          'Hata',
          style: TextStyle(color: AppConstants.darkTextColor),
        ),
        content: Text(
          message,
          style: const TextStyle(color: AppConstants.lightTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(color: AppConstants.primaryColor),
            ),
          ),
        ],
      ),
    );
  }
}
