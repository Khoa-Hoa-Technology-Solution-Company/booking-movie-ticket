import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';
import 'forgot_password_screen.dart';
import '../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _getDeviceName() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iOS Device';
      if (Platform.isMacOS) return 'MacOS App';
      if (Platform.isWindows) return 'Windows App';
      if (Platform.isLinux) return 'Linux App';
    } catch (_) {}
    return 'Unknown Device';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final email = _identifierController.text.trim();
      final password = _passwordController.text;
      final deviceName = _getDeviceName();

      // 1. Đăng nhập bằng Firebase Auth
      final user = await authService.login(email: email, password: password);
      if (user == null) {
        throw Exception('Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.');
      }

      // 2. Ghi nhận đăng nhập thành công cục bộ (để lưu login history, check thiết bị lạ)
      await securityService.recordLoginLog(deviceName);

      // 3. Kiểm tra trạng thái 2FA từ local securityService
      final dashboard = await securityService.getDashboard();
      final bool twoFactorEnabled = dashboard['twoFactorEnabled'] ?? dashboard['security']?['twoFactorEnabled'] ?? false;

      if (mounted) {
        if (twoFactorEnabled) {
          // Kích hoạt 2FA:
          // a. Đánh dấu phiên hiện tại chưa xác thực 2FA
          await securityService.setTwoFactorVerified(false);

          // b. Sinh mã OTP và in ra Debug Console để phục vụ môi trường demo
          final otp = securityService.generate2FAOTP();
          debugPrint('==================================================');
          debugPrint('[2FA OTP] MÃ XÁC THỰC 2 LỚP CỦA BẠN LÀ: $otp');
          debugPrint('==================================================');

          bool emailSent = false;
          try {
            await authService.send2FASignInLink(email, otp);
            emailSent = true;
          } catch (e) {
            debugPrint('[WARNING] Loi gui email qua Firebase: $e');
            debugPrint('[WARNING] De gui email thuc te, hay bat "Email link (passwordless sign-in)" trong Firebase Console.');
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(emailSent 
                  ? 'Yêu cầu 2FA: Đã gửi email xác thực thành công!'
                  : 'Yêu cầu 2FA: Không gửi được email qua Firebase. Vui lòng xem mã OTP tại Terminal/Console.'),
              backgroundColor: emailSent ? Colors.green : Colors.amber,
              duration: const Duration(seconds: 6),
            ),
          );
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyEmailScreen(
                email: email,
                isTwoFactor: true,
              ),
            ),
          );
        } else {
          // Đăng nhập thành công trực tiếp (Không bật 2FA)
          await securityService.setTwoFactorVerified(true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const App()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF0F0F1A)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.local_movies_rounded,
                      size: 90,
                      color: Color(0xFFC084FC),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Rạp Chiếu Phim',
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Đăng nhập qua Firebase để đặt vé và bảo vệ tài khoản',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Email Field
                    TextFormField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email đăng nhập',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.email, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Nhập email của bạn',
                        hintStyle: const TextStyle(color: Colors.white38),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Vui lòng nhập email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return 'Email không đúng định dạng';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập mật khẩu';
                        }
                        return null;
                      },
                    ),
                    
                    // Forgot Password link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                          );
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Color(0xFFC084FC)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Login Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFC084FC),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text(
                              'Đăng Nhập',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Navigation to Register
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản? ',
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const RegisterScreen()),
                            );
                          },
                          child: const Text(
                            'Đăng ký ngay',
                            style: TextStyle(
                              color: Color(0xFFC084FC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
