import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar_badge.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    return StreamBuilder<UserModel?>(
      stream: db.userStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final user = snapshot.data!;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Khung Preview Trang phục (Live Discord Style Preview)
                Card(
                  color: Colors.grey.shade900,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text('Xem trước Trang phục & Danh hiệu', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        const SizedBox(height: 12),
                        UserHeaderBadge(
                          name: user.name,
                          inventory: user.equipped.values.toList(),
                          isAdmin: user.isAdmin,
                          subtitle: '${user.msv.isNotEmpty ? user.msv : "SV"} • ${user.university}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Thẻ Vai trò & Quyền hạn
                Card(
                  child: ListTile(
                    leading: Icon(
                      user.isAdmin ? Icons.shield : Icons.person,
                      color: user.isAdmin ? Colors.redAccent : Colors.blueAccent,
                      size: 30,
                    ),
                    title: const Text('Vai trò tài khoản', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      user.isAdmin
                          ? 'Quản trị viên (Có quyền xóa bài viết và quản lý người dùng)'
                          : 'Sinh viên / Thành viên tiêu chuẩn',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                    ),
                    trailing: user.isAdmin
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.redAccent),
                            ),
                            child: const Text('ADMIN', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.key, size: 16),
                            label: const Text('Nhập mã Admin'),
                            onPressed: () => _showAdminKeyDialog(context, db, user.uid),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Thẻ Điểm tích lũy
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.stars, color: Colors.amber, size: 32),
                    title: const Text('Điểm tích lũy'),
                    trailing: Text('${user.points} pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ),
                ),
                const SizedBox(height: 20),

                // 4. Kho vật phẩm & Quản lý Trang bị
                const Text('Kho trang trí của tôi (Bấm để đeo/tháo)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                user.inventory.isEmpty
                    ? const Card(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Chưa có vật phẩm nào. Hãy ghé Cửa hàng để đổi quà!', style: TextStyle(color: Colors.grey)),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: user.inventory.map((item) {
                          final isEquipped = user.equipped.containsValue(item);

                          return FilterChip(
                            selected: isEquipped,
                            avatar: Icon(
                              isEquipped ? Icons.check_circle : Icons.military_tech,
                              color: isEquipped ? Colors.green : Colors.amber,
                            ),
                            label: Text(item),
                            selectedColor: Colors.amber.withValues(alpha: 0.3),
                            onSelected: (bool selected) async {
                              final currentEquipped = Map<String, String>.from(user.equipped);
                              
                              if (selected) {
                                currentEquipped[item] = item;
                              } else {
                                currentEquipped.removeWhere((key, value) => value == item);
                              }

                              await db.updateEquippedItems(currentEquipped);
                            },
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 32),

                // Nút Đăng xuất
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  onPressed: () => AuthService().signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất tài khoản'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAdminKeyDialog(BuildContext context, DatabaseService db, String uid) async {
    final keyController = TextEditingController();
    final isSuccess = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.security, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Xác thực Quản Trị Viên'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Chỉ những người được ủy quyền mới có thể truy cập quyền Quản trị. Vui lòng nhập Mã Bí Mật Quản Trị Viên:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: keyController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mã bí mật Admin',
                hintText: 'Nhập mã bảo mật...',
                prefixIcon: Icon(Icons.key),
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              // Mã bí mật quản trị viên (Chỉ bạn và người có thẩm quyền mới biết mã này)
              const secretKey = 'DAU28NrTrn@1f&M';
              if (keyController.text.trim() == secretKey) {
                Navigator.pop(ctx, true);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text('❌ Mã bí mật Admin không chính xác!'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (isSuccess == true) {
      await db.updateUserRole(uid, 'admin');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Xác thực thành công! Bạn đã được cấp quyền Quản trị viên (Admin).')),
        );
      }
    }
  }
}