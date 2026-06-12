import 'package:dio/dio.dart';
import '../core/api/api_client.dart';

class BookingService {
  /// Tạo một đơn đặt vé mới
  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    String? promotionCode,
  }) async {
    try {
      final response = await apiClient.dio.post('/bookings', data: {
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        if (promotionCode != null && promotionCode.isNotEmpty) 'promotionCode': promotionCode,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Xác nhận thanh toán Demo và xuất vé
  Future<Map<String, dynamic>> confirmDemoPayment(int bookingId) async {
    try {
      final response = await apiClient.dio.post('/payments/demo-confirm', data: {
        'bookingId': bookingId,
      });
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy lịch sử đặt vé của user hiện tại
  Future<List<dynamic>> getBookingHistory() async {
    try {
      final response = await apiClient.dio.get('/bookings/history');
      return response.data['data']['bookings'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Chi tiết đơn đặt vé
  Future<Map<String, dynamic>> getBookingById(int id) async {
    try {
      final response = await apiClient.dio.get('/bookings/$id');
      return response.data['data']['booking'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Hủy đặt vé (chỉ khi trạng thái là PENDING)
  Future<Map<String, dynamic>> cancelBooking(int id) async {
    try {
      final response = await apiClient.dio.patch('/bookings/$id/cancel');
      return response.data['data'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }
}

final bookingService = BookingService();
