class ExpenseReminder {
  final String id;
  final String petId;
  final String userId;
  final String? expenseId;
  final String reminderType; // 'food_low', 'recurring_expense', 'custom'
  final String title;
  final String? message;
  final DateTime reminderDate;
  final bool isActive;
  final bool isSent;
  final DateTime createdAt;

  ExpenseReminder({
    required this.id,
    required this.petId,
    required this.userId,
    this.expenseId,
    required this.reminderType,
    required this.title,
    this.message,
    required this.reminderDate,
    this.isActive = true,
    this.isSent = false,
    required this.createdAt,
  });

  factory ExpenseReminder.fromJson(Map<String, dynamic> json) {
    return ExpenseReminder(
      id: json['id'] ?? '',
      petId: json['pet_id'] ?? '',
      userId: json['user_id'] ?? '',
      expenseId: json['expense_id'],
      reminderType: json['reminder_type'] ?? 'custom',
      title: json['title'] ?? '',
      message: json['message'],
      reminderDate: json['reminder_date'] != null
          ? DateTime.parse(json['reminder_date'])
          : DateTime.now(),
      isActive: json['is_active'] ?? true,
      isSent: json['is_sent'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'expense_id': expenseId,
      'reminder_type': reminderType,
      'title': title,
      'message': message,
      'reminder_date': reminderDate.toIso8601String().split('T')[0],
      'is_active': isActive,
      'is_sent': isSent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  ExpenseReminder copyWith({
    String? id,
    String? petId,
    String? userId,
    String? expenseId,
    String? reminderType,
    String? title,
    String? message,
    DateTime? reminderDate,
    bool? isActive,
    bool? isSent,
    DateTime? createdAt,
  }) {
    return ExpenseReminder(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      expenseId: expenseId ?? this.expenseId,
      reminderType: reminderType ?? this.reminderType,
      title: title ?? this.title,
      message: message ?? this.message,
      reminderDate: reminderDate ?? this.reminderDate,
      isActive: isActive ?? this.isActive,
      isSent: isSent ?? this.isSent,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
