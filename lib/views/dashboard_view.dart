import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/facebook_chat_box.dart';
import 'admin_panel_view.dart';
import 'documents_view.dart';
import 'forum_view.dart';
import 'profile_view.dart';
import 'reviews_view.dart';
import 'store_view.dart';

/// Model lưu trữ số liệu thống kê đếm gộp từ Firestore Server
class DashboardStats {
  final int adminCount;
  final int userCount;
  final int postsCount;
  final int documentsCount;
  final int reviewsCount;

  const DashboardStats({
    this.adminCount = 0,
    this.userCount = 0,
    this.postsCount = 0,
    this.documentsCount = 0,
    this.reviewsCount = 0,
  });

  int get totalUsers => adminCount + userCount;
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _selectedIndex = 0;
  final _db = DatabaseService();
  UserModel? _activeChatFriend;
  String _friendSearchQuery = '';

  DashboardStats? _stats;
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  /// Hàm đếm gộp số liệu máy chủ bằng Promise.all (Future.wait trong Flutter/Dart)
  /// Sử dụng count().get(source: AggregateSource.server) tương đương getCountFromServer
  Future<DashboardStats> getCountFromServer() async {
    final firestore = FirebaseFirestore.instance;

    // Chạy song song tất cả các tác vụ đếm gộp (Promise.all)
    final results = await Future.wait([
      // 1. Đếm số admin: từ collection users lọc theo role == 'admin'
      firestore.collection('users').where('role', isEqualTo: 'admin').count().get(source: AggregateSource.server),
      // 2. Đếm số user thường: từ collection users lọc theo role == 'user'
      firestore.collection('users').where('role', isEqualTo: 'user').count().get(source: AggregateSource.server),
      // 3. Đếm số bài viết
      firestore.collection('posts').count().get(source: AggregateSource.server),
      // 4. Đếm lượt chia sẻ (tài liệu)
      firestore.collection('documents').count().get(source: AggregateSource.server),
      // 5. Đếm số đánh giá
      firestore.collection('reviews').count().get(source: AggregateSource.server),
    ]);

    return DashboardStats(
      adminCount: results[0].count ?? 0,
      userCount: results[1].count ?? 0,
      postsCount: results[2].count ?? 0,
      documentsCount: results[3].count ?? 0,
      reviewsCount: results[4].count ?? 0,
    );
  }

  /// Gọi hàm đếm và cập nhật trạng thái UI
  Future<void> _loadDashboardStats() async {
    if (!mounted) return;
    setState(() => _isLoadingStats = true);
    try {
      final stats = await getCountFromServer();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi đếm thống kê server (getCountFromServer): $e');
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _db.userStream(),
      builder: (context, userSnapshot) {
        final currentUser = userSnapshot.data;
        final isAdmin = currentUser?.isAdmin ?? false;

        // Danh sách các view
        final tabs = [
          const ForumView(),
          const DocumentsView(),
          const ReviewsView(),
          const StoreView(),
          const ProfileView(),
          if (isAdmin) const AdminPanelView(),
        ];

        // Nếu index vượt quá số tab khả dụng (ví dụ khi hạ quyền admin)
        if (_selectedIndex >= tabs.length) {
          _selectedIndex = 0;
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 1080;
            final isTablet = constraints.maxWidth >= 768 && !isDesktop;

            return Scaffold(
              appBar: AppBar(
                titleSpacing: 16,
                elevation: 1,
                backgroundColor: const Color(0xFF0F172A),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.shade700,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school, size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Mạng Xã Hội Sinh Viên',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                actions: [
                  if (currentUser != null) ...[
                    Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber.shade700, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.stars, size: 16, color: Colors.amber),
                            const SizedBox(width: 4),
                            Text(
                              '${currentUser.points} pts',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isAdmin)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.redAccent, width: 0.8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield, size: 12, color: Colors.redAccent),
                            SizedBox(width: 4),
                            Text('ADMIN', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                  ],
                  // Nút xem thống kê hệ thống máy chủ (getCountFromServer)
                  IconButton(
                    icon: _isLoadingStats
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                          )
                        : const Icon(Icons.analytics_outlined, color: Colors.blueAccent),
                    tooltip: 'Thống kê hệ thống',
                    onPressed: () => _showStatsDialog(context),
                  ),
                  if (!isDesktop)
                    IconButton(
                      icon: const Icon(Icons.people_alt_outlined),
                      tooltip: 'Danh sách bạn bè',
                      onPressed: () {
                        Scaffold.of(context).openEndDrawer();
                      },
                    ),
                  IconButton(
                    tooltip: 'Đăng xuất',
                    onPressed: () => AuthService().signOut(),
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
              endDrawer: !isDesktop
                  ? Drawer(
                      child: SafeArea(
                        child: _buildRightFriendsSidebar(currentUser),
                      ),
                    )
                  : null,
              body: Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CỘT TRÁI: Thanh điều hướng phong cách Facebook (Menu)
                      _buildLeftSidebar(currentUser, isAdmin, isTablet),

                      // CỘT GIỮA: Nội dung chính
                      Expanded(
                        child: Container(
                          color: const Color(0xFF0F172A),
                          child: IndexedStack(
                            index: _selectedIndex,
                            children: tabs,
                          ),
                        ),
                      ),

                      // CỘT PHẢI: Danh sách bạn bè / Tin nhắn (Facebook Contacts)
                      if (isDesktop)
                        SizedBox(
                          width: 290,
                          child: _buildRightFriendsSidebar(currentUser),
                        ),
                    ],
                  ),

                  // Khung chat nổi Messenger ở góc dưới bên phải
                  if (_activeChatFriend != null)
                    Positioned(
                      bottom: 0,
                      right: isDesktop ? 300 : 16,
                      child: FacebookChatBox(
                        friend: _activeChatFriend!,
                        onClose: () => setState(() => _activeChatFriend = null),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Cột trái: Điều hướng và thông tin tài khoản
  Widget _buildLeftSidebar(UserModel? currentUser, bool isAdmin, bool isTablet) {
    final sidebarWidth = isTablet ? 72.0 : 260.0;

    return Container(
      width: sidebarWidth,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(right: BorderSide(color: Colors.grey.shade800, width: 0.8)),
      ),
      child: Column(
        children: [
          // Thẻ người dùng
          if (currentUser != null && !isTablet)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade800, width: 0.5),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: isAdmin ? Colors.redAccent.shade700 : Colors.blueAccent.shade700,
                    child: Text(
                      currentUser.name.isNotEmpty ? currentUser.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentUser.msv.isNotEmpty ? currentUser.msv : 'Sinh viên',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          if (isTablet) const SizedBox(height: 16),

          // Menu các mục điều hướng
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.forum_outlined,
                  activeIcon: Icons.forum,
                  label: 'Sảnh chém gió',
                  isTablet: isTablet,
                  badgeText: _stats != null ? '${_stats!.postsCount}' : null,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.folder_shared_outlined,
                  activeIcon: Icons.folder_shared,
                  label: 'Kho tài liệu',
                  isTablet: isTablet,
                  badgeText: _stats != null ? '${_stats!.documentsCount}' : null,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.rate_review_outlined,
                  activeIcon: Icons.rate_review,
                  label: 'Trạm review',
                  isTablet: isTablet,
                  badgeText: _stats != null ? '${_stats!.reviewsCount}' : null,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.storefront_outlined,
                  activeIcon: Icons.storefront,
                  label: 'Cửa hàng đổi quà',
                  isTablet: isTablet,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Trang cá nhân',
                  isTablet: isTablet,
                ),
                if (isAdmin) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: Divider(height: 1),
                  ),
                  _buildNavItem(
                    index: 5,
                    icon: Icons.admin_panel_settings_outlined,
                    activeIcon: Icons.admin_panel_settings,
                    label: 'Quản trị Admin',
                    isTablet: isTablet,
                    isSpecial: true,
                    badgeText: _stats != null ? '${_stats!.adminCount}' : null,
                  ),
                ],
                if (!isTablet) ...[
                  const SizedBox(height: 8),
                  _buildSidebarStatsCard(),
                ],
              ],
            ),
          ),

          // Nút đăng xuất ở dưới cùng
          Padding(
            padding: const EdgeInsets.all(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => AuthService().signOut(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.red.withValues(alpha: 0.1),
                ),
                child: Row(
                  mainAxisAlignment: isTablet ? MainAxisAlignment.center : MainAxisAlignment.start,
                  children: [
                    const Icon(Icons.logout, color: Colors.redAccent, size: 20),
                    if (!isTablet) ...[
                      const SizedBox(width: 12),
                      const Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isTablet,
    bool isSpecial = false,
    String? badgeText,
  }) {
    final isSelected = _selectedIndex == index;
    final color = isSpecial
        ? Colors.redAccent
        : (isSelected ? Colors.blueAccent : Colors.grey.shade300);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        tileColor: isSelected
            ? (isSpecial ? Colors.redAccent.withValues(alpha: 0.15) : Colors.blueAccent.withValues(alpha: 0.15))
            : Colors.transparent,
        leading: Icon(
          isSelected ? activeIcon : icon,
          color: color,
          size: 22,
        ),
        title: isTablet
            ? null
            : Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13.5,
                ),
              ),
        trailing: (badgeText != null && !isTablet)
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSpecial
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : (isSelected ? Colors.blueAccent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSpecial
                        ? Colors.redAccent.withValues(alpha: 0.4)
                        : (isSelected ? Colors.blueAccent.withValues(alpha: 0.5) : Colors.grey.shade700),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isSpecial ? Colors.redAccent : (isSelected ? Colors.blueAccent : Colors.grey.shade400),
                  ),
                ),
              )
            : null,
        onTap: () => setState(() => _selectedIndex = index),
      ),
    );
  }

  /// Khung hiển thị số liệu thống kê nhanh trên thanh điều hướng cột trái
  Widget _buildSidebarStatsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics_outlined, size: 16, color: Colors.blueAccent),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Thống kê hệ thống',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              InkWell(
                onTap: _isLoadingStats ? null : _loadDashboardStats,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: _isLoadingStats
                      ? const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: Colors.blueAccent),
                        )
                      : const Tooltip(
                          message: 'Làm mới số liệu (Server count)',
                          child: Icon(Icons.refresh, size: 14, color: Colors.grey),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildStatRow(Icons.shield, 'Quản trị viên (Admin):', _stats?.adminCount, Colors.redAccent),
          const SizedBox(height: 6),
          _buildStatRow(Icons.person, 'Sinh viên (Users):', _stats?.userCount, Colors.blueAccent),
          const SizedBox(height: 6),
          _buildStatRow(Icons.forum, 'Bài viết:', _stats?.postsCount, Colors.purpleAccent),
          const SizedBox(height: 6),
          _buildStatRow(Icons.folder_shared, 'Tài liệu chia sẻ:', _stats?.documentsCount, Colors.amber),
          const SizedBox(height: 6),
          _buildStatRow(Icons.star, 'Lượt đánh giá:', _stats?.reviewsCount, Colors.greenAccent),
        ],
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, int? count, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            count != null ? '$count' : '...',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  /// Hộp thoại hiển thị chi tiết số liệu thống kê đếm gộp Firestore (getCountFromServer)
  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.bar_chart_rounded, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thống Kê Hệ Thống',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Đếm gộp máy chủ Firestore (getCountFromServer)',
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: _isLoadingStats
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
                      )
                    : const Icon(Icons.refresh, size: 20),
                tooltip: 'Cập nhật lại số liệu',
                onPressed: _isLoadingStats
                    ? null
                    : () async {
                        setDialogState(() {});
                        await _loadDashboardStats();
                        setDialogState(() {});
                      },
              ),
            ],
          ),
          content: SizedBox(
            width: 440,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogStatCard(
                  icon: Icons.shield,
                  title: 'Quản trị viên (Admin)',
                  subtitle: "collection('users').where('role', == 'admin')",
                  value: _stats?.adminCount,
                  color: Colors.redAccent,
                ),
                const SizedBox(height: 8),
                _buildDialogStatCard(
                  icon: Icons.people_alt,
                  title: 'Người dùng thường (Sinh viên)',
                  subtitle: "collection('users').where('role', == 'user')",
                  value: _stats?.userCount,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 8),
                _buildDialogStatCard(
                  icon: Icons.forum_rounded,
                  title: 'Tổng số bài viết',
                  subtitle: "collection('posts').count()",
                  value: _stats?.postsCount,
                  color: Colors.purpleAccent,
                ),
                const SizedBox(height: 8),
                _buildDialogStatCard(
                  icon: Icons.folder_shared_rounded,
                  title: 'Tài liệu chia sẻ',
                  subtitle: "collection('documents').count()",
                  value: _stats?.documentsCount,
                  color: Colors.amber,
                ),
                const SizedBox(height: 8),
                _buildDialogStatCard(
                  icon: Icons.rate_review_rounded,
                  title: 'Lượt đánh giá',
                  subtitle: "collection('reviews').count()",
                  value: _stats?.reviewsCount,
                  color: Colors.greenAccent,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogStatCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int? value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value != null ? '$value' : '...',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CỘT PHẢI: Danh bạ bạn bè phong cách Facebook ───

  Widget _buildRightFriendsSidebar(UserModel? currentUser) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        border: Border(left: BorderSide(color: Colors.grey.shade800, width: 0.8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tiêu đề
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.people, size: 20, color: Colors.blueAccent),
                const SizedBox(width: 8),
                const Text(
                  'Tin nhắn bạn bè',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(radius: 3, backgroundColor: Colors.greenAccent),
                      SizedBox(width: 4),
                      Text('Online', style: TextStyle(fontSize: 10, color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Ô tìm kiếm
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: TextField(
              onChanged: (val) => setState(() => _friendSearchQuery = val.trim().toLowerCase()),
              style: const TextStyle(fontSize: 12.5),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sinh viên...',
                hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                filled: true,
                fillColor: const Color(0xFF0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Divider(height: 12),

          // Chế độ Contacts (search trống) hoặc Search results
          Expanded(
            child: _friendSearchQuery.isEmpty
                ? _buildContactsList(currentUser)
                : _buildSearchResultsList(currentUser),
          ),
        ],
      ),
    );
  }

  /// Chỉ hiển thị bạn bè + người đã có lịch sử chat
  Widget _buildContactsList(UserModel? currentUser) {
    return StreamBuilder<List<UserModel>>(
      stream: _db.contactsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
        }

        final contacts = snapshot.data ?? [];

        if (contacts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline, size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 12),
                  Text(
                    'Chưa có bạn bè trong danh bạ.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gõ tên sinh viên vào ô tìm kiếm ở trên để kết bạn hoặc nhắn tin!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          itemCount: contacts.length,
          itemBuilder: (context, index) {
            final contact = contacts[index];
            final isChatting = _activeChatFriend?.uid == contact.uid;
            final isFriend = currentUser?.friends.contains(contact.uid) ?? false;
            return _buildContactTile(contact, isChatting, isFriend, isSearchMode: false);
          },
        );
      },
    );
  }

  /// Tìm kiếm toàn bộ sinh viên, hiển thị nút Kết bạn + Nhắn tin
  Widget _buildSearchResultsList(UserModel? currentUser) {
    return StreamBuilder<List<UserModel>>(
      stream: _db.usersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(fontSize: 12)));
        }

        final allUsers = snapshot.data ?? [];
        final filtered = allUsers.where((u) {
          if (u.uid == _db.uid) return false;
          return u.name.toLowerCase().contains(_friendSearchQuery) ||
              u.msv.toLowerCase().contains(_friendSearchQuery) ||
              u.university.toLowerCase().contains(_friendSearchQuery);
        }).toList();

        if (filtered.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Không tìm thấy sinh viên nào.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final user = filtered[index];
            final isChatting = _activeChatFriend?.uid == user.uid;
            final isFriend = currentUser?.friends.contains(user.uid) ?? false;
            return _buildContactTile(user, isChatting, isFriend, isSearchMode: true);
          },
        );
      },
    );
  }

  Widget _buildContactTile(
    UserModel friend,
    bool isChatting,
    bool isFriend, {
    required bool isSearchMode,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isChatting ? Colors.blueAccent.withValues(alpha: 0.13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // Avatar với chấm xanh online
            Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: friend.isAdmin ? Colors.redAccent.shade700 : Colors.blueGrey.shade800,
                  child: Text(
                    friend.name.isNotEmpty ? friend.name[0].toUpperCase() : 'U',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),

            // Tên + Trường / MSV
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          friend.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (friend.isAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'ADMIN',
                            style: TextStyle(fontSize: 7.5, color: Colors.redAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isFriend && !isSearchMode)
                        const Icon(Icons.people, size: 12, color: Colors.blueAccent),
                    ],
                  ),
                  Text(
                    friend.university.isNotEmpty
                        ? friend.university
                        : (friend.msv.isNotEmpty ? friend.msv : 'Sinh viên'),
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 10.5),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Nút hành động
            if (isSearchMode) ...[
              const SizedBox(width: 4),
              // Nút Kết bạn / Hủy kết bạn
              GestureDetector(
                onTap: () => _db.toggleFriend(friend.uid),
                child: Tooltip(
                  message: isFriend ? 'Hủy kết bạn' : 'Kết bạn',
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: isFriend
                          ? Colors.blueAccent.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isFriend ? Colors.blueAccent : Colors.grey.shade600,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      isFriend ? Icons.person_remove_outlined : Icons.person_add_outlined,
                      size: 14,
                      color: isFriend ? Colors.blueAccent : Colors.grey.shade400,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Nút Nhắn tin
              GestureDetector(
                onTap: () {
                  setState(() => _activeChatFriend = friend);
                  if (Scaffold.of(context).isEndDrawerOpen) Navigator.pop(context);
                },
                child: Tooltip(
                  message: 'Nhắn tin',
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blueAccent, width: 0.8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline, size: 14, color: Colors.blueAccent),
                  ),
                ),
              ),
            ] else ...[
              // Chế độ contacts: chỉ nút Chat
              GestureDetector(
                onTap: () {
                  setState(() => _activeChatFriend = friend);
                  if (Scaffold.of(context).isEndDrawerOpen) Navigator.pop(context);
                },
                child: Icon(
                  Icons.chat_bubble_outline,
                  size: 16,
                  color: isChatting ? Colors.blueAccent : Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}