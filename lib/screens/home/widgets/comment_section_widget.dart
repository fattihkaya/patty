import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/supabase_config.dart';
import 'package:pet_ai/models/comment_model.dart';
import 'package:pet_ai/providers/social_provider.dart';
import 'package:intl/intl.dart';

class CommentSectionWidget extends StatefulWidget {
  final String logId;

  const CommentSectionWidget({
    super.key,
    required this.logId,
  });

  @override
  State<CommentSectionWidget> createState() => _CommentSectionWidgetState();
}

class _CommentSectionWidgetState extends State<CommentSectionWidget> {
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().fetchComments(widget.logId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await context.read<SocialProvider>().addComment(
            logId: widget.logId,
            commentText: _commentController.text.trim(),
          );
      _commentController.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorumunuz eklendi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Yorum eklenirken hata oluştu: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.watch<SocialProvider>();
    final comments = socialProvider.getCommentsForLog(widget.logId);
    final isLoading = socialProvider.isLoading;

    return Container(
      margin: const EdgeInsets.only(top: AppConstants.spacingMD),
      padding: const EdgeInsets.all(AppConstants.spacingMD),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.comment_rounded,
                color: AppConstants.primaryColor,
                size: 20,
              ),
              const SizedBox(width: AppConstants.spacingSM),
              Text(
                'Yorumlar (${comments.length})',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // Comment Input
          Container(
            decoration: BoxDecoration(
              color: AppConstants.backgroundColor,
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border: Border.all(
                color: AppConstants.mutedColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Yorumunuzu yazın...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        color: AppConstants.lightTextColor,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(AppConstants.spacingMD),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _submitComment(),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : _submitComment,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: AppConstants.primaryColor,
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppConstants.spacingMD),

          // Comments List
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(AppConstants.spacingLG),
                child: CircularProgressIndicator(),
              ),
            )
          else if (comments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.spacingLG),
                child: Text(
                  'Henüz yorum yok. İlk yorumu siz yapın!',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppConstants.lightTextColor,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...comments.map((comment) => _CommentItem(comment: comment)),
        ],
      ),
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;

  const _CommentItem({required this.comment});

  @override
  Widget build(BuildContext context) {
    final socialProvider = context.read<SocialProvider>();
    final currentUserId = SupabaseConfig.client.auth.currentUser?.id;
    final isMyComment = currentUserId != null && comment.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: AppConstants.spacingMD),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppConstants.primaryLight,
            backgroundImage: comment.userAvatarUrl != null
                ? NetworkImage(comment.userAvatarUrl!)
                : null,
            child: comment.userAvatarUrl == null
                ? Text(
                    (comment.userEmail?.substring(0, 1).toUpperCase() ?? 'U'),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppConstants.primaryColor,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),

          const SizedBox(width: AppConstants.spacingSM),

          // Comment Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Comment Header
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.userEmail ?? 'Kullanıcı',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                    ),
                    if (comment.isEdited)
                      Text(
                        ' (düzenlendi)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: AppConstants.lightTextColor,
                        ),
                      ),
                    Text(
                      ' • ${_formatDate(comment.createdAt)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Comment Text
                Text(
                  comment.commentText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: AppConstants.darkTextColor,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 8),

                // Like Button
                Row(
                  children: [
                    InkWell(
                      onTap: () async {
                        try {
                          await socialProvider.toggleCommentLike(comment.id);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Hata: $e'),
                                backgroundColor: AppConstants.errorColor,
                              ),
                            );
                          }
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              comment.isLikedByMe
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              size: 16,
                              color: comment.isLikedByMe
                                  ? AppConstants.errorColor
                                  : AppConstants.lightTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${comment.likeCount}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Delete Button (if own comment)
                    if (isMyComment) ...[
                      const SizedBox(width: AppConstants.spacingSM),
                      InkWell(
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Yorumu Sil'),
                              content: const Text(
                                  'Bu yorumu silmek istediğinizden emin misiniz?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Sil',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true && context.mounted) {
                            try {
                              await socialProvider.deleteComment(
                                comment.id,
                                comment.logId,
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Yorum silindi'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: AppConstants.errorColor,
                                  ),
                                );
                              }
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: AppConstants.errorColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'şimdi';
        }
        return '${difference.inMinutes} dk önce';
      }
      return '${difference.inHours} saat önce';
    } else if (difference.inDays == 1) {
      return 'dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return DateFormat('dd MMM yyyy', 'tr_TR').format(date);
    }
  }
}
