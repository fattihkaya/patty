class SubscriptionPlan {
  final String id;
  final String name;
  final String displayName;
  final String? description;
  final double priceMonthly;
  final double priceYearly;
  final Map<String, dynamic> features;
  final int trialDays;
  final bool isActive;
  final int displayOrder;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.displayName,
    this.description,
    required this.priceMonthly,
    required this.priceYearly,
    required this.features,
    this.trialDays = 0,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      displayName: json['display_name'] as String,
      description: json['description'] as String?,
      priceMonthly: (json['price_monthly'] as num?)?.toDouble() ?? 0.0,
      priceYearly: (json['price_yearly'] as num?)?.toDouble() ?? 0.0,
      features: json['features'] as Map<String, dynamic>? ?? {},
      trialDays: json['trial_days'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'display_name': displayName,
      'description': description,
      'price_monthly': priceMonthly,
      'price_yearly': priceYearly,
      'features': features,
      'trial_days': trialDays,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }

  // Helper methods
  bool get hasUnlimitedAI => features['ai_analyses_per_month'] == -1;
  int get aiAnalysesPerMonth => features['ai_analyses_per_month'] as int? ?? 3;
  bool get hasUnlimitedPets => features['max_pets'] == -1;
  int get maxPets => features['max_pets'] as int? ?? 1;
  bool get hasPdfExports => features['pdf_exports'] == true;
  bool get hasAdvancedAnalytics => features['advanced_analytics'] == true;
  bool get isAdFree => features['ad_free'] == true;
  bool get hasPrioritySupport => features['priority_support'] == true;
  bool get hasCustomThemes => features['custom_themes'] == true;
  bool get hasPriorityAIProcessing => features['priority_ai_processing'] == true;
  
  // Check if plan is free
  bool get isFree => name == 'free';
  
  // Get display price with currency
  String getPriceMonthlyText() {
    if (priceMonthly == 0) return 'Ücretsiz';
    return '₺${priceMonthly.toStringAsFixed(0)}/ay';
  }
  
  String getPriceYearlyText() {
    if (priceYearly == 0) return 'Ücretsiz';
    final monthlyPrice = priceYearly / 12;
    return '₺${priceYearly.toStringAsFixed(0)}/yıl (₺${monthlyPrice.toStringAsFixed(1)}/ay)';
  }
}
