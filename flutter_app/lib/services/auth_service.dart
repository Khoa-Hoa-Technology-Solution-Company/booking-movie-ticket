import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../config/supabase_config.dart';
import '../core/api/app_exception.dart';
import '../models/user.dart';

abstract class IAuthService {
  /// Stream lắng nghe thay đổi trạng thái đăng nhập
  Stream<User?> get onAuthStateChanged;

  /// Lấy thông tin user hiện tại đang đăng nhập
  Future<User?> get currentUser;

  /// Đăng ký tài khoản mới bằng Email/Password
  Future<User> register({
    required String name,
    required String email,
    required String password,
  });

  /// Đăng nhập bằng Email/Password
  Future<User> loginWithEmail({
    required String email,
    required String password,
    required String deviceName,
    required String userAgent,
  });

  /// Đăng nhập bằng Google
  Future<User> loginWithGoogle();

  /// Đăng xuất khỏi hệ thống
  Future<void> logout();

  /// Kiểm tra trạng thái đăng nhập
  Future<bool> isLoggedIn();

  /// Xác minh Email đăng ký bằng mã OTP/token
  Future<void> verifyEmail({
    required String email,
    required String code,
  });

  /// Gửi lại mã xác minh Email
  Future<void> resendEmailCode({
    required String email,
  });

  /// Xác minh OTP 2FA khi đăng nhập
  Future<User> verify2FA({
    required String email,
    required String code,
  });

  /// Gửi lại mã OTP 2FA
  Future<void> resend2FACode({
    required String email,
  });
}

class AuthService implements IAuthService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Stream<User?> get onAuthStateChanged {
    return _supabase.auth.onAuthStateChange.asyncMap((event) async {
      final session = event.session;
      if (session == null) return null;
      return await _fetchUserProfile(session.user.id);
    });
  }

  @override
  Future<User?> get currentUser async {
    final sbUser = _supabase.auth.currentUser;
    if (sbUser == null) return null;
    return await _fetchUserProfile(sbUser.id);
  }

  Future<User?> _fetchUserProfile(String id) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (response == null) return null;
      return User.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  @override
  Future<User> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );
      
      final sbUser = response.user;
      if (sbUser == null) {
        throw AuthException('Đăng ký không thành công. Vui lòng thử lại.');
      }
      
      // Khi Supabase bật email confirmation, sau signUp không có session,
      // nên RLS sẽ chặn SELECT trên public.users.
      // Thử fetch profile trước (thành công nếu tắt email confirmation).
      User? user;
      for (int i = 0; i < 3; i++) {
        user = await _fetchUserProfile(sbUser.id);
        if (user != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Nếu không fetch được (do RLS chặn vì chưa verify email),
      // tạo User tạm từ dữ liệu signUp response để app chuyển sang verify email screen.
      if (user == null) {
        user = User(
          id: sbUser.id,
          name: name,
          email: email,
          role: UserRole.user,
          emailVerified: false,
          twoFactorEnabled: false,
          failedLoginAttempts: 0,
          createdAt: DateTime.now(),
        );
      }
      
      return user;
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Đã xảy ra lỗi trong quá trình đăng ký: $e');
    }
  }

  @override
  Future<User> loginWithEmail({
    required String email,
    required String password,
    required String deviceName,
    required String userAgent,
  }) async {
    try {
      // 1. Thực hiện đăng nhập qua Supabase Auth trước (để lấy session của user đó)
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final sbUser = response.user;
      if (sbUser == null) {
        throw AuthException('Đăng nhập không thành công.');
      }

      // 2. Lấy profile (lúc này đã có session nên RLS cho phép đọc)
      final userProfile = await _supabase
          .from('users')
          .select('locked_until, failed_login_attempts, two_factor_enabled')
          .eq('id', sbUser.id)
          .single();

      // 3. Kiểm tra xem tài khoản có bị khóa không
      final lockedUntilStr = userProfile['locked_until'] as String?;
      if (lockedUntilStr != null) {
        final lockedUntil = DateTime.parse(lockedUntilStr).toLocal();
        if (lockedUntil.isAfter(DateTime.now())) {
          // Ghi nhận lịch sử đăng nhập thất bại do bị khóa tài khoản
          await _logLoginHistory(
            userId: sbUser.id,
            email: email,
            deviceName: deviceName,
            userAgent: userAgent,
            success: false,
            reason: 'Tài khoản đang bị khóa tạm thời',
          );
          
          // Đăng xuất ngay lập tức
          await _supabase.auth.signOut();

          final waitMin = lockedUntil.difference(DateTime.now()).inMinutes + 1;
          throw AuthException('Tài khoản đã bị khóa do đăng nhập sai nhiều lần. Vui lòng thử lại sau $waitMin phút.', 'user_locked');
        }
      }

      // 4. Kiểm tra xem 2FA có được bật không
      final is2FAEnabled = userProfile['two_factor_enabled'] == true;
      if (is2FAEnabled) {
        // Gửi OTP 2FA thông qua Supabase signInWithOtp
        await _supabase.auth.signInWithOtp(email: email);
        // Đăng xuất ngay lập tức để huỷ session vừa tạo bằng password
        await _supabase.auth.signOut();
        // Ném exception để UI chuyển sang Verify2FAScreen
        throw AuthException('Yêu cầu xác thực 2 bước (2FA).', '2fa_required');
      }

      // 5. Reset failed login attempts & update last_login_at
      await _supabase.from('users').update({
        'failed_login_attempts': 0,
        'locked_until': null,
        'last_login_at': DateTime.now().toIso8601String(),
      }).eq('id', sbUser.id);

      // 6. Lấy profile đầy đủ
      final user = await _fetchUserProfile(sbUser.id);
      if (user == null) {
        throw AuthException('Không tìm thấy thông tin tài khoản người dùng.');
      }

      // 7. Ghi lịch sử đăng nhập thành công
      await _logLoginHistory(
        userId: sbUser.id,
        email: email,
        deviceName: deviceName,
        userAgent: userAgent,
        success: true,
      );

      return user;
    } on sb.AuthException catch (e) {
      // Cập nhật số lần đăng nhập sai
      await _handleFailedLogin(email, deviceName, userAgent, e.message);
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Đăng nhập thất bại: $e');
    }
  }

  Future<void> _handleFailedLogin(String email, String deviceName, String userAgent, String reason) async {
    try {
      final userProfile = await _supabase
          .from('users')
          .select('id, failed_login_attempts')
          .eq('email', email)
          .maybeSingle();

      if (userProfile != null) {
        final userId = userProfile['id'] as String;
        final currentAttempts = (userProfile['failed_login_attempts'] as int? ?? 0) + 1;
        
        final updates = <String, dynamic>{
          'failed_login_attempts': currentAttempts,
        };

        String failReason = 'Sai mật khẩu (Lần $currentAttempts)';
        
        if (currentAttempts >= 5) {
          final lockoutTime = DateTime.now().add(const Duration(minutes: 5)).toIso8601String();
          updates['locked_until'] = lockoutTime;
          failReason = 'Sai mật khẩu nhiều lần (Tài khoản bị khóa 5 phút)';
          
          // Tạo security alert
          await _supabase.from('security_alerts').insert({
            'user_id': userId,
            'type': 'SUSPICIOUS_LOGIN_ATTEMPTS',
            'message': 'Phát hiện 5 lần đăng nhập thất bại liên tiếp. Tài khoản đã bị khóa tạm thời.',
            'severity': 'HIGH',
          });
        }

        await _supabase.from('users').update(updates).eq('id', userId);

        await _logLoginHistory(
          userId: userId,
          email: email,
          deviceName: deviceName,
          userAgent: userAgent,
          success: false,
          reason: failReason,
          suspicious: currentAttempts >= 3,
        );
      } else {
        // Tài khoản không tồn tại
        await _logLoginHistory(
          email: email,
          deviceName: deviceName,
          userAgent: userAgent,
          success: false,
          reason: 'Tài khoản không tồn tại',
        );
      }
    } catch (_) {
      // Tránh crash nếu ghi log lỗi
    }
  }

  Future<void> _logLoginHistory({
    String? userId,
    required String email,
    required String deviceName,
    required String userAgent,
    required bool success,
    String? reason,
    bool suspicious = false,
  }) async {
    try {
      await _supabase.from('login_history').insert({
        'user_id': userId,
        'email': email,
        'device_name': deviceName,
        'user_agent': userAgent,
        'success': success,
        'reason': reason,
        'suspicious': suspicious,
      });
    } catch (_) {
      // Ignored
    }
  }

  @override
  Future<User> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: SupabaseConfig.googleWebClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Đăng nhập bằng Google bị hủy.');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (idToken == null) {
        throw AuthException('Không nhận được ID Token từ Google.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final sbUser = response.user;
      if (sbUser == null) {
        throw AuthException('Đăng nhập bằng Google thất bại.');
      }

      // Check and update profile
      User? user = await _fetchUserProfile(sbUser.id);
      if (user == null) {
        // Nếu database trigger chậm, đợi một chút
        await Future.delayed(const Duration(seconds: 1));
        user = await _fetchUserProfile(sbUser.id);
      }

      if (user == null) {
        throw AuthException('Không thể khởi tạo thông tin người dùng.');
      }

      return user;
    } catch (e) {
      throw AuthException('Đăng nhập bằng Google thất bại: $e');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Đảm bảo logout hoạt động kể cả khi mất kết nối mạng
    }
  }

  @override
  Future<bool> isLoggedIn() async {
    return _supabase.auth.currentSession != null;
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: sb.OtpType.signup,
      );
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Xác minh thất bại: $e');
    }
  }

  @override
  Future<void> resendEmailCode({required String email}) async {
    try {
      await _supabase.auth.resend(
        email: email,
        type: sb.OtpType.signup,
      );
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Gửi lại mã thất bại: $e');
    }
  }

  @override
  Future<User> verify2FA({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        email: email,
        token: code,
        type: sb.OtpType.email,
      );
      final sbUser = response.user;
      if (sbUser == null) {
        throw AuthException('Xác thực 2 bước không thành công.');
      }
      final user = await _fetchUserProfile(sbUser.id);
      if (user == null) {
        throw AuthException('Không tìm thấy thông tin tài khoản người dùng.');
      }
      return user;
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Xác thực 2 bước thất bại: $e');
    }
  }

  @override
  Future<void> resend2FACode({required String email}) async {
    try {
      await _supabase.auth.signInWithOtp(email: email);
    } on sb.AuthException catch (e) {
      throw _mapAuthException(e);
    } catch (e) {
      throw AuthException('Gửi lại mã thất bại: $e');
    }
  }

  AuthException _mapAuthException(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials')) {
      return AuthException('Email hoặc mật khẩu không chính xác.', 'invalid_credentials');
    } else if (msg.contains('email not confirmed')) {
      return AuthException('Tài khoản chưa được xác minh email. Vui lòng kiểm tra hộp thư thoại.', 'email_not_confirmed');
    } else if (msg.contains('user already exists') || msg.contains('already registered')) {
      return AuthException('Email này đã được đăng ký cho tài khoản khác.', 'user_already_exists');
    } else if (msg.contains('password is too short')) {
      return AuthException('Mật khẩu tối thiểu phải từ 6 ký tự trở lên.', 'password_too_short');
    }
    return AuthException(e.message);
  }
}

final authService = AuthService();
