import 'package:dio/dio.dart';
import '../core/api/api_client.dart';

class MovieService {
  /// Lấy danh sách phim đang chiếu
  Future<List<dynamic>> getNowShowing() async {
    try {
      final response = await apiClient.dio.get('/movies/now-showing');
      return response.data['data']['movies'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy danh sách phim sắp chiếu
  Future<List<dynamic>> getComingSoon() async {
    try {
      final response = await apiClient.dio.get('/movies/coming-soon');
      return response.data['data']['movies'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy chi tiết phim theo ID (kèm danh sách lịch chiếu tương lai)
  Future<Map<String, dynamic>> getMovieById(int id) async {
    try {
      final response = await apiClient.dio.get('/movies/$id');
      return response.data['data']['movie'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy danh sách rạp chiếu phim
  Future<List<dynamic>> getCinemas() async {
    try {
      final response = await apiClient.dio.get('/cinemas');
      return response.data['data']['cinemas'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy danh sách lịch chiếu
  Future<List<dynamic>> getShowtimes({
    int? movieId,
    int? cinemaId,
    String? date,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (movieId != null) queryParams['movieId'] = movieId;
      if (cinemaId != null) queryParams['cinemaId'] = cinemaId;
      if (date != null) queryParams['date'] = date;

      final response = await apiClient.dio.get(
        '/showtimes',
        queryParameters: queryParams,
      );
      return response.data['data']['showtimes'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }

  /// Lấy chi tiết lịch chiếu và sơ đồ ghế trống/đã đặt
  Future<Map<String, dynamic>> getShowtimeById(int id) async {
    try {
      final response = await apiClient.dio.get('/showtimes/$id');
      return response.data['data']['showtime'];
    } on DioException catch (e) {
      throw apiClient.handleDioError(e);
    }
  }
}

final movieService = MovieService();
