import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';

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
            // Avatar & Tên
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.amber,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text('${user.msv} • ${user.university}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Thẻ Điểm tích lũy
            Card(
              child: ListTile(
                leading: const Icon(Icons.stars, color: Colors.amber, size: 32),
                title: const Text('Điểm tích lũy'),
                trailing: Text('${user.points} pts', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              ),
            ),
            const SizedBox(height: 16),

            // Kho vật phẩm trang trí đã sở hữu
            const Text('Kho trang trí của tôi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                    children: user.inventory
                        .map((item) => Chip(
                              avatar: const Icon(Icons.military_tech, color: Colors.amber),
                              label: Text(item),
                            ))
                        .toList(),
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