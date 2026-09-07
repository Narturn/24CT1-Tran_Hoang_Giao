import 'package:flutter/material.dart';

class UserHeaderBadge extends StatelessWidget {
  final String name;
  final List<String> inventory;

  const UserHeaderBadge({
    super.key,
    required this.name,
    required this.inventory,
  });

  @override
  Widget build(BuildContext context) {
    // Kiểm tra các vật phẩm người dùng đang sở hữu
    final hasGoldFrame = inventory.contains('frame_gold') || inventory.contains('Khung Avatar Hoàng Kim');
    final hasCyberName = inventory.contains('theme_cyber') || inventory.contains('Thẻ Đổi Màu Tên (Cyberpunk)');
    final hasHocThan = inventory.contains('title_pro') || inventory.contains('Danh hiệu "Học Thần"');
    final hasChemGio = inventory.contains('badge_active') || inventory.contains('Huy hiệu "Chiến Thần Chém Gió"');

    return Row(
      children: [
        // 1. AVATAR + KHUNG HOÀNG KIM (Discord Style Frame)
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasGoldFrame
                ? const LinearGradient(
                    colors: [Colors.amber, Colors.orangeAccent, Colors.yellow],
                  )
                : null,
            boxShadow: hasGoldFrame
                ? [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.blueGrey.shade800,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // 2. TÊN ĐỔI MÀU + HUY HIỆU / DANH HIỆU
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Tên người dùng (Có Effect Neon Cyberpunk nếu có thẻ đổi màu)
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: hasCyberName ? Colors.purpleAccent : null,
                      shadows: hasCyberName
                          ? [const Shadow(color: Colors.purpleAccent, blurRadius: 8)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Huy hiệu "Học Thần"
                  if (hasHocThan)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber, width: 0.8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.military_tech, size: 12, color: Colors.amber),
                          SizedBox(width: 2),
                          Text('Học Thần', style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                  // Huy hiệu "Chiến Thần Chém Gió"
                  if (hasChemGio)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.deepOrange, width: 0.8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.whatshot, size: 12, color: Colors.deepOrange),
                          SizedBox(width: 2),
                          Text('Chém Gió', style: TextStyle(fontSize: 10, color: Colors.deepOrange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}