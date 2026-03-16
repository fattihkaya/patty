class ProductRecommendation {
  final String id;
  final String partnerId;
  final String productName;
  final String? productDescription;
  final String? productImageUrl;
  final String productUrl;
  final double? productPrice;
  final String currency;
  final String? category;
  final List<String>? tags;
  final List<String>? targetPetTypes;
  final List<String>? targetConditions;
  final String? recommendationReason;
  final int priority;
  final bool isFeatured;
  final bool isActive;
  final int clickCount;
  final int purchaseCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProductRecommendation({
    required this.id,
    required this.partnerId,
    required this.productName,
    this.productDescription,
    this.productImageUrl,
    required this.productUrl,
    this.productPrice,
    this.currency = 'TRY',
    this.category,
    this.tags,
    this.targetPetTypes,
    this.targetConditions,
    this.recommendationReason,
    this.priority = 0,
    this.isFeatured = false,
    this.isActive = true,
    this.clickCount = 0,
    this.purchaseCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProductRecommendation.fromJson(Map<String, dynamic> json) {
    return ProductRecommendation(
      id: json['id'] as String,
      partnerId: json['partner_id'] as String,
      productName: json['product_name'] as String,
      productDescription: json['product_description'] as String?,
      productImageUrl: json['product_image_url'] as String?,
      productUrl: json['product_url'] as String,
      productPrice: (json['product_price'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'TRY',
      category: json['category'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags'] as List) : null,
      targetPetTypes: json['target_pet_types'] != null 
          ? List<String>.from(json['target_pet_types'] as List) 
          : null,
      targetConditions: json['target_conditions'] != null
          ? List<String>.from(json['target_conditions'] as List)
          : null,
      recommendationReason: json['recommendation_reason'] as String?,
      priority: json['priority'] as int? ?? 0,
      isFeatured: json['is_featured'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      clickCount: json['click_count'] as int? ?? 0,
      purchaseCount: json['purchase_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'partner_id': partnerId,
      'product_name': productName,
      'product_description': productDescription,
      'product_image_url': productImageUrl,
      'product_url': productUrl,
      'product_price': productPrice,
      'currency': currency,
      'category': category,
      'tags': tags,
      'target_pet_types': targetPetTypes,
      'target_conditions': targetConditions,
      'recommendation_reason': recommendationReason,
      'priority': priority,
      'is_featured': isFeatured,
      'is_active': isActive,
      'click_count': clickCount,
      'purchase_count': purchaseCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
