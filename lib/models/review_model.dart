import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String authorId;
  final String authorName;
  final String targetName;
  final String category;
  final double rating;
  final String comment;
  final DateTime? createdAt;

  ReviewModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.targetName,
    required this.category,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromMap(Map<String, dynamic> map, String docId) {
    return ReviewModel(
      id: docId,
      authorId: map['authorId'] ?? map['userId'] ?? '',
      authorName: map['authorName'] ?? map['userName'] ?? 'Sinh viên',
      targetName: map['targetName'] ?? map['subject'] ?? map['teacher'] ?? '',
      category: map['category'] ?? 'Môn học',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] ?? map['content'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'targetName': targetName,
      'category': category,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}