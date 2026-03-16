class ConditionModel {
  final String label;
  final String category;
  final int? score;
  final String? note;
  final String? severity;
  final DateTime? createdAt;

  const ConditionModel({
    required this.label,
    required this.category,
    this.score,
    this.note,
    this.severity,
    this.createdAt,
  });

  factory ConditionModel.fromJson(Map<String, dynamic> json) {
    return ConditionModel(
      label: json['label'] as String? ?? '-',
      category: json['category'] as String? ?? 'general',
      score: (json['score'] as num?)?.round(),
      note: json['note'] as String?,
      severity: json['severity'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'category': category,
      'score': score,
      'note': note,
      'severity': severity,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  static List<ConditionModel> listFromJson(dynamic value) {
    if (value is List) {
      return value
          .whereType<Map<String, dynamic>>()
          .map(ConditionModel.fromJson)
          .toList();
    }
    return const [];
  }
}
