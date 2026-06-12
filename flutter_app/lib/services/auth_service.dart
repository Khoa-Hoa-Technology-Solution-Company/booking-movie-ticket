import 'package:dio/dio.dart';
import '../core/api/api_client.dart';
import '../core/storage/token_storage.dart';

class AuthService {
  /// Đăng ký tài khoản
  Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    String? phoneNumber,
    required String password,
  }) async {
    try {
      final data = {
        'name': name,
        'password': password,
      };
      if (email != null && email.isNotEmpty) data['email'] = email;
      if (phoneNumber != null && phoneNumber.isNotEmpty) data['phoneNumber'] = phoneNumber;

      final response = await apiClient.dio.post('/auth/register', data: data);
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Đăng nhập tài khoản
  /// Trả về map chứa thông tin đăng nhập. 
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
        'deviceName': deviceName,
      });

      final responseData = response.data['data'];
      
      // Nếu không yêu cầu OTP -> Lưu tokens vào secure storage luôn
      if (responseData['requireOtp'] != true && responseData['otpRequired'] != true) {
        final accessToken = responseData['accessToken'];
        final refreshToken = responseData['refreshToken'];
        await TokenStorage.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
      }
      return responseData;
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Xác minh Email đăng ký
  Future<void> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      await apiClient.dio.post('/auth/verify-email', data: {
        'email': email,
        'code': code,
      });
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Gửi lại mã xác minh Email
  Future<void> resendEmailCode({required String email}) async {
    try {
      await apiClient.dio.post('/auth/resend-email-code', data: {
        'email': email,
      });
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Xác minh số điện thoại đăng ký
  Future<void> verifyPhone({
    required String phoneNumber,
    required String code,
  }) async {
    try {
      await apiClient.dio.post('/auth/verify-phone', data: {
        'phoneNumber': phoneNumber,
        'code': code,
      });
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Gửi lại mã xác minh số điện thoại
  Future<void> resendPhoneCode({required String phoneNumber}) async {
    try {
      await apiClient.dio.post('/auth/resend-phone-code', data: {
        'phoneNumber': phoneNumber,
      });
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Xác minh mã OTP / 2FA khi đăng nhập
  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String code,
    required String deviceName,
  }) async {
    try {
      final response = await apiClient.dio.post('/auth/verify-otp', data: {
        'email': email,
        'code': code,
        'deviceName': deviceName,
      });

      final responseData = response.data['data'];
      final accessToken = responseData['accessToken'];
      final refreshToken = responseData['refreshToken'];
      
      await TokenStorage.saveTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return responseData;
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    try {
      final refreshToken = await TokenStorage.getRefreshToken();
      if (refreshToken != null) {
        await apiClient.dio.post('/auth/logout', data: {
          'refreshToken': refreshToken,
        });
      }
    } catch (_) {
      // Bỏ qua lỗi kết nối khi logout để đảm bảo xóa sạch dữ liệu cục bộ
    } finally {
      await TokenStorage.clearTokens();
    }
  }

  /// Kiểm tra trạng thái đã đăng nhập hay chưa
  Future<bool> isLoggedIn() async {
    final token = await TokenStorage.getAccessToken();
    return token != null;
  }
}

final authService = AuthService();
