import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      throw Exception('Không tìm thấy tài khoản người dùng.');
    }
    return doc.data() as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({required String name}) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    await _db.collection('users').doc(user.uid).update({
      'name': name,
    });

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data() as Map<String, dynamic>;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    if (user.email == null) {
      throw Exception('Không tìm thấy thông tin email.');
    }

    // Re-authenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );

    try {
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      // Create a security alert
      await _db.collection('security_alerts').add({
        'userId': user.uid,
        'type': 'PASSWORD_CHANGED',
        'message': 'Mật khẩu của bạn đã được thay đổi thành công.',
        'severity': 'MEDIUM',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }
}

final userService = UserService();