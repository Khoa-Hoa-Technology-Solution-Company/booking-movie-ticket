import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';
import 'login_screen.dart';
import '../../app.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final bool isTwoFactor;

  const VerifyEmailScreen({
    super.key,
    required this.email,
    this.isTwoFactor = false,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _otpController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldownTimer() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown == 0) {
        timer.cancel();
      } else {
        setState(() => _resendCooldown--);
      }
    });
  }

  Future<void> _handleCheckVerification() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isTwoFactor) {
        final input = _otpController.text.trim();
        if (input.isEmpty) {
          throw Exception('Vui lòng nhập mã OTP 6 số hoặc dán liên kết đăng nhập từ email.');
        }

        if (input.startsWith('http://') || input.startsWith('https://')) {
          // Người dùng dán liên kết Firebase Sign-In Link
          final user = await authService.verify2FALink(widget.email, input);
          if (user == null) {
            throw Exception('Liên kết xác thực không hợp lệ hoặc đã hết hạn.');
          }
          await securityService.setTwoFactorVerified(true);
        } else {
          // Người dùng nhập mã OTP 6 số
          if (input.length != 6 || int.tryParse(input) == null) {
            throw Exception('Mã OTP phải gồm 6 chữ số hoặc dán liên kết bắt đầu bằng http/https.');
          }

          final isValid = securityService.verifyOTP(input);
          if (!isValid) {
            throw Exception('Mã OTP không đúng hoặc đã hết hạn.');
          }

          await securityService.setTwoFactorVerified(true);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Xác thực 2 lớp thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const App()),
            (route) => false,
          );
        }
      } else {
        final isVerified = await authService.checkEmailVerified();

        if (mounted) {
          if (isVerified) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Xác minh email thành công!'),
                backgroundColor: Colors.green,
              ),
            );

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const App()),
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tài khoản chưa được xác minh. Vui lòng kiểm tra email của bạn và click vào liên kết.'),
                backgroundColor: Colors.amber,
              ),
            );
          }
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

  Future<void> _handleResend() async {
    if (_resendCooldown > 0) return;

    setState(() => _isResending = true);

    try {
      if (widget.isTwoFactor) {
        final otp = securityService.generate2FAOTP();
        debugPrint('==================================================');
        debugPrint('[2FA OTP] MÃ XÁC THỰC 2 LỚP MỚI CỦA BẠN LÀ: $otp');
        debugPrint('==================================================');
      } else {
        await authService.sendEmailVerification();
      }
      _startCooldownTimer();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isTwoFactor
                ? 'Đã tạo mã OTP mới! Vui lòng xem Debug Console.'
                : 'Liên kết xác minh mới đã được gửi!'),
            backgroundColor: Colors.green,
          ),
        );
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
      if (mounted) setState(() => _isResending = false);
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    widget.isTwoFactor ? Icons.security_rounded : Icons.mark_email_unread_rounded,
                    size: 80,
                    color: const Color(0xFFC084FC),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.isTwoFactor ? 'Xác Thực 2 Lớp (2FA)' : 'Xác Minh Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isTwoFactor
                        ? 'Tài khoản đã kích hoạt 2FA. Vui lòng nhập mã OTP hoặc dán liên kết đăng nhập:\n${widget.email}'
                        : 'Chúng tôi đã gửi liên kết xác minh email qua Firebase vào địa chỉ:\n${widget.email}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.isTwoFactor
                        ? 'Nếu bạn đã kích hoạt "Email link" trong Firebase Console, một email chứa liên kết đăng nhập sẽ được gửi tới bạn. Nếu chưa bật, vui lòng sử dụng mã OTP hiển thị tại Debug Console.'
                        : 'Vui lòng mở hộp thư, click vào liên kết để xác nhận, sau đó quay lại ứng dụng và bấm nút bên dưới.',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.isTwoFactor) ...[
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelText: 'Mã OTP hoặc Liên kết xác thực (2FA)',
                        labelStyle: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        prefixIcon: const Icon(Icons.security, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Nhập OTP 6 số hoặc dán liên kết tại đây...',
                        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Check Verification Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleCheckVerification,
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
                        : Text(
                            widget.isTwoFactor ? 'Xác Minh & Đăng Nhập' : 'Tôi Đã Xác Minh Qua Link',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Resend Button
                  TextButton(
                    onPressed: (_resendCooldown > 0 || _isResending) ? null : _handleResend,
                    child: _isResending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _resendCooldown > 0
                                ? 'Gửi lại mã sau ${_resendCooldown}s'
                                : (widget.isTwoFactor ? 'Gửi lại mã OTP' : 'Gửi lại liên kết xác minh'),
                            style: TextStyle(
                              color: _resendCooldown > 0 ? Colors.white38 : const Color(0xFFC084FC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Back to Login
                  GestureDetector(
                    onTap: () async {
                      await authService.logout();
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text(
                      'Quay lại Đăng nhập',
                      style: TextStyle(color: Colors.white70, decoration: TextDecoration.underline),
                      textAlign: TextAlign.center,
                    ),
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
