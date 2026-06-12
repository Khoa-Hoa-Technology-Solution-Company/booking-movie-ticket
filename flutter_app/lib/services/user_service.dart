import 'package:dio/dio.dart';

import '../core/api/api_client.dart';

class UserService {
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await apiClient.dio.get('/users/profile');
      return response.data['data']['user'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> updateProfile({required String name}) async {
    try {
      final response = await apiClient.dio.put('/users/profile', data: {
        'name': name,
      });
      return response.data['data']['user'] as Map<String, dynamic>;
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await apiClient.dio.put('/users/change-password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }
}

final userService = UserService();