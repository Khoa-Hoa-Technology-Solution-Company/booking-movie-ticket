import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/api/app_exception.dart';
import '../models/security.dart';

abstract class ISecurityService {
  /// Lấy thông tin tổng quan Dashboard bảo mật
  Future<SecurityDashboard> getDashboard();

  /// Lấy danh sách các vấn đề bảo mật hiện tại
  Future<List<SecurityIssue>> getIssues();

  /// Lấy lịch sử đăng nhập phân trang
  Future<Map<String, dynamic>> getLoginHistory({
    int page = 1,
    int limit = 10,
  });

  /// Lấy danh sách các cảnh báo bảo mật (Security Alerts)
  Future<List<SecurityAlert>> getAlerts();

  /// Bật/Tắt xác thực 2 bước 2FA
  Future<bool> toggle2FA(bool enabled);
}

class SecurityService implements ISecurityService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Future<SecurityDashboard> getDashboard() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để xem thông tin bảo mật');
      }

      final response = await _supabase
          .from('users')
          .select('two_factor_enabled, email_verified, last_login_at')
          .eq('id', currentUserId)
          .single();

      final twoFactorEnabled = response['two_factor_enabled'] == true;
      final emailVerified = _supabase.auth.currentUser?.emailConfirmedAt != null || response['email_verified'] == true;
      final hasEmail = _supabase.auth.currentUser?.email != null;
      final lastLoginAtStr = response['last_login_at'] as String?;
      final lastLoginAt = lastLoginAtStr != null ? DateTime.parse(lastLoginAtStr).toLocal() : null;

      int score = 50;
      if (emailVerified) score += 25;
      if (twoFactorEnabled) score += 25;

      return SecurityDashboard(
        securityScore: score,
        twoFactorEnabled: twoFactorEnabled,
        emailVerified: emailVerified,
        phoneVerified: false,
        hasEmail: hasEmail,
        hasPhoneNumber: false,
        lastLoginAt: lastLoginAt,
      );
    } catch (e) {
      throw DatabaseException('Không tải được thông tin bảo mật: $e');
    }
  }

  @override
  Future<List<SecurityIssue>> getIssues() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập');
      }

      final response = await _supabase
          .from('users')
          .select('two_factor_enabled, email_verified')
          .eq('id', currentUserId)
          .single();

      final twoFactorEnabled = response['two_factor_enabled'] == true;
      final emailVerified = _supabase.auth.currentUser?.emailConfirmedAt != null || response['email_verified'] == true;

      final List<SecurityIssue> issues = [];

      if (!emailVerified) {
        issues.add(SecurityIssue(
          title: 'Email chưa xác minh',
          description: 'Địa chỉ email của bạn chưa được xác minh. Hãy hoàn tất xác minh email để bảo vệ tài khoản tốt hơn.',
          severity: 'HIGH',
        ));
      }

      if (!twoFactorEnabled) {
        issues.add(SecurityIssue(
          title: 'Chưa bật xác thực 2 bước',
          description: 'Tài khoản chưa kích hoạt xác thực 2 lớp. Bạn nên bật 2FA để tránh nguy cơ bị đăng nhập trái phép.',
          severity: 'MEDIUM',
        ));
      }

      return issues;
    } catch (e) {
      throw DatabaseException('Không tải được danh sách sự cố bảo mật: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getLoginHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để xem lịch sử');
      }

      final from = (page - 1) * limit;
      final to = from + limit - 1;

      final response = await _supabase
          .from('login_history')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .range(from, to);

      final countRes = await _supabase
          .from('login_history')
          .select('id')
          .eq('user_id', currentUserId);

      final int totalCount = (countRes as List).length;
      final int totalPages = (totalCount / limit).ceil();
      final List<LoginHistoryItem> items = (response as List)
          .map((json) => LoginHistoryItem.fromJson(json))
          .toList();

      return {
        'items': items,
        'pagination': {
          'totalPages': totalPages > 0 ? totalPages : 1,
        }
      };
    } catch (e) {
      throw DatabaseException('Không tải được lịch sử đăng nhập: $e');
    }
  }

  @override
  Future<List<SecurityAlert>> getAlerts() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để xem cảnh báo');
      }

      final response = await _supabase
          .from('security_alerts')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => SecurityAlert.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Không tải được danh sách cảnh báo: $e');
    }
  }

  @override
  Future<bool> toggle2FA(bool enabled) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập');
      }

      await _supabase
          .from('users')
          .update({'two_factor_enabled': enabled})
          .eq('id', currentUserId);

      final actionText = enabled ? 'Bật' : 'Tắt';
      await _supabase.from('security_alerts').insert({
        'user_id': currentUserId,
        'type': '2FA_TOGGLED',
        'message': 'Bạn đã $actionText xác thực 2 bước (2FA) thành công.',
        'severity': 'MEDIUM',
      });

      return enabled;
    } catch (e) {
      throw DatabaseException('Không thể thay đổi cài đặt 2FA: $e');
    }
  }
}

final securityService = SecurityService();
