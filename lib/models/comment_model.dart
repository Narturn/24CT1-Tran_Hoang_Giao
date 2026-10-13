import 'package:cloud_firestore/cloud_firestore.dart';

class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final List<String> authorEquipped;
  final String content;
  final DateTime? createdAt;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    this.authorEquipped = const [],
    this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map, String docId) {
    return CommentModel(
      id: docId,
      authorId: map['authorId'] ?? map['userId'] ?? '',
      authorName: map['authorName'] ?? map['userName'] ?? 'Sinh viên',
      authorEquipped: List<String>.from(map['authorEquipped'] ?? []),
      content: map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'authorId': authorId,
      'authorName': authorName,
      'authorEquipped': authorEquipped,
      'content': content,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
