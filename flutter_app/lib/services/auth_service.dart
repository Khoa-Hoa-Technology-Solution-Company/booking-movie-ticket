import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import '../core/storage/token_storage.dart';
import 'security_service.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;

  /// Đăng ký tài khoản bằng Firebase Auth
  Future<fb.User?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final creds = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final user = creds.user;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload(); // Reload to apply name change
        // Tự động gửi link xác thực email qua Firebase
        await user.sendEmailVerification();
      }
      return _auth.currentUser;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng ký thất bại.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Đăng nhập bằng Firebase Auth
  Future<fb.User?> login({
    required String email,
    required String password,
  }) async {
    try {
      final creds = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return creds.user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Đăng nhập thất bại.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Gửi email đặt lại mật khẩu (Quên mật khẩu)
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Không thể gửi email đặt lại mật khẩu.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Gửi link xác thực email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.sendEmailVerification();
      }
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Không thể gửi link xác thực email.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Kiểm tra xem email đã được xác thực hay chưa
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        return _auth.currentUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking email verification status: $e');
      return false;
    }
  }

  /// Đăng xuất khỏi Firebase Auth
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await TokenStorage.clearTokens();
      await securityService.clearTwoFactorSession();
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }

  /// Gửi link đăng nhập qua email để xác thực 2 lớp (MFA)
  Future<void> send2FASignInLink(String email, String otp) async {
    try {
      final actionCodeSettings = fb.ActionCodeSettings(
        url: 'https://fir-8e3c4.firebaseapp.com/verify-2fa?email=${Uri.encodeComponent(email)}&otp=$otp',
        handleCodeInApp: true,
        androidPackageName: 'com.movieapp.flutter_app',
        androidMinimumVersion: '12',
        androidInstallApp: true,
      );
      await _auth.sendSignInLinkToEmail(
        email: email.trim(),
        actionCodeSettings: actionCodeSettings,
      );
      debugPrint('[AUTH] Da gui link dang nhap 2FA chua OTP $otp toi $email');
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Không thể gửi email xác thực.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Xác thực bằng link đăng nhập 2FA và hoàn tất đăng nhập
  Future<fb.User?> verify2FALink(String email, String emailLink) async {
    try {
      if (!_auth.isSignInWithEmailLink(emailLink)) {
        throw Exception('Đường dẫn xác thực không đúng định dạng của Firebase.');
      }
      final creds = await _auth.signInWithEmailLink(
        email: email.trim(),
        emailLink: emailLink.trim(),
      );
      return creds.user;
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Xác thực liên kết thất bại hoặc đã hết hạn.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  /// Kiểm tra trạng thái đã đăng nhập
  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }

  /// Lấy thông tin user hiện tại
  fb.User? get currentUser => _auth.currentUser;
}

final authService = AuthService();
