import 'package:flutter/material.dart';
import '../models/document_model.dart';
import '../models/post_model.dart';
import '../models/review_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  final _db = DatabaseService();
  String _userSearchQuery = '';
  String _postSearchQuery = '';
  String _docSearchQuery = '';
  String _reviewSearchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DefaultTabController(
        length: 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & Quick Stats
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.redAccent, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bảng Quản Trị Hệ Thống (Admin Panel)',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Kiểm duyệt bài viết, tài liệu, đánh giá, quản lý người dùng & kho vật phẩm',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quick Stats Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng thành viên',
                          stream: _db.usersStream().map((list) => list.length.toString()),
                          icon: Icons.people_alt,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tổng bài viết',
                          stream: _db.postsStream().map((list) => list.length.toString()),
                          icon: Icons.forum,
                          color: Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Tài liệu chia sẻ',
                          stream: _db.documentsStream().map((list) => list.length.toString()),
                          icon: Icons.folder,
                          color: Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildStatCard(
                          title: 'Lượt đánh giá',
                          stream: _db.reviewsStream().map((list) => list.length.toString()),
                          icon: Icons.rate_review,
                          color: Colors.tealAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade800, width: 0.8),
                    ),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicatorColor: Colors.redAccent,
                      indicatorWeight: 3,
                      labelColor: Colors.redAccent,
                      unselectedLabelColor: Colors.grey.shade400,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(icon: Icon(Icons.people_alt, size: 18), text: 'Người dùng & Phân quyền'),
                        Tab(icon: Icon(Icons.forum, size: 18), text: 'Quản lý Bài viết'),
                        Tab(icon: Icon(Icons.folder, size: 18), text: 'Quản lý Tài liệu'),
                        Tab(icon: Icon(Icons.rate_review, size: 18), text: 'Quản lý Review'),
                        Tab(icon: Icon(Icons.storefront, size: 18), text: 'Quản lý Cửa hàng'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                children: [
                  _buildUsersTab(),
                  _buildPostsTab(),
                  _buildDocumentsTab(),
                  _buildReviewsTab(),
                  _buildStoreTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== TAB 1: USERS & ROLES ====================
  Widget _buildUsersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Danh sách Người dùng & Phân quyền',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => setState(() => _userSearchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Tìm tên, email, MSV...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<UserModel>>(
                stream: _db.usersStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                  final users = snapshot.data ?? [];
                  final filtered = users.where((u) {
                    if (_userSearchQuery.isEmpty) return true;
                    return u.name.toLowerCase().contains(_userSearchQuery) ||
                        u.email.toLowerCase().contains(_userSearchQuery) ||
                        u.msv.toLowerCase().contains(_userSearchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(30), child: Text('Không tìm thấy người dùng phù hợp')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final user = filtered[index];
                      final isCurrentUser = user.uid == _db.uid;
                      final isAdmin = user.isAdmin;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: CircleAvatar(
                          backgroundColor: isAdmin ? Colors.redAccent.shade700 : Colors.blueGrey.shade800,
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (isCurrentUser)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text('(Bạn)', style: TextStyle(fontSize: 12, color: Colors.blueAccent.shade100)),
                              ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? Colors.redAccent.withValues(alpha: 0.2)
                                    : Colors.grey.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isAdmin ? Colors.redAccent : Colors.grey,
                                  width: 0.6,
                                ),
                              ),
                              child: Text(
                                isAdmin ? 'ADMIN' : 'USER',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isAdmin ? Colors.redAccent : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          '${user.email} • ${user.msv.isNotEmpty ? user.msv : "Chưa có MSV"} • ${user.university.isNotEmpty ? user.university : "Chưa cập nhật trường"} • ${user.points} pts',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                        trailing: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAdmin ? Colors.grey.shade800 : Colors.redAccent.shade700,
                            foregroundColor: Colors.white,
                          ),
                          icon: Icon(isAdmin ? Icons.person : Icons.shield, size: 16),
                          label: Text(isAdmin ? 'Hạ xuống User' : 'Thăng lên Admin'),
                          onPressed: () async {
                            final newRole = isAdmin ? 'user' : 'admin';
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: Text('Xác nhận ${isAdmin ? "hạ quyền" : "thăng quyền"}'),
                                content: Text('Bạn có chắc muốn đổi vai trò của "${user.name}" thành $newRole?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                                  FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await _db.updateUserRole(user.uid, newRole);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Đã cập nhật quyền của ${user.name} thành $newRole')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== TAB 2: POSTS MODERATION ====================
  Widget _buildPostsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Quản lý & Kiểm duyệt Bài viết (Forum)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => setState(() => _postSearchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Tìm nội dung hoặc tác giả...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<PostModel>>(
                stream: _db.postsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                  final posts = snapshot.data ?? [];
                  final filtered = posts.where((p) {
                    if (_postSearchQuery.isEmpty) return true;
                    return p.content.toLowerCase().contains(_postSearchQuery) ||
                        p.authorName.toLowerCase().contains(_postSearchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(30), child: Text('Không có bài viết nào.')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final post = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: Colors.purpleAccent.shade700,
                          child: Text(
                            post.authorName.isNotEmpty ? post.authorName[0].toUpperCase() : 'P',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(width: 8),
                            Text(
                              '${post.likes.length} thích • ${post.commentsCount} bình luận',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            post.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5),
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Xóa bài viết này (Quyền Admin)',
                          onPressed: () => _confirmDeletePost(post),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeletePost(PostModel post) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa bài viết'),
        content: Text('Bạn có chắc chắn muốn xóa bài viết của "${post.authorName}" không?\n\n"${post.content}"'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deletePost(post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài viết thành công (Admin)')),
        );
      }
    }
  }

  // ==================== TAB 3: DOCUMENTS MODERATION ====================
  Widget _buildDocumentsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Quản lý & Kiểm duyệt Kho tài liệu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => setState(() => _docSearchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Tìm tiêu đề hoặc người chia sẻ...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<DocumentModel>>(
                stream: _db.documentsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                  final docs = snapshot.data ?? [];
                  final filtered = docs.where((d) {
                    if (_docSearchQuery.isEmpty) return true;
                    return d.title.toLowerCase().contains(_docSearchQuery) ||
                        d.ownerName.toLowerCase().contains(_docSearchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(30), child: Text('Không có tài liệu nào.')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final doc = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        leading: const CircleAvatar(
                          backgroundColor: Colors.amber,
                          child: Icon(Icons.link, color: Colors.black),
                        ),
                        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                        subtitle: Text(
                          'Người đăng: ${doc.ownerName} • ${doc.downloadCount} lượt tải • Link: ${doc.downloadUrl}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Xóa tài liệu này (Quyền Admin)',
                          onPressed: () => _confirmDeleteDocument(doc),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDocument(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa tài liệu "${doc.title}" của "${doc.ownerName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteDocument(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài liệu thành công (Admin)')),
        );
      }
    }
  }

  // ==================== TAB 4: REVIEWS MODERATION ====================
  Widget _buildReviewsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Quản lý & Kiểm duyệt Trạm Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 260,
                    height: 38,
                    child: TextField(
                      onChanged: (val) => setState(() => _reviewSearchQuery = val.trim().toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Tìm môn, giảng viên, tác giả...',
                        hintStyle: const TextStyle(fontSize: 12),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<ReviewModel>>(
                stream: _db.reviewsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                  final reviews = snapshot.data ?? [];
                  final filtered = reviews.where((r) {
                    if (_reviewSearchQuery.isEmpty) return true;
                    return r.targetName.toLowerCase().contains(_reviewSearchQuery) ||
                        r.authorName.toLowerCase().contains(_reviewSearchQuery) ||
                        r.comment.toLowerCase().contains(_reviewSearchQuery);
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(30), child: Text('Không có đánh giá nào.')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final review = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: Colors.tealAccent.shade700,
                          child: Text(
                            '${review.rating.toInt()}★',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(review.targetName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(review.category, style: const TextStyle(fontSize: 10, color: Colors.tealAccent)),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 2),
                            Text(
                              'Đánh giá bởi: ${review.authorName}',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              review.comment,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Xóa đánh giá này (Quyền Admin)',
                          onPressed: () => _confirmDeleteReview(review),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteReview(ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa đánh giá'),
        content: Text('Bạn có chắc chắn muốn xóa bài đánh giá "${review.targetName}" của "${review.authorName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteReview(review.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa bài đánh giá thành công (Admin)')),
        );
      }
    }
  }

  // ==================== TAB 5: STORE ITEMS MANAGEMENT ====================
  Widget _buildStoreTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Quản lý Vật phẩm Cửa hàng (Store Items)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade700),
                    icon: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('Thêm vật phẩm mới'),
                    onPressed: _showAddStoreItemDialog,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Dữ liệu lưu trữ động trên Cloud Firestore collection "store_items", mở rộng không giới hạn.',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _db.storeItemsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: Padding(padding: EdgeInsets.all(30), child: CircularProgressIndicator()));
                  }
                  if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));

                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return const Center(
                      child: Padding(padding: EdgeInsets.all(30), child: Text('Chưa có vật phẩm nào trong cửa hàng.')),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = item['name'] ?? '';
                      final desc = item['desc'] ?? '';
                      final price = item['price'] ?? 0;
                      final iconName = item['icon'] ?? 'stars';
                      final colorVal = item['color'] ?? 0xFFFFC107;
                      final iconColor = Color(colorVal is int ? colorVal : 0xFFFFC107);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: iconColor.withValues(alpha: 0.4), width: 1),
                          ),
                          child: Icon(_getIconData(iconName), color: iconColor, size: 24),
                        ),
                        title: Row(
                          children: [
                            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$price pts',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          tooltip: 'Xóa vật phẩm này',
                          onPressed: () => _confirmDeleteStoreItem(item),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddStoreItemDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: '50');
    String selectedIcon = 'military_tech';
    int selectedColor = 0xFFFFC107;

    final icons = [
      {'name': 'military_tech', 'label': 'Huy chương (military_tech)'},
      {'name': 'stars', 'label': 'Ngôi sao (stars)'},
      {'name': 'whatshot', 'label': 'Ngọn lửa (whatshot)'},
      {'name': 'palette', 'label': 'Bảng màu (palette)'},
      {'name': 'diamond', 'label': 'Kim cương (diamond)'},
      {'name': 'workspace_premium', 'label': 'Vương miện (workspace_premium)'},
      {'name': 'shield', 'label': 'Chiến khiên (shield)'},
      {'name': 'school', 'label': 'Mũ cử nhân (school)'},
      {'name': 'auto_awesome', 'label': 'Phép thuật (auto_awesome)'},
      {'name': 'bolt', 'label': 'Sấm sét (bolt)'},
    ];

    final colors = [
      {'val': 0xFFFFC107, 'label': 'Vàng Amber', 'color': Colors.amber},
      {'val': 0xFFFFAB40, 'label': 'Cam Hoàng Kim', 'color': Colors.orangeAccent},
      {'val': 0xFFFF5722, 'label': 'Cam Đỏ Rực Lửa', 'color': Colors.deepOrange},
      {'val': 0xFFE040FB, 'label': 'Tím Neon Cyber', 'color': Colors.purpleAccent},
      {'val': 0xFF00E5FF, 'label': 'Xanh Cyan', 'color': Colors.cyanAccent},
      {'val': 0xFF00E676, 'label': 'Xanh Ngọc Lục', 'color': Colors.greenAccent},
      {'val': 0xFFFF1744, 'label': 'Đỏ Ruby', 'color': Colors.redAccent},
    ];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Thêm Vật Phẩm Cửa Hàng Mới'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tên vật phẩm',
                      hintText: 'VD: Khung Avatar Rồng Xanh',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Mô tả hiệu ứng',
                      hintText: 'VD: Hiệu ứng rồng xanh bay quanh tên người dùng',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá đổi (Điểm / Points)',
                      hintText: '50',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedIcon,
                    decoration: const InputDecoration(labelText: 'Biểu tượng (Icon)', border: OutlineInputBorder()),
                    items: icons.map((ic) {
                      return DropdownMenuItem<String>(
                        value: ic['name'] as String,
                        child: Row(
                          children: [
                            Icon(_getIconData(ic['name'] as String), size: 20),
                            const SizedBox(width: 8),
                            Text(ic['label'] as String, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedIcon = val);
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: selectedColor,
                    decoration: const InputDecoration(labelText: 'Tông màu chủ đạo', border: OutlineInputBorder()),
                    items: colors.map((c) {
                      return DropdownMenuItem<int>(
                        value: c['val'] as int,
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: c['color'] as Color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(c['label'] as String, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedColor = val);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thêm vào Cửa Hàng'),
            ),
          ],
        ),
      ),
    );

    final name = nameCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final price = int.tryParse(priceCtrl.text.trim()) ?? 50;

    nameCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();

    if (result == true && name.isNotEmpty) {
      await _db.createStoreItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        desc: desc,
        price: price,
        icon: selectedIcon,
        color: selectedColor,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('🎉 Đã thêm vật phẩm "$name" vào Cửa Hàng thành công!')),
        );
      }
    }
  }

  Future<void> _confirmDeleteStoreItem(Map<String, dynamic> item) async {
    final name = item['name'] ?? 'vật phẩm';
    final itemId = item['id'] as String;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa vật phẩm'),
        content: Text('Bạn có chắc chắn muốn gỡ vật phẩm "$name" khỏi Cửa Hàng không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteStoreItem(itemId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã gỡ vật phẩm "$name" khỏi Cửa Hàng.')),
        );
      }
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'military_tech':
        return Icons.military_tech;
      case 'stars':
        return Icons.stars;
      case 'whatshot':
        return Icons.whatshot;
      case 'palette':
        return Icons.palette;
      case 'diamond':
        return Icons.diamond;
      case 'workspace_premium':
        return Icons.workspace_premium;
      case 'shield':
        return Icons.shield;
      case 'school':
        return Icons.school;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'bolt':
        return Icons.bolt;
      default:
        return Icons.card_giftcard;
    }
  }

  Widget _buildStatCard({
    required String title,
    required Stream<String> stream,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  StreamBuilder<String>(
                    stream: stream,
                    builder: (context, snap) {
                      return Text(
                        snap.data ?? '...',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
