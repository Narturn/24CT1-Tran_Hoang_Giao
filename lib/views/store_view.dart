import 'package:flutter/material.dart';
import '../services/database_service.dart';

class StoreView extends StatelessWidget {
  const StoreView({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService();

    // Danh sách vật phẩm trang trí ảo
    final items = [
      {
        'id': 'title_pro',
        'name': 'Danh hiệu "Học Thần"',
        'desc': 'Hiển thị huy hiệu VIP bên cạnh tên bài viết',
        'price': 30,
        'icon': Icons.military_tech,
        'color': Colors.amber,
      },
      {
        'id': 'frame_gold',
        'name': 'Khung Avatar',
        'desc': 'Trang trí viền avatar vàng lấp lánh',
        'price': 60,
        'icon': Icons.stars,
        'color': Colors.orangeAccent,
      },
      {
        'id': 'badge_active',
        'name': 'Huy hiệu "Chiến Thần Chém Gió"',
        'desc': 'Mở khóa icon lửa nhiệt huyết ở Forum',
        'price': 100,
        'icon': Icons.whatshot,
        'color': Colors.deepOrange,
      },
      {
        'id': 'theme_cyber',
        'name': 'Thẻ Đổi Màu Tên',
        'desc': 'Tên sinh viên đổi sang màu Neon nổi bật',
        'price': 150,
        'icon': Icons.palette,
        'color': Colors.purpleAccent,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item['id'] as String;
        final name = item['name'] as String;
        final desc = item['desc'] as String;
        final price = item['price'] as int;
        final icon = item['icon'] as IconData;
        final color = item['color'] as Color;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color),
            ),
            title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('$desc\nGiá đổi: $price pts'),
            isThreeLine: true,
            trailing: ElevatedButton(
              onPressed: () async {
                try {
                  await db.buyItem(id, price);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('🎉 Mở khóa "$name" thành công!')),
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
              child: const Text('Đổi vật phẩm'),
            ),
          ),
        );
      },
    );
  }
}