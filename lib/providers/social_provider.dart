import 'package:flutter/material.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/comment_model.dart';
import 'package:pet_ai/models/story_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialProvider extends ChangeNotifier {
  // Comments cache: logId -> List<Comment>
  final Map<String, List<Comment>> _commentsCache = {};

  // Likes cache: commentId -> bool (isLikedByMe)
  final Map<String, bool> _commentLikesCache = {};

  // Follows cache: userId -> bool (isFollowing)
  final Map<String, bool> _followsCache = {};

  bool _isLoading = false;
  String? _error;

  bool _isMissingTableError(Object e) {
    if (e is PostgrestException) {
      if (e.code == 'PGRST205') return true;
      final msg = (e.message).toLowerCase();
      if (msg.contains('does not exist')) return true;
      if (msg.contains('schema cache')) return true;
    }
    final raw = e.toString().toLowerCase();
    return raw.contains('pgrst205') ||
        raw.contains('does not exist') ||
        raw.contains('schema cache');
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Public Feed
  List<Map<String, dynamic>> _publicLogs = [];
  List<Map<String, dynamic>> get publicLogs => _publicLogs;

  Future<void> fetchPublicLogs() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseConfig.client
          .from('daily_logs')
          .select('''
            *,
            pets:pet_id(
              id, name, photo_url, type, breed, owner_id,
              profiles:owner_id(id, email, first_name, last_name, username)
            )
          ''')
          .eq('visibility', 'public')
          .order('created_at', ascending: false)
          .limit(50);

      _publicLogs = (response as List).cast<Map<String, dynamic>>();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_isMissingTableError(e)) {
        _publicLogs = [];
        _error = null;
      } else {
        _error = 'Genel akış yüklenirken hata oluştu: ${e.toString()}';
      }
      _isLoading = false;
      debugPrint('Fetch public logs error: $e');
      notifyListeners();
    }
  }

  // Get comments for a log
  List<Comment> getCommentsForLog(String logId) {
    return _commentsCache[logId] ?? [];
  }

  // Get comment count for a log
  int getCommentCount(String logId) {
    return _commentsCache[logId]?.length ?? 0;
  }

  // Check if user is following another user
  bool isFollowing(String userId) {
    return _followsCache[userId] ?? false;
  }

  // Fetch comments for a log
  Future<void> fetchComments(String logId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = SupabaseConfig.client.auth.currentUser?.id;

      // Fetch comments with user info
      final response =
          await SupabaseConfig.client.from('log_comments').select('''
            *,
            profiles:user_id(id, email)
          ''').eq('log_id', logId).order('created_at', ascending: true);

      // Filter top-level comments only (parent_comment_id is null)
      final allComments = response as List;
      final topLevelComments = allComments
          .where((item) => item['parent_comment_id'] == null)
          .toList();

      // Fetch likes separately for each comment
      final commentIds =
          topLevelComments.map((item) => item['id'] as String).toList();
      Map<String, int> likeCounts = {};
      Map<String, bool> likedByMe = {};

      if (commentIds.isNotEmpty) {
        // Build filter string for multiple IDs
        final idList = commentIds.map((e) => "'$e'").join(',');
        final likesResponse = await SupabaseConfig.client
            .from('comment_likes')
            .select('comment_id, user_id')
            .filter('comment_id', 'in', '($idList)');

        final likes = likesResponse as List;
        for (var like in likes) {
          final commentId = like['comment_id'] as String;
          likeCounts[commentId] = (likeCounts[commentId] ?? 0) + 1;
          if (userId != null && like['user_id'] == userId) {
            likedByMe[commentId] = true;
          }
        }
      }

      // Process comments
      List<Comment> comments = [];
      for (var item in topLevelComments) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        final commentId = item['id'] as String;

        comments.add(Comment.fromJson({
          ...item,
          'user_email': profile?['email'],
          'user_avatar_url': profile?['avatar_url'],
          'like_count': likeCounts[commentId] ?? 0,
          'is_liked_by_me': likedByMe[commentId] ?? false,
        }));
      }

      _commentsCache[logId] = comments;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_isMissingTableError(e)) {
        _commentsCache[logId] = [];
        _error = null;
      } else {
        _error = 'Yorumlar yüklenirken hata oluştu: ${e.toString()}';
      }
      _isLoading = false;
      debugPrint('Fetch comments error: $e');
      notifyListeners();
    }
  }

  // Add a comment
  Future<Comment> addComment({
    required String logId,
    required String commentText,
    String? parentCommentId,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await SupabaseConfig.client
          .from('log_comments')
          .insert({
            'log_id': logId,
            'user_id': userId,
            'comment_text': commentText,
            'parent_comment_id': parentCommentId,
          })
          .select()
          .single();

      final comment = Comment.fromJson(response);

      // Add to cache
      if (!_commentsCache.containsKey(logId)) {
        _commentsCache[logId] = [];
      }
      _commentsCache[logId]!.add(comment);
      notifyListeners();

      return comment;
    } catch (e) {
      debugPrint('Add comment error: $e');
      rethrow;
    }
  }

  // Update a comment
  Future<void> updateComment(String commentId, String newText) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseConfig.client
          .from('log_comments')
          .update({
            'comment_text': newText,
            'is_edited': true,
            'edited_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId)
          .eq('user_id', userId);

      // Update cache
      for (var comments in _commentsCache.values) {
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          comments[index] = comments[index].copyWith(
            commentText: newText,
            isEdited: true,
            editedAt: DateTime.now(),
          );
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Update comment error: $e');
      rethrow;
    }
  }

  // Delete a comment
  Future<void> deleteComment(String commentId, String logId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseConfig.client
          .from('log_comments')
          .delete()
          .eq('id', commentId)
          .eq('user_id', userId);

      // Remove from cache
      _commentsCache[logId]?.removeWhere((c) => c.id == commentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete comment error: $e');
      rethrow;
    }
  }

  // Like/unlike a comment
  Future<void> toggleCommentLike(String commentId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final isLiked = _commentLikesCache[commentId] ?? false;

      if (isLiked) {
        // Unlike
        await SupabaseConfig.client
            .from('comment_likes')
            .delete()
            .eq('comment_id', commentId)
            .eq('user_id', userId);

        _commentLikesCache[commentId] = false;
      } else {
        // Like
        await SupabaseConfig.client.from('comment_likes').insert({
          'comment_id': commentId,
          'user_id': userId,
        });

        _commentLikesCache[commentId] = true;
      }

      // Update cache
      for (var comments in _commentsCache.values) {
        final index = comments.indexWhere((c) => c.id == commentId);
        if (index != -1) {
          final currentLikeCount = comments[index].likeCount;
          comments[index] = comments[index].copyWith(
            likeCount: isLiked ? currentLikeCount - 1 : currentLikeCount + 1,
            isLikedByMe: !isLiked,
          );
          break;
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Toggle comment like error: $e');
      rethrow;
    }
  }

  // Follow a user
  Future<void> followUser(String userId) async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');
      if (currentUserId == userId) throw Exception('Cannot follow yourself');

      await SupabaseConfig.client.from('user_follows').insert({
        'follower_id': currentUserId,
        'following_id': userId,
      });

      _followsCache[userId] = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Follow user error: $e');
      rethrow;
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await SupabaseConfig.client
          .from('user_follows')
          .delete()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId);

      _followsCache[userId] = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Unfollow user error: $e');
      rethrow;
    }
  }

  // Check if following a user
  Future<void> checkFollowingStatus(String userId) async {
    try {
      final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
      if (currentUserId == null) return;

      final response = await SupabaseConfig.client
          .from('user_follows')
          .select()
          .eq('follower_id', currentUserId)
          .eq('following_id', userId)
          .maybeSingle();

      _followsCache[userId] = response != null;
      notifyListeners();
    } catch (e) {
      debugPrint('Check following status error: $e');
    }
  }

  // Get follower count
  Future<int> getFollowerCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_follows')
          .select()
          .eq('following_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Get follower count error: $e');
      return 0;
    }
  }

  // Get following count
  Future<int> getFollowingCount(String userId) async {
    try {
      final response = await SupabaseConfig.client
          .from('user_follows')
          .select()
          .eq('follower_id', userId);

      return (response as List).length;
    } catch (e) {
      debugPrint('Get following count error: $e');
      return 0;
    }
  }

  // Clear cache
  void clearCache() {
    _commentsCache.clear();
    _commentLikesCache.clear();
    _followsCache.clear();
    notifyListeners();
  }

  // Clear comments for a specific log
  void clearCommentsForLog(String logId) {
    _commentsCache.remove(logId);
    notifyListeners();
  }

  // ========== Story Methods ==========

  List<Story> _stories = [];

  List<Story> get stories => _stories;

  // Fetch active stories for the current user
  Future<void> fetchActiveStories() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      // Note: This would typically use a database function
      // For now, fetch stories from pets the user owns or follows
      final response = await SupabaseConfig.client
          .from('pet_stories')
          .select('''
            *,
            pets:pet_id(id, name, photo_url, owner_id)
          ''')
          .eq('is_active', true)
          .gt('expires_at', DateTime.now().toIso8601String())
          .order('created_at', ascending: false);

      // Filter and process stories
      final allStories = (response as List);
      _stories = allStories.where((item) {
        final pet = item['pets'] as Map<String, dynamic>?;
        final petOwnerId = pet?['owner_id'] as String?;
        // Show own pets' stories or stories from followed users
        return petOwnerId == userId || _followsCache[petOwnerId] == true;
      }).map((item) {
        final pet = item['pets'] as Map<String, dynamic>?;
        return Story.fromJson({
          ...item,
          'pet_name': pet?['name'],
          'pet_photo_url': pet?['photo_url'],
        });
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      if (_isMissingTableError(e)) {
        _stories = [];
        _error = null;
      } else {
        _error = 'Hikayeler yüklenirken hata oluştu: ${e.toString()}';
        debugPrint('Fetch stories error: $e');
      }
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a story
  Future<Story> createStory({
    required String petId,
    required String imageUrl,
    String? caption,
  }) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final expiresAt = DateTime.now().add(const Duration(hours: 24));

      final response = await SupabaseConfig.client
          .from('pet_stories')
          .insert({
            'pet_id': petId,
            'user_id': userId,
            'image_url': imageUrl,
            'caption': caption,
            'expires_at': expiresAt.toIso8601String(),
          })
          .select()
          .single();

      final story = Story.fromJson(response);

      // Add to cache
      _stories.insert(0, story);
      notifyListeners();

      return story;
    } catch (e) {
      debugPrint('Create story error: $e');
      rethrow;
    }
  }

  // Mark story as viewed
  Future<void> viewStory(String storyId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) return;

      await SupabaseConfig.client.rpc('view_story', params: {
        'p_story_id': storyId,
        'p_user_id': userId,
      });

      // Update cache
      final index = _stories.indexWhere((s) => s.id == storyId);
      if (index != -1) {
        _stories[index] = _stories[index].copyWith(
          viewCount: _stories[index].viewCount + 1,
          isViewed: true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('View story error: $e');
    }
  }

  // Delete a story
  Future<void> deleteStory(String storyId) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseConfig.client
          .from('pet_stories')
          .update({'is_active': false})
          .eq('id', storyId)
          .eq('user_id', userId);

      // Remove from cache
      _stories.removeWhere((s) => s.id == storyId);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete story error: $e');
      rethrow;
    }
  }
}
