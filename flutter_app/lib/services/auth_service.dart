import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

class AuthService {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConfig.googleWebClientId : null,
    serverClientId: kIsWeb ? null : AppConfig.googleWebClientId,
    scopes: ['email', 'profile'],
  );

  /// Helper to get device name
  String _getDeviceName() {
    String deviceName = 'Unknown Device';
    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) deviceName = 'Android Device';
        if (Platform.isIOS) deviceName = 'iOS Device';
        if (Platform.isWindows) deviceName = 'Windows App';
      } catch (_) {}
    }
    return deviceName;
  }

  /// Helper to log login history
  Future<void> _logLoginHistory({
    required String userId,
    required String email,
    required bool success,
    String? reason,
  }) async {
    try {
      await _db.collection('login_history').add({
        'userId': userId,
        'email': email,
        'ipAddress': '127.0.0.1',
        'userAgent': kIsWeb ? 'Web Browser' : 'Mobile App',
        'deviceName': _getDeviceName(),
        'success': success,
        'reason': reason,
        'suspicious': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error writing login history: $e');
    }
  }

  /// Helper to generate mock OTP code
  Future<String> _generateMockCode(String userId, String type) async {
    final code = '123456'; // standard simple demo code
    final expiresAt = DateTime.now().add(const Duration(minutes: 10));
    
    await _db.collection('users').doc(userId).collection('verification_codes').doc(type).set({
      'code': code,
      'expiresAt': Timestamp.fromDate(expiresAt),
      'used': false,
    });
    
    debugPrint('=== DEMO CODE GENERATED ===');
    debugPrint('User: $userId | Type: $type | Code: $code');
    debugPrint('============================');
    return code;
  }

  /// Đăng ký tài khoản
  Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    try {
      if (email == null || email.isEmpty) {
        throw Exception('Email là bắt buộc đối với Firebase Auth');
      }

      // Create firebase auth user
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credentials.user!.uid;

      // Đợi 200ms để Token xác thực kịp đồng bộ sang Firestore client
      await Future.delayed(const Duration(milliseconds: 200));

      // Create user profile document
      final userDoc = {
        'id': uid,
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'emailVerified': false,
        'phoneVerified': false,
        'twoFactorEnabled': false,
        'role': 'USER',
        'failedLoginAttempts': 0,
        'lockedUntil': null,
        'lastLoginAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'avatarUrl': null,
      };

      await _db.collection('users').doc(uid).set(userDoc);

      // Generate verification code
      await _generateMockCode(uid, 'EMAIL_VERIFY');

      return {'user': userDoc};
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Đăng nhập tài khoản
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    String email = identifier.trim();
    try {
      // 1. Nếu identifier là số điện thoại, tìm kiếm email thông qua Cloud Function bảo mật
      if (!identifier.contains('@')) {
        debugPrint('[AuthService] Identifier is phone number, fetching email via Cloud Function...');
        final result = await _functions.httpsCallable('getEmailByPhone').call({
          'phoneNumber': identifier.trim(),
        });
        email = result.data['email'] as String;
      }

      // 2. Thực hiện đăng nhập bằng Firebase Auth trước
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credentials.user!.uid;
      final userRef = _db.collection('users').doc(uid);
      final userSnap = await userRef.get();
      if (!userSnap.exists) {
        throw Exception('Không tìm thấy tài khoản trong hệ thống.');
      }
      final userMap = userSnap.data()!;

      // 3. Kiểm tra trạng thái khóa tài khoản sau khi đã được xác thực (có quyền đọc doc cá nhân)
      final lockedUntil = userMap['lockedUntil'] as Timestamp?;
      if (lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now())) {
        await _auth.signOut();
        throw Exception('Tài khoản đang tạm thời bị khóa. Vui lòng thử lại sau.');
      }

      // 4. Kiểm tra trạng thái 2FA
      final twoFactorEnabled = userMap['twoFactorEnabled'] == true;
      if (twoFactorEnabled) {
        // Tạo mã OTP
        await _generateMockCode(uid, 'OTP_LOGIN');
        // Giữ đăng nhập tạm thời để Client đọc mã OTP, nhưng trả về requireOtp để hiển thị màn hình nhập OTP
        return {
          'requireOtp': true,
          'otpRequired': true,
          'identifier': identifier,
        };
      }

      // 5. Cập nhật thông tin đăng nhập thành công
      await userRef.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'failedLoginAttempts': 0,
      });

      await _logLoginHistory(
        userId: uid,
        email: email,
        success: true,
      );

      return {
        'requireOtp': false,
        'otpRequired': false,
        'user': userMap,
      };
    } on fb.FirebaseAuthException catch (e) {
      debugPrint('[AuthService] AuthException during login: ${e.code} - ${e.message}');
      // Ghi nhận lỗi đăng nhập sai mật khẩu qua Cloud Function để tự động đếm lockout
      try {
        await _functions.httpsCallable('recordFailedLogin').call({
          'email': email,
          'reason': e.message ?? 'Wrong password',
          'deviceName': deviceName,
        });
      } catch (logErr) {
        debugPrint('[AuthService] Error writing failed login log: $logErr');
      }
      
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Tài khoản hoặc mật khẩu không chính xác.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Tài khoản này đã bị vô hiệu hóa.');
      }
      throw Exception(e.message ?? 'Đăng nhập thất bại.');
    } catch (e) {
      debugPrint('[AuthService] General error during login: $e');
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Đăng nhập bằng Google
  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Đăng nhập Google bị hủy');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final credentials = await _auth.signInWithCredential(credential);
      final uid = credentials.user!.uid;

      final userRef = _db.collection('users').doc(uid);
      final userSnap = await userRef.get();

      Map<String, dynamic> userDoc;
      if (!userSnap.exists) {
        userDoc = {
          'id': uid,
          'name': googleUser.displayName ?? 'Google User',
          'email': googleUser.email,
          'phoneNumber': null,
          'emailVerified': true,
          'phoneVerified': false,
          'twoFactorEnabled': false,
          'role': 'USER',
          'failedLoginAttempts': 0,
          'lockedUntil': null,
          'lastLoginAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
          'avatarUrl': googleUser.photoUrl,
        };
        await userRef.set(userDoc);
      } else {
        userDoc = userSnap.data()!;
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'avatarUrl': userDoc['avatarUrl'] ?? googleUser.photoUrl,
        });
      }

      await _logLoginHistory(
        userId: uid,
        email: googleUser.email,
        success: true,
      );

      return {
        'requireOtp': false,
        'user': userDoc,
      };
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Xác minh Email đăng ký
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản.');
      }

      final uid = userQuery.docs.first.id;
      final codeRef = _db
          .collection('users')
          .doc(uid)
          .collection('verification_codes')
          .doc('EMAIL_VERIFY');

      final snap = await codeRef.get();
      if (!snap.exists) {
        throw Exception('Mã xác thực không tồn tại.');
      }

      final data = snap.data()!;
      if (data['used'] == true) {
        throw Exception('Mã xác thực đã được sử dụng.');
      }

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw Exception('Mã xác thực đã hết hạn.');
      }

      if (data['code'] != code) {
        throw Exception('Mã xác thực không chính xác.');
      }

      // Mark code as used & user email as verified
      await codeRef.update({'used': true});
      await _db.collection('users').doc(uid).update({'emailVerified': true});
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Gửi lại mã xác minh Email
  Future<void> resendEmailCode({required String email}) async {
    try {
      final userQuery = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản.');
      }

      final uid = userQuery.docs.first.id;
      await _generateMockCode(uid, 'EMAIL_VERIFY');
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Xác minh số điện thoại đăng ký
  Future<void> verifyPhone({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      final userQuery = await _db
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản với số điện thoại này.');
      }

      final uid = userQuery.docs.first.id;
      final codeRef = _db
          .collection('users')
          .doc(uid)
          .collection('verification_codes')
          .doc('PHONE_VERIFY');

      final snap = await codeRef.get();
      if (!snap.exists) {
        throw Exception('Mã xác thực không tồn tại.');
      }

      final data = snap.data()!;
      if (data['used'] == true) {
        throw Exception('Mã xác thực đã được sử dụng.');
      }

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw Exception('Mã xác thực đã hết hạn.');
      }

      if (data['code'] != code) {
        throw Exception('Mã xác thực không chính xác.');
      }

      await codeRef.update({'used': true});
      await _db.collection('users').doc(uid).update({'phoneVerified': true});
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Gửi lại mã xác minh số điện thoại
  Future<void> resendPhoneCode({required String phoneNumber}) async {
    try {
      final userQuery = await _db
          .collection('users')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản với số điện thoại này.');
      }

      final uid = userQuery.docs.first.id;
      await _generateMockCode(uid, 'PHONE_VERIFY');
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Xác minh mã OTP / 2FA khi đăng nhập
  Future<Map<String, dynamic>> verifyOtp({
    required String identifier,
    required String code,
    required String deviceName,
  }) async {
    try {
      String email = identifier;
      if (!identifier.contains('@')) {
        final query = await _db
            .collection('users')
            .where('phoneNumber', isEqualTo: identifier)
            .limit(1)
            .get();
        if (query.docs.isEmpty) {
          throw Exception('Không tìm thấy tài khoản.');
        }
        email = query.docs.first.data()['email'] ?? '';
      }

      final query = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Không tìm thấy tài khoản.');
      }

      final uid = query.docs.first.id;
      final codeRef = _db
          .collection('users')
          .doc(uid)
          .collection('verification_codes')
          .doc('OTP_LOGIN');

      final snap = await codeRef.get();
      if (!snap.exists) {
        throw Exception('Mã OTP không tồn tại.');
      }

      final data = snap.data()!;
      if (data['used'] == true) {
        throw Exception('Mã OTP đã được sử dụng.');
      }

      final expiresAt = (data['expiresAt'] as Timestamp).toDate();
      if (expiresAt.isBefore(DateTime.now())) {
        throw Exception('Mã OTP đã hết hạn.');
      }

      if (data['code'] != code) {
        throw Exception('Mã OTP không chính xác.');
      }

      // Mark code as used
      await codeRef.update({'used': true});

      // Now authenticate on Firebase Auth (Wait, since we signed out to check OTP, let's login again without OTP check or set the authentication token)
      // Since it's a student demo, we can just sign in again. In production we'd do MFA, but here we can sign in the user again and return the user map.
      // We will perform direct email auth to authenticate them on Firebase Auth:
      // Note: the caller expects the user to be fully logged in. So let's authenticate:
      // The user already entered their password in the previous step. Wait! Since we don't have the password anymore, we can generate a custom token on a cloud function or we can just authenticate.
      // But wait! Can we just sign them in? Yes, since we signed them out, we can store their email/password in memory temporarily, or since we have Firebase Auth, we can just bypass the signout during verification.
      // Wait! A cleaner way to do it: in `login()`, instead of signing out, we can keep the user signed in, but mark the session in our local state as "needs OTP".
      // Or, we can just perform the login and verify the OTP from the firestore. Let's make it so `login` doesn't sign out, but we check if OTP is verified.
      // Actually, since Firebase Auth keeps the user signed in, we can sign in the user in `login` and keep them signed in, but return `requireOtp: true`. The app won't let them proceed until they enter the OTP.
      // In `verifyOtp`, we check the OTP, and if correct, we just return the user! This is extremely elegant and doesn't require storing passwords!
      // Let's ensure that in `login()` we sign them in, but if `twoFactorEnabled == true`, we return `requireOtp: true`. And then `verifyOtp` simply marks the code as used and returns the user document!
      // This is absolutely perfect!
      
      final userSnap = await _db.collection('users').doc(uid).get();
      final userMap = userSnap.data()!;

      await _db.collection('users').doc(uid).update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'failedLoginAttempts': 0,
      });

      await _logLoginHistory(
        userId: uid,
        email: email,
        success: true,
      );

      return {
        'requireOtp': false,
        'user': userMap,
      };
    } catch (e) {
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  /// Kiểm tra trạng thái đã đăng nhập hay chưa
  Future<bool> isLoggedIn() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    // Check if 2FA is enabled. If so, force authentication on start for security.
    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      if (snap.exists) {
        final data = snap.data()!;
        if (data['twoFactorEnabled'] == true) {
          await logout();
          return false;
        }
      }
    } catch (_) {}
    return true;
  }
}

final authService = AuthService();
