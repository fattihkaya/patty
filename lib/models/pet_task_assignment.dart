class PetTaskAssignment {
  final String id;
  final String petId;
  final String taskId;
  final String userId;
  final bool isActive;
  final int? customFrequencyDays;
  final String? customName;
  final String? customDescription;
  final String? notes;

  PetTaskAssignment({
    required this.id,
    required this.petId,
    required this.taskId,
    required this.userId,
    this.isActive = true,
    this.customFrequencyDays,
    this.customName,
    this.customDescription,
    this.notes,
  });

  factory PetTaskAssignment.fromJson(Map<String, dynamic> json) {
    return PetTaskAssignment(
      id: json['id'] ?? '',
      petId: json['pet_id'] ?? '',
      taskId: json['task_id'] ?? '',
      userId: json['user_id'] ?? '',
      isActive: json['is_active'] ?? true,
      customFrequencyDays: json['custom_frequency_days'] as int?,
      customName: json['custom_name'] as String?,
      customDescription: json['custom_description'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'task_id': taskId,
      'user_id': userId,
      'is_active': isActive,
      'custom_frequency_days': customFrequencyDays,
      'custom_name': customName,
      'custom_description': customDescription,
      'notes': notes,
    };
  }

  PetTaskAssignment copyWith({
    String? id,
    String? petId,
    String? taskId,
    String? userId,
    bool? isActive,
    int? customFrequencyDays,
    String? customName,
    String? customDescription,
    String? notes,
  }) {
    return PetTaskAssignment(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      taskId: taskId ?? this.taskId,
      userId: userId ?? this.userId,
      isActive: isActive ?? this.isActive,
      customFrequencyDays: customFrequencyDays ?? this.customFrequencyDays,
      customName: customName ?? this.customName,
      customDescription: customDescription ?? this.customDescription,
      notes: notes ?? this.notes,
    );
  }
}
