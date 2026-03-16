class AffiliatePartner {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? websiteUrl;
  final String affiliateCode;
  final double commissionRate;
  final bool isActive;
  final String partnerType;
  final String? category;
  final DateTime createdAt;
  final DateTime updatedAt;

  AffiliatePartner({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.websiteUrl,
    required this.affiliateCode,
    this.commissionRate = 0.0,
    this.isActive = true,
    this.partnerType = 'product',
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AffiliatePartner.fromJson(Map<String, dynamic> json) {
    return AffiliatePartner(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      affiliateCode: json['affiliate_code'] as String,
      commissionRate: (json['commission_rate'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      partnerType: json['partner_type'] as String? ?? 'product',
      category: json['category'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'website_url': websiteUrl,
      'affiliate_code': affiliateCode,
      'commission_rate': commissionRate,
      'is_active': isActive,
      'partner_type': partnerType,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
