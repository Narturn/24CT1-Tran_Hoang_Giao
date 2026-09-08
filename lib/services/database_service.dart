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
          uid: uid,
          msv: '',
          name: 'Sinh viên',
          university: '',
          email: _auth.currentUser?.email ?? '',
          points: 0,
          inventory: [],
          equipped: {},
          role: 'user',
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
      uid: userId,
      msv: '',
      name: 'Sinh viên',
      university: '',
      email: '',
      points: 0,
      inventory: [],
      equipped: {},
      role: 'user',
    );
  }

  // Hàm cập nhật vật phẩm đang trang bị
  Future<void> updateEquippedItems(Map<String, String> newEquipped) async {
    await _db.collection('users').doc(uid).update({
      'equipped': newEquipped,
    });
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
      'authorEquipped': user.equipped.values.toList(),
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

  Future<void> deletePost(String postId) async {
    await _db.collection('posts').doc(postId).delete();
  }

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

  Future<void> deleteDocument(String docId) async {
    await _db.collection('documents').doc(docId).delete();
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

    final RegExp regExp = RegExp(r'#\w+');
    final List<String> tags = regExp
      .allMatches(comment)
      .map((match) => match.group(0)!.toLowerCase())
      .toList();

      await reviewRef.set({
      'id': reviewRef.id,
      'authorId': uid,
      'authorName': user.name,
      'authorEquipped': user.equipped.values.toList(),
      'targetName': targetName,
      'category': category,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await addPoints(uid, 15);
  }

  Future<void> deleteReview(String reviewId) async {
    await _db.collection('reviews').doc(reviewId).delete();
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

  // DYNAMIC STORE ITEMS (FIRESTORE)
  Stream<List<Map<String, dynamic>>> storeItemsStream() {
    return _db.collection('store_items').orderBy('price').snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        _seedDefaultStoreItems();
      }
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> _seedDefaultStoreItems() async {
    final defaults = [
      {
        'id': 'title_pro',
        'name': 'Danh hiệu "Học Thần"',
        'desc': 'Hiển thị huy hiệu VIP bên cạnh tên bài viết',
        'price': 30,
        'icon': 'military_tech',
        'color': 0xFFFFC107, // Amber
      },
      {
        'id': 'frame_gold',
        'name': 'Khung Avatar Hoàng Kim',
        'desc': 'Trang trí viền avatar vàng lấp lánh',
        'price': 60,
        'icon': 'stars',
        'color': 0xFFFFAB40, // OrangeAccent
      },
      {
        'id': 'badge_active',
        'name': 'Huy hiệu "Chiến Thần Chém Gió"',
        'desc': 'Mở khóa icon lửa nhiệt huyết ở Forum',
        'price': 100,
        'icon': 'whatshot',
        'color': 0xFFFF5722, // DeepOrange
      },
      {
        'id': 'theme_cyber',
        'name': 'Thẻ Đổi Màu Tên (Cyberpunk)',
        'desc': 'Tên sinh viên đổi sang màu Neon nổi bật',
        'price': 150,
        'icon': 'palette',
        'color': 0xFFE040FB, // PurpleAccent
      },
    ];

    for (final item in defaults) {
      await _db.collection('store_items').doc(item['id'] as String).set({
        ...item,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Future<void> createStoreItem({
    required String id,
    required String name,
    required String desc,
    required int price,
    required String icon,
    required int color,
  }) async {
    final docId = id.trim().isNotEmpty ? id.trim() : 'item_${DateTime.now().millisecondsSinceEpoch}';
    await _db.collection('store_items').doc(docId).set({
      'id': docId,
      'name': name.trim(),
      'desc': desc.trim(),
      'price': price,
      'icon': icon,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteStoreItem(String itemId) async {
    await _db.collection('store_items').doc(itemId).delete();
  }

  // USER MANAGEMENT & ADMIN
  Stream<List<UserModel>> usersStream() {
    return _db.collection('users').snapshots().map((snap) {
      return snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Future<void> updateUserRole(String targetUid, String newRole) async {
    await _db.collection('users').doc(targetUid).update({'role': newRole});
  }

  // FACEBOOK FRIENDSHIP & CONTACTS
  Future<void> toggleFriend(String targetUid) async {
    if (uid.isEmpty || targetUid == uid) return;
    final user = await getUser(uid);
    final isFriend = user.friends.contains(targetUid);
    final userRef = _db.collection('users').doc(uid);
    final targetRef = _db.collection('users').doc(targetUid);

    if (isFriend) {
      await userRef.update({'friends': FieldValue.arrayRemove([targetUid])});
      await targetRef.update({'friends': FieldValue.arrayRemove([uid])});
    } else {
      await userRef.update({'friends': FieldValue.arrayUnion([targetUid])});
      await targetRef.update({'friends': FieldValue.arrayUnion([uid])});
    }
  }

  // Lấy danh bạ gồm: Bạn bè + những người có hội thoại chat với mình
  Stream<List<UserModel>> contactsStream() {
    if (uid.isEmpty) return Stream.value([]);

    return _db.collection('users').doc(uid).snapshots().asyncMap((doc) async {
      final Set<String> contactUids = {};
      if (doc.exists && doc.data() != null) {
        final friends = List<String>.from(doc.data()!['friends'] ?? []);
        contactUids.addAll(friends);
      }

      // Lấy các phòng chat có mình
      try {
        final chatSnaps = await _db
            .collection('chats')
            .where('users', arrayContains: uid)
            .get();

        for (final c in chatSnaps.docs) {
          final users = List<String>.from(c.data()['users'] ?? []);
          for (final u in users) {
            if (u != uid) contactUids.add(u);
          }
        }
      } catch (_) {}

      if (contactUids.isEmpty) return <UserModel>[];

      final List<UserModel> list = [];
      for (final cUid in contactUids) {
        final u = await getUser(cUid);
        list.add(u);
      }
      return list;
    });
  }

  // REALTIME FACEBOOK CHAT
  String getChatId(String u1, String u2) {
    return u1.compareTo(u2) < 0 ? '${u1}_$u2' : '${u2}_$u1';
  }

  Stream<List<Map<String, dynamic>>> messagesStream(String friendId) {
    final chatId = getChatId(uid, friendId);
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  Future<void> sendMessage({
    required String recipientId,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || uid.isEmpty) return;

    final user = await getUser(uid);
    final chatId = getChatId(uid, recipientId);
    final chatDocRef = _db.collection('chats').doc(chatId);
    final messageRef = chatDocRef.collection('messages').doc();

    await messageRef.set({
      'id': messageRef.id,
      'senderId': uid,
      'senderName': user.name,
      'recipientId': recipientId,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await chatDocRef.set({
      'users': [uid, recipientId],
      'lastMessage': trimmed,
      'lastSenderId': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}