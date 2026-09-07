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

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Khung Preview Trang phục (Live Discord Style Preview)
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Xem trước Trang phục', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 12),
                    UserHeaderBadge(
                      name: user.name,
                      inventory: user.equipped.values.toList(), // Hiển thị theo item đang đeo
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Thẻ Điểm tích lũy
            Card(
              child: ListTile(
                leading: const Icon(Icons.stars, color: Colors.amber, size: 32),
                title: const Text('Điểm tích lũy'),
                trailing: Text('${user.points} pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 20),

            // 3. Kho vật phẩm & Quản lý Trang bị
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
                        selectedColor: Colors.amber.withOpacity(0.3),
                        onSelected: (bool selected) async {
                          final currentEquipped = Map<String, String>.from(user.equipped);
                          
                          if (selected) {
                            // Đeo trang bị vào slot tương ứng
                            currentEquipped[item] = item;
                          } else {
                            // Tháo trang bị
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
        );
      },
    );
  }
}