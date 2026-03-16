class PetFoodTracking {
  final String id;
  final String petId;
  final String userId;
  final String foodName;
  final DateTime purchaseDate;
  final int estimatedDays;
  final DateTime estimatedFinishDate;
  final bool isFinished;
  final DateTime createdAt;
  final DateTime updatedAt;

  PetFoodTracking({
    required this.id,
    required this.petId,
    required this.userId,
    required this.foodName,
    required this.purchaseDate,
    required this.estimatedDays,
    required this.estimatedFinishDate,
    this.isFinished = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PetFoodTracking.fromJson(Map<String, dynamic> json) {
    return PetFoodTracking(
      id: json['id'] ?? '',
      petId: json['pet_id'] ?? '',
      userId: json['user_id'] ?? '',
      foodName: json['food_name'] ?? '',
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : DateTime.now(),
      estimatedDays: json['estimated_days'] ?? 30,
      estimatedFinishDate: json['estimated_finish_date'] != null
          ? DateTime.parse(json['estimated_finish_date'])
          : DateTime.now().add(const Duration(days: 30)),
      isFinished: json['is_finished'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'food_name': foodName,
      'purchase_date': purchaseDate.toIso8601String().split('T')[0],
      'estimated_days': estimatedDays,
      'estimated_finish_date': estimatedFinishDate.toIso8601String().split('T')[0],
      'is_finished': isFinished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PetFoodTracking copyWith({
    String? id,
    String? petId,
    String? userId,
    String? foodName,
    DateTime? purchaseDate,
    int? estimatedDays,
    DateTime? estimatedFinishDate,
    bool? isFinished,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PetFoodTracking(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      foodName: foodName ?? this.foodName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      estimatedDays: estimatedDays ?? this.estimatedDays,
      estimatedFinishDate: estimatedFinishDate ?? this.estimatedFinishDate,
      isFinished: isFinished ?? this.isFinished,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  int get daysRemaining {
    final now = DateTime.now();
    final difference = estimatedFinishDate.difference(now).inDays;
    return difference > 0 ? difference : 0;
  }

  bool get isLowStock {
    return daysRemaining <= 3 && !isFinished;
  }
}
