import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/database_service.dart';
import '../widgets/user_avatar_badge.dart';

class ReviewsView extends StatefulWidget {
  const ReviewsView({super.key});

  @override
  State<ReviewsView> createState() => _ReviewsViewState();
}

class _ReviewsViewState extends State<ReviewsView> {
  final _db = DatabaseService();
  String _selectedTag = 'Tất cả';

  Future<void> _addReview() async {
    final targetController = TextEditingController();
    final commentController = TextEditingController();
    String category = 'Trong trường';
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
              decoration: const InputDecoration(
                labelText: 'Tên bài viết',
                hintText: 'VD: Công nghệ phần mềm',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Phân loại review'),
              items: const [
                DropdownMenuItem(
                  value: 'Trong trường', 
                  child: Text('Trong trường'),
                ),
                DropdownMenuItem(
                  value: 'Ngoài trường', 
                  child: Text('Ngoài trường'),
                ),
              ],
              onChanged: (val) => category = val ?? 'Trong trường',
            ),
            const SizedBox(height: 8),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                labelText: 'Nội dung review',
                hintText: 'Thêm hashtag tự do trong bài, ví dụ: Thầy dạy hay lắm #monhoc #dau',
              ),
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
          
          final allReviews = snapshot.data!;

          // Lấy tất cả các hashtag duy nhất hiện có trong cơ sở dữ liệu
          final Set<String> allTags = {'Tất cả'};
          for (var r in allReviews) {
            allTags.addAll(r.tags);
          }

          // Lọc bài viết theo tag đang chọn
          final filteredReviews = _selectedTag == 'Tất cả'
              ? allReviews
              : allReviews.where((r) => r.tags.contains(_selectedTag)).toList();

          return Column(
            children: [
              // Thanh cuộn ngang danh sách Hashtags
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: allTags.map((tag) {
                    final isSelected = _selectedTag == tag;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (_) {
                          setState(() {
                            _selectedTag = tag;
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Danh sách bài viết review
              Expanded(
                child: filteredReviews.isEmpty
                    ? const Center(child: Text('Không có bài viết nào với hashtag này'))
                    : ListView.builder(
                        itemCount: filteredReviews.length,
                        padding: const EdgeInsets.all(12),
                        itemBuilder: (context, index) {
                          final item = filteredReviews[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Hiển thị Avatar, Khung, Tên & Danh hiệu trang bị của Tác giả
                                  UserHeaderBadge(
                                    name: item.authorName,
                                    inventory: item.authorEquipped,
                                  ),
                                  const SizedBox(height: 8),

                                  // Tiêu đề môn / địa điểm
                                  Text(
                                    '${item.targetName} [${item.category}]',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),

                                  // Nội dung review
                                  Text(item.comment),
                                  const SizedBox(height: 8),

                                  // Thẻ Hashtags
                                  if (item.tags.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      children: item.tags
                                          .map((tag) => Chip(
                                                label: Text(tag, style: const TextStyle(fontSize: 11)),
                                                padding: EdgeInsets.zero,
                                              ))
                                          .toList(),
                                    ),
                                ],
                              ),
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