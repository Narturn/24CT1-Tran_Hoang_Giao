import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final List<String> likes;
  final int commentsCount;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.likes,
    required this.commentsCount,
    this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map, String docId) {
    return PostModel(
      id: docId,
      authorId: map['authorId'] ?? map['userId'] ?? '',
      authorName: map['authorName'] ?? map['userName'] ?? 'Sinh viên',
      content: map['content'] ?? '',
      likes: List<String>.from(map['likes'] ?? []),
      commentsCount: map['commentsCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'content': content,
      'likes': likes,
      'commentsCount': commentsCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}