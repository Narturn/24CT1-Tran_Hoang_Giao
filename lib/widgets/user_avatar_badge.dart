import 'package:flutter/material.dart';
import '../models/cosmetic_registry.dart';

/// Widget hiển thị header của người dùng với đầy đủ:
/// - Avatar (có viền trang trí nếu sở hữu khung)
/// - Tên (đổi màu nếu có thẻ tên)
/// - Huy hiệu ADMIN
/// - Huy chương / Danh hiệu trang bị
///
/// Truyền [equipped] là danh sách ID vật phẩm đang trang bị.
/// Tất cả hiệu ứng được tra cứu từ [CosmeticRegistry].
class UserHeaderBadge extends StatelessWidget {
  final String name;

  /// Danh sách ID vật phẩm đang được trang bị (equipped).
  /// Đây là một subset của inventory mà người dùng chọn hiển thị.
  final List<String> inventory;

  final bool isAdmin;
  final String? subtitle;

  const UserHeaderBadge({
    super.key,
    required this.name,
    this.inventory = const [],
    this.isAdmin = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    // Tra cứu từ CosmeticRegistry
    final frameGradient = CosmeticRegistry.getAvatarFrameGradient(inventory);
    final nameColor = CosmeticRegistry.getNameColor(inventory);
    final badges = CosmeticRegistry.getBadges(inventory);

    // Có viền gradient không?
    final hasFrame = frameGradient != null;

    // Glow shadow cho viền
    final glowColor = hasFrame
        ? frameGradient!.first.withValues(alpha: 0.5)
        : (isAdmin ? Colors.redAccent.withValues(alpha: 0.4) : null);

    return Row(
      children: [
        // ── AVATAR + VIỀN KHUNG ──
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasFrame
                ? LinearGradient(colors: frameGradient!)
                : (isAdmin
                    ? const LinearGradient(
                        colors: [Colors.redAccent, Colors.deepOrange, Colors.orange],
                      )
                    : null),
            boxShadow: glowColor != null
                ? [BoxShadow(color: glowColor, blurRadius: 6, spreadRadius: 1)]
                : null,
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: isAdmin ? Colors.red.shade900 : Colors.blueGrey.shade800,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 10),

        // ── TÊN + HUY HIỆU ──
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 5,
                runSpacing: 3,
                children: [
                  // Tên người dùng (có hiệu ứng neon/màu nếu trang bị thẻ đổi màu)
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: nameColor,
                      shadows: nameColor != null
                          ? [Shadow(color: nameColor.withValues(alpha: 0.7), blurRadius: 8)]
                          : null,
                    ),
                  ),

                  // Huy hiệu ADMIN
                  if (isAdmin)
                    _buildAdminBadge(),

                  // Huy chương / Danh hiệu từ CosmeticRegistry
                  for (final badge in badges)
                    _buildBadge(badge),
                ],
              ),

              // Phụ đề (thời gian đăng, MSV, v.v.)
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.redAccent, width: 0.8),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield, size: 11, color: Colors.redAccent),
          SizedBox(width: 3),
          Text(
            'ADMIN',
            style: TextStyle(
              fontSize: 9,
              color: Colors.redAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(CosmeticItem badge) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badge.color.withValues(alpha: 0.8), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badge.icon, size: 12, color: badge.color),
          const SizedBox(width: 3),
          Text(
            badge.name,
            style: TextStyle(
              fontSize: 10,
              color: badge.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}