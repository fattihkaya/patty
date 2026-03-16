class PetModel {
  final String id;
  final String ownerId;
  final String name;
  final String type;
  final String breed;
  final DateTime birthDate;
  final String photoUrl;
  final double? weight;
  final String? gender;
  final int energyLevel;
  final String? profileNote;

  PetModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    required this.breed,
    required this.birthDate,
    required this.photoUrl,
    this.weight,
    this.gender,
    this.energyLevel = 3,
    this.profileNote,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? '',
      ownerId: json['owner_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      breed: json['breed'] ?? '',
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : DateTime.now(),
      photoUrl: json['photo_url'] ?? '',
      weight: json['weight']?.toDouble(),
      gender: json['gender'],
      energyLevel: json['energy_level'] ?? 3,
      profileNote: json['profile_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'breed': breed,
      'birth_date': birthDate.toIso8601String(),
      'photo_url': photoUrl,
      'weight': weight,
      'gender': gender,
      'energy_level': energyLevel,
      'profile_note': profileNote,
    };
  }

  PetModel copyWith({
    String? profileNote,
  }) {
    return PetModel(
      id: id,
      ownerId: ownerId,
      name: name,
      type: type,
      breed: breed,
      birthDate: birthDate,
      photoUrl: photoUrl,
      weight: weight,
      gender: gender,
      energyLevel: energyLevel,
      profileNote: profileNote ?? this.profileNote,
    );
  }
}

/// PetModel extension for age calculation and helper methods
extension PetModelExtension on PetModel {
  /// Calculate pet age in days
  int get ageInDays {
    final now = DateTime.now();
    return now.difference(birthDate).inDays;
  }

  /// Calculate pet age in months
  int get ageInMonths {
    final now = DateTime.now();
    final years = now.year - birthDate.year;
    final months = now.month - birthDate.month;
    return years * 12 + months;
  }

  /// Calculate pet age in years (as double for precision)
  double get ageInYears {
    final now = DateTime.now();
    final days = now.difference(birthDate).inDays;
    return days / 365.25;
  }

  /// Get age description (e.g., "2 ay", "1 yaş", "3 yaş")
  String get ageDescription {
    final months = ageInMonths;
    if (months < 1) {
      return '$ageInDays gün';
    } else if (months < 12) {
      return '$months ay';
    } else {
      final years = (months / 12).floor();
      final remainingMonths = months % 12;
      if (remainingMonths == 0) {
        return '$years yaş';
      } else {
        return '$years yaş $remainingMonths ay';
      }
    }
  }

  /// Check if pet is a puppy/kitten (less than 1 year old)
  bool get isYoung {
    return ageInMonths < 12;
  }

  /// Check if pet is adult (1-7 years old for dogs/cats, adjusted for other types)
  bool get isAdult {
    final months = ageInMonths;
    final normalizedType = type.toLowerCase();
    if (normalizedType.contains('köpek') || normalizedType.contains('dog')) {
      return months >= 12 && months < 84; // 1-7 years
    } else if (normalizedType.contains('kedi') || normalizedType.contains('cat')) {
      return months >= 12 && months < 96; // 1-8 years
    }
    return months >= 12 && months < 84; // Default
  }

  /// Check if pet is senior (7+ years for dogs, 8+ for cats)
  bool get isSenior {
    final months = ageInMonths;
    final normalizedType = type.toLowerCase();
    if (normalizedType.contains('köpek') || normalizedType.contains('dog')) {
      return months >= 84; // 7+ years
    } else if (normalizedType.contains('kedi') || normalizedType.contains('cat')) {
      return months >= 96; // 8+ years
    }
    return months >= 84; // Default
  }
}