import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String authorId;
  final String authorName;
  final List<String> authorEquipped;
  final String targetName;
  final String category;
  final double rating;
  final String comment;
  final List<String> tags;
  final int commentsCount;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorEquipped,
    required this.targetName,
    required this.category,
    required this.rating,
    required this.comment,
    required this.tags,
    this.commentsCount = 0,
    this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      authorId: map['authorId'] ?? map['userId'] ?? '',
      authorName: map['authorName'] ?? map['userName'] ?? 'Sinh viên',
      authorEquipped: List<String>.from(map['authorEquipped'] ?? []),
      targetName: map['targetName'] ?? map['subject'] ?? map['teacher'] ?? '',
      category: map['category'] ?? 'Môn học',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? map['content'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      commentsCount: map['commentsCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorEquipped': authorEquipped,
      'targetName': targetName,
      'category': category,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'commentsCount': commentsCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}