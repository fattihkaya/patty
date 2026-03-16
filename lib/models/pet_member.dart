class PetMember {
  final String petId;
  final String userId;
  final String? role;
  final String? addedBy;
  final DateTime createdAt;
  final String? email;

  const PetMember({
    required this.petId,
    required this.userId,
    this.role,
    this.addedBy,
    required this.createdAt,
    this.email,
  });

  factory PetMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return PetMember(
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String?,
      addedBy: json['added_by'] as String?,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      email: profile?['email'] as String?,
    );
  }
}
