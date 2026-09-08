import 'package:flutter/material.dart';

/// Định nghĩa một vật phẩm trang trí / huy chương
class CosmeticItem {
  final String id;
  final String name;
  final String desc;
  final int price;
  final IconData icon;
  final Color color;
  final CosmeticEffect effect;

  const CosmeticItem({
    required this.id,
    required this.name,
    required this.desc,
    required this.price,
    required this.icon,
    required this.color,
    required this.effect,
  });
}

/// Loại hiệu ứng trang trí mà vật phẩm mang lại
enum CosmeticEffect {
  /// Viền gradient quanh avatar
  avatarFrame,

  /// Đổi màu tên người dùng
  nameColor,

  /// Hiển thị badge/huy chương bên cạnh tên
  badge,
}

/// Registry trung tâm – định nghĩa TẤT CẢ vật phẩm trong code.
/// Để thêm vật phẩm mới, chỉ cần thêm một entry vào danh sách này.
/// Không cần admin tạo trên web, không mất dữ liệu khi deploy lại.
class CosmeticRegistry {
  CosmeticRegistry._();

  static const List<CosmeticItem> items = [
    // ────────── KHUNG AVATAR ──────────
    CosmeticItem(
      id: 'frame_gold',
      name: 'Khung Avatar Hoàng Kim',
      desc: 'Viền gradient vàng lấp lánh quanh avatar',
      price: 60,
      icon: Icons.stars,
      color: Color(0xFFFFAB40),
      effect: CosmeticEffect.avatarFrame,
    ),
    CosmeticItem(
      id: 'frame_cyber',
      name: 'Khung Avatar Cyber Neon',
      desc: 'Viền gradient tím–xanh cyan kiểu cyberpunk',
      price: 120,
      icon: Icons.blur_on,
      color: Color(0xFFE040FB),
      effect: CosmeticEffect.avatarFrame,
    ),
    CosmeticItem(
      id: 'frame_ruby',
      name: 'Khung Avatar Hồng Ngọc',
      desc: 'Viền gradient đỏ ruby rực rỡ',
      price: 150,
      icon: Icons.favorite,
      color: Color(0xFFFF1744),
      effect: CosmeticEffect.avatarFrame,
    ),
    CosmeticItem(
      id: 'frame_emerald',
      name: 'Khung Avatar Ngọc Lục Bảo',
      desc: 'Viền gradient xanh ngọc huyền bí',
      price: 150,
      icon: Icons.eco,
      color: Color(0xFF00E676),
      effect: CosmeticEffect.avatarFrame,
    ),

    // ────────── ĐỔI MÀU TÊN ──────────
    CosmeticItem(
      id: 'theme_cyber',
      name: 'Thẻ Đổi Màu Tên (Cyberpunk)',
      desc: 'Tên hiển thị màu tím neon phát sáng',
      price: 150,
      icon: Icons.palette,
      color: Color(0xFFE040FB),
      effect: CosmeticEffect.nameColor,
    ),
    CosmeticItem(
      id: 'theme_gold',
      name: 'Thẻ Đổi Màu Tên (Hoàng Kim)',
      desc: 'Tên hiển thị màu vàng ánh kim sang trọng',
      price: 130,
      icon: Icons.auto_awesome,
      color: Color(0xFFFFD700),
      effect: CosmeticEffect.nameColor,
    ),
    CosmeticItem(
      id: 'theme_ruby',
      name: 'Thẻ Đổi Màu Tên (Hồng Ngọc)',
      desc: 'Tên hiển thị màu đỏ ruby phong cách',
      price: 130,
      icon: Icons.color_lens,
      color: Color(0xFFFF5252),
      effect: CosmeticEffect.nameColor,
    ),
    CosmeticItem(
      id: 'theme_ocean',
      name: 'Thẻ Đổi Màu Tên (Đại Dương)',
      desc: 'Tên hiển thị màu xanh cyan biển cả',
      price: 130,
      icon: Icons.water,
      color: Color(0xFF00E5FF),
      effect: CosmeticEffect.nameColor,
    ),

    // ────────── HUY HIỆU / DANH HIỆU ──────────
    CosmeticItem(
      id: 'title_pro',
      name: 'Danh hiệu "Học Thần"',
      desc: 'Huy chương vàng Học Thần bên cạnh tên',
      price: 30,
      icon: Icons.military_tech,
      color: Color(0xFFFFC107),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_active',
      name: 'Huy hiệu "Chiến Thần Chém Gió"',
      desc: 'Icon ngọn lửa nhiệt huyết bên cạnh tên',
      price: 100,
      icon: Icons.whatshot,
      color: Color(0xFFFF5722),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_diamond',
      name: 'Huy hiệu "Kim Cương"',
      desc: 'Biểu tượng kim cương xanh quý giá',
      price: 200,
      icon: Icons.diamond,
      color: Color(0xFF00E5FF),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_crown',
      name: 'Huy hiệu "Vương Miện"',
      desc: 'Vương miện vàng của người dẫn đầu bảng xếp hạng',
      price: 300,
      icon: Icons.workspace_premium,
      color: Color(0xFFFFD700),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_shield',
      name: 'Huy hiệu "Vệ Binh"',
      desc: 'Khiên xanh của những thành viên trung thành',
      price: 80,
      icon: Icons.shield,
      color: Color(0xFF42A5F5),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_school',
      name: 'Huy hiệu "Cựu Sinh Viên Xuất Sắc"',
      desc: 'Mũ tốt nghiệp dành cho những thành tích học tập',
      price: 250,
      icon: Icons.school,
      color: Color(0xFF66BB6A),
      effect: CosmeticEffect.badge,
    ),
    CosmeticItem(
      id: 'badge_lightning',
      name: 'Huy hiệu "Tốc Chiến"',
      desc: 'Sấm sét của những thành viên hoạt động nhanh',
      price: 90,
      icon: Icons.bolt,
      color: Color(0xFFFFEE58),
      effect: CosmeticEffect.badge,
    ),
  ];

  /// Lấy vật phẩm theo ID
  static CosmeticItem? getById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Lấy tất cả vật phẩm mà người dùng đang sở hữu (inventory là list các ID)
  static List<CosmeticItem> getOwned(List<String> inventory) {
    return items.where((item) => inventory.contains(item.id)).toList();
  }

  /// Lấy màu gradient cho khung avatar dựa trên inventory đang trang bị
  /// Ưu tiên hiệu ứng frame cao cấp nhất
  static List<Color>? getAvatarFrameGradient(List<String> equipped) {
    // Ưu tiên item có giá cao nhất (hiếm nhất) trước
    for (final id in ['frame_ruby', 'frame_emerald', 'frame_cyber', 'frame_gold']) {
      if (equipped.contains(id)) {
        final item = getById(id);
        if (item != null) {
          return _frameGradients[id];
        }
      }
    }
    return null;
  }

  /// Màu gradient cho từng loại khung
  static const Map<String, List<Color>> _frameGradients = {
    'frame_gold': [Color(0xFFFFD700), Color(0xFFFFAB40), Color(0xFFFFE082)],
    'frame_cyber': [Color(0xFFE040FB), Color(0xFF00E5FF), Color(0xFF7C4DFF)],
    'frame_ruby': [Color(0xFFFF1744), Color(0xFFFF5252), Color(0xFFD50000)],
    'frame_emerald': [Color(0xFF00E676), Color(0xFF69F0AE), Color(0xFF00BFA5)],
  };

  /// Màu hiển thị tên dựa trên inventory trang bị
  static Color? getNameColor(List<String> equipped) {
    for (final id in ['theme_cyber', 'theme_gold', 'theme_ruby', 'theme_ocean']) {
      if (equipped.contains(id)) {
        final item = getById(id);
        return item?.color;
      }
    }
    return null;
  }

  /// Danh sách các badge để hiển thị (theo thứ tự ưu tiên)
  static List<CosmeticItem> getBadges(List<String> equipped) {
    return items
        .where((item) => item.effect == CosmeticEffect.badge && equipped.contains(item.id))
        .toList();
  }
}
