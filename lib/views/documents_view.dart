import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/document_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class DocumentsView extends StatefulWidget {
  const DocumentsView({super.key});
  @override
  State<DocumentsView> createState() => _DocumentsViewState();
}

class _DocumentsViewState extends State<DocumentsView> {
  final _db = DatabaseService();
  bool _uploading = false;

  Future<void> _addDocumentLink() async {
    final titleController = TextEditingController();
    final urlController = TextEditingController();

    final isSubmitted = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chia sẻ Link Tài Liệu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Tên / Tiêu đề tài liệu',
                hintText: 'VD: Slide Công nghệ phần mềm',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                labelText: 'Đường link (Google Drive, Dropbox,...)',
                hintText: 'https://drive.google.com/...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Chia sẻ (+10 điểm)'),
          ),
        ],
      ),
    );

    final title = titleController.text.trim();
    final url = urlController.text.trim();
    titleController.dispose();
    urlController.dispose();

    if (isSubmitted != true || title.isEmpty || url.isEmpty) return;

    setState(() => _uploading = true);
    try {
      final uid = _db.uid;
      final user = await _db.getUser(uid);
      final docRef = DateTime.now().microsecondsSinceEpoch.toString();

      await _db.createDocument(
        document: DocumentModel(
          id: docRef,
          ownerId: uid,
          ownerName: user.name,
          title: title,
          fileName: 'Link chia sẻ',
          downloadUrl: url,
          storagePath: 'external',
          createdAt: DateTime.now(),
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🎉 Chia sẻ tài liệu thành công: +10 points!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Thất bại: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _download(DocumentModel doc) async {
    final uri = Uri.tryParse(doc.downloadUrl);
    if (uri == null) return;
    await _db.incrementDownloadCount(doc.id);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _confirmDelete(DocumentModel doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa tài liệu'),
        content: Text('Bạn có chắc chắn muốn xóa tài liệu "${doc.title}" không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.deleteDocument(doc.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa tài liệu thành công.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _db.userStream(),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;
        final isAdmin = currentUser?.isAdmin ?? false;

        return StreamBuilder<List<DocumentModel>>(
          stream: _db.documentsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text('Lỗi: ${snapshot.error}'));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!;
            
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Chưa có tài liệu nào. Hãy là người đầu tiên chia sẻ!'),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _addDocumentLink,
                      icon: const Icon(Icons.add_link),
                      label: const Text('Chia sẻ Link Tài Liệu'),
                    )
                  ],
                ),
              );
            }

            return Stack(
              children: [
                ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final doc = docs[i];
                    final canDelete = doc.ownerId == _db.uid || isAdmin;

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.link)),
                        title: Text(doc.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Đăng bởi: ${doc.ownerName} • ${doc.downloadCount} lượt truy cập'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.open_in_new, size: 18),
                              label: const Text('Mở Link'),
                              onPressed: () => _download(doc),
                            ),
                            if (canDelete) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                                tooltip: isAdmin && doc.ownerId != _db.uid ? 'Xóa (Admin)' : 'Xóa tài liệu',
                                onPressed: () => _confirmDelete(doc),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
            Positioned(
              right: 20,
              bottom: 20,
              child: FloatingActionButton.extended(
                onPressed: _uploading ? null : _addDocumentLink,
                icon: _uploading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.add_link),
                label: const Text('Thêm Tài Liệu'),
              ),
            ),
          ],
        );
      },
    );
      },
    );
  }
}