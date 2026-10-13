import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_service.dart';

class OtpSendResult {
  final bool success;
  final bool isRealEmail;
  final String? otpCode;
  final String message;

  OtpSendResult({
    required this.success,
    required this.isRealEmail,
    this.otpCode,
    required this.message,
  });
}

class _LocalOtpEntry {
  final String otp;
  final DateTime expiresAt;
  final String studentEmail;

  _LocalOtpEntry({
    required this.otp,
    required this.expiresAt,
    required this.studentEmail,
  });
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final Map<String, _LocalOtpEntry> _localOtpCache = {};

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<OtpSendResult> sendStudentVerificationOTP({
    required String studentEmail,
    String? name,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@(dau\.edu\.vn|gmail\.com)$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Email phải có đuôi @dau.edu.vn hoặc @gmail.com!');
    }

    try {
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Email này đã được đăng ký tài khoản!');
      }
    } catch (e) {
      if (e.toString().contains('đã được đăng ký tài khoản')) {
        rethrow;
      }
    }

    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    final docId = cleanEmail.replaceAll('/', '_');
    _localOtpCache[docId] = _LocalOtpEntry(
      otp: otp,
      expiresAt: expiresAt,
      studentEmail: cleanEmail,
    );

    try {
      await _firestore.collection('otp_requests').doc(docId).set({
        'studentEmail': cleanEmail,
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    } catch (_) {}

    final sendResult = await EmailService.sendStudentOtp(
      studentEmail: cleanEmail,
      otp: otp,
      studentName: name,
    );

    if (sendResult.success) {
      return OtpSendResult(
        success: true,
        isRealEmail: true,
        message: 'Mã OTP đã được gửi đến email: $cleanEmail. Vui lòng kiểm tra hộp thư (hoặc mục Spam)!',
      );
    } else {
      final reason = (sendResult.errorMessage != null && sendResult.errorMessage!.isNotEmpty)
          ? sendResult.errorMessage!
          : 'Lỗi kết nối EmailJS';
      return OtpSendResult(
        success: true,
        isRealEmail: false,
        otpCode: otp,
        message: 'Lỗi EmailJS ($reason). Mã OTP dự phòng: $otp',
      );
    }
  }

  Future<UserCredential> verifyOTPAndRegister({
    required String studentEmail,
    required String password,
    required String inputOTP,
    required String name,
    required String studentId,
    required String university,
  }) async {
    final cleanEmail = studentEmail.trim().toLowerCase();
    final trimmedOTP = inputOTP.trim();

    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@(dau\.edu\.vn|gmail\.com)$');
    if (!emailRegex.hasMatch(cleanEmail)) {
      throw Exception('Email phải có đuôi @dau.edu.vn hoặc @gmail.com!');
    }

    if (trimmedOTP.isEmpty) {
      throw Exception('Vui lòng nhập mã OTP!');
    }

    try {
      final existingUser = await _firestore
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (existingUser.docs.isNotEmpty) {
        throw Exception('Email này đã được đăng ký tài khoản!');
      }
    } catch (e) {
      if (e.toString().contains('đã được đăng ký tài khoản')) {
        rethrow;
      }
    }

    final docId = cleanEmail.replaceAll('/', '_');
    String? validOtp;
    DateTime? expiresAt;

    try {
      final otpDoc = await _firestore.collection('otp_requests').doc(docId).get();
      if (otpDoc.exists && otpDoc.data() != null) {
        final data = otpDoc.data()!;
        validOtp = data['otp']?.toString();
        final expTimestamp = data['expiresAt'] as Timestamp?;
        if (expTimestamp != null) {
          expiresAt = expTimestamp.toDate();
        }
      }
    } catch (_) {}

    if (validOtp == null && _localOtpCache.containsKey(docId)) {
      final entry = _localOtpCache[docId]!;
      validOtp = entry.otp;
      expiresAt = entry.expiresAt;
    }

    if (validOtp == null) {
      throw Exception('Chưa có mã OTP nào cho email $cleanEmail. Vui lòng bấm "Lấy OTP" trước!');
    }

    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw Exception('Mã OTP đã hết hiệu lực (quá 5 phút). Vui lòng bấm "Gửi lại OTP"!');
    }

    if (validOtp != trimmedOTP) {
      throw Exception('Mã OTP xác thực không chính xác. Vui lòng kiểm tra lại!');
    }

    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password.trim(),
    );

    if (credential.user != null) {
      try {
        await credential.user!.updateDisplayName(name.trim());
      } catch (_) {}

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': cleanEmail,
        'studentEmail': cleanEmail,
        'studentId': studentId.trim(),
        'msv': studentId.trim(),
        'university': university.trim(),
        'points': 0,
        'inventory': <String>[],
        'equipped': <String, String>{},
        'friends': <String>[],
        'role': 'user',
        'isStudentVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _localOtpCache.remove(docId);
      try {
        await _firestore.collection('otp_requests').doc(docId).delete();
      } catch (_) {}
    }

    return credential;
  }
}