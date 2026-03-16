import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/expense_reminder_model.dart';
import 'package:pet_ai/services/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderService {
  // Check and send reminders that are due
  static Future<void> checkAndSendReminders() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('checkAndSendReminders skipped: no auth session');
        return;
      }

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Fetch active reminders that are due today or in the past
      final response = await SupabaseConfig.client
          .from('expense_reminders')
          .select()
          .eq('user_id', userId)
          .eq('is_active', true)
          .eq('is_sent', false)
          .lte('reminder_date', today.toIso8601String().split('T')[0]);

      final reminders = (response as List)
          .map((json) => ExpenseReminder.fromJson(json))
          .toList();

      for (final reminder in reminders) {
        await _sendReminderNotification(reminder);
        await _markReminderAsSent(reminder.id);
      }
    } catch (e) {
      debugPrint('Check and send reminders failed: $e');
      if (e is PostgrestException) {
        debugPrint(
            'PostgrestException: ${e.message} code=${e.code} details=${e.details}');
      }
    }
  }

  // Send notification for a reminder
  static Future<void> _sendReminderNotification(ExpenseReminder reminder) async {
    try {
      final notificationId = _generateNotificationId(reminder.id);
      
      await NotificationService.scheduleTaskNotification(
        id: notificationId,
        title: reminder.title,
        body: reminder.message ?? reminder.title,
        scheduledDate: DateTime.now().add(const Duration(seconds: 1)), // Send immediately
        payload: 'expense_reminder:${reminder.id}',
      );
    } catch (e) {
      debugPrint('Send reminder notification failed: $e');
    }
  }

  // Mark reminder as sent
  static Future<void> _markReminderAsSent(String reminderId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseConfig.client
          .from('expense_reminders')
          .update({
            'is_sent': true,
          })
          .eq('id', reminderId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('Mark reminder as sent failed: $e');
    }
  }

  // Schedule a reminder notification
  static Future<void> scheduleReminderNotification(ExpenseReminder reminder) async {
    try {
      final notificationId = _generateNotificationId(reminder.id);
      final reminderDateTime = DateTime(
        reminder.reminderDate.year,
        reminder.reminderDate.month,
        reminder.reminderDate.day,
        9, // 9 AM
      );

      await NotificationService.scheduleTaskNotification(
        id: notificationId,
        title: reminder.title,
        body: reminder.message ?? reminder.title,
        scheduledDate: reminderDateTime,
        payload: 'expense_reminder:${reminder.id}',
      );
    } catch (e) {
      debugPrint('Schedule reminder notification failed: $e');
    }
  }

  // Cancel a reminder notification
  static Future<void> cancelReminderNotification(String reminderId) async {
    try {
      final notificationId = _generateNotificationId(reminderId);
      await NotificationService.cancelNotification(notificationId);
    } catch (e) {
      debugPrint('Cancel reminder notification failed: $e');
    }
  }

  // Generate unique notification ID from reminder ID
  static int _generateNotificationId(String reminderId) {
    // Use first 8 characters of UUID to create a unique int
    final hash = reminderId.substring(0, 8).hashCode;
    return hash.abs() % 2147483647; // Max int32
  }

  // Check food tracking and create reminders if needed
  static Future<void> checkFoodTrackingReminders() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      final now = DateTime.now();
      final threeDaysFromNow = now.add(const Duration(days: 3));

      // Fetch food tracking that will finish soon
      final response = await SupabaseConfig.client
          .from('pet_food_tracking')
          .select()
          .eq('user_id', userId)
          .eq('is_finished', false)
          .lte('estimated_finish_date', threeDaysFromNow.toIso8601String().split('T')[0])
          .gte('estimated_finish_date', now.toIso8601String().split('T')[0]);

      final foodTracking = response as List;

      for (final tracking in foodTracking) {
        // Check if reminder already exists
        final existingReminder = await SupabaseConfig.client
            .from('expense_reminders')
            .select()
            .eq('pet_id', tracking['pet_id'])
            .eq('reminder_type', 'food_low')
            .eq('is_active', true)
            .maybeSingle();

        if (existingReminder == null) {
          // Create reminder
          final reminderDate = DateTime.parse(tracking['estimated_finish_date']).subtract(const Duration(days: 3));
          
          await SupabaseConfig.client.from('expense_reminders').insert({
            'pet_id': tracking['pet_id'],
            'user_id': userId,
            'reminder_type': 'food_low',
            'title': 'Mama Bitmek Üzere',
            'message': '${tracking['food_name']} için mama bitmek üzere. Yeni mama almayı unutmayın!',
            'reminder_date': reminderDate.toIso8601String().split('T')[0],
            'is_active': true,
            'is_sent': false,
          });
        }
      }
    } catch (e) {
      debugPrint('Check food tracking reminders failed: $e');
    }
  }
}
