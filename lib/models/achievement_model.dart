import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String code;
  final String name;
  final String description;
  final String? iconName;
  final int pointsReward;
  final String category;
  final AchievementRarity rarity;
  final bool isActive;
  final int displayOrder;

  Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.iconName,
    this.pointsReward = 0,
    this.category = 'general',
    this.rarity = AchievementRarity.common,
    this.isActive = true,
    this.displayOrder = 0,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconName: json['icon_name'] as String?,
      pointsReward: json['points_reward'] as int? ?? 0,
      category: json['category'] as String? ?? 'general',
      rarity: AchievementRarity.fromString(json['rarity'] as String? ?? 'common'),
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'points_reward': pointsReward,
      'category': category,
      'rarity': rarity.value,
      'is_active': isActive,
      'display_order': displayOrder,
    };
  }
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary;

  String get value {
    switch (this) {
      case AchievementRarity.common:
        return 'common';
      case AchievementRarity.rare:
        return 'rare';
      case AchievementRarity.epic:
        return 'epic';
      case AchievementRarity.legendary:
        return 'legendary';
    }
  }

  static AchievementRarity fromString(String value) {
    switch (value) {
      case 'common':
        return AchievementRarity.common;
      case 'rare':
        return AchievementRarity.rare;
      case 'epic':
        return AchievementRarity.epic;
      case 'legendary':
        return AchievementRarity.legendary;
      default:
        return AchievementRarity.common;
    }
  }

  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final String? petId;
  final Map<String, dynamic>? metadata;

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.petId,
    this.metadata,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      petId: json['pet_id'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
      'pet_id': petId,
      'metadata': metadata,
    };
  }
}
