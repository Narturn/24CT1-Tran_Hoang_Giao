import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:emailjs/emailjs.dart';

class EmailSendResult {
  final bool success;
  final String? errorMessage;

  EmailSendResult({
    required this.success,
    this.errorMessage,
  });
}

class EmailService {
  // Cấu hình EmailJS từ người dùng
  static const String _serviceId = 'service_q3zazbn';
  static const String _templateId = 'template_oeykbq9';
  static const String _publicKey = 'oEjGs5K_T0q-LbY34';

  /// Gửi mã OTP xác thực đến Email (Gmail hoặc Email sinh viên)
  static Future<EmailSendResult> sendStudentOtp({
    required String studentEmail,
    required String otp,
    String? studentName,
  }) async {
    return sendOtp(
      targetEmail: studentEmail,
      otp: otp,
      studentName: studentName,
    );
  }

  /// Hàm gửi OTP linh hoạt với đầy đủ biến template
  static Future<EmailSendResult> sendOtp({
    required String targetEmail,
    required String otp,
    String? studentName,
  }) async {
    final cleanEmail = targetEmail.trim().toLowerCase();
    if (cleanEmail.isEmpty) {
      return EmailSendResult(success: false, errorMessage: 'Địa chỉ email rỗng');
    }

    if (_publicKey.isEmpty || _publicKey == 'THAY_PUBLIC_KEY_CUABAN_VAO_DAY') {
      debugPrint('⚠️ EmailJS: Public Key chưa được cấu hình.');
      return EmailSendResult(
        success: false,
        errorMessage: 'Chưa cấu hình Public Key EmailJS',
      );
    }

    final name = (studentName != null && studentName.trim().isNotEmpty)
        ? studentName.trim()
        : 'Sinh viên';

    // Tập hợp đầy đủ các tên tham số phổ biến trong template EmailJS
    final templateParams = <String, dynamic>{
      'to_email': cleanEmail,
      'email': cleanEmail,
      'user_email': cleanEmail,
      'student_email': cleanEmail,
      'reply_to': cleanEmail,
      'otp_code': otp,
      'otp': otp,
      'code': otp,
      'passcode': otp,
      'student_name': name,
      'to_name': name,
      'user_name': name,
      'name': name,
      'message':
          'Mã OTP xác thực của bạn là: $otp (hiệu lực trong 5 phút). Tuyệt đối không chia sẻ mã này cho người khác.',
    };

    String? lastError;

    // 1. Thử gửi qua EmailJS Flutter SDK chính thức
    try {
      final response = await EmailJS.send(
        _serviceId,
        _templateId,
        templateParams,
        const Options(publicKey: _publicKey),
      );

      if (response.status == 200) {
        debugPrint('✅ EmailJS SDK: Gửi OTP thành công tới $cleanEmail');
        return EmailSendResult(success: true);
      }
    } catch (e) {
      lastError = e.toString();
      debugPrint('⚠️ EmailJS SDK error ($e), đang thử fallback qua HTTP REST API...');
    }

    // 2. Dự phòng: Gửi trực tiếp qua EmailJS REST API
    try {
      final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (!kIsWeb) {
        headers['origin'] = 'http://localhost';
      }

      final httpResponse = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'service_id': _serviceId,
          'template_id': _templateId,
          'user_id': _publicKey,
          'template_params': templateParams,
        }),
      );

      if (httpResponse.statusCode == 200) {
        debugPrint('✅ EmailJS HTTP: Gửi OTP thành công tới $cleanEmail');
        return EmailSendResult(success: true);
      } else {
        final errorBody = httpResponse.body.isNotEmpty
            ? httpResponse.body
            : 'Mã phản hồi HTTP ${httpResponse.statusCode}';
        debugPrint('❌ EmailJS HTTP Error: [${httpResponse.statusCode}] $errorBody');
        return EmailSendResult(
          success: false,
          errorMessage: errorBody,
        );
      }
    } catch (e) {
      debugPrint('❌ Lỗi ngoại lệ khi gửi EmailJS HTTP: $e');
      return EmailSendResult(
        success: false,
        errorMessage: lastError ?? e.toString(),
      );
    }
  }
}