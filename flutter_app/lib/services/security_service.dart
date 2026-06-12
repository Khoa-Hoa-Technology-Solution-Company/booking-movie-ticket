import 'package:dio/dio.dart';
import '../core/api/api_client.dart';

class SecurityService {
  /// Lấy thông tin tổng quan Dashboard bảo mật
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final response = await apiClient.dio.get('/security/dashboard');
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy danh sách các vấn đề bảo mật hiện tại
  Future<List<dynamic>> getIssues() async {
    try {
      final response = await apiClient.dio.get('/security/issues');
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy lịch sử đăng nhập phân trang
  Future<Map<String, dynamic>> getLoginHistory({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await apiClient.dio.get(
        '/security/login-history',
        queryParameters: {'page': page, 'limit': limit},
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy danh sách các cảnh báo bảo mật (Security Alerts)
  Future<List<dynamic>> getAlerts() async {
    try {
      final response = await apiClient.dio.get('/security/alerts');
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Bật/Tắt xác thực 2 bước 2FA
  Future<Map<String, dynamic>> toggle2FA(bool enabled) async {
    try {
      final response = await apiClient.dio.patch('/security/toggle-2fa', data: {
        'enabled': enabled,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }
}

final securityService = SecurityService();
