import 'dart:convert';

class PointsShopItem {
  final String id;
  final String name;
  final String description;
  final String? iconName;
  final int pointsCost;
  final PointsItemType itemType;
  final String? itemValue; // JSON string
  final bool isAvailable;
  final int? stockLimit;
  final int displayOrder;

  PointsShopItem({
    required this.id,
    required this.name,
    required this.description,
    this.iconName,
    required this.pointsCost,
    required this.itemType,
    this.itemValue,
    this.isAvailable = true,
    this.stockLimit,
    this.displayOrder = 0,
  });

  factory PointsShopItem.fromJson(Map<String, dynamic> json) {
    return PointsShopItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String?,
      pointsCost: json['points_cost'] as int,
      itemType: PointsItemType.fromString(json['item_type'] as String),
      itemValue: json['item_value'] as String?,
      isAvailable: json['is_available'] as bool? ?? true,
      stockLimit: json['stock_limit'] as int?,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'points_cost': pointsCost,
      'item_type': itemType.value,
      'item_value': itemValue,
      'is_available': isAvailable,
      'stock_limit': stockLimit,
      'display_order': displayOrder,
    };
  }

  // Parse item value as JSON
  Map<String, dynamic>? get parsedItemValue {
    if (itemValue == null) return null;
    try {
      return jsonDecode(itemValue!) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }
  
  // Get premium trial days
  int? get premiumTrialDays {
    if (itemType != PointsItemType.premiumTrial) return null;
    final parsed = parsedItemValue;
    return parsed?['days'] as int?;
  }
}

enum PointsItemType {
  premiumTrial('premium_trial'),
  badge('badge'),
  customization('customization'),
  discount('discount'),
  theme('theme');

  final String value;
  const PointsItemType(this.value);

  static PointsItemType fromString(String value) {
    switch (value) {
      case 'premium_trial':
        return PointsItemType.premiumTrial;
      case 'badge':
        return PointsItemType.badge;
      case 'customization':
        return PointsItemType.customization;
      case 'discount':
        return PointsItemType.discount;
      case 'theme':
        return PointsItemType.theme;
      default:
        return PointsItemType.badge;
    }
  }
}

class PointsRedemption {
  final String id;
  final String userId;
  final String shopItemId;
  final int pointsSpent;
  final DateTime redeemedAt;
  final RedemptionStatus status;
  final DateTime? expiresAt;
  final Map<String, dynamic>? metadata;

  PointsRedemption({
    required this.id,
    required this.userId,
    required this.shopItemId,
    required this.pointsSpent,
    required this.redeemedAt,
    required this.status,
    this.expiresAt,
    this.metadata,
  });

  factory PointsRedemption.fromJson(Map<String, dynamic> json) {
    return PointsRedemption(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      shopItemId: json['shop_item_id'] as String,
      pointsSpent: json['points_spent'] as int,
      redeemedAt: DateTime.parse(json['redeemed_at'] as String),
      status: RedemptionStatus.fromString(json['status'] as String? ?? 'active'),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'shop_item_id': shopItemId,
      'points_spent': pointsSpent,
      'redeemed_at': redeemedAt.toIso8601String(),
      'status': status.value,
      'expires_at': expiresAt?.toIso8601String(),
      'metadata': metadata,
    };
  }
}

enum RedemptionStatus {
  active,
  used,
  expired;

  String get value {
    switch (this) {
      case RedemptionStatus.active:
        return 'active';
      case RedemptionStatus.used:
        return 'used';
      case RedemptionStatus.expired:
        return 'expired';
    }
  }

  static RedemptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return RedemptionStatus.active;
      case 'used':
        return RedemptionStatus.used;
      case 'expired':
        return RedemptionStatus.expired;
      default:
        return RedemptionStatus.active;
    }
  }
}
