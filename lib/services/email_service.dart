import 'dart:developer' as developer;
import 'package:emailjs/emailjs.dart' as emailjs;

/// Dịch vụ gửi email thông qua EmailJS (https://www.emailjs.com/)
/// Giúp gửi email OTP trực tiếp từ Flutter đến sinh viên mà không cần backend riêng.
class EmailService {
  // ===========================================================================
  // ⚙️ CẤU HÌNH EMAILJS:
  // Bạn có thể đăng ký tài khoản miễn phí tại https://www.emailjs.com/
  // (Miễn phí 200 email/tháng, đủ cho nhu cầu đồ án/demo).
  //
  // 1. serviceId: Lấy từ mục 'Email Services' (VD: 'service_xxxxxx')
  // 2. templateId: Lấy từ mục 'Email Templates' (VD: 'template_xxxxxx')
  // 3. publicKey: Lấy từ mục 'Account' -> 'API Keys' -> 'Public Key' (VD: 'user_xxxx' hoặc 'pub_xxxx')
  // ===========================================================================
  static const String serviceId = 'YOUR_SERVICE_ID';
  static const String templateId = 'YOUR_TEMPLATE_ID';
  static const String publicKey = 'YOUR_PUBLIC_KEY';
  static const String? privateKey = null; // Tùy chọn nếu bật private key

  /// Kiểm tra xem người dùng đã cấu hình khóa EmailJS hay chưa
  static bool get isConfigured =>
      serviceId.isNotEmpty &&
      serviceId != 'YOUR_SERVICE_ID' &&
      templateId.isNotEmpty &&
      templateId != 'YOUR_TEMPLATE_ID' &&
      publicKey.isNotEmpty &&
      publicKey != 'YOUR_PUBLIC_KEY';

  /// Gửi mã OTP xác nhận về địa chỉ Email sinh viên
  /// - Trả về `true` nếu đã gửi email thực tế thành công qua EmailJS.
  /// - Trả về `false` nếu chưa cấu hình EmailJS (hệ thống sẽ hoạt động ở chế độ Demo/Test).
  static Future<bool> sendStudentOtp({
    required String studentEmail,
    required String otp,
    String? studentName,
  }) async {
    if (!isConfigured) {
      developer.log(
        '⚠️ EmailJS chưa được cấu hình khóa (serviceId/templateId/publicKey). '
        'Hệ thống đang chạy ở chế độ TEST DEMO.\n'
        '👉 Mã OTP gửi đến $studentEmail là: $otp',
        name: 'EmailService',
      );
      return false; // Chế độ Test/Demo
    }

    try {
      final templateParams = {
        'to_email': studentEmail,
        'email': studentEmail,
        'student_email': studentEmail,
        'to_name': studentName ?? studentEmail.split('@').first,
        'otp': otp,
        'otp_code': otp,
        'university': 'Đại học Kiến trúc Đà Nẵng',
        'message':
            'Mã OTP xác thực sinh viên Trường ĐH Kiến trúc Đà Nẵng của bạn là: $otp. Mã có hiệu lực trong 5 phút.',
      };

      await emailjs.send(
        serviceId,
        templateId,
        templateParams,
        const emailjs.Options(
          publicKey: publicKey,
          privateKey: privateKey,
        ),
      );

      developer.log(
        '✅ Đã gửi thành công email OTP đến $studentEmail qua EmailJS',
        name: 'EmailService',
      );
      return true;
    } catch (e) {
      developer.log(
        '❌ Lỗi khi gửi OTP qua EmailJS: $e',
        name: 'EmailService',
        error: e,
      );
      rethrow;
    }
  }
}
