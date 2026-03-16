import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/achievement_model.dart';
import 'package:pet_ai/models/points_shop_item_model.dart';

class GamificationProvider extends ChangeNotifier {
  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  List<PointsShopItem> _shopItems = [];
  List<PointsRedemption> _userRedemptions = [];
  bool _isLoading = false;

  // Getters
  List<Achievement> get allAchievements => _allAchievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  List<PointsShopItem> get shopItems => _shopItems;
  List<PointsRedemption> get userRedemptions => _userRedemptions;
  bool get isLoading => _isLoading;

  // Get unlocked achievement codes
  Set<String> get unlockedAchievementCodes {
    return _userAchievements
        .map((ua) => _allAchievements.firstWhere(
              (a) => a.id == ua.achievementId,
              orElse: () => Achievement(
                id: '',
                code: '',
                name: '',
                description: '',
              ),
            ).code)
        .where((code) => code.isNotEmpty)
        .toSet();
  }

  // Check if achievement is unlocked
  bool isAchievementUnlocked(String achievementCode) {
    return unlockedAchievementCodes.contains(achievementCode);
  }

  GamificationProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      fetchAllAchievements(),
      fetchUserAchievements(),
      fetchShopItems(),
      fetchUserRedemptions(),
    ]);
  }

  // Fetch all available achievements
  Future<void> fetchAllAchievements() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('achievements')
          .select()
          .eq('is_active', true)
          .order('display_order');

      _allAchievements = (response as List)
          .map((json) => Achievement.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      debugPrint('Fetch achievements error: $e');
      notifyListeners();
    }
  }

  // Fetch user's unlocked achievements
  Future<void> fetchUserAchievements() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('user_achievements')
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      _userAchievements = (response as List)
          .map((json) => UserAchievement.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Fetch user achievements error: $e');
    }
  }

  // Fetch points shop items
  Future<void> fetchShopItems() async {
    try {
      final response = await SupabaseConfig.client
          .from('points_shop_items')
          .select()
          .eq('is_available', true)
          .order('display_order');

      _shopItems = (response as List)
          .map((json) => PointsShopItem.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Fetch shop items error: $e');
    }
  }

  // Fetch user's redemptions
  Future<void> fetchUserRedemptions() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await SupabaseConfig.client
          .from('points_redemptions')
          .select()
          .eq('user_id', userId)
          .order('redeemed_at', ascending: false);

      _userRedemptions = (response as List)
          .map((json) => PointsRedemption.fromJson(json))
          .toList();

      notifyListeners();
    } catch (e) {
      debugPrint('Fetch redemptions error: $e');
    }
  }

  // Check and grant achievement (called from backend trigger or manually)
  Future<bool> checkAndGrantAchievement(
    String achievementCode, {
    String? petId,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return false;

      // Call Supabase function
      final response = await SupabaseConfig.client.rpc(
        'check_and_grant_achievement',
        params: {
          'p_user_id': userId,
          'p_achievement_code': achievementCode,
          'p_pet_id': petId,
        },
      );

      final granted = response as bool? ?? false;

      if (granted) {
        // Refresh achievements
        await fetchUserAchievements();
      }

      return granted;
    } catch (e) {
      debugPrint('Check achievement error: $e');
      return false;
    }
  }

  // Redeem points for shop item
  Future<bool> redeemPoints(String shopItemId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get shop item
      final item = _shopItems.firstWhere((i) => i.id == shopItemId);
      
      // Get user's current points
      final profileResponse = await SupabaseConfig.client
          .from('profiles')
          .select('total_pati_points')
          .eq('id', userId)
          .maybeSingle();

      final currentPoints = (profileResponse?['total_pati_points'] as int?) ?? 0;

      if (currentPoints < item.pointsCost) {
        throw Exception('Yeterli puanınız yok');
      }

      // Create redemption
      DateTime? expiresAt;
      if (item.itemType == PointsItemType.premiumTrial) {
        final days = item.premiumTrialDays ?? 3;
        expiresAt = DateTime.now().add(Duration(days: days));
      }

      await SupabaseConfig.client.from('points_redemptions').insert({
        'user_id': userId,
        'shop_item_id': shopItemId,
        'points_spent': item.pointsCost,
        'expires_at': expiresAt?.toIso8601String(),
      });

      // Deduct points
      await SupabaseConfig.client
          .from('profiles')
          .update({
            'total_pati_points': currentPoints - item.pointsCost,
          })
          .eq('id', userId);

      // Refresh data
      await fetchUserRedemptions();

      return true;
    } catch (e) {
      debugPrint('Redeem points error: $e');
      rethrow;
    }
  }

  // Get user's current points
  Future<int> getUserPoints() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await SupabaseConfig.client
          .from('profiles')
          .select('total_pati_points')
          .eq('id', userId)
          .maybeSingle();

      return (response?['total_pati_points'] as int?) ?? 0;
    } catch (e) {
      debugPrint('Get user points error: $e');
      return 0;
    }
  }

  // Get achievements by category
  List<Achievement> getAchievementsByCategory(String category) {
    return _allAchievements.where((a) => a.category == category).toList();
  }

  // Get unlocked achievements with details
  List<Achievement> getUnlockedAchievementsDetails() {
    return _userAchievements.map((ua) {
      return _allAchievements.firstWhere(
        (a) => a.id == ua.achievementId,
        orElse: () => Achievement(
          id: '',
          code: '',
          name: '',
          description: '',
        ),
      );
    }).where((a) => a.id.isNotEmpty).toList();
  }

  // Refresh all data
  Future<void> refresh() async {
    await _loadInitialData();
  }
}
