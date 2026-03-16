class Expense {
  final String id;
  final String petId;
  final String userId;
  final String? categoryId;
  final double amount;
  final String? description;
  final DateTime expenseDate;
  final String? receiptUrl;
  final bool isRecurring;
  final int? recurringIntervalDays;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.petId,
    required this.userId,
    this.categoryId,
    required this.amount,
    this.description,
    required this.expenseDate,
    this.receiptUrl,
    this.isRecurring = false,
    this.recurringIntervalDays,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] ?? '',
      petId: json['pet_id'] ?? '',
      userId: json['user_id'] ?? '',
      categoryId: json['category_id'],
      amount: (json['amount'] ?? 0).toDouble(),
      description: json['description'],
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'])
          : DateTime.now(),
      receiptUrl: json['receipt_url'],
      isRecurring: json['is_recurring'] ?? false,
      recurringIntervalDays: json['recurring_interval_days'],
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
      'category_id': categoryId,
      'amount': amount,
      'description': description,
      'expense_date': expenseDate.toIso8601String().split('T')[0],
      'receipt_url': receiptUrl,
      'is_recurring': isRecurring,
      'recurring_interval_days': recurringIntervalDays,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? petId,
    String? userId,
    String? categoryId,
    double? amount,
    String? description,
    DateTime? expenseDate,
    String? receiptUrl,
    bool? isRecurring,
    int? recurringIntervalDays,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      expenseDate: expenseDate ?? this.expenseDate,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringIntervalDays: recurringIntervalDays ?? this.recurringIntervalDays,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
