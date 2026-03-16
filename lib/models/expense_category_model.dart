import 'package:flutter/material.dart';

class ExpenseCategory {
  final String id;
  final String name;
  final String? iconName;
  final String? color;

  ExpenseCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.color,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconName: json['icon_name'],
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_name': iconName,
      'color': color,
    };
  }

  IconData get icon {
    switch (iconName) {
      case 'restaurant':
        return Icons.restaurant_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'toys':
        return Icons.toys_rounded;
      case 'shopping_bag':
        return Icons.shopping_bag_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'security':
        return Icons.security_rounded;
      case 'more_horiz':
        return Icons.more_horiz_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color get categoryColor {
    if (color != null && color!.startsWith('#')) {
      try {
        return Color(int.parse(color!.substring(1), radix: 16) + 0xFF000000);
      } catch (e) {
        return const Color(0xFF6B7280);
      }
    }
    return const Color(0xFF6B7280);
  }
}
