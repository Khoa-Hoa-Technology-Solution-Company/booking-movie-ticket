import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Lấy thông tin cá nhân từ Firebase User
  Future<Map<String, dynamic>> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    return {
      'id': user.uid.hashCode, // Tạo ID nguyên từ UID
      'name': user.displayName ?? 'Firebase User',
      'email': user.email ?? '',
      'phoneNumber': user.phoneNumber ?? '',
      'emailVerified': user.emailVerified,
      'createdAt': user.metadata.creationTime?.toIso8601String() ?? '',
    };
  }

  /// Cập nhật họ tên của User trên Firebase Profile
  Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    await user.updateDisplayName(name);
    await user.reload(); // Tải lại thông tin mới
    
    return await getProfile();
  }

  /// Thay đổi mật khẩu tài khoản Firebase
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    try {
      // Trong Firebase, thay đổi mật khẩu cần xác thực lại nếu phiên đăng nhập đã lâu.
      // Để đơn giản cho ứng dụng demo, ta gọi trực tiếp phương thức cập nhật mật khẩu.
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Hành động bảo mật cao yêu cầu bạn đăng nhập lại trước khi đổi mật khẩu.');
      }
      throw Exception(e.message ?? 'Đổi mật khẩu thất bại.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }
}

final userService = UserService();