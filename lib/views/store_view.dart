import 'package:flutter/material.dart';
import '../models/cosmetic_registry.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

/// Cửa hàng đổi quà - danh sách vật phẩm đọc từ [CosmeticRegistry] (định nghĩa trong code).
/// Để thêm vật phẩm mới, chỉ cần thêm entry vào CosmeticRegistry.items.
class StoreView extends StatelessWidget {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();
    final items = CosmeticRegistry.items;

    // Nhóm vật phẩm theo loại hiệu ứng
    final avatarFrames = items.where((i) => i.effect == CosmeticEffect.avatarFrame).toList();
    final nameColors = items.where((i) => i.effect == CosmeticEffect.nameColor).toList();
    final badges = items.where((i) => i.effect == CosmeticEffect.badge).toList();

    return StreamBuilder<UserModel?>(
      stream: db.userStream(),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        final myInventory = currentUser?.inventory ?? [];
        final myPoints = currentUser?.points ?? 0;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              children: [
                // Tiêu đề & điểm hiện tại
                _buildHeader(myPoints),
                const SizedBox(height: 16),

                // Nhóm: Khung Avatar
                if (avatarFrames.isNotEmpty) ...[
                  _buildSectionTitle(
                    icon: Icons.photo_camera,
                    title: 'Khung Avatar',
                    desc: 'Viền gradient quanh ảnh đại diện',
                    color: Colors.amber,
                  ),
                  ...avatarFrames.map((item) => _buildItemCard(context, db, item, myInventory)),
                  const SizedBox(height: 12),
                ],

                // Nhóm: Đổi màu tên
                if (nameColors.isNotEmpty) ...[
                  _buildSectionTitle(
                    icon: Icons.palette,
                    title: 'Thẻ Đổi Màu Tên',
                    desc: 'Tên hiển thị với màu sắc độc đáo và hiệu ứng glow',
                    color: Colors.purpleAccent,
                  ),
                  ...nameColors.map((item) => _buildItemCard(context, db, item, myInventory)),
                  const SizedBox(height: 12),
                ],

                // Nhóm: Huy hiệu / Danh hiệu
                if (badges.isNotEmpty) ...[
                  _buildSectionTitle(
                    icon: Icons.military_tech,
                    title: 'Huy Hiệu & Danh Hiệu',
                    desc: 'Hiển thị bên cạnh tên trong tất cả bài đăng',
                    color: Colors.tealAccent,
                  ),
                  ...badges.map((item) => _buildItemCard(context, db, item, myInventory)),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int myPoints) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront, color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa Hàng Đổi Quà',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Dùng điểm tích lũy để mở khóa vật phẩm trang trí hiển thị trong bài đăng',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber.shade700, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  '$myPoints pts',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(
    BuildContext context,
    DatabaseService db,
    CosmeticItem item,
    List<String> myInventory,
  ) {
    final isOwned = myInventory.contains(item.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Icon vật phẩm
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: item.color.withValues(alpha: 0.4), width: 1),
                boxShadow: [
                  BoxShadow(color: item.color.withValues(alpha: 0.2), blurRadius: 8, spreadRadius: 0),
                ],
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(width: 14),

            // Tên + mô tả
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${item.price} pts',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(item.desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
                  const SizedBox(height: 6),
                  // Preview hiệu ứng nhỏ
                  _buildEffectPreview(item),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Nút mua / badge "Đã sở hữu"
            isOwned
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.greenAccent),
                        SizedBox(width: 5),
                        Text('Đã sở hữu', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  )
                : ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: item.color.withValues(alpha: 0.2),
                      foregroundColor: item.color,
                      side: BorderSide(color: item.color.withValues(alpha: 0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    icon: const Icon(Icons.shopping_cart_outlined, size: 16),
                    label: const Text('Đổi', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () async {
                      try {
                        await db.buyItem(item.id, item.price);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('🎉 Mở khóa "${item.name}" thành công!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                          );
                        }
                      }
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectPreview(CosmeticItem item) {
    switch (item.effect) {
      case CosmeticEffect.avatarFrame:
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: CosmeticRegistry.getAvatarFrameGradient([item.id]) ??
                      [item.color, item.color.withValues(alpha: 0.5)],
                ),
              ),
              child: CircleAvatar(
                radius: 10,
                backgroundColor: Colors.blueGrey.shade800,
                child: const Text('A', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Text('Preview: Viền khung avatar', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        );
      case CosmeticEffect.nameColor:
        return Row(
          children: [
            Text(
              'Preview: Tên người dùng',
              style: TextStyle(
                fontSize: 11,
                color: item.color,
                fontWeight: FontWeight.bold,
                shadows: [Shadow(color: item.color.withValues(alpha: 0.6), blurRadius: 6)],
              ),
            ),
          ],
        );
      case CosmeticEffect.badge:
        return Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: item.color.withValues(alpha: 0.8), width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(item.icon, size: 11, color: item.color),
                  const SizedBox(width: 3),
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 9, color: item.color, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        );
    }
  }
}