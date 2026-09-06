import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/document_model.dart';
import '../models/review_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get uid => _auth.currentUser?.uid ?? '';

  Stream<UserModel?> userStream() {
    if (uid.isEmpty) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return UserModel(
          id: uid,
          msv: '',
          name: 'Sinh viên',
          university: '',
          email: _auth.currentUser?.email ?? '',
          points: 0,
          inventory: [],
        );
      }
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<UserModel> getUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, doc.id);
    }
    return UserModel(
      id: userId,
      msv: '',
      name: 'Sinh viên',
      university: '',
      email: '',
      points: 0,
      inventory: [],
    );
  }

  Future<void> addPoints(String userId, int amount) async {
    await _db.collection('users').doc(userId).update({
      'points': FieldValue.increment(amount),
    });
  }

  // FORUM
  Stream<List<PostModel>> postsStream() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> createPost(String content) async {
    final user = await getUser(uid);
    final postRef = _db.collection('posts').doc();
    
    await postRef.set({
      'id': postRef.id,
      'authorId': uid,
      'authorName': user.name,
      'content': content,
      'likes': [],
      'commentsCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addPoints(uid, 5);
  }

  Future<void> toggleLikePost(String postId, List<String> currentLikes) async {
    final postRef = _db.collection('posts').doc(postId);
    if (currentLikes.contains(uid)) {
      await postRef.update({'likes': FieldValue.arrayRemove([uid])});
    } else {
      await postRef.update({'likes': FieldValue.arrayUnion([uid])});
    }
  }

  Future<void> toggleLike(String postId, List<String> currentLikes) => toggleLikePost(postId, currentLikes);

  // DOCUMENTS
  Stream<List<DocumentModel>> documentsStream() {
    return _db
        .collection('documents')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => DocumentModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> createDocument({required DocumentModel document}) async {
    await _db.collection('documents').doc(document.id).set(document.toMap());
    await addPoints(uid, 10);
  }

  Future<void> incrementDownloadCount(String docId) async {
    await _db.collection('documents').doc(docId).update({
      'downloadCount': FieldValue.increment(1),
    });
  }

  // REVIEWS
  Stream<List<ReviewModel>> reviewsStream() {
    return _db
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => ReviewModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> createReview({
    required String targetName,
    required String category,
    required double rating,
    required String comment,
  }) async {
    final user = await getUser(uid);
    final reviewRef = _db.collection('reviews').doc();

    await reviewRef.set({
      'id': reviewRef.id,
      'authorId': uid,
      'authorName': user.name,
      'targetName': targetName,
      'category': category,
      'rating': rating,
      'comment': comment,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addPoints(uid, 15);
  }

  // STORE (TRANSACTION)
  Future<void> buyItem(String itemId, int price) async {
    final userRef = _db.collection('users').doc(uid);

    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) throw Exception("User không tồn tại!");

      final currentPoints = snapshot.data()?['points'] ?? 0;
      final List<dynamic> inventory = List.from(snapshot.data()?['inventory'] ?? []);

      if (currentPoints < price) {
        throw Exception("Không đủ điểm tích lũy!");
      }

      if (inventory.contains(itemId)) {
        throw Exception("Bạn đã sở hữu vật phẩm này rồi!");
      }

      transaction.update(userRef, {
        'points': currentPoints - price,
        'inventory': FieldValue.arrayUnion([itemId]),
      });
    });
  }

  Future<void> purchaseItem(String itemId, int price) => buyItem(itemId, price);
}