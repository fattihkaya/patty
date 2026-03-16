import 'package:flutter/material.dart';

class TaskModel {
  final String id;
  final String name;
  final String? description;
  final String petType; // 'dog', 'cat', 'bird', 'rabbit', 'hamster', 'other'
  final String? breed; // Specific breed (null means applies to all breeds of this type)
  final String category; // 'health', 'care', 'hygiene', 'social', 'training'
  final int frequencyDays; // How often (e.g., 7 for weekly)
  final int points; // Pati points earned
  final String? iconName;
  final bool isActive;

  TaskModel({
    required this.id,
    required this.name,
    this.description,
    required this.petType,
    this.breed,
    required this.category,
    required this.frequencyDays,
    required this.points,
    this.iconName,
    this.isActive = true,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      petType: json['pet_type'] ?? 'other',
      breed: json['breed'],
      category: json['category'] ?? 'care',
      frequencyDays: json['frequency_days'] ?? 1,
      points: json['points'] ?? 10,
      iconName: json['icon_name'],
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'pet_type': petType,
      'breed': breed,
      'category': category,
      'frequency_days': frequencyDays,
      'points': points,
      'icon_name': iconName,
      'is_active': isActive,
    };
  }

  // Convert Turkish pet type to database type
  static String normalizePetType(String turkishType) {
    switch (turkishType.toLowerCase()) {
      case 'köpek':
        return 'dog';
      case 'kedi':
        return 'cat';
      case 'kuş':
        return 'bird';
      case 'hamster':
        return 'hamster';
      case 'tavşan':
      case 'rabbit':
        return 'rabbit';
      default:
        return 'other';
    }
  }

  IconData get icon {
    switch (iconName) {
      case 'vaccines':
        return Icons.vaccines_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'content_cut':
        return Icons.content_cut_rounded;
      case 'bathtub':
        return Icons.bathtub_rounded;
      case 'brush':
        return Icons.brush_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'water_drop':
        return Icons.water_drop_rounded;
      case 'favorite':
        return Icons.favorite_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'monitor_weight':
        return Icons.monitor_weight_rounded;
      case 'camera_alt':
        return Icons.camera_alt_rounded;
      case 'note':
        return Icons.note_rounded;
      default:
        return Icons.task_rounded;
    }
  }

  Color get categoryColor {
    switch (category) {
      case 'health':
        return const Color(0xFFDC2626); // Red
      case 'care':
        return const Color(0xFF2563EB); // Blue
      case 'hygiene':
        return const Color(0xFF059669); // Green
      case 'social':
        return const Color(0xFF8B5CF6); // Purple
      case 'training':
        return const Color(0xFFD97706); // Orange
      default:
        return const Color(0xFF6B7280); // Gray
    }
  }
}

class TaskCompletion {
  final String id;
  final String petId;
  final String taskId;
  final DateTime completedAt;
  final String? notes;
  final String userId;

  TaskCompletion({
    required this.id,
    required this.petId,
    required this.taskId,
    required this.completedAt,
    this.notes,
    required this.userId,
  });

  factory TaskCompletion.fromJson(Map<String, dynamic> json) {
    return TaskCompletion(
      id: json['id'] ?? '',
      petId: json['pet_id'] ?? '',
      taskId: json['task_id'] ?? '',
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : DateTime.now(),
      notes: json['notes'],
      userId: json['user_id'] ?? '',
    );
  }
}
