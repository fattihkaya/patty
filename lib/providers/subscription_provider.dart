import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/subscription_plan_model.dart';
import 'package:pet_ai/models/user_subscription_model.dart';
import 'package:pet_ai/models/usage_tracking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pet_ai/services/purchase_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  List<SubscriptionPlan> _plans = [];
  UserSubscription? _currentSubscription;
  SubscriptionPlan? _currentPlan;
  Map<String, int> _usageCounts = {}; // feature_type -> count
  bool _isLoading = false;
  String? _error;

  bool _isMissingTableError(Object e) {
    if (e is PostgrestException) {
      if (e.code == 'PGRST205') return true;
      final msg = (e.message).toLowerCase();
      if (msg.contains('does not exist')) return true;
      if (msg.contains('schema cache')) return true;
    }
    final raw = e.toString().toLowerCase();
    return raw.contains('pgrst205') ||
        raw.contains('does not exist') ||
        raw.contains('schema cache');
  }

  // Getters
  List<SubscriptionPlan> get plans => _plans;
  UserSubscription? get currentSubscription => _currentSubscription;
  SubscriptionPlan? get currentPlan => _currentPlan;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasActiveSubscription =>
      _currentSubscription != null && _currentSubscription!.isActive;

  // Get current plan name
  String get currentPlanName => _currentPlan?.name ?? 'free';

  // ─── Convenience helpers for UI paywalls ───
  bool get isFree => currentPlanName == 'free';
  bool get isPremium => !isFree;

  /// Max pets allowed on current plan (1 for free, unlimited for premium)
  int get maxPetsAllowed {
    if (isPremium) return 999;
    return _currentPlan?.maxPets ?? 1;
  }

  /// Monthly AI analyses allowed (3 for free, unlimited for premium)
  int get monthlyAiAnalysesAllowed {
    if (isPremium) return 999;
    return _currentPlan?.aiAnalysesPerMonth ?? 3;
  }

  /// Current month AI usage count (from cache)
  int get currentAiUsage => _usageCounts['ai_analysis'] ?? 0;

  /// Remaining free AI analyses this month
  int get freeAiRemaining {
    final limit = monthlyAiAnalysesAllowed;
    if (limit >= 999) return 999; // unlimited
    final remaining = limit - currentAiUsage;
    return remaining > 0 ? remaining : 0;
  }

  bool get canUseAdvancedAnalytics => isPremium;
  bool get canExportPdf => isPremium;
  bool get isAdFree => isPremium;

  SubscriptionProvider() {
    _loadSubscriptionData();
  }

  // Load all subscription data
  Future<void> _loadSubscriptionData() async {
    await Future.wait([
      fetchPlans(),
      fetchUserSubscription(),
      fetchUsageForCurrentMonth(),
    ]);
  }

  // Fetch available subscription plans
  Future<void> fetchPlans() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('subscription_plans')
          .select()
          .eq('is_active', true)
          .order('display_order');

      _plans = (response as List)
          .map((json) => SubscriptionPlan.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_isMissingTableError(e)) {
        _plans = [];
        _currentPlan = null;
        _error = null;
      } else {
        _error = 'Planlar yüklenirken hata oluştu: ${e.toString()}';
      }
      _isLoading = false;
      debugPrint('Fetch plans error: $e');
      notifyListeners();
    }
  }

  // Fetch user's current subscription
  Future<void> fetchUserSubscription() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        // No user logged in, use free plan
        _currentPlan = _getFreePlanOrNull();
        notifyListeners();
        return;
      }

      final response = await SupabaseConfig.client
          .from('user_subscriptions')
          .select('*, subscription_plans(*)')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _currentSubscription = UserSubscription.fromJson(response);

        // Get plan details
        if (response['subscription_plans'] != null) {
          _currentPlan =
              SubscriptionPlan.fromJson(response['subscription_plans']);
        } else {
          // Fallback: fetch plan by plan_id
          final planResponse = await SupabaseConfig.client
              .from('subscription_plans')
              .select()
              .eq('id', _currentSubscription!.planId)
              .maybeSingle();

          if (planResponse != null) {
            _currentPlan = SubscriptionPlan.fromJson(planResponse);
          }
        }
      } else {
        // No subscription found, default to free
        _currentPlan = _getFreePlanOrNull();
      }

      notifyListeners();
    } catch (e) {
      if (_isMissingTableError(e)) {
        _error = null;
      } else {
        _error = 'Abonelik bilgisi yüklenirken hata oluştu: ${e.toString()}';
      }
      debugPrint('Fetch subscription error: $e');

      // Fallback to free plan
      _currentPlan = _getFreePlanOrNull();
      notifyListeners();
    }
  }

  /// Safe fallback: returns the free plan from _plans, or null if _plans is empty.
  SubscriptionPlan? _getFreePlanOrNull() {
    if (_plans.isEmpty) return null;
    try {
      return _plans.firstWhere((p) => p.name == 'free');
    } catch (_) {
      return _plans.first;
    }
  }

  // Fetch usage for current month
  Future<void> fetchUsageForCurrentMonth() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final response = await SupabaseConfig.client
          .from('usage_tracking')
          .select()
          .eq('user_id', userId)
          .gte('usage_date', monthStart.toIso8601String().split('T')[0])
          .lte('usage_date', monthEnd.toIso8601String().split('T')[0]);

      _usageCounts = {};
      for (var item in (response as List)) {
        final tracking = UsageTracking.fromJson(item);
        _usageCounts[tracking.featureType] =
            (_usageCounts[tracking.featureType] ?? 0) + tracking.usageCount;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Fetch usage error: $e');
      if (_isMissingTableError(e)) {
        _usageCounts = {};
        notifyListeners();
      }
    }
  }

  // Check if user has access to a feature
  bool checkFeatureAccess(String feature) {
    if (_currentPlan == null) return false;

    switch (feature) {
      case 'advanced_analytics':
        return _currentPlan!.hasAdvancedAnalytics;
      case 'pdf_export':
        return _currentPlan!.hasPdfExports;
      case 'ad_free':
        return _currentPlan!.isAdFree;
      case 'priority_support':
        return _currentPlan!.hasPrioritySupport;
      case 'custom_themes':
        return _currentPlan!.hasCustomThemes;
      case 'unlimited_pets':
        return _currentPlan!.hasUnlimitedPets;
      default:
        return true; // Default allow
    }
  }

  // Check if user can use a feature (rate limiting)
  Future<bool> checkUsageLimit(String featureType) async {
    if (_currentPlan == null) return false;

    // Premium/Pro users have unlimited (if feature allows)
    if (featureType == 'ai_analysis' && _currentPlan!.hasUnlimitedAI) {
      return true;
    }

    // Check usage limit from plan features
    final limit = _getFeatureLimit(featureType);
    if (limit == -1) return true; // Unlimited

    // Get current month usage
    final currentUsage = await getUsageCount(featureType);
    return currentUsage < limit;
  }

  // Get usage count for a feature in current month
  Future<int> getUsageCount(String featureType) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return 0;

      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 0);

      final response = await SupabaseConfig.client
          .from('usage_tracking')
          .select()
          .eq('user_id', userId)
          .eq('feature_type', featureType)
          .gte('usage_date', monthStart.toIso8601String().split('T')[0])
          .lte('usage_date', monthEnd.toIso8601String().split('T')[0]);

      int total = 0;
      for (var item in (response as List)) {
        total += (item['usage_count'] as int? ?? 0);
      }

      return total;
    } catch (e) {
      debugPrint('Get usage count error: $e');
      return 0;
    }
  }

  // Get remaining usage for a feature
  Future<int> getRemainingUsage(String featureType) async {
    final limit = _getFeatureLimit(featureType);
    if (limit == -1) return -1; // Unlimited

    final currentUsage = await getUsageCount(featureType);
    final remaining = limit - currentUsage;
    return remaining > 0 ? remaining : 0;
  }

  // Get feature limit from current plan
  int _getFeatureLimit(String featureType) {
    if (_currentPlan == null) return 0;

    switch (featureType) {
      case 'ai_analysis':
        return _currentPlan!.aiAnalysesPerMonth;
      case 'pet_creation':
        return _currentPlan!.maxPets;
      default:
        return -1; // No limit
    }
  }

  // Increment usage count
  Future<void> incrementUsage(String featureType) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final dateString = today.toIso8601String().split('T')[0];

      // Try to update existing record
      final existing = await SupabaseConfig.client
          .from('usage_tracking')
          .select()
          .eq('user_id', userId)
          .eq('feature_type', featureType)
          .eq('usage_date', dateString)
          .maybeSingle();

      if (existing != null) {
        // Update existing
        await SupabaseConfig.client.from('usage_tracking').update({
          'usage_count': (existing['usage_count'] as int? ?? 0) + 1,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', existing['id']);
      } else {
        // Insert new
        await SupabaseConfig.client.from('usage_tracking').insert({
          'user_id': userId,
          'feature_type': featureType,
          'usage_date': dateString,
          'usage_count': 1,
        });
      }

      // Refresh usage counts
      await fetchUsageForCurrentMonth();
    } catch (e) {
      debugPrint('Increment usage error: $e');
      if (_isMissingTableError(e)) {
        return;
      }
    }
  }

  // Update subscription (called from purchase service after successful purchase)
  Future<void> updateSubscriptionFromPurchase({
    required String planName,
    required String transactionId,
    String? platform,
    String? billingPeriod,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Find plan
      final plan = _plans.firstWhere((p) => p.name == planName);

      // Update or create subscription
      final existing = await SupabaseConfig.client
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      final expiresAt = billingPeriod == 'yearly'
          ? DateTime.now().add(const Duration(days: 365))
          : DateTime.now().add(const Duration(days: 30));

      if (existing != null) {
        // Update existing
        await SupabaseConfig.client.from('user_subscriptions').update({
          'plan_id': plan.id,
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
          'original_transaction_id': transactionId,
          'platform': platform,
          'billing_period': billingPeriod,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('user_id', userId);
      } else {
        // Create new
        await SupabaseConfig.client.from('user_subscriptions').insert({
          'user_id': userId,
          'plan_id': plan.id,
          'status': 'active',
          'started_at': DateTime.now().toIso8601String(),
          'expires_at': expiresAt.toIso8601String(),
          'original_transaction_id': transactionId,
          'platform': platform,
          'billing_period': billingPeriod,
        });
      }

      // Refresh subscription data
      await fetchUserSubscription();
    } catch (e) {
      _error = 'Abonelik güncellenirken hata oluştu: ${e.toString()}';
      debugPrint('Update subscription error: $e');
      notifyListeners();
      rethrow;
    }
  }

  // Refresh subscription status (for checking expiry, etc.)
  Future<void> refreshSubscription() async {
    await fetchUserSubscription();
    await fetchUsageForCurrentMonth();
    await syncWithRevenueCat();
  }

  // Sync with RevenueCat status
  Future<void> syncWithRevenueCat() async {
    try {
      final isPro = await PurchaseService.isPro();
      if (isPro) {
        // If RC says we are pro but local state says free, force local state to premium
        if (currentPlanName == 'free') {
          // This ensures UI updates even if Supabase sync hasn't happened yet
          debugPrint('SubscriptionProvider: RC says PRO, refreshing Supabase...');
          await fetchUserSubscription();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Sync with RevenueCat error: $e');
    }
  }

  // Check if user has premium access
  bool get hasPremiumAccess {
    return currentPlanName == 'premium' ||
        currentPlanName == 'pro' ||
        currentPlanName == 'premium_monthly' ||
        currentPlanName == 'premium_yearly' ||
        currentPlanName == 'premium_lifetime';
  }

  // Check if user can perform AI analysis
  Future<bool> canPerformAiAnalysis() async {
    if (_currentPlan == null) return false;

    // Premium/Pro users have unlimited
    if (_currentPlan!.hasUnlimitedAI) {
      return true;
    }

    // Check usage limit
    return await checkUsageLimit('ai_analysis');
  }

  // Check if user can add more pets
  Future<bool> canAddMorePets(int currentPetCount) async {
    if (_currentPlan == null) return false;

    // Premium/Pro users have unlimited
    if (_currentPlan!.hasUnlimitedPets) {
      return true;
    }

    // Check limit
    final maxPets = _currentPlan!.maxPets;
    if (maxPets == -1) return true; // Unlimited

    return currentPetCount < maxPets;
  }
}
