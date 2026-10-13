import 'package:flutter/material.dart';
import '../models/comment_model.dart';
import '../models/user_model.dart';
import 'user_avatar_badge.dart';

/// Modal Bottom Sheet hiển thị và quản lý bình luận theo thời gian thực (Realtime)
/// Hỗ trợ cả Sảnh chém gió (Forum) và Trạm review (Reviews).
class CommentsSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Stream<List<CommentModel>> commentsStream;
  final Future<void> Function(String content) onSendComment;
  final Future<void> Function(String commentId) onDeleteComment;
  final String currentUserId;
  final bool isAdmin;
  final UserModel? currentUser;

  const CommentsSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.commentsStream,
    required this.onSendComment,
    required this.onDeleteComment,
    required this.currentUserId,
    required this.isAdmin,
    this.currentUser,
  });

  /// Hàm tiện ích mở Bottom Sheet bình luận
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Stream<List<CommentModel>> commentsStream,
    required Future<void> Function(String content) onSendComment,
    required Future<void> Function(String commentId) onDeleteComment,
    required String currentUserId,
    required bool isAdmin,
    UserModel? currentUser,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(
        title: title,
        subtitle: subtitle,
        commentsStream: commentsStream,
        onSendComment: onSendComment,
        onDeleteComment: onDeleteComment,
        currentUserId: currentUserId,
        isAdmin: isAdmin,
        currentUser: currentUser,
      ),
    );
  }

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return 'Vừa xong';
    final diff = DateTime.now().difference(dateTime);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  Future<void> _handleSend() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSubmitting) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onSendComment(text);
      _commentController.clear();
      // Cuộn xuống cuối để thấy bình luận mới nhất
      await Future.delayed(const Duration(milliseconds: 200));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi gửi bình luận: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete(CommentModel comment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa bình luận'),
          ],
        ),
        content: const Text('Bạn có chắc muốn xóa bình luận này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await widget.onDeleteComment(comment.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa bình luận thành công.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa bình luận: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 680,
          maxHeight: screenHeight * 0.85,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Thanh kéo (Drag Handle)
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Tiêu đề BottomSheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.mode_comment, color: Colors.blueAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty)
                            Text(
                              widget.subtitle!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white12),

              // Danh sách bình luận Realtime
              Expanded(
                child: StreamBuilder<List<CommentModel>>(
                  stream: widget.commentsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Lỗi tải bình luận: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final comments = snapshot.data!;
                    if (comments.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.shade600),
                            const SizedBox(height: 12),
                            const Text(
                              'Chưa có bình luận nào.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Hãy là người đầu tiên để lại ý kiến (+2 pts tích lũy)!',
                              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final c = comments[index];
                        final canDelete = c.authorId == widget.currentUserId || widget.isAdmin;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Tác giả bình luận (Có Khung, Tên đổi màu, Huy hiệu đầy đủ)
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: UserHeaderBadge(
                                      name: c.authorName,
                                      inventory: c.authorEquipped,
                                      subtitle: _formatTimeAgo(c.createdAt),
                                    ),
                                  ),
                                  if (canDelete)
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        size: 18,
                                        color: Colors.redAccent.shade100,
                                      ),
                                      tooltip: widget.isAdmin && c.authorId != widget.currentUserId
                                          ? 'Xóa bình luận (Quyền Admin)'
                                          : 'Xóa bình luận của bạn',
                                      onPressed: () => _confirmDelete(c),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Nội dung bình luận
                              SelectableText(
                                c.content,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.4,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(height: 1, color: Colors.white12),

              // Thanh nhập bình luận
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color(0xFF1E293B),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.blueAccent.shade700,
                      child: Text(
                        widget.currentUser?.name.isNotEmpty == true
                            ? widget.currentUser!.name[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _handleSend(),
                        decoration: InputDecoration(
                          hintText: 'Viết bình luận công khai... (+2 pts)',
                          hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: const Color(0xFF0F172A),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isSubmitting
                        ? const SizedBox(
                            width: 36,
                            height: 36,
                            child: Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                            ),
                          )
                        : IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.send_rounded, size: 18),
                            onPressed: _handleSend,
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
