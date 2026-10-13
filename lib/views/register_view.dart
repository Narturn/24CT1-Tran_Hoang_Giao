import 'package:flutter/material.dart';
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
  final _otpController = TextEditingController();           // Mã OTP
  final _emailController = TextEditingController();        // Email cá nhân dùng đăng nhập
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isSendingOtp = false;
  bool _otpSent = false;

  // Gán mặc định tên trường duy nhất
  static const String _defaultUniversity = 'Đại học Kiến trúc Đà Nẵng';

  // Hàm gửi OTP về Email Sinh Viên
  Future<void> _handleSendOTP() async {
    final studentEmail = _studentEmailController.text.trim();
    if (studentEmail.isEmpty || !studentEmail.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Email sinh viên hợp lệ!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      await _authService.sendStudentVerificationOTP(
        studentEmail: studentEmail,
        personalEmail: _emailController.text.trim(),
      );

      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Mã OTP đã được gửi đến Email sinh viên của bạn!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi gửi OTP: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  // Hàm Đăng ký tài khoản
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bấm lấy và nhập mã OTP xác thực trước!'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final studentEmail = _studentEmailController.text.trim();
      // Tự động cắt phần trước @ làm Mã sinh viên (VD: 2011001@dau.edu.vn -> 2011001)
      final studentId = studentEmail.split('@').first;

      await _authService.verifyOTPAndRegister(
        personalEmail: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        studentEmail: studentEmail,
        inputOTP: _otpController.text.trim(),
        name: _nameController.text.trim(),
        studentId: studentId,
        university: _defaultUniversity,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardView()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentEmailController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng Ký Tài Khoản')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Họ và tên
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên tài khoản',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập tên tài khoản (biệt danh)' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Email sinh viên (nhận OTP)',
                        hintText: 'VD: 2011001@dau.edu.vn',
                        prefixIcon: Icon(Icons.mark_email_read),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Vui lòng nhập Email sinh viên';
                        if (!val.contains('@')) return 'Email không hợp lệ';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSendingOtp ? null : _handleSendOTP,
                      child: _isSendingOtp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_otpSent ? 'Gửi lại' : 'Lấy OTP'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Ô Nhập Mã OTP
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mã xác thực OTP (6 chữ số)',
                  prefixIcon: const Icon(Icons.security),
                  border: const OutlineInputBorder(),
                  helperText: _otpSent ? 'Mã OTP đã gửi về Email sinh viên của bạn' : null,
                  helperStyle: const TextStyle(color: Colors.green),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Vui lòng nhập mã OTP' : null,
              ),
              const SizedBox(height: 16),

              // 4. Email cá nhân (Dùng đăng nhập chính & khôi phục)
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email cá nhân (Gmail/Outlook dùng đăng nhập)',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng nhập Email cá nhân';
                  if (!val.contains('@')) return 'Email không hợp lệ';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 5. Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mật khẩu (ít nhất 6 ký tự)',
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
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
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Nhập lại mật khẩu',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Vui lòng xác nhận mật khẩu';
                  if (val != _passwordController.text) return 'Mật khẩu nhập lại không khớp';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Nút Đăng ký
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text('ĐĂNG KÝ NGAY', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}