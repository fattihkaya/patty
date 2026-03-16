import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/expense_model.dart';
import 'package:pet_ai/models/expense_category_model.dart';
import 'package:pet_ai/models/expense_reminder_model.dart';
import 'package:pet_ai/models/pet_food_tracking_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseProvider extends ChangeNotifier {
  final Map<String, List<Expense>> _expensesPerPet = {};
  final Map<String, List<ExpenseReminder>> _remindersPerPet = {};
  final Map<String, List<PetFoodTracking>> _foodTrackingPerPet = {};
  final List<ExpenseCategory> _categories = [];
  // ignore: prefer_final_fields
  bool _isLoading = false;
  bool _isLoadingExpenses = false;

  ExpenseProvider() {
    fetchExpenseCategories();
  }

  // Getters
  List<ExpenseCategory> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingExpenses => _isLoadingExpenses;

  List<Expense> expensesForPet(String petId) => _expensesPerPet[petId] ?? [];
  List<ExpenseReminder> remindersForPet(String petId) => _remindersPerPet[petId] ?? [];
  List<PetFoodTracking> foodTrackingForPet(String petId) => _foodTrackingPerPet[petId] ?? [];

  // Fetch expense categories
  Future<void> fetchExpenseCategories() async {
    try {
      final response = await SupabaseConfig.client
          .from('expense_categories')
          .select()
          .order('name');

      _categories.clear();
      _categories.addAll(
        (response as List).map((json) => ExpenseCategory.fromJson(json)).toList(),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch expense categories failed: $e');
      _logSupabaseError(e);
    }
  }

  // Fetch expenses for a pet
  Future<void> fetchExpenses(String petId) async {
    try {
      _isLoadingExpenses = true;
      notifyListeners();

      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('fetchExpenses skipped: no auth session');
        return;
      }

      final response = await SupabaseConfig.client
          .from('expenses')
          .select()
          .eq('pet_id', petId)
          .order('expense_date', ascending: false);

      _expensesPerPet[petId] =
          (response as List).map((json) => Expense.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch expenses failed: $e');
      _logSupabaseError(e);
    } finally {
      _isLoadingExpenses = false;
      notifyListeners();
    }
  }

  // Fetch expenses by date range
  Future<List<Expense>> fetchExpensesByDateRange(
    String petId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      final response = await SupabaseConfig.client
          .from('expenses')
          .select()
          .eq('pet_id', petId)
          .gte('expense_date', start.toIso8601String().split('T')[0])
          .lte('expense_date', end.toIso8601String().split('T')[0])
          .order('expense_date', ascending: false);

      return (response as List)
          .map((json) => Expense.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Fetch expenses by date range failed: $e');
      _logSupabaseError(e);
      return [];
    }
  }

  // Add expense
  Future<void> addExpense(Expense expense) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final data = expense.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data['user_id'] = userId;

      await SupabaseConfig.client.from('expenses').insert(data);
      await fetchExpenses(expense.petId);
    } catch (e) {
      debugPrint('Add expense failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  // Update expense
  Future<void> updateExpense(Expense expense) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final data = expense.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      await SupabaseConfig.client
          .from('expenses')
          .update(data)
          .eq('id', expense.id)
          .eq('user_id', userId);

      await fetchExpenses(expense.petId);
    } catch (e) {
      debugPrint('Update expense failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId, String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      await SupabaseConfig.client
          .from('expenses')
          .delete()
          .eq('id', expenseId)
          .eq('user_id', userId);

      await fetchExpenses(petId);
    } catch (e) {
      debugPrint('Delete expense failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  // Get total expenses
  double getTotalExpenses(String petId, {DateTime? start, DateTime? end}) {
    final expenses = _expensesPerPet[petId] ?? [];
    if (start == null && end == null) {
      return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    }

    final filtered = expenses.where((expense) {
      if (start != null && expense.expenseDate.isBefore(start)) return false;
      if (end != null && expense.expenseDate.isAfter(end)) return false;
      return true;
    });

    return filtered.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  // Get expenses grouped by category
  Map<String, double> getExpensesByCategory(String petId) {
    final expenses = _expensesPerPet[petId] ?? [];
    final grouped = <String, double>{};

    for (final expense in expenses) {
      final categoryId = expense.categoryId ?? 'other';
      grouped[categoryId] = (grouped[categoryId] ?? 0) + expense.amount;
    }

    return grouped;
  }

  // Food tracking methods
  Future<void> fetchFoodTracking(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      final response = await SupabaseConfig.client
          .from('pet_food_tracking')
          .select()
          .eq('pet_id', petId)
          .eq('is_finished', false)
          .order('estimated_finish_date', ascending: true);

      _foodTrackingPerPet[petId] = (response as List)
          .map((json) => PetFoodTracking.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch food tracking failed: $e');
      _logSupabaseError(e);
    }
  }

  Future<void> addFoodTracking(PetFoodTracking tracking) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final data = tracking.toJson();
      data.remove('id');
      data.remove('created_at');
      data.remove('updated_at');
      data['user_id'] = userId;

      await SupabaseConfig.client.from('pet_food_tracking').insert(data);
      await fetchFoodTracking(tracking.petId);
    } catch (e) {
      debugPrint('Add food tracking failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  Future<void> updateFoodTracking(PetFoodTracking tracking) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final data = tracking.toJson();
      data.remove('created_at');
      data.remove('updated_at');

      await SupabaseConfig.client
          .from('pet_food_tracking')
          .update(data)
          .eq('id', tracking.id)
          .eq('user_id', userId);

      await fetchFoodTracking(tracking.petId);
    } catch (e) {
      debugPrint('Update food tracking failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  Future<void> deleteFoodTracking(String trackingId, String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      await SupabaseConfig.client
          .from('pet_food_tracking')
          .delete()
          .eq('id', trackingId)
          .eq('user_id', userId);

      await fetchFoodTracking(petId);
    } catch (e) {
      debugPrint('Delete food tracking failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  // Reminder methods
  Future<void> fetchActiveReminders(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        return;
      }

      final now = DateTime.now();
      final response = await SupabaseConfig.client
          .from('expense_reminders')
          .select()
          .eq('pet_id', petId)
          .eq('is_active', true)
          .gte('reminder_date', now.toIso8601String().split('T')[0])
          .order('reminder_date', ascending: true);

      _remindersPerPet[petId] = (response as List)
          .map((json) => ExpenseReminder.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch reminders failed: $e');
      _logSupabaseError(e);
    }
  }

  Future<void> createReminder(ExpenseReminder reminder) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      final data = reminder.toJson();
      data.remove('id');
      data.remove('created_at');
      data['user_id'] = userId;

      await SupabaseConfig.client.from('expense_reminders').insert(data);
      await fetchActiveReminders(reminder.petId);
    } catch (e) {
      debugPrint('Create reminder failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  Future<void> markReminderAsSent(String reminderId, String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      await SupabaseConfig.client
          .from('expense_reminders')
          .update({'is_sent': true})
          .eq('id', reminderId)
          .eq('user_id', userId);

      await fetchActiveReminders(petId);
    } catch (e) {
      debugPrint('Mark reminder as sent failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId, String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Kullanıcı girişi gerekli');
      }

      await SupabaseConfig.client
          .from('expense_reminders')
          .delete()
          .eq('id', reminderId)
          .eq('user_id', userId);

      await fetchActiveReminders(petId);
    } catch (e) {
      debugPrint('Delete reminder failed: $e');
      _logSupabaseError(e);
      rethrow;
    }
  }

  // Get recommendations (simple rule-based)
  List<String> getRecommendations(String petId) {
    final recommendations = <String>[];
    final expenses = _expensesPerPet[petId] ?? [];
    final foodTracking = _foodTrackingPerPet[petId] ?? [];

    if (expenses.isEmpty) {
      recommendations.add('Henüz harcama kaydı yok. İlk harcamanızı ekleyerek başlayın!');
      return recommendations;
    }

    // Check for low food stock
    final lowStockFoods = foodTracking.where((tracking) => tracking.isLowStock).toList();
    if (lowStockFoods.isNotEmpty) {
      for (final food in lowStockFoods) {
        recommendations.add('${food.foodName} için mama bitmek üzere! (${food.daysRemaining} gün kaldı)');
      }
    }

    // Check monthly average
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);

    final thisMonthTotal = getTotalExpenses(petId, start: thisMonthStart, end: now);
    final lastMonthTotal = getTotalExpenses(petId, start: lastMonthStart, end: lastMonthEnd);

    if (lastMonthTotal > 0) {
      final increase = ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100;
      if (increase > 20) {
        recommendations.add('Bu ay harcamalarınız geçen aya göre %${increase.toStringAsFixed(0)} arttı.');
      }
    }

    // Check category balance
    final byCategory = getExpensesByCategory(petId);
    if (byCategory.isNotEmpty) {
      final total = byCategory.values.reduce((a, b) => a + b);
      final foodCategory = byCategory['food'] ?? 0;
      if (foodCategory / total > 0.5) {
        recommendations.add('Harcamalarınızın yarısından fazlası mama kategorisinde. Diğer kategorilere de bakabilirsiniz.');
      }
    }

    return recommendations;
  }

  void _logSupabaseError(Object e) {
    if (e is PostgrestException) {
      debugPrint(
          'PostgrestException: ${e.message} code=${e.code} details=${e.details} hint=${e.hint}');
    } else {
      debugPrint('Error: $e');
    }
  }
}
