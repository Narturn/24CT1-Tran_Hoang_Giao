import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});
  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signIn(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent.shade700,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _authError(e),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email hoặc mật khẩu không đúng.';
      case 'invalid-email':
        return 'Email không hợp lệ.';
      case 'too-many-requests':
        return 'Bạn đã thử quá nhiều lần. Vui lòng thử lại sau.';
      default:
        return e.message ?? 'Đăng nhập thất bại.';
    }
  }

  InputDecoration _buildInputDecoration({
    required String label,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: Colors.blueAccent.shade200, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFF0F172A).withValues(alpha: 0.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.blueAccent, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Stack(
        children: [
          // 1. Ánh sáng Ambient Glow trang trí góc trên trái (Xanh dương)
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 380,
              height: 380,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.blueAccent.shade700.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 2. Ánh sáng Ambient Glow góc dưới phải (Tím mộng mơ)
          Positioned(
            bottom: -130,
            right: -90,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.purpleAccent.shade700.withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Khối trung tâm
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 36),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Badge Slogan nhỏ phía trên Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, color: Colors.blueAccent, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'CAMPUSHUB • DAU ARCHITECTURE',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Logo Icon trường tỏa sáng
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blueAccent.withValues(alpha: 0.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blueAccent.shade400.withValues(alpha: 0.45),
                                blurRadius: 35,
                                spreadRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF2563EB),
                                Colors.indigoAccent.shade700,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Tiêu đề & Slogan nổi bật
                    const Text(
                      'Mạng Xã Hội Sinh Viên',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.extrabold,
                        color: Colors.white,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Slogan chính
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          Colors.blue.shade200,
                          Colors.purple.shade200,
                        ],
                      ).createShader(bounds),
                      child: const Text(
                        ' Kết nối tri thức • Chia sẻ đam mê • Chắp cánh tương lai ',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    Text(
                      'Cộng đồng học tập & giải trí dành riêng cho sinh viên DAU',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Các Badge tính năng độc đáo
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildFeatureChip(Icons.forum_rounded, 'Sảnh chém gió', Colors.lightBlueAccent),
                        _buildFeatureChip(Icons.folder_zip_rounded, 'Kho tài liệu', Colors.amberAccent),
                        _buildFeatureChip(Icons.stars_rounded, 'Trạm Review', Colors.greenAccent),
                        _buildFeatureChip(Icons.palette_rounded, 'Profile Decor', Colors.purpleAccent),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Khung Form Đăng nhập Glassmorphism
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.5),
                            blurRadius: 30,
                            offset: const Offset(0, 14),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.blueAccent, Colors.purpleAccent],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Đăng nhập tài khoản',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Ô nhập Email
                              TextFormField(
                                controller: _email,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: _buildInputDecoration(
                                  label: 'Email sinh viên / Gmail',
                                  hint: 'VD: 2011001@dau.edu.vn hoặc ban@gmail.com',
                                  prefixIcon: Icons.alternate_email_rounded,
                                ),
                                validator: (v) =>
                                    v == null || !v.contains('@') ? 'Vui lòng nhập Email hợp lệ' : null,
                              ),
                              const SizedBox(height: 16),

                              // Ô nhập Mật khẩu
                              TextFormField(
                                controller: _password,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _loading ? null : _login(),
                                style: const TextStyle(fontSize: 14, color: Colors.white),
                                decoration: _buildInputDecoration(
                                  label: 'Mật khẩu',
                                  hint: 'Nhập mật khẩu (tối thiểu 6 ký tự)',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                      color: Colors.grey.shade400,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) =>
                                    v == null || v.length < 6 ? 'Mật khẩu tối thiểu 6 ký tự' : null,
                              ),
                              const SizedBox(height: 24),

                              // Nút Đăng nhập Gradient
                              Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blueAccent.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _loading ? null : _login,
                                  child: _loading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.rocket_launch_rounded, size: 19, color: Colors.white),
                                            SizedBox(width: 8),
                                            Text(
                                              'ĐĂNG NHẬP NGAY',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14.5,
                                                letterSpacing: 0.8,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              // Đường phân cách
                              Row(
                                children: [
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'Chưa có tài khoản?',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                                    ),
                                  ),
                                  Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                                ],
                              ),
                              const SizedBox(height: 18),

                              // Nút Chuyển sang Đăng ký
                              SizedBox(
                                height: 46,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blueAccent.shade100,
                                    side: BorderSide(
                                      color: Colors.blueAccent.withValues(alpha: 0.45),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: () => Navigator.pushNamed(context, '/register'),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                                  label: const Text(
                                    'Đăng ký tài khoản sinh viên mới',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Thẻ thống kê nhỏ tạo niềm tin ở chân trang
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('100%', 'Xác thực OTP'),
                          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
                          _buildStatItem('DAU', 'Kiến Trúc ĐN'),
                          Container(width: 1, height: 24, color: Colors.white.withValues(alpha: 0.1)),
                          _buildStatItem('Free', 'Kho tài liệu'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}