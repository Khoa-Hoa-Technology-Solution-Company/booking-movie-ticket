import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

class ApiClient {
  late final Dio dio;
  
  // Callback sẽ được gán trong App để điều hướng đăng xuất khi session hết hạn
  static Function()? onSessionExpired;

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    // Request Interceptor: Tự động gán Firebase ID token vào headers
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        try {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            final token = await user.getIdToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
        } catch (e) {
          debugPrint('Error getting Firebase ID Token in request interceptor: $e');
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final response = error.response;
        
        // Phát hiện lỗi 401 Unauthorized -> Đăng xuất khỏi Firebase và báo session expired
        if (response?.statusCode == 401) {
          try {
            await FirebaseAuth.instance.signOut();
          } catch (_) {}
          await TokenStorage.clearTokens();
          if (onSessionExpired != null) {
            onSessionExpired!();
          }
        }
        return handler.next(error);
      },
    ));
  }

  // Hàm tiện ích phân tích lỗi từ DioException sang ApiException
  ApiException handleDioError(DioException e) {
    final response = e.response;
    if (response != null && response.data != null && response.data is Map) {
      final message = response.data['message'] ?? 'API Request failed';
      final errors = response.data['errors'];
      return ApiException(
        message: message,
        statusCode: response.statusCode,
        errors: errors,
      );
    }
    return ApiException(
      message: e.message ?? 'Connection failed. Please check your internet connection.',
      statusCode: response?.statusCode,
    );
  }
}

// Singleton instance
final apiClient = ApiClient();
