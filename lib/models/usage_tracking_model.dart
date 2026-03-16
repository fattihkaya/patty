class UsageTracking {
  final String id;
  final String userId;
  final String featureType;
  final DateTime usageDate;
  final int usageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  UsageTracking({
    required this.id,
    required this.userId,
    required this.featureType,
    required this.usageDate,
    required this.usageCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UsageTracking.fromJson(Map<String, dynamic> json) {
    return UsageTracking(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      featureType: json['feature_type'] as String,
      usageDate: DateTime.parse(json['usage_date'] as String),
      usageCount: json['usage_count'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'feature_type': featureType,
      'usage_date': usageDate.toIso8601String().split('T')[0], // Date only
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Feature types enum
enum FeatureType {
  aiAnalysis('ai_analysis'),
  logCreation('log_creation'),
  pdfExport('pdf_export'),
  petCreation('pet_creation'),
  advancedAnalytics('advanced_analytics');

  final String value;
  const FeatureType(this.value);
}
