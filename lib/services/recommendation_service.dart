import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/expense_model.dart';
import 'package:pet_ai/models/pet_food_tracking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Recommendation {
  final String title;
  final String message;
  final String type; // 'info', 'warning', 'suggestion'
  final String? actionId; // Optional action identifier

  Recommendation({
    required this.title,
    required this.message,
    this.type = 'info',
    this.actionId,
  });
}

class RecommendationService {
  // Get recommendations for a pet
  static Future<List<Recommendation>> getRecommendations(String petId) async {
    final recommendations = <Recommendation>[];

    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return recommendations;

      // Fetch expenses
      final expensesResponse = await SupabaseConfig.client
          .from('expenses')
          .select()
          .eq('pet_id', petId)
          .order('expense_date', ascending: false);

      final expenses = (expensesResponse as List)
          .map((json) => Expense.fromJson(json))
          .toList();

      if (expenses.isEmpty) {
        recommendations.add(Recommendation(
          title: 'Hoş Geldiniz!',
          message: 'Henüz harcama kaydı yok. İlk harcamanızı ekleyerek başlayın!',
          type: 'info',
        ));
        return recommendations;
      }

      // Fetch food tracking
      final foodTrackingResponse = await SupabaseConfig.client
          .from('pet_food_tracking')
          .select()
          .eq('pet_id', petId)
          .eq('is_finished', false);

      final foodTracking = (foodTrackingResponse as List)
          .map((json) => PetFoodTracking.fromJson(json))
          .toList();

      // Check for low food stock
      for (final food in foodTracking) {
        if (food.isLowStock) {
          recommendations.add(Recommendation(
            title: 'Mama Bitmek Üzere',
            message: '${food.foodName} için mama bitmek üzere! (${food.daysRemaining} gün kaldı)',
            type: 'warning',
            actionId: 'food_low_${food.id}',
          ));
        }
      }

      // Check monthly spending trends
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      final thisMonthExpenses = expenses.where((e) =>
          e.expenseDate.isAfter(thisMonthStart) || e.expenseDate.isAtSameMomentAs(thisMonthStart)).toList();
      final lastMonthExpenses = expenses.where((e) =>
          e.expenseDate.isAfter(lastMonthStart) && e.expenseDate.isBefore(lastMonthEnd.add(const Duration(days: 1)))).toList();

      final thisMonthTotal = thisMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      final lastMonthTotal = lastMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);

      if (lastMonthTotal > 0) {
        final increase = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
        if (increase > 20) {
          recommendations.add(Recommendation(
            title: 'Harcama Artışı',
            message: 'Bu ay harcamalarınız geçen aya göre %${increase.toStringAsFixed(0)} arttı. Bütçenizi gözden geçirmenizi öneririz.',
            type: 'warning',
            actionId: 'spending_increase',
          ));
        } else if (increase < -20) {
          recommendations.add(Recommendation(
            title: 'Tasarruf',
            message: 'Bu ay harcamalarınız geçen aya göre %${(-increase).toStringAsFixed(0)} azaldı. Harika!',
            type: 'info',
          ));
        }
      }

      // Check category balance
      final categoryTotals = <String, double>{};
      for (final expense in expenses) {
        final categoryId = expense.categoryId ?? 'other';
        categoryTotals[categoryId] = (categoryTotals[categoryId] ?? 0) + expense.amount;
      }

      if (categoryTotals.isNotEmpty) {
        final total = categoryTotals.values.reduce((a, b) => a + b);
        final foodCategory = categoryTotals['food'] ?? 0;
        
        if (foodCategory / total > 0.5) {
          recommendations.add(Recommendation(
            title: 'Kategori Dengesi',
            message: 'Harcamalarınızın yarısından fazlası mama kategorisinde. Diğer kategorilere (veteriner, oyuncak, vs.) de bakabilirsiniz.',
            type: 'suggestion',
          ));
        }

        // Check if vet expenses are too low (might indicate missed checkups)
        final vetCategory = categoryTotals['vet'] ?? 0;
        if (vetCategory / total < 0.1 && total > 1000) {
          recommendations.add(Recommendation(
            title: 'Sağlık Kontrolü',
            message: 'Veteriner harcamalarınız düşük görünüyor. Düzenli sağlık kontrollerini unutmayın!',
            type: 'suggestion',
            actionId: 'vet_checkup',
          ));
        }
      }

      // Seasonal recommendations
      final month = now.month;
      if (month >= 11 || month <= 2) {
        // Winter months
        recommendations.add(Recommendation(
          title: 'Kış Önerisi',
          message: 'Soğuk havalarda pet\'iniz için kıyafet veya yatak gibi ekstra bakım ürünleri düşünebilirsiniz.',
          type: 'suggestion',
        ));
      } else if (month >= 6 && month <= 8) {
        // Summer months
        recommendations.add(Recommendation(
          title: 'Yaz Önerisi',
          message: 'Sıcak havalarda pet\'iniz için serinleme ürünleri veya su oyuncakları düşünebilirsiniz.',
          type: 'suggestion',
        ));
      }

      // Check for recurring expenses that might need attention
      final recurringExpenses = expenses.where((e) => e.isRecurring).toList();
      if (recurringExpenses.isNotEmpty) {
        final nextDue = recurringExpenses.map((e) {
          if (e.recurringIntervalDays != null) {
            return e.expenseDate.add(Duration(days: e.recurringIntervalDays!));
          }
          return null;
        }).whereType<DateTime>().toList();

        if (nextDue.isNotEmpty) {
          nextDue.sort();
          final nearest = nextDue.first;
          final daysUntil = nearest.difference(now).inDays;
          
          if (daysUntil <= 7 && daysUntil > 0) {
            recommendations.add(Recommendation(
              title: 'Yaklaşan Harcama',
              message: 'Tekrarlayan bir harcamanız $daysUntil gün içinde yapılacak. Hazırlıklı olun!',
              type: 'info',
              actionId: 'recurring_expense',
            ));
          }
        }
      }

    } catch (e) {
      if (e is PostgrestException) {
        debugPrint('PostgrestException: ${e.message}');
      } else {
        debugPrint('Get recommendations failed: $e');
      }
    }

    return recommendations;
  }
}
