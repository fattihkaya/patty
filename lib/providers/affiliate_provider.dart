import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/affiliate_partner_model.dart';
import 'package:pet_ai/models/product_recommendation_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateProvider extends ChangeNotifier {
  List<AffiliatePartner> _partners = [];
  List<ProductRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<AffiliatePartner> get partners => _partners;
  List<ProductRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch active affiliate partners
  Future<void> fetchPartners() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('affiliate_partners')
          .select()
          .eq('is_active', true)
          .order('name');

      _partners = (response as List)
          .map((json) => AffiliatePartner.fromJson(json))
          .toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Partner\'lar yüklenirken hata oluştu: ${e.toString()}';
      _isLoading = false;
      debugPrint('Fetch partners error: $e');
      notifyListeners();
    }
  }

  // Fetch product recommendations
  Future<void> fetchRecommendations({
    String? category,
    List<String>? petTypes,
    int? limit,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      var query = SupabaseConfig.client
          .from('product_recommendations')
          .select()
          .eq('is_active', true);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query.order('is_featured', ascending: false)
          .order('priority', ascending: false)
          .order('click_count', ascending: false)
          .limit(limit ?? 100);

      List<ProductRecommendation> recommendations = (response as List)
          .map((json) => ProductRecommendation.fromJson(json))
          .toList();

      // Filter by pet types if provided
      if (petTypes != null && petTypes.isNotEmpty) {
        recommendations = recommendations.where((rec) {
          if (rec.targetPetTypes == null || rec.targetPetTypes!.isEmpty) {
            return true; // No target restriction
          }
          return rec.targetPetTypes!.any((type) => petTypes.contains(type));
        }).toList();
      }

      _recommendations = recommendations;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Öneriler yüklenirken hata oluştu: ${e.toString()}';
      _isLoading = false;
      debugPrint('Fetch recommendations error: $e');
      notifyListeners();
    }
  }

  // Get recommendations for a specific pet
  Future<List<ProductRecommendation>> getRecommendationsForPet(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return [];

      // Get pet info
      final petResponse = await SupabaseConfig.client
          .from('pets')
          .select('type')
          .eq('id', petId)
          .maybeSingle();

      if (petResponse == null) return [];

      final petType = petResponse['type'] as String?;
      final petTypes = petType != null ? [petType] : null;

      // Fetch recommendations
      await fetchRecommendations(petTypes: petTypes, limit: 5);

      return _recommendations;
    } catch (e) {
      debugPrint('Get recommendations for pet error: $e');
      return [];
    }
  }

  // Track affiliate click
  Future<String?> trackClick({
    required String productRecommendationId,
    required String source,
    String? petId,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('No user ID, skipping click tracking');
        return null;
      }

      // Call Supabase function to track click
      final response = await SupabaseConfig.client.rpc(
        'track_affiliate_click',
        params: {
          'p_user_id': userId,
          'p_product_recommendation_id': productRecommendationId,
          'p_source': source,
          'p_pet_id': petId,
        },
      );

      final clickId = response as String?;
      debugPrint('Affiliate click tracked: $clickId');

      return clickId;
    } catch (e) {
      debugPrint('Track click error: $e');
      // Don't throw - tracking is optional
      return null;
    }
  }

  // Open affiliate link (with tracking)
  Future<void> openAffiliateLink({
    required ProductRecommendation recommendation,
    required String source,
    String? petId,
  }) async {
    try {
      // Track click first
      await trackClick(
        productRecommendationId: recommendation.id,
        source: source,
        petId: petId,
      );

      // Open URL
      final uri = Uri.parse(recommendation.productUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('URL açılamadı: ${recommendation.productUrl}');
      }
    } catch (e) {
      debugPrint('Open affiliate link error: $e');
      rethrow;
    }
  }

  // Get recommendations by category
  List<ProductRecommendation> getRecommendationsByCategory(String category) {
    return _recommendations.where((r) => r.category == category).toList();
  }

  // Get featured recommendations
  List<ProductRecommendation> get featuredRecommendations {
    return _recommendations.where((r) => r.isFeatured).toList();
  }

  // Dismiss recommendation (save user preference)
  Future<void> dismissRecommendation(String recommendationId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseConfig.client.from('user_recommendation_preferences').insert({
        'user_id': userId,
        'product_recommendation_id': recommendationId,
        'action': 'dismissed',
      });

      // Remove from current recommendations
      _recommendations.removeWhere((r) => r.id == recommendationId);
      notifyListeners();
    } catch (e) {
      debugPrint('Dismiss recommendation error: $e');
    }
  }

  // Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      fetchPartners(),
      fetchRecommendations(),
    ]);
  }
}
