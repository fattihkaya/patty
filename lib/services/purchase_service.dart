import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:pet_ai/core/app_config.dart';
import 'package:pet_ai/core/supabase_config.dart';

/// Purchase Service - RevenueCat Implementation for Patty
class PurchaseService {
  static bool _isInitialized = false;

  static bool get _hasConfiguredKeys {
    if (Platform.isIOS) return AppConfig.revenueCatApiKeyIOS.isNotEmpty;
    if (Platform.isAndroid) return AppConfig.revenueCatApiKeyAndroid.isNotEmpty;
    return false;
  }

  /// Initialize RevenueCat
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      if (kIsWeb) return;

      if (!_hasConfiguredKeys) {
        debugPrint('RevenueCat API keys are not configured.');
        return;
      }

      // Configure SDK
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      PurchasesConfiguration configuration;
      if (Platform.isIOS) {
        configuration = PurchasesConfiguration(AppConfig.revenueCatApiKeyIOS);
      } else if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(AppConfig.revenueCatApiKeyAndroid);
      } else {
        return;
      }

      await Purchases.configure(configuration);

      // Sync with Supabase Auth ID if available
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId != null) {
        await Purchases.logIn(userId);
      }

      _isInitialized = true;
      debugPrint('RevenueCat initialized successfully.');
    } catch (e) {
      debugPrint('RevenueCat initialization error: $e');
    }
  }

  /// Sync User ID after login
  static Future<void> login(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      debugPrint('RevenueCat login error: $e');
    }
  }

  /// Logout
  static Future<void> logout() async {
    try {
      await Purchases.logOut();
      _isInitialized = false;
    } catch (e) {
      debugPrint('RevenueCat logout error: $e');
    }
  }

  /// Get Offerings
  static Future<Offerings?> getOfferings() async {
    try {
      if (!_isInitialized) await initialize();
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('RevenueCat getOfferings error: $e');
      return null;
    }
  }

  /// Purchase Package (Legacy support for manual UI)
  static Future<CustomerInfo> purchasePackage(Package package) async {
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      await _updateSupabaseSubscription(customerInfo);
      return customerInfo;
    } on PurchasesError catch (e) {
      if (e.code == PurchasesErrorCode.purchaseCancelledError) {
        throw PurchaseException('Satın alma iptal edildi', PurchaseErrorType.cancelled);
      }
      throw PurchaseException(e.message, PurchaseErrorType.unknown);
    } catch (e) {
      throw PurchaseException(e.toString(), PurchaseErrorType.unknown);
    }
  }

  /// Check for "Patty Pro" Entitlement
  static Future<bool> isPro() async {
    try {
      if (!_isInitialized) await initialize();
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(AppConfig.entitlementId);
    } catch (e) {
      debugPrint('Error checking entitlement: $e');
      return false;
    }
  }

  /// Present RevenueCat Paywall
  static Future<void> showPaywall({Function(CustomerInfo)? onPurchaseCompleted}) async {
    try {
      if (kIsWeb) return; // Web'de RevenueCat UI yok
      if (!_isInitialized) await initialize();

      final paywallResult = await RevenueCatUI.presentPaywall(
        displayCloseButton: true,
      );

      if (paywallResult == PaywallResult.purchased || paywallResult == PaywallResult.restored) {
        final customerInfo = await Purchases.getCustomerInfo();
        await _updateSupabaseSubscription(customerInfo);
        if (onPurchaseCompleted != null) onPurchaseCompleted(customerInfo);
      }
    } catch (e) {
      debugPrint('Error showing paywall: $e');
    }
  }

  /// Present Customer Center (Self-service cancellation, etc.)
  static Future<void> showCustomerCenter() async {
    try {
      if (kIsWeb) return;
      await RevenueCatUI.presentCustomerCenter();
    } catch (e) {
      debugPrint('Error showing Customer Center: $e');
    }
  }

  /// Restore Purchases
  static Future<CustomerInfo?> restorePurchases() async {
    try {
      if (kIsWeb) return null;
      final customerInfo = await Purchases.restorePurchases();
      await _updateSupabaseSubscription(customerInfo);
      return customerInfo;
    } catch (e) {
      debugPrint('Restore error: $e');
      return null;
    }
  }

  /// Update Supabase metadata after purchase
  static Future<void> _updateSupabaseSubscription(CustomerInfo customerInfo) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final proEntitlement = customerInfo.entitlements.active[AppConfig.entitlementId];
      if (proEntitlement == null) return;

      final productId = proEntitlement.productIdentifier; // monthly, yearly, lifetime
      final expiresAt = proEntitlement.expirationDate;

      await SupabaseConfig.client.from('user_subscriptions').upsert({
        'user_id': userId,
        'status': 'active',
        'platform': Platform.isIOS ? 'ios' : 'android',
        'revenuecat_customer_id': customerInfo.originalAppUserId,
        'active_product_id': productId,
        'expires_at': expiresAt, // already Iso8601 string or null
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id');
      
      debugPrint('Supabase subscription updated for user $userId');
    } catch (e) {
      debugPrint('Error updating Supabase after purchase: $e');
    }
  }
}

/// Purchase Exception
class PurchaseException implements Exception {
  final String message;
  final PurchaseErrorType type;

  PurchaseException(this.message, this.type);

  @override
  String toString() => message;
}

/// Purchase error types
enum PurchaseErrorType {
  cancelled,
  notAllowed,
  invalid,
  notSupported,
  configuration,
  unknown,
}

