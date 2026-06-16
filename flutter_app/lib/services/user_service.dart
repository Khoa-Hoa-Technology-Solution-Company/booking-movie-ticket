import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/api/app_exception.dart';
import '../models/user.dart';

abstract class IUserService {
  /// Lấy thông tin tài khoản hiện tại
  Future<User> getProfile();

  /// Cập nhật tên hiển thị
  Future<User> updateProfile({required String name});

  /// Đổi mật khẩu
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });
}

class UserService implements IUserService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Future<User> getProfile() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để tải thông tin tài khoản');
      }

      final response = await _supabase
          .from('users')
          .select()
          .eq('id', currentUserId)
          .single();

      return User.fromJson(response);
    } catch (e) {
      throw DatabaseException('Không tải được thông tin tài khoản: $e');
    }
  }

  @override
  Future<User> updateProfile({required String name}) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập');
      }

      await _supabase
          .from('users')
          .update({'name': name})
          .eq('id', currentUserId);

      await _supabase.auth.updateUser(sb.UserAttributes(
        data: {'name': name},
      ));

      return await getProfile();
    } catch (e) {
      throw DatabaseException('Không thể cập nhật thông tin tài khoản: $e');
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) {
        throw AuthException('Không tìm thấy thông tin email của tài khoản.');
      }

      // Xác thực mật khẩu cũ trước khi đổi
      await _supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Cập nhật mật khẩu mới
      await _supabase.auth.updateUser(sb.UserAttributes(password: newPassword));

      // Lưu cảnh báo bảo mật
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        await _supabase.from('security_alerts').insert({
          'user_id': currentUserId,
          'type': 'PASSWORD_CHANGED',
          'message': 'Mật khẩu tài khoản đã được thay đổi thành công.',
          'severity': 'HIGH',
        });
      }
    } on sb.AuthException catch (e) {
      throw AuthException(e.message.contains('Invalid login credentials')
          ? 'Mật khẩu hiện tại không chính xác.'
          : 'Không thể thay đổi mật khẩu: ${e.message}');
    } catch (e) {
      throw DatabaseException('Đã xảy ra lỗi khi đổi mật khẩu: $e');
    }
  }
}

final userService = UserService();