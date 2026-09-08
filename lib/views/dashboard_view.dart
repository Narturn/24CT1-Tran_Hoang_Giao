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
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.folder_shared_outlined,
                  activeIcon: Icons.folder_shared,
                  label: 'Kho tài liệu',
                  isTablet: isTablet,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.rate_review_outlined,
                  activeIcon: Icons.rate_review,
                  label: 'Trạm review',
                  isTablet: isTablet,
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
                  ),
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
        onTap: () => setState(() => _selectedIndex = index),
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