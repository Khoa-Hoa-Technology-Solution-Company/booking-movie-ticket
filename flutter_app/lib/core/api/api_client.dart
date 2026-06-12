import 'package:dio/dio.dart';
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

    // Request Interceptor: Tự động gán access token vào headers
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final accessToken = await TokenStorage.getAccessToken();
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        final response = error.response;
        
        // Phát hiện lỗi 401 Unauthorized (Có thể do Access token hết hạn)
        if (response?.statusCode == 401) {
          final requestPath = error.requestOptions.path;
          
          // Tránh gọi đệ quy vô hạn nếu chính API refresh-token hoặc login trả về 401
          if (!requestPath.contains('/auth/refresh-token') && !requestPath.contains('/auth/login')) {
            final refreshToken = await TokenStorage.getRefreshToken();
            
            if (refreshToken != null) {
              try {
                // Tạo một Dio instance sạch độc lập để gọi refresh token
                final refreshDio = Dio(BaseOptions(
                  baseUrl: AppConfig.baseUrl,
                  headers: {'Content-Type': 'application/json'},
                ));
                
                final refreshResponse = await refreshDio.post('/auth/refresh-token', data: {
                  'refreshToken': refreshToken,
                });
                
                if (refreshResponse.statusCode == 200 && refreshResponse.data['success'] == true) {
                  final data = refreshResponse.data['data'];
                  final newAccessToken = data['accessToken'];
                  final newRefreshToken = data['refreshToken'];
                  
                  // Lưu token mới
                  await TokenStorage.saveTokens(
                    accessToken: newAccessToken,
                    refreshToken: newRefreshToken,
                  );
                  
                  // Tạo lại request cũ với header mới
                  final requestOptions = error.requestOptions;
                  requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final retryOpts = Options(
                    method: requestOptions.method,
                    headers: requestOptions.headers,
                  );
                  
                  final retryResponse = await dio.request(
                    requestOptions.path,
                    data: requestOptions.data,
                    queryParameters: requestOptions.queryParameters,
                    options: retryOpts,
                  );
                  
                  return handler.resolve(retryResponse);
                }
              } catch (refreshError) {
                // Refresh thất bại -> Session đã chết (Refresh token hết hạn / bị thu hồi)
                await TokenStorage.clearTokens();
                if (onSessionExpired != null) {
                  onSessionExpired!();
                }
              }
            } else {
              // Không có refresh token -> yêu cầu đăng nhập lại
              await TokenStorage.clearTokens();
              if (onSessionExpired != null) {
                onSessionExpired!();
              }
            }
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
