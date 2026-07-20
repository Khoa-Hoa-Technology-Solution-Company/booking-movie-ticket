import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/api/app_exception.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';
import 'verify_2fa_screen.dart';
import '../../app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _animController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeIn = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    super.dispose();
  }

  String _getDeviceName() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'iOS Device';
    } catch (_) {}
    return 'Unknown Device';
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await authService.loginWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        deviceName: _getDeviceName(),
        userAgent: 'Flutter Mobile App',
      );
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const App()));
      }
    } catch (e) {
      if (mounted) {
        final is2FA = e is AuthException && e.code == '2fa_required';
        final isNotVerified = e is AuthException && e.code == 'email_not_confirmed';
        if (!is2FA) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger));
        }
        if (isNotVerified) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: _emailController.text.trim())));
        }
        if (is2FA) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => Verify2FAScreen(email: _emailController.text.trim())));
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    try {
      await authService.loginWithGoogle();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const App()));
    } catch (e) {
      if (mounted) {
        final is2FA = e is AuthException && e.code == '2fa_required';
        if (!is2FA) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: AppColors.danger),
          );
        } else {
          final targetEmail = authService.lastAttemptedEmail ?? '';
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => Verify2FAScreen(email: targetEmail)),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context); // Đăng ký lắng nghe sự kiện đổi theme để vẽ lại giao diện lập tức
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: FadeTransition(
                opacity: _fadeIn,
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo
                      Container(
                        width: 80, height: 80,
                        margin: const EdgeInsets.only(bottom: AppSpacing.base),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10))],
                        ),
                        child: const Icon(Icons.local_movies_rounded, size: 44, color: Colors.black),
                      ),
                      Text('MovieTicket',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const SizedBox(height: 6),
                      Text('Đăng nhập để đặt vé và bảo vệ tài khoản',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body),
                      const SizedBox(height: AppSpacing.xxxl),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary),
                          hintText: 'Nhập email của bạn',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Vui lòng nhập email';
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(v.trim())) return 'Email không hợp lệ';
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                          suffixIcon: GestureDetector(
                            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary, size: 20,
                              ),
                            ),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Vui lòng nhập mật khẩu' : null,
                      ),
                      const SizedBox(height: AppSpacing.xxl),

                      // Login button
                      AppPrimaryButton(
                        label: 'Đăng Nhập',
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                        icon: Icons.login_rounded,
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: AppColors.border)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text('hoặc', style: AppTextStyles.caption),
                          ),
                          Expanded(child: Divider(color: AppColors.border)),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Google login
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _handleGoogleLogin,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: AppColors.border, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/48px-Google_%22G%22_logo.svg.png',
                          height: 18,
                          errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, color: AppColors.danger, size: 20),
                        ),
                        label: Text('Tiếp tục với Google',
                          style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                      const SizedBox(height: AppSpacing.xl),

                      // Register link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Chưa có tài khoản? ', style: AppTextStyles.body),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                            child: Text('Đăng ký ngay',
                              style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
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
      ),
    );
  }
}
