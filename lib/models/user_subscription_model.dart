class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionStatus status;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final DateTime? canceledAt;
  final String? originalTransactionId;
  final String? revenuecatCustomerId;
  final Map<String, dynamic>? revenuecatEntitlements;
  final SubscriptionPlatform? platform;
  final BillingPeriod? billingPeriod;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.expiresAt,
    this.canceledAt,
    this.originalTransactionId,
    this.revenuecatCustomerId,
    this.revenuecatEntitlements,
    this.platform,
    this.billingPeriod,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      planId: json['plan_id'] as String,
      status: SubscriptionStatus.fromString(json['status'] as String),
      startedAt: DateTime.parse(json['started_at'] as String),
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
      canceledAt: json['canceled_at'] != null
          ? DateTime.parse(json['canceled_at'] as String)
          : null,
      originalTransactionId: json['original_transaction_id'] as String?,
      revenuecatCustomerId: json['revenuecat_customer_id'] as String?,
      revenuecatEntitlements: json['revenuecat_entitlements'] as Map<String, dynamic>?,
      platform: json['platform'] != null 
          ? SubscriptionPlatform.fromString(json['platform'] as String)
          : null,
      billingPeriod: json['billing_period'] != null
          ? BillingPeriod.fromString(json['billing_period'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'plan_id': planId,
      'status': status.value,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'canceled_at': canceledAt?.toIso8601String(),
      'original_transaction_id': originalTransactionId,
      'revenuecat_customer_id': revenuecatCustomerId,
      'revenuecat_entitlements': revenuecatEntitlements,
      'platform': platform?.value,
      'billing_period': billingPeriod?.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired;
  bool get isTrial => status == SubscriptionStatus.trial;
  bool get isCanceled => status == SubscriptionStatus.canceled;
  
  bool get willExpireSoon {
    if (expiresAt == null) return false;
    final daysUntilExpiry = expiresAt!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }
  
  bool get hasExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }
  
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    final days = expiresAt!.difference(DateTime.now()).inDays;
    return days > 0 ? days : null;
  }
}

enum SubscriptionStatus {
  active,
  canceled,
  expired,
  trial,
  gracePeriod;

  String get value {
    switch (this) {
      case SubscriptionStatus.active:
        return 'active';
      case SubscriptionStatus.canceled:
        return 'canceled';
      case SubscriptionStatus.expired:
        return 'expired';
      case SubscriptionStatus.trial:
        return 'trial';
      case SubscriptionStatus.gracePeriod:
        return 'grace_period';
    }
  }

  static SubscriptionStatus fromString(String value) {
    switch (value) {
      case 'active':
        return SubscriptionStatus.active;
      case 'canceled':
        return SubscriptionStatus.canceled;
      case 'expired':
        return SubscriptionStatus.expired;
      case 'trial':
        return SubscriptionStatus.trial;
      case 'grace_period':
        return SubscriptionStatus.gracePeriod;
      default:
        return SubscriptionStatus.expired;
    }
  }
}

enum SubscriptionPlatform {
  ios,
  android;

  String get value {
    switch (this) {
      case SubscriptionPlatform.ios:
        return 'ios';
      case SubscriptionPlatform.android:
        return 'android';
    }
  }

  static SubscriptionPlatform fromString(String value) {
    switch (value) {
      case 'ios':
        return SubscriptionPlatform.ios;
      case 'android':
        return SubscriptionPlatform.android;
      default:
        throw ArgumentError('Invalid platform: $value');
    }
  }
}

enum BillingPeriod {
  monthly,
  yearly;

  String get value {
    switch (this) {
      case BillingPeriod.monthly:
        return 'monthly';
      case BillingPeriod.yearly:
        return 'yearly';
    }
  }

  static BillingPeriod fromString(String value) {
    switch (value) {
      case 'monthly':
        return BillingPeriod.monthly;
      case 'yearly':
        return BillingPeriod.yearly;
      default:
        throw ArgumentError('Invalid billing period: $value');
    }
  }
}
