import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  String? get currentUid => _auth.currentUser?.uid;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String name,
    required String studentId,
    required String university,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (cred.user != null) {
      await _db.collection('users').doc(cred.user!.uid).set({
        'msv': studentId,
        'name': name,
        'university': university,
        'email': email,
        'points': 0,
        'inventory': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return cred;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}