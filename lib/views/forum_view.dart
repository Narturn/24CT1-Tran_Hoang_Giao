import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar_badge.dart';

class ForumView extends StatefulWidget {
  const ForumView({super.key});

  @override
  State<ForumView> createState() => _ForumViewState();
}

class _ForumViewState extends State<ForumView> {
  final _db = DatabaseService();
  final _controller = TextEditingController();
  bool _isPosting = false;

  Future<void> _submitPost() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      await _db.createPost(text);
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Đã đăng bài thành công: +5 points!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng bài: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  Future<void> _confirmDeletePost(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xóa bài viết'),
          ],
        ),
        content: const Text(
          'Bạn có chắc chắn muốn xóa bài viết này không? Hành động này không thể hoàn tác.',
        ),
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
        await _db.deletePost(post.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài viết thành công.')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi xóa bài: $e')),
        );
      }
    }
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _db.userStream(),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        final isAdmin = currentUser?.isAdmin ?? false;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                // Khung tạo bài viết (Facebook style compose box)
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent.shade700,
                              radius: 18,
                              child: Text(
                                currentUser?.name.isNotEmpty == true ? currentUser!.name[0].toUpperCase() : 'U',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                currentUser != null ? 'Chào ${currentUser.name}, chia sẻ điều gì đó nhé!' : 'Bạn đang nghĩ gì?',
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _controller,
                          maxLines: 3,
                          minLines: 2,
                          decoration: InputDecoration(
                            hintText: 'Nhập nội dung chia sẻ với mọi người... (+5 pts khi đăng)',
                            hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton.icon(
                              onPressed: _isPosting ? null : _submitPost,
                              icon: _isPosting
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send, size: 18),
                              label: const Text('Đăng bài'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Danh sách bài viết
                Expanded(
                  child: StreamBuilder<List<PostModel>>(
                    stream: _db.postsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                      final posts = snapshot.data!;

                      if (posts.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.forum_outlined, size: 56, color: Colors.grey.shade600),
                              const SizedBox(height: 12),
                              const Text('Chưa có bài viết nào. Hãy là người đầu tiên mở bát!'),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final isLiked = post.likes.contains(_db.uid);
                          final canDelete = post.authorId == _db.uid || isAdmin;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header bài viết: Avatar, tên, thời gian và nút Xóa
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: UserHeaderBadge(
                                          name: post.authorName,
                                          subtitle: _formatTimeAgo(post.createdAt),
                                          inventory: post.authorEquipped,
                                        ),
                                      ),
                                      if (canDelete)
                                        PopupMenuButton<String>(
                                          icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
                                          tooltip: 'Tùy chọn bài viết',
                                          onSelected: (val) {
                                            if (val == 'delete') {
                                              _confirmDeletePost(post);
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Row(
                                                children: [
                                                  const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    isAdmin && post.authorId != _db.uid
                                                        ? 'Xóa bài viết (Quyền Admin)'
                                                        : 'Xóa bài viết',
                                                    style: const TextStyle(color: Colors.redAccent),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Nội dung bài viết
                                  Text(
                                    post.content,
                                    style: const TextStyle(fontSize: 14, height: 1.45),
                                  ),
                                  const SizedBox(height: 12),

                                  const Divider(height: 1),
                                  const SizedBox(height: 6),

                                  // Thanh tương tác (Like, Comments)
                                  Row(
                                    children: [
                                      TextButton.icon(
                                        onPressed: () => _db.toggleLikePost(post.id, post.likes),
                                        icon: Icon(
                                          isLiked ? Icons.favorite : Icons.favorite_border,
                                          color: isLiked ? Colors.redAccent : Colors.grey,
                                          size: 20,
                                        ),
                                        label: Text(
                                          '${post.likes.length} Thích',
                                          style: TextStyle(
                                            color: isLiked ? Colors.redAccent : Colors.grey.shade300,
                                            fontWeight: isLiked ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      TextButton.icon(
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Tính năng bình luận chi tiết đang được phát triển!')),
                                          );
                                        },
                                        icon: const Icon(Icons.mode_comment_outlined, size: 18, color: Colors.grey),
                                        label: Text(
                                          '${post.commentsCount} Bình luận',
                                          style: TextStyle(color: Colors.grey.shade300),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}