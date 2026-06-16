import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Helper to convert Timestamp to ISO string
  String? _formatTimestamp(Timestamp? ts) {
    if (ts == null) return null;
    return ts.toDate().toIso8601String();
  }

  /// Tính toán Security Score và các Issue trên Client
  Map<String, dynamic> _calculateSecurityScore(Map<String, dynamic> user, int suspiciousLogins) {
    int score = 100;
    final List<Map<String, dynamic>> issues = [];

    final hasEmail = user['email'] != null && (user['email'] as String).isNotEmpty;
    final emailVerified = user['emailVerified'] == true;
    if (hasEmail && !emailVerified) {
      score -= 30;
      issues.add({
        'type': 'EMAIL_NOT_VERIFIED',
        'title': 'Email chưa xác minh',
        'description': 'Xác minh email để bảo vệ tài khoản',
        'severity': 'HIGH',
        'impact': -30,
      });
    }

    final hasPhone = user['phoneNumber'] != null && (user['phoneNumber'] as String).isNotEmpty;
    final phoneVerified = user['phoneVerified'] == true;
    if (hasPhone && !phoneVerified) {
      score -= 25;
      issues.add({
        'type': 'PHONE_NOT_VERIFIED',
        'title': 'Số điện thoại chưa xác minh',
        'description': 'Xác minh số điện thoại để tăng bảo mật',
        'severity': 'HIGH',
        'impact': -25,
      });
    }

    if (!hasPhone) {
      score -= 15;
      issues.add({
        'type': 'NO_PHONE_NUMBER',
        'title': 'Thiếu số điện thoại',
        'description': 'Thêm số điện thoại để có tùy chọn khôi phục tài khoản',
        'severity': 'MEDIUM',
        'impact': -15,
      });
    }

    final twoFactorEnabled = user['twoFactorEnabled'] == true;
    if (!twoFactorEnabled) {
      score -= 20;
      issues.add({
        'type': 'TWO_FACTOR_DISABLED',
        'title': 'Chưa bật xác thực 2 lớp',
        'description': 'Bật 2FA để bảo vệ tài khoản tốt hơn',
        'severity': 'MEDIUM',
        'impact': -20,
      });
    }

    final failedAttempts = user['failedLoginAttempts'] ?? 0;
    if (failedAttempts > 3) {
      score -= 15;
      issues.add({
        'type': 'MULTIPLE_FAILED_LOGINS',
        'title': 'Nhiều lần đăng nhập sai',
        'description': 'Phát hiện $failedAttempts lần đăng nhập sai gần đây',
        'severity': 'HIGH',
        'impact': -15,
      });
    }

    if (suspiciousLogins > 0) {
      score -= 15;
      issues.add({
        'type': 'SUSPICIOUS_LOGINS',
        'title': 'Đăng nhập đáng ngờ',
        'description': 'Phát hiện đăng nhập từ thiết bị lạ',
        'severity': 'MEDIUM',
        'impact': -15,
      });
    }

    final lockedUntil = user['lockedUntil'] as Timestamp?;
    final isLocked = lockedUntil != null && lockedUntil.toDate().isAfter(DateTime.now());
    if (isLocked) {
      score -= 20;
      issues.add({
        'type': 'ACCOUNT_LOCKED',
        'title': 'Tài khoản đang bị khóa',
        'description': 'Tài khoản tạm thời bị khóa do vấn đề an toàn',
        'severity': 'CRITICAL',
        'impact': -20,
      });
    }

    score = score.clamp(0, 100);

    return {
      'score': score,
      'issues': issues,
    };
  }

  /// Lấy thông tin tổng quan Dashboard bảo mật
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final userDoc = await _db.collection('users').doc(user.uid).get();
      if (!userDoc.exists) throw Exception('User document not found');
      final userData = userDoc.data()!;

      // Count unread alerts
      final alertsQuery = await _db
          .collection('security_alerts')
          .where('userId', isEqualTo: user.uid)
          .where('read', isEqualTo: false)
          .get();
      final unreadAlerts = alertsQuery.docs.length;

      // Count suspicious logins
      final suspiciousQuery = await _db
          .collection('login_history')
          .where('userId', isEqualTo: user.uid)
          .where('suspicious', isEqualTo: true)
          .get();
      final suspiciousLogins = suspiciousQuery.docs.length;

      // Calculate score & issues
      final scoreResult = _calculateSecurityScore(userData, suspiciousLogins);
      final score = scoreResult['score'] as int;
      final issues = scoreResult['issues'] as List<Map<String, dynamic>>;

      // Fetch recent logins (limit 5)
      final loginsSnap = await _db
          .collection('login_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentLogins = loginsSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'email': d['email'],
          'ipAddress': d['ipAddress'],
          'deviceName': d['deviceName'],
          'success': d['success'],
          'suspicious': d['suspicious'],
          'createdAt': _formatTimestamp(d['createdAt'] as Timestamp?),
        };
      }).toList();

      // Fetch recent alerts (limit 5)
      final alertsSnap = await _db
          .collection('security_alerts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      final recentAlerts = alertsSnap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'type': d['type'],
          'message': d['message'],
          'severity': d['severity'],
          'read': d['read'],
          'createdAt': _formatTimestamp(d['createdAt'] as Timestamp?),
        };
      }).toList();

      return {
        'hasEmail': userData['email'] != null,
        'hasPhoneNumber': userData['phoneNumber'] != null,
        'accountVerified': userData['emailVerified'] == true || userData['phoneVerified'] == true,
        'emailVerified': userData['emailVerified'] == true,
        'phoneVerified': userData['phoneVerified'] == true,
        'twoFactorEnabled': userData['twoFactorEnabled'] == true,
        'lastLoginAt': _formatTimestamp(userData['lastLoginAt'] as Timestamp?),
        'failedLoginAttempts': userData['failedLoginAttempts'] ?? 0,
        'accountLocked': userData['lockedUntil'] != null && (userData['lockedUntil'] as Timestamp).toDate().isAfter(DateTime.now()),
        'securityScore': score,
        'recentAlerts': recentAlerts,
        'user': {
          'id': user.uid,
          'name': userData['name'],
          'email': userData['email'],
          'phoneNumber': userData['phoneNumber'],
          'role': userData['role'] ?? 'USER',
          'createdAt': _formatTimestamp(userData['createdAt'] as Timestamp?),
          'avatarUrl': userData['avatarUrl'],
          'authProvider': 'FIREBASE',
        },
        'security': {
          'emailVerified': userData['emailVerified'] == true,
          'phoneVerified': userData['phoneVerified'] == true,
          'hasEmail': userData['email'] != null,
          'hasPhoneNumber': userData['phoneNumber'] != null,
          'twoFactorEnabled': userData['twoFactorEnabled'] == true,
          'lastLogin': _formatTimestamp(userData['lastLoginAt'] as Timestamp?),
          'failedLoginAttempts': userData['failedLoginAttempts'] ?? 0,
          'accountLocked': userData['lockedUntil'] != null && (userData['lockedUntil'] as Timestamp).toDate().isAfter(DateTime.now()),
          'lockedUntil': _formatTimestamp(userData['lockedUntil'] as Timestamp?),
          'securityScore': score,
          'unreadAlerts': unreadAlerts,
          'suspiciousLogins': suspiciousLogins,
          'authProvider': 'FIREBASE',
        },
        'securityIssues': issues,
        'recentLogins': recentLogins,
      };
    } catch (e) {
      throw Exception('Không thể tải thông tin bảo mật: $e');
    }
  }

  /// Lấy danh sách các vấn đề bảo mật hiện tại
  Future<List<dynamic>> getIssues() async {
    try {
      final dashboard = await getDashboard();
      return dashboard['securityIssues'] ?? [];
    } catch (e) {
      throw Exception('Không thể tải danh sách vấn đề: $e');
    }
  }

  /// Lấy lịch sử đăng nhập phân trang
  Future<Map<String, dynamic>> getLoginHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final snap = await _db
          .collection('login_history')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      final list = snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'email': d['email'],
          'ipAddress': d['ipAddress'],
          'userAgent': d['userAgent'],
          'deviceName': d['deviceName'],
          'success': d['success'],
          'reason': d['reason'],
          'suspicious': d['suspicious'],
          'createdAt': _formatTimestamp(d['createdAt'] as Timestamp?),
        };
      }).toList();

      // Simple client side pagination to match API interface
      final startIndex = (page - 1) * limit;
      final endIndex = (startIndex + limit).clamp(0, list.length);
      final pagedList = list.isEmpty ? [] : list.sublist(startIndex, endIndex);

      return {
        'history': pagedList,
        'pagination': {
          'page': page,
          'limit': limit,
          'total': list.length,
          'totalPages': (list.length / limit).ceil(),
        }
      };
    } catch (e) {
      throw Exception('Không thể tải lịch sử đăng nhập: $e');
    }
  }

  /// Lấy danh sách các cảnh báo bảo mật (Security Alerts)
  Future<List<dynamic>> getAlerts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final snap = await _db
          .collection('security_alerts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map((doc) {
        final d = doc.data();
        return {
          'id': doc.id,
          'type': d['type'],
          'message': d['message'],
          'severity': d['severity'],
          'read': d['read'],
          'createdAt': _formatTimestamp(d['createdAt'] as Timestamp?),
        };
      }).toList();
    } catch (e) {
      throw Exception('Không thể tải cảnh báo bảo mật: $e');
    }
  }

  /// Bật/Tắt xác thực 2 bước 2FA
  Future<Map<String, dynamic>> toggle2FA(bool enabled) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      await _db.collection('users').doc(user.uid).update({
        'twoFactorEnabled': enabled,
      });

      // Add alert log
      await _db.collection('security_alerts').add({
        'userId': user.uid,
        'type': enabled ? 'TWO_FACTOR_ENABLED' : 'TWO_FACTOR_DISABLED',
        'message': enabled ? 'Xác thực 2 lớp đã được bật.' : 'Xác thực 2 lớp đã tắt.',
        'severity': enabled ? 'LOW' : 'MEDIUM',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return {
        'twoFactorEnabled': enabled,
        'message': enabled ? 'Bật 2FA thành công.' : 'Tắt 2FA thành công.',
      };
    } catch (e) {
      throw Exception('Thao tác thất bại: $e');
    }
  }
}

final securityService = SecurityService();
