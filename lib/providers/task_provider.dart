import 'package:flutter/material.dart';
import '../core/supabase_config.dart';
import '../services/notification_service.dart';
import '../models/task_model.dart';
import '../models/pet_task_assignment.dart';
import '../models/task_display_data.dart';
import '../models/pet_model.dart';

class TaskProvider extends ChangeNotifier {
  final Map<String, List<TaskModel>> _tasksByPetType = {};
  final Map<String, List<TaskCompletion>> _completionsByPet = {};
  final Map<String, List<PetTaskAssignment>> _assignmentsByPet = {};
  final Map<String, TaskModel> _taskCache = {}; // Cache for task details
  final Map<String, DateTime?> _lastCompletionByTask = {};
  final Map<String, Set<String>> _completedVaccinesByPet = {}; // Aşı ismine göre tamamlanan aşılar
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  // Get tasks for a pet type and breed (template tasks)
  List<TaskModel> getTasksForPetType(String petType, {String? breed}) {
    final normalizedType = TaskModel.normalizePetType(petType);
    final cacheKey = breed != null ? '${normalizedType}_$breed' : normalizedType;
    return _tasksByPetType[cacheKey] ?? [];
  }

  // Get assigned tasks for a pet (user's personalized tasks)
  List<PetTaskAssignment> getAssignmentsForPet(String petId) {
    return _assignmentsByPet[petId] ?? [];
  }

  // Get task model by ID (from cache)
  TaskModel? getTaskById(String taskId) {
    return _taskCache[taskId];
  }

  // Get effective task data (assignment overrides + task defaults)
  TaskDisplayData getTaskDisplayData(TaskModel task, PetTaskAssignment? assignment) {
    return TaskDisplayData(
      name: assignment?.customName ?? task.name,
      description: assignment?.customDescription ?? task.description,
      frequencyDays: assignment?.customFrequencyDays ?? task.frequencyDays,
      points: task.points,
      isActive: assignment?.isActive ?? true,
      notes: assignment?.notes,
    );
  }

  // Get completions for a pet
  List<TaskCompletion> getCompletionsForPet(String petId) {
    return _completionsByPet[petId] ?? [];
  }

  // Check if task is completed today
  bool isTaskCompletedToday(String petId, String taskId) {
    final lastCompletion = _lastCompletionByTask['${petId}_$taskId'];
    if (lastCompletion == null) return false;
    final today = DateTime.now();
    return lastCompletion.year == today.year &&
        lastCompletion.month == today.month &&
        lastCompletion.day == today.day;
  }

  // Get next due date for a task
  DateTime? getNextDueDate(String petId, String taskId, int frequencyDays) {
    final lastCompletion = _lastCompletionByTask['${petId}_$taskId'];
    if (lastCompletion == null) return DateTime.now();
    return lastCompletion.add(Duration(days: frequencyDays));
  }

  // Check if task is overdue
  bool isTaskOverdue(String petId, String taskId, int frequencyDays) {
    final nextDue = getNextDueDate(petId, taskId, frequencyDays);
    if (nextDue == null) return false;
    return DateTime.now().isAfter(nextDue);
  }

  Future<void> fetchTasksForPetType(String petType, {String? breed}) async {
    final normalizedType = TaskModel.normalizePetType(petType);
    final cacheKey = breed != null ? '${normalizedType}_$breed' : normalizedType;
    
    if (_tasksByPetType.containsKey(cacheKey)) {
      return; // Already loaded
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Get all tasks for this pet type, then filter by breed on client side
      final allTasksResponse = await SupabaseConfig.client
          .from('tasks')
          .select()
          .eq('pet_type', normalizedType)
          .eq('is_active', true)
          .order('category', ascending: true)
          .order('name', ascending: true);

      // Filter by breed: show tasks that are either breed-specific (matching breed) or general (breed is null)
      final allTasks = (allTasksResponse as List);
      final filteredTasks = <dynamic>[];
      
      if (breed != null && breed.isNotEmpty) {
        // Show tasks that match breed OR are general (breed is null)
        for (final task in allTasks) {
          final taskBreed = task['breed'] as String?;
          if (taskBreed == null || taskBreed == breed) {
            filteredTasks.add(task);
          }
        }
      } else {
        // If no breed specified, only show general tasks (breed is null)
        for (final task in allTasks) {
          if (task['breed'] == null) {
            filteredTasks.add(task);
          }
        }
      }

      final tasks = filteredTasks
          .map((json) => TaskModel.fromJson(json))
          .toList();

      _tasksByPetType[cacheKey] = tasks;
      for (final task in tasks) {
        _taskCache[task.id] = task; // Populate task cache
      }
    } catch (e) {
      debugPrint('Fetch tasks failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchAssignmentsForPet(String petId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('pet_task_assignments')
          .select()
          .eq('pet_id', petId)
          .order('created_at', ascending: true);

      final assignments = (response as List)
          .map((json) => PetTaskAssignment.fromJson(json))
          .toList();

      _assignmentsByPet[petId] = assignments;
    } catch (e) {
      debugPrint('Fetch assignments failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAssignment(String petId, String taskId) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Kullanıcı oturum bilgisi bulunamadı');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseConfig.client.from('pet_task_assignments').insert({
        'pet_id': petId,
        'task_id': taskId,
        'user_id': userId,
      });
      await fetchAssignmentsForPet(petId); // Refresh assignments
    } catch (e) {
      debugPrint('Create assignment failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateAssignment(PetTaskAssignment assignment) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseConfig.client
          .from('pet_task_assignments')
          .update(assignment.toJson())
          .eq('id', assignment.id);
      await fetchAssignmentsForPet(assignment.petId); // Refresh assignments
    } catch (e) {
      debugPrint('Update assignment failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? get getUserId => SupabaseConfig.client.auth.currentUser?.id;

  Future<void> fetchCompletionsForPet(String petId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await SupabaseConfig.client
          .from('pet_task_completions')
          .select()
          .eq('pet_id', petId)
          .order('completed_at', ascending: false);

      final completions = (response as List)
          .map((json) => TaskCompletion.fromJson(json))
          .toList();

      _completionsByPet[petId] = completions;

      // Update last completion map
      for (final completion in completions) {
        final key = '${petId}_${completion.taskId}';
        final current = _lastCompletionByTask[key];
        if (current == null || completion.completedAt.isAfter(current)) {
          _lastCompletionByTask[key] = completion.completedAt;
        }
      }
    } catch (e) {
      debugPrint('Fetch completions failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> completeTask(
    String petId,
    String taskId, {
    String? notes,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Kullanıcı oturum bilgisi bulunamadı');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Check if already completed today
      if (isTaskCompletedToday(petId, taskId)) {
        throw Exception('Bu görev bugün zaten tamamlandı');
      }

      await SupabaseConfig.client.from('pet_task_completions').insert({
        'pet_id': petId,
        'task_id': taskId,
        'user_id': userId,
        'notes': notes,
        'completed_at': DateTime.now().toIso8601String(),
      });

      // Refresh completions
      await fetchCompletionsForPet(petId);

      // Schedule next notification (trigger will create notification record,
      // we schedule the local notification here)
      await _scheduleNextNotification(petId, taskId);

      // Refresh user streak (points will be updated by trigger)
      // We might want to refresh user profile here
    } catch (e) {
      debugPrint('Complete task failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _scheduleNextNotification(String petId, String taskId) async {
    try {
      // Get task details to find frequency
      final taskResponse = await SupabaseConfig.client
          .from('tasks')
          .select('frequency_days, name')
          .eq('id', taskId)
          .maybeSingle();

      if (taskResponse == null) return;

      final frequencyDays = taskResponse['frequency_days'] as int? ?? 1;
      final taskName = taskResponse['name'] as String? ?? 'Görev';

      // Get pet name
      final petResponse = await SupabaseConfig.client
          .from('pets')
          .select('name')
          .eq('id', petId)
          .maybeSingle();

      final petName = petResponse?['name'] as String? ?? 'Dostun';

      // Calculate next due date
      final nextDue = DateTime.now().add(Duration(days: frequencyDays));
      
      // Schedule notification for next due date at 9 AM
      final notificationTime = DateTime(
        nextDue.year,
        nextDue.month,
        nextDue.day,
        9, // 9 AM
      );

      final notificationId = NotificationService.generateNotificationId(petId, taskId);

      await NotificationService.scheduleTaskNotification(
        id: notificationId,
        title: '$petName için Görev Hatırlatıcısı',
        body: '$taskName görevini yapmayı unutma!',
        scheduledDate: notificationTime,
        payload: 'pet:$petId|task:$taskId',
      );
    } catch (e) {
      debugPrint('Schedule notification failed: $e');
      // Don't throw, notification scheduling failure shouldn't break task completion
    }
  }

  // Load and schedule all pending notifications
  Future<void> loadAndScheduleNotifications(String petId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      // Get pending notifications from database
      final notifications = await SupabaseConfig.client
          .from('task_notifications')
          .select('task_id, scheduled_for, tasks(name), pets(name)')
          .eq('pet_id', petId)
          .eq('user_id', userId)
          .eq('is_sent', false)
          .gt('scheduled_for', DateTime.now().toIso8601String())
          .limit(50);

      for (final notif in notifications as List) {
        final taskId = notif['task_id'] as String?;
        final scheduledFor = notif['scheduled_for'] as String?;
        final taskName = (notif['tasks'] as Map<String, dynamic>?)?['name'] as String? ?? 'Görev';
        final petName = (notif['pets'] as Map<String, dynamic>?)?['name'] as String? ?? 'Dostun';

        if (taskId == null || scheduledFor == null) continue;

        final notificationId = NotificationService.generateNotificationId(petId, taskId);
        final scheduledDate = DateTime.parse(scheduledFor);

        await NotificationService.scheduleTaskNotification(
          id: notificationId,
          title: '$petName için Görev Hatırlatıcısı',
          body: '$taskName görevini yapmayı unutma!',
          scheduledDate: scheduledDate,
          payload: 'pet:$petId|task:$taskId',
        );
      }
    } catch (e) {
      debugPrint('Load notifications failed: $e');
    }
  }

  Future<void> deleteCompletion(String completionId, String petId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseConfig.client
          .from('pet_task_completions')
          .delete()
          .eq('id', completionId);

      // Refresh completions
      await fetchCompletionsForPet(petId);
    } catch (e) {
      debugPrint('Delete completion failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get assigned tasks for a pet (combines templates with assignments)
  List<(TaskModel, PetTaskAssignment?)> getAssignedTasksForPet(String petId, String petType, {String? breed}) {
    final templateTasks = getTasksForPetType(petType, breed: breed);
    final assignments = getAssignmentsForPet(petId);
    final assignmentMap = {
      for (final assignment in assignments) assignment.taskId: assignment
    };

    final result = <(TaskModel, PetTaskAssignment?)>[];
    for (final task in templateTasks) {
      final assignment = assignmentMap[task.id];
      // Only show tasks that are assigned and active (or not assigned yet)
      if (assignment == null || assignment.isActive) {
        result.add((task, assignment));
      }
    }

    return result;
  }

  // Get upcoming tasks (due soon or overdue)
  List<TaskModel> getUpcomingTasks(String petId, String petType, {String? breed}) {
    final assignedTasks = getAssignedTasksForPet(petId, petType, breed: breed);
    final upcoming = <TaskModel>[];

    for (final (task, assignment) in assignedTasks) {
      final displayData = getTaskDisplayData(task, assignment);
      if (!displayData.isActive) continue;
      
      final frequencyDays = displayData.frequencyDays;
      if (isTaskOverdue(petId, task.id, frequencyDays) ||
          !isTaskCompletedToday(petId, task.id)) {
        upcoming.add(task);
      }
    }

    return upcoming;
  }

  // Create a custom task for a pet
  Future<void> createCustomTask({
    required PetModel pet,
    required String name,
    String? description,
    required String category,
    required int frequencyDays,
    required int points,
    String? iconName,
    String? notes,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Kullanıcı oturum bilgisi bulunamadı');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Create task in database
      final normalizedType = TaskModel.normalizePetType(pet.type);
      final taskResponse = await SupabaseConfig.client
          .from('tasks')
          .insert({
            'name': name,
            'description': description,
            'pet_type': normalizedType,
            'breed': pet.breed,
            'category': category,
            'frequency_days': frequencyDays,
            'points': points,
            'icon_name': iconName ?? 'task_rounded',
            'is_active': true,
          })
          .select()
          .single();

      final newTask = TaskModel.fromJson(taskResponse);
      
      // Add to cache
      final cacheKey = '${normalizedType}_${pet.breed}';
      _tasksByPetType.putIfAbsent(cacheKey, () => []).add(newTask);
      _taskCache[newTask.id] = newTask;

      // Create assignment for this pet
      await SupabaseConfig.client.from('pet_task_assignments').insert({
        'pet_id': pet.id,
        'task_id': newTask.id,
        'user_id': userId,
        'is_active': true,
        'custom_name': null, // Use task default
        'custom_description': null, // Use task default
        'custom_frequency_days': null, // Use task default
        'notes': notes,
      });

      // Refresh assignments
      await fetchAssignmentsForPet(pet.id);
    } catch (e) {
      debugPrint('Create custom task failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Aşı kayıtları için metodlar
  Future<void> fetchVaccinationRecords(String petId) async {
    try {
      final response = await SupabaseConfig.client
          .from('vaccination_records')
          .select('vaccine_name')
          .eq('pet_id', petId)
          .order('completed_at', ascending: false);

      final records = (response as List).map((json) => json['vaccine_name'] as String).toSet();
      _completedVaccinesByPet[petId] = records;
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch vaccination records failed: $e');
      _completedVaccinesByPet[petId] = {};
    }
  }

  bool isVaccineCompleted(String petId, String vaccineName) {
    return _completedVaccinesByPet[petId]?.contains(vaccineName) ?? false;
  }

  Future<void> markVaccineAsCompleted(
    String petId,
    String vaccineName,
    String vaccineDescription,
    int recommendedAgeDays, {
    String? notes,
    DateTime? completedDate,
  }) async {
    final userId = SupabaseConfig.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('Kullanıcı oturum bilgisi bulunamadı');
    }

    _isLoading = true;
    notifyListeners();

    try {
      await SupabaseConfig.client.from('vaccination_records').insert({
        'pet_id': petId,
        'user_id': userId,
        'vaccine_name': vaccineName,
        'vaccine_description': vaccineDescription,
        'recommended_age_days': recommendedAgeDays,
        'completed_at': (completedDate ?? DateTime.now()).toIso8601String().split('T')[0],
        'notes': notes,
      });

      await fetchVaccinationRecords(petId);
    } catch (e) {
      debugPrint('Mark vaccine as completed failed: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
