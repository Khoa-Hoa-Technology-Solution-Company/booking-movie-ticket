import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecurityService {
  final _storage = const FlutterSecureStorage();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache in-memory
  bool _twoFactorEnabled = false;
  List<Map<String, dynamic>> _loginHistory = [];
  List<Map<String, dynamic>> _alerts = [];
  bool _initialized = false;

  Future<void> _initIfNeeded() async {
    if (_initialized) return;
    
    // Đọc trạng thái 2FA từ secure storage
    final tfaVal = await _storage.read(key: 'two_factor_enabled');
    _twoFactorEnabled = tfaVal == 'true';

    // Tạo sẵn một số dữ liệu lịch sử đăng nhập demo cho đẹp mắt
    _loginHistory = [
      {
        'id': 1,
        'email': _auth.currentUser?.email ?? 'user@example.com',
        'ipAddress': '192.168.1.100',
        'deviceName': 'Android Emulator',
        'success': true,
        'suspicious': false,
        'createdAt': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 2,
        'email': _auth.currentUser?.email ?? 'user@example.com',
        'ipAddress': '14.232.84.102',
        'deviceName': 'Chrome Browser - Windows',
        'success': true,
        'suspicious': true,
        'reason': null,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
      {
        'id': 3,
        'email': _auth.currentUser?.email ?? 'user@example.com',
        'ipAddress': '192.168.1.15',
        'deviceName': 'iPhone 15 Pro',
        'success': false,
        'reason': 'Sai mật khẩu',
        'suspicious': false,
        'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      }
    ];

    // Tạo sẵn cảnh báo bảo mật demo
    _alerts = [
      if (_twoFactorEnabled == false)
        {
          'id': 101,
          'type': 'TWO_FACTOR_DISABLED',
          'message': 'Xác thực 2 bước (2FA) đang bị tắt. Hãy bật để tăng bảo mật.',
          'severity': 'MEDIUM',
          'read': false,
          'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        },
      {
        'id': 102,
        'type': 'SUSPICIOUS_LOGIN',
        'message': 'Phát hiện đăng nhập lạ từ địa chỉ IP 14.232.84.102 (Windows Device)',
        'severity': 'MEDIUM',
        'read': true,
        'createdAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      }
    ];

    _initialized = true;
  }

  /// Ghi nhận log đăng nhập khi user login thành công
  Future<void> recordLoginLog(String deviceName) async {
    await _initIfNeeded();
    final user = _auth.currentUser;
    final email = user?.email ?? 'unknown@example.com';
    final timestamp = DateTime.now().toIso8601String();

    // Check xem thiết bị này đã từng đăng nhập thành công chưa
    final bool isKnown = _loginHistory.any((log) => log['deviceName'] == deviceName && log['success'] == true);
    final bool isSuspicious = _loginHistory.isNotEmpty && !isKnown;

    final newLog = {
      'id': _loginHistory.length + 1,
      'email': email,
      'ipAddress': '192.168.1.50',
      'deviceName': deviceName,
      'success': true,
      'suspicious': isSuspicious,
      'createdAt': timestamp,
    };

    _loginHistory.insert(0, newLog);

    if (isSuspicious) {
      final newAlert = {
        'id': _alerts.length + 101,
        'type': 'SUSPICIOUS_LOGIN',
        'message': 'Đăng nhập lạ từ thiết bị mới phát hiện: $deviceName',
        'severity': 'HIGH',
        'read': false,
        'createdAt': timestamp,
      };
      _alerts.insert(0, newAlert);
    }
  }

  /// Lấy dữ liệu Security Dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    await _initIfNeeded();
    final user = _auth.currentUser;

    final bool emailVerified = user?.emailVerified ?? false;
    
    // Tính toán điểm bảo mật (tổng 100)
    int score = 100;
    final List<Map<String, dynamic>> issues = [];

    if (!emailVerified) {
      score -= 30;
      issues.add({
        'type': 'EMAIL_NOT_VERIFIED',
        'title': 'Email chưa được xác minh',
        'description': 'Xác minh email để nâng cao tính bảo mật cho tài khoản của bạn.',
        'severity': 'HIGH',
        'impact': -30,
      });
    }

    if (!_twoFactorEnabled) {
      score -= 20;
      issues.add({
        'type': 'TWO_FACTOR_DISABLED',
        'title': 'Chưa bật xác thực 2 bước (2FA)',
        'description': 'Kích hoạt xác thực 2 lớp để yêu cầu kiểm tra liên kết qua email mỗi khi đăng nhập.',
        'severity': 'MEDIUM',
        'impact': -20,
      });
    }

    final suspiciousCount = _loginHistory.where((log) => log['suspicious'] == true).length;
    if (suspiciousCount > 0) {
      score -= 15;
      issues.add({
        'type': 'SUSPICIOUS_LOGINS',
        'title': 'Phát hiện đăng nhập nghi vấn',
        'description': 'Có $suspiciousCount phiên đăng nhập từ các thiết bị chưa nhận dạng.',
        'severity': 'MEDIUM',
        'impact': -15,
      });
    }

    score = score.clamp(0, 100);

    return {
      'hasEmail': user?.email != null,
      'hasPhoneNumber': user?.phoneNumber != null,
      'accountVerified': emailVerified,
      'emailVerified': emailVerified,
      'phoneVerified': user?.phoneNumber != null,
      'twoFactorEnabled': _twoFactorEnabled,
      'lastLoginAt': _loginHistory.isNotEmpty ? _loginHistory.first['createdAt'] : null,
      'failedLoginAttempts': 0,
      'accountLocked': false,
      'securityScore': score,
      'recentAlerts': _alerts.take(5).toList(),
      'user': {
        'id': user?.uid.hashCode ?? 0,
        'name': user?.displayName ?? 'Firebase User',
        'email': user?.email ?? '',
        'role': 'USER',
        'createdAt': user?.metadata.creationTime?.toIso8601String() ?? '',
      },
      'security': {
        'emailVerified': emailVerified,
        'phoneVerified': user?.phoneNumber != null,
        'hasEmail': user?.email != null,
        'hasPhoneNumber': user?.phoneNumber != null,
        'twoFactorEnabled': _twoFactorEnabled,
        'lastLogin': _loginHistory.isNotEmpty ? _loginHistory.first['createdAt'] : null,
        'failedLoginAttempts': 0,
        'accountLocked': false,
        'securityScore': score,
        'unreadAlerts': _alerts.where((a) => a['read'] == false).length,
        'suspiciousLogins': suspiciousCount,
      },
      'securityIssues': issues,
      'recentLogins': _loginHistory.take(5).toList(),
    };
  }

  /// Lấy danh sách các sự cố bảo mật hiện tại
  Future<List<dynamic>> getIssues() async {
    final dashboard = await getDashboard();
    return dashboard['securityIssues'] ?? [];
  }

  /// Lấy lịch sử đăng nhập phân trang
  Future<Map<String, dynamic>> getLoginHistory({
    int page = 1,
    int limit = 10,
  }) async {
    await _initIfNeeded();
    final total = _loginHistory.length;
    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, total);
    
    final pagedItems = _loginHistory.sublist(startIndex, endIndex);

    return {
      'history': pagedItems,
      'pagination': {
        'page': page,
        'limit': limit,
        'total': total,
        'totalPages': (total / limit).ceil(),
      }
    };
  }

  /// Lấy danh sách cảnh báo bảo mật
  Future<List<dynamic>> getAlerts() async {
    await _initIfNeeded();
    return _alerts;
  }

  /// Bật/Tắt xác thực 2 bước (2FA)
  Future<Map<String, dynamic>> toggle2FA(bool enabled) async {
    await _initIfNeeded();
    _twoFactorEnabled = enabled;
    await _storage.write(key: 'two_factor_enabled', value: enabled.toString());

    // Thêm cảnh báo tương ứng
    final timestamp = DateTime.now().toIso8601String();
    final newAlert = {
      'id': _alerts.length + 101,
      'type': enabled ? 'TWO_FACTOR_ENABLED' : 'TWO_FACTOR_DISABLED',
      'message': enabled 
          ? 'Xác thực 2 bước (2FA) đã được bật thành công!' 
          : 'Cảnh báo: Xác thực 2 bước (2FA) đã bị tắt.',
      'severity': enabled ? 'LOW' : 'MEDIUM',
      'read': false,
      'createdAt': timestamp,
    };
    _alerts.insert(0, newAlert);

    return {
      'twoFactorEnabled': _twoFactorEnabled,
      'message': enabled
          ? 'Đã bật 2FA thành công. Bạn sẽ cần xác thực email mỗi khi đăng nhập.'
          : 'Đã tắt xác thực 2 bước.',
    };
  }

  /// Kiểm tra xem 2FA đã được xác thực cho phiên hiện tại chưa
  Future<bool> isTwoFactorVerifiedForSession() async {
    final verified = await _storage.read(key: 'two_factor_session_verified');
    return verified == 'true';
  }

  /// Cập nhật trạng thái xác thực 2FA cho phiên hiện tại
  Future<void> setTwoFactorVerified(bool verified) async {
    await _storage.write(key: 'two_factor_session_verified', value: verified.toString());
  }

  String? _currentOTP;
  DateTime? _otpExpireTime;

  /// Sinh mã OTP 2FA ngẫu nhiên 6 chữ số
  String generate2FAOTP() {
    final rand = Random();
    final otp = (100000 + rand.nextInt(900000)).toString();
    _currentOTP = otp;
    _otpExpireTime = DateTime.now().add(const Duration(minutes: 5));
    return otp;
  }

  /// Xác thực mã OTP 2FA
  bool verifyOTP(String code) {
    if (_currentOTP == null || _otpExpireTime == null) return false;
    if (DateTime.now().isAfter(_otpExpireTime!)) {
      _currentOTP = null;
      _otpExpireTime = null;
      return false;
    }
    final isValid = _currentOTP == code.trim();
    if (isValid) {
      _currentOTP = null; // Xoá mã sau khi xác thực thành công
      _otpExpireTime = null;
    }
    return isValid;
  }

  /// Xóa trạng thái xác thực 2FA của phiên (khi logout)
  Future<void> clearTwoFactorSession() async {
    await _storage.delete(key: 'two_factor_session_verified');
    _currentOTP = null;
    _otpExpireTime = null;
  }
}

final securityService = SecurityService();
