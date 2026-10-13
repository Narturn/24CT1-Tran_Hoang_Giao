import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'email_service.dart';

class OtpSendResult {
  final bool success;
  final bool isRealEmail;
  final String? otpCode; // Dùng để hiển thị trong môi trường demo/thử nghiệm khi chưa cấu hình EmailJS
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

  // Bộ nhớ đệm tạm thời cho OTP để hỗ trợ test mượt mà
  static final Map<String, _LocalOtpEntry> _localOtpCache = {};

  // 1. Stream lắng nghe trạng thái đăng nhập (dùng ở main.dart)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 2. Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // 3. Hàm Đăng nhập bằng Email & Mật khẩu (dùng ở login_view.dart)
  // Lưu ý: Đăng nhập bằng EMAIL CÁ NHÂN chính thức của người dùng
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  // 4. Hàm Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 5. Hàm gửi OTP xác thực đến Email sinh viên (...@dau.edu.vn)
  Future<OtpSendResult> sendStudentVerificationOTP({
    required String studentEmail,
    required String personalEmail,
    String? name,
  }) async {
    final cleanStudentEmail = studentEmail.trim().toLowerCase();
    final cleanPersonalEmail = personalEmail.trim().toLowerCase();

    // Kiểm tra định dạng Email sinh viên Đại học Kiến trúc Đà Nẵng
    final dauEmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@dau\.edu\.vn$');
    if (!dauEmailRegex.hasMatch(cleanStudentEmail)) {
      throw Exception('Email sinh viên phải có đuôi @dau.edu.vn (VD: 2011001@dau.edu.vn)!');
    }

    // Kiểm tra email cá nhân không được trùng email sinh viên
    if (cleanPersonalEmail.isNotEmpty && cleanPersonalEmail == cleanStudentEmail) {
      throw Exception('Email cá nhân dùng đăng nhập không được trùng với Email sinh viên!');
    }

    // Kiểm tra xem Email sinh viên này đã được liên kết với tài khoản nào chưa
    try {
      final existingStudent = await _firestore
          .collection('users')
          .where('studentEmail', isEqualTo: cleanStudentEmail)
          .limit(1)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        throw Exception('Email sinh viên này đã được liên kết với một tài khoản khác!');
      }
    } catch (e) {
      if (e.toString().contains('liên kết với một tài khoản khác')) {
        rethrow;
      }
    }

    // Sinh ngẫu nhiên mã OTP 6 chữ số
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();
    final expiresAt = DateTime.now().add(const Duration(minutes: 5));

    // Lưu mã OTP vào Firestore & Cache bộ nhớ
    final docId = cleanStudentEmail.replaceAll('/', '_');
    _localOtpCache[docId] = _LocalOtpEntry(
      otp: otp,
      expiresAt: expiresAt,
      studentEmail: cleanStudentEmail,
    );

    try {
      await _firestore.collection('otp_requests').doc(docId).set({
        'studentEmail': cleanStudentEmail,
        'personalEmail': cleanPersonalEmail,
        'otp': otp,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    } catch (_) {
      // Nếu Firestore rules chưa mở hoặc offline, bộ nhớ đệm _localOtpCache vẫn đảm bảo xác thực
    }

    // Gửi OTP đến hộp thư sinh viên qua EmailService (EmailJS)
    final isRealSent = await EmailService.sendStudentOtp(
      studentEmail: cleanStudentEmail,
      otp: otp,
      studentName: name,
    );

    if (isRealSent) {
      return OtpSendResult(
        success: true,
        isRealEmail: true,
        message: 'Mã OTP đã được gửi đến email sinh viên: $cleanStudentEmail',
      );
    } else {
      return OtpSendResult(
        success: true,
        isRealEmail: false,
        otpCode: otp,
        message: 'Mã OTP thử nghiệm: $otp (do chưa cấu hình EmailJS)',
      );
    }
  }

  // 6. Hàm xác thực OTP và Đăng ký tài khoản
  // - Email đăng nhập chính: personalEmail (Gmail/Outlook cá nhân)
  // - Email sinh viên: studentEmail (chỉ dùng để xác thực và cấp mã SV)
  Future<UserCredential> verifyOTPAndRegister({
    required String personalEmail,
    required String password,
    required String studentEmail,
    required String inputOTP,
    required String name,
    required String studentId,
    required String university,
  }) async {
    final cleanStudentEmail = studentEmail.trim().toLowerCase();
    final cleanPersonalEmail = personalEmail.trim().toLowerCase();
    final trimmedOTP = inputOTP.trim();

    // 1. Kiểm tra email sinh viên
    final dauEmailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@dau\.edu\.vn$');
    if (!dauEmailRegex.hasMatch(cleanStudentEmail)) {
      throw Exception('Email sinh viên phải có đuôi @dau.edu.vn (VD: 2011001@dau.edu.vn)!');
    }

    if (trimmedOTP.isEmpty) {
      throw Exception('Vui lòng nhập mã OTP!');
    }

    // 2. Kiểm tra email cá nhân không được trùng email sinh viên
    if (cleanPersonalEmail == cleanStudentEmail) {
      throw Exception('Email cá nhân dùng đăng nhập không được trùng với Email sinh viên!');
    }

    // 3. Kiểm tra xem email sinh viên này đã có tài khoản nào đăng ký trước đó chưa
    try {
      final existingStudent = await _firestore
          .collection('users')
          .where('studentEmail', isEqualTo: cleanStudentEmail)
          .limit(1)
          .get();

      if (existingStudent.docs.isNotEmpty) {
        throw Exception('Email sinh viên này đã được liên kết với một tài khoản khác!');
      }
    } catch (e) {
      if (e.toString().contains('liên kết với một tài khoản khác')) {
        rethrow;
      }
    }

    // 4. Lấy mã OTP từ Firestore hoặc Memory Cache
    final docId = cleanStudentEmail.replaceAll('/', '_');
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
      throw Exception('Chưa có mã OTP nào cho email $cleanStudentEmail. Vui lòng bấm "Lấy OTP" trước!');
    }

    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      throw Exception('Mã OTP đã hết hiệu lực (quá 5 phút). Vui lòng bấm "Gửi lại OTP"!');
    }

    if (validOtp != trimmedOTP) {
      throw Exception('Mã OTP xác thực không chính xác. Vui lòng kiểm tra lại!');
    }

    // 5. Đăng ký tài khoản Firebase Auth bằng EMAIL CÁ NHÂN làm email chính đăng nhập
    UserCredential credential = await _auth.createUserWithEmailAndPassword(
      email: cleanPersonalEmail,
      password: password.trim(),
    );

    // 6. Cập nhật Display Name và Lưu thông tin sinh viên vào Firestore
    if (credential.user != null) {
      try {
        await credential.user!.updateDisplayName(name.trim());
      } catch (_) {}

      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': name.trim(),
        'email': cleanPersonalEmail,          // Email đăng nhập chính
        'personalEmail': cleanPersonalEmail,  // Email cá nhân
        'studentEmail': cleanStudentEmail,    // Email sinh viên (chỉ để xác thực)
        'studentId': studentId.trim(),
        'msv': studentId.trim(),              // Mã sinh viên DAU
        'university': university.trim(),
        'points': 0,
        'inventory': <String>[],
        'equipped': <String, String>{},
        'friends': <String>[],
        'role': 'user',
        'isStudentVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 7. Dọn dẹp mã OTP sau khi xác nhận thành công
      _localOtpCache.remove(docId);
      try {
        await _firestore.collection('otp_requests').doc(docId).delete();
      } catch (_) {}
    }

    return credential;
  }
}