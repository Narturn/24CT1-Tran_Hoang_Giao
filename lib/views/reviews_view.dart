import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/database_service.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  final _db = DatabaseService();

  Future<void> _addReview() async {
    final targetController = TextEditingController();
    final commentController = TextEditingController();
    String category = 'Môn học';
    double rating = 5.0;

    final isSubmitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng Review (+15 points)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              decoration: const InputDecoration(labelText: 'Tên bài review'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              items: const [
                DropdownMenuItem(value: 'Trong trường', child: Text('Trong trường')),
                DropdownMenuItem(value: 'Ngoài trường', child: Text('Ngoài trường')),
              ],
              onChanged: (val) => category = val ?? 'Trong trường',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(labelText: 'Nội dung review'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Đăng')),
        ],
      ),
    );

    if (isSubmitted == true && targetController.text.isNotEmpty) {
      await _db.createReview(
        targetName: targetController.text.trim(),
        category: category,
        rating: rating,
        comment: commentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng Review thành công: +15 points!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addReview,
        icon: const Icon(Icons.rate_review),
        label: const Text('Viết Review'),
      ),
      body: StreamBuilder<List<ReviewModel>>(
        stream: _db.reviewsStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final reviews = snapshot.data!;

          return Column(
            children: [
              // Thanh lọc Hashtag
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(label: const Text('Tất cả'), selected: true, onSelected: (_) {}),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('#MonHoc'), selected: false, onSelected: (_) {}),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('#GiangVien'), selected: false, onSelected: (_) {}),
                    const SizedBox(width: 8),
                    FilterChip(label: const Text('#QuanAnNearCampus'), selected: false, onSelected: (_) {}),
                  ],
                ),
              ),
              // Danh sách review nằm trong Expanded
              Expanded(
                child: ListView.builder(
                  itemCount: reviews.length,
                  padding: const EdgeInsets.all(12),
                  itemBuilder: (context, index) {
                    final item = reviews[index];
                    return Card(
                      child: ListTile(
                        title: Text('${item.targetName} [${item.category}]'),
                        subtitle: Text('${item.comment}\nViết bởi: ${item.authorName}'),
                        trailing: Text('⭐ ${item.rating}'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}