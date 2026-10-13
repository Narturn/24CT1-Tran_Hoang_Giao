import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'dashboard_view.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _studentEmailController = TextEditingController(); // Email trường để nhận OTP
  final _otpController = TextEditingController();          // Mã OTP xác thực
  final _emailController = TextEditingController();       // Email cá nhân dùng đăng nhập
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();

  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Quản lý đếm ngược thời gian gửi lại OTP (60s)
  Timer? _countdownTimer;
  int _countdown = 0;
  String? _sentToStudentEmail;

  // Gán mặc định tên trường duy nhất
  static const String _defaultUniversity = 'Đại học Kiến trúc Đà Nẵng';

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _nameController.dispose();
    _studentEmailController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Bắt đầu đếm ngược 60 giây tránh spam gửi OTP
  void _startCountdown() {
    setState(() => _countdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() => _countdown--);
      } else {
        timer.cancel();
      }
    });
  }

  // Kiểm tra định dạng Email sinh viên Đại học Kiến trúc Đà Nẵng
  bool _isDauStudentEmail(String email) {
    final clean = email.trim().toLowerCase();
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@dau\.edu\.vn$');
    return regex.hasMatch(clean);
  }

  // 1. Hàm gửi OTP về Email Sinh Viên
  Future<void> _handleSendOTP() async {
    final studentEmail = _studentEmailController.text.trim();

    if (studentEmail.isEmpty) {
      _showSnackbar('Vui lòng nhập Email sinh viên trước!', isError: true);
      return;
    }

    if (!_isDauStudentEmail(studentEmail)) {
      _showSnackbar(
        'Email sinh viên bắt buộc phải có đuôi @dau.edu.vn (VD: name_24512200xx@dau.edu.vn)!',
        isError: true,
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      final result = await _authService.sendStudentVerificationOTP(
        studentEmail: studentEmail,
        personalEmail: _emailController.text.trim(),
        name: _nameController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _otpSent = true;
          _sentToStudentEmail = studentEmail.toLowerCase();
        });
        _startCountdown();

        if (result.isRealEmail) {
          _showSnackbar('🎉 ${result.message}', isSuccess: true);
        } else {
          // Thông báo hỗ trợ test trực tiếp khi chưa cấu hình EmailJS
          _showSnackbar(
            '⚡ [CHẾ ĐỘ TEST] Mã OTP của bạn là: ${result.otpCode}\n(Do chưa cấu hình EmailJS, hệ thống hiển thị trực tiếp mã OTP để bạn thử nghiệm).',
            isWarning: true,
            durationSeconds: 8,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Lỗi gửi OTP: ${_formatError(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  // 2. Hàm Đăng ký tài khoản
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final studentEmail = _studentEmailController.text.trim().toLowerCase();
    final personalEmail = _emailController.text.trim().toLowerCase();

    // Kiểm tra đã lấy OTP chưa
    if (!_otpSent || _sentToStudentEmail == null) {
      _showSnackbar('Vui lòng bấm "Lấy OTP" để xác thực email sinh viên trước!', isWarning: true);
      return;
    }

    // Kiểm tra xem email sinh viên có bị thay đổi sau khi gửi OTP không
    if (studentEmail != _sentToStudentEmail) {
      _showSnackbar(
        'Email sinh viên đã bị thay đổi so với mã OTP được gửi! Vui lòng bấm "Lấy OTP" lại.',
        isWarning: true,
      );
      return;
    }

    // Kiểm tra email cá nhân không được trùng email sinh viên
    if (personalEmail == studentEmail) {
      _showSnackbar(
        'Email cá nhân (dùng đăng nhập) không được trùng với Email sinh viên (xác thực)!',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Tự động cắt phần trước @ làm Mã sinh viên (VD: 2011001@dau.edu.vn -> 2011001)
      final studentId = studentEmail.split('@').first;

      await _authService.verifyOTPAndRegister(
        personalEmail: personalEmail,
        password: _passwordController.text.trim(),
        studentEmail: studentEmail,
        inputOTP: _otpController.text.trim(),
        name: _nameController.text.trim(),
        studentId: studentId,
        university: _defaultUniversity,
      );

      if (mounted) {
        _showSnackbar('🎉 Đăng ký tài khoản thành công!', isSuccess: true);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String msg = 'Đăng ký thất bại';
        if (e.code == 'email-already-in-use') {
          msg = 'Email cá nhân này đã được đăng ký tài khoản trước đó!';
        } else if (e.code == 'weak-password') {
          msg = 'Mật khẩu quá yếu (cần tối thiểu 6 ký tự).';
        } else if (e.code == 'invalid-email') {
          msg = 'Email cá nhân không hợp lệ.';
        } else {
          msg = e.message ?? msg;
        }
        _showSnackbar(msg, isError: true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackbar('Đăng ký thất bại: ${_formatError(e)}', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
    bool isWarning = false,
    int durationSeconds = 4,
  }) {
    Color bg = Colors.grey.shade800;
    if (isError) bg = Colors.redAccent.shade700;
    if (isSuccess) bg = Colors.green.shade700;
    if (isWarning) bg = Colors.blueAccent.shade700;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: bg,
        duration: Duration(seconds: durationSeconds),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatError(dynamic e) {
    String msg = e.toString();
    if (msg.startsWith('Exception: ')) {
      msg = msg.substring(11);
    }
    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng Ký Tài Khoản Sinh Viên'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // --- THẺ GIẢI THÍCH QUY TRÌNH ---
                  Card(
                    color: Colors.blue.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.blue.shade700.withValues(alpha: 0.3)),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(14.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_user, color: Colors.blueAccent, size: 28),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cơ chế xác thực Sinh viên DAU',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  '• Email sinh viên (...@dau.edu.vn) dùng để nhận mã OTP xác minh là sinh viên trường.\n'
                                  '• Email cá nhân (Gmail, Outlook...) là tài khoản chính thức dùng để ĐĂNG NHẬP.',
                                  style: TextStyle(fontSize: 12, height: 1.4, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 1. Họ và tên / Tên hiển thị
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Họ và tên / Tên hiển thị',
                      hintText: 'VD: Hoàng Văn A',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.trim().isEmpty ? 'Vui lòng nhập họ tên hoặc biệt danh' : null,
                  ),
                  const SizedBox(height: 16),

                  // 2. Email Sinh Viên (Nhận OTP) + Nút Lấy mã
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _studentEmailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email sinh viên DAU',
                            hintText: 'VD: 2011001@dau.edu.vn',
                            prefixIcon: const Icon(Icons.school_outlined),
                            border: const OutlineInputBorder(),
                            helperText: 'Bắt buộc có đuôi @dau.edu.vn (dùng nhận OTP)',
                            helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Vui lòng nhập Email sinh viên';
                            }
                            if (!_isDauStudentEmail(val)) {
                              return 'Email phải có đuôi @dau.edu.vn';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _countdown > 0 ? Colors.grey.shade800 : Colors.blue.shade700,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: (_isSendingOtp || _countdown > 0) ? null : _handleSendOTP,
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  _countdown > 0
                                      ? 'Lại (${_countdown}s)'
                                      : (_otpSent ? 'Gửi lại' : 'Lấy OTP'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 3. Ô Nhập Mã OTP (6 chữ số)
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Mã xác thực OTP (6 chữ số)',
                      hintText: 'Nhập mã 6 chữ số đã gửi về email SV',
                      prefixIcon: const Icon(Icons.security),
                      border: const OutlineInputBorder(),
                      counterText: '',
                      helperText: _otpSent
                          ? '✅ Đã gửi mã OTP đến ${_sentToStudentEmail ?? "email sinh viên"}'
                          : null,
                      helperStyle: const TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập mã OTP';
                      if (val.trim().length != 6) return 'Mã OTP gồm đúng 6 chữ số';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 4. Email cá nhân (Dùng đăng nhập chính)
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email cá nhân (Gmail/Outlook dùng ĐĂNG NHẬP)',
                      hintText: 'VD: ABC@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      helperText: 'Tài khoản chính thức để đăng nhập app & nhận tin',
                      helperStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Vui lòng nhập Email cá nhân';
                      final clean = val.trim().toLowerCase();
                      if (!clean.contains('@') || !clean.contains('.')) return 'Email không hợp lệ';
                      if (clean.endsWith('@dau.edu.vn')) {
                        return 'Vui lòng dùng Gmail/Email cá nhân (không dùng @dau.edu.vn) để đăng nhập';
                      }
                      if (clean == _studentEmailController.text.trim().toLowerCase()) {
                        return 'Email cá nhân không được trùng với Email sinh viên';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Mật khẩu
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu (tối thiểu 6 ký tự)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Vui lòng nhập mật khẩu';
                      if (val.length < 6) return 'Mật khẩu phải từ 6 ký tự trở lên';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 6. Nhập lại Mật khẩu
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Xác nhận lại mật khẩu',
                      prefixIcon: const Icon(Icons.lock_reset),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    validator: (val) {
                      if (val == null || val.isEmpty) return 'Vui lòng nhập lại mật khẩu';
                      if (val != _passwordController.text) return 'Mật khẩu nhập lại không khớp';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Nút Đăng ký
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Text(
                              'ĐĂNG KÝ TÀI KHOẢN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Chuyển sang màn hình Đăng nhập
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Đã có tài khoản?', style: TextStyle(color: Colors.grey)),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Đăng nhập ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}