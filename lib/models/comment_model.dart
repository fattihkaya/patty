class Comment {
  final String id;
  final String logId;
  final String userId;
  final String commentText;
  final String? parentCommentId;
  final bool isEdited;
  final DateTime? editedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Computed fields (from joins)
  final String? userName;
  final String? userEmail;
  final String? userAvatarUrl;
  final int likeCount;
  final bool isLikedByMe;

  Comment({
    required this.id,
    required this.logId,
    required this.userId,
    required this.commentText,
    this.parentCommentId,
    this.isEdited = false,
    this.editedAt,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.userAvatarUrl,
    this.likeCount = 0,
    this.isLikedByMe = false,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as String,
      logId: json['log_id'] as String,
      userId: json['user_id'] as String,
      commentText: json['comment_text'] as String,
      parentCommentId: json['parent_comment_id'] as String?,
      isEdited: json['is_edited'] as bool? ?? false,
      editedAt: json['edited_at'] != null
          ? DateTime.parse(json['edited_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userName: json['user_name'] as String?,
      userEmail: json['user_email'] as String?,
      userAvatarUrl: json['user_avatar_url'] as String?,
      likeCount: json['like_count'] as int? ?? 0,
      isLikedByMe: json['is_liked_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'log_id': logId,
      'user_id': userId,
      'comment_text': commentText,
      'parent_comment_id': parentCommentId,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Comment copyWith({
    String? id,
    String? logId,
    String? userId,
    String? commentText,
    String? parentCommentId,
    bool? isEdited,
    DateTime? editedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? userAvatarUrl,
    int? likeCount,
    bool? isLikedByMe,
  }) {
    return Comment(
      id: id ?? this.id,
      logId: logId ?? this.logId,
      userId: userId ?? this.userId,
      commentText: commentText ?? this.commentText,
      parentCommentId: parentCommentId ?? this.parentCommentId,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
    );
  }
}
