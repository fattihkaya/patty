class Story {
  final String id;
  final String petId;
  final String userId;
  final String imageUrl;
  final String? caption;
  final DateTime createdAt;
  final DateTime expiresAt;
  final int viewCount;
  final bool isActive;
  
  // Computed fields (from joins)
  final String? petName;
  final String? petPhotoUrl;
  final bool isViewed;

  Story({
    required this.id,
    required this.petId,
    required this.userId,
    required this.imageUrl,
    this.caption,
    required this.createdAt,
    required this.expiresAt,
    this.viewCount = 0,
    this.isActive = true,
    this.petName,
    this.petPhotoUrl,
    this.isViewed = false,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as String,
      petId: json['pet_id'] as String,
      userId: json['user_id'] as String,
      imageUrl: json['image_url'] as String,
      caption: json['caption'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
      viewCount: json['view_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      petName: json['pet_name'] as String?,
      petPhotoUrl: json['pet_photo_url'] as String?,
      isViewed: json['is_viewed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'user_id': userId,
      'image_url': imageUrl,
      'caption': caption,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'view_count': viewCount,
      'is_active': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Story copyWith({
    String? id,
    String? petId,
    String? userId,
    String? imageUrl,
    String? caption,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? viewCount,
    bool? isActive,
    String? petName,
    String? petPhotoUrl,
    bool? isViewed,
  }) {
    return Story(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      caption: caption ?? this.caption,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewCount: viewCount ?? this.viewCount,
      isActive: isActive ?? this.isActive,
      petName: petName ?? this.petName,
      petPhotoUrl: petPhotoUrl ?? this.petPhotoUrl,
      isViewed: isViewed ?? this.isViewed,
    );
  }
}
