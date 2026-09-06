import 'package:cloud_firestore/cloud_firestore.dart';

class DocumentModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String title;
  final String fileName;
  final String downloadUrl;
  final String storagePath;
  final int downloadCount;
  final DateTime? createdAt;

  DocumentModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.title,
    required this.fileName,
    required this.downloadUrl,
    required this.storagePath,
    this.downloadCount = 0,
    this.createdAt,
  });

  factory DocumentModel.fromMap(Map<String, dynamic> map, String docId) {
    return DocumentModel(
      id: docId,
      ownerId: map['ownerId'] ?? map['userId'] ?? '',
      ownerName: map['ownerName'] ?? map['userName'] ?? 'Sinh viên',
      title: map['title'] ?? '',
      fileName: map['fileName'] ?? 'Tài liệu',
      downloadUrl: map['downloadUrl'] ?? '',
      storagePath: map['storagePath'] ?? 'external',
      downloadCount: map['downloadCount'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'title': title,
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'downloadCount': downloadCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}