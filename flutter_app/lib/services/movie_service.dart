import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/api/app_exception.dart';
import '../models/movie.dart';
import '../models/cinema.dart';
import '../models/showtime.dart';

abstract class IMovieService {
  /// Lấy danh sách phim đang chiếu
  Future<List<Movie>> getNowShowing();

  /// Lấy danh sách phim sắp chiếu
  Future<List<Movie>> getComingSoon();

  /// Chi tiết phim theo ID
  Future<Movie> getMovieById(int id);

  /// Lấy danh sách tất cả các rạp
  Future<List<Cinema>> getCinemas();

  /// Lấy danh sách showtimes theo bộ lọc phim, rạp hoặc ngày chiếu
  Future<List<Showtime>> getShowtimes({
    int? movieId,
    int? cinemaId,
    DateTime? date,
  });

  /// Lấy sơ đồ ghế trống/đã đặt cho lịch chiếu cụ thể
  Future<ShowtimeDetail> getShowtimeDetail(int id);
}

class MovieService implements IMovieService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Future<List<Movie>> getNowShowing() async {
    try {
      final response = await _supabase
          .from('movies')
          .select()
          .eq('status', 'NOW_SHOWING')
          .order('release_date', ascending: false);
      
      return (response as List).map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Không thể lấy danh sách phim đang chiếu: $e');
    }
  }

  @override
  Future<List<Movie>> getComingSoon() async {
    try {
      final response = await _supabase
          .from('movies')
          .select()
          .eq('status', 'COMING_SOON')
          .order('release_date', ascending: true);
      
      return (response as List).map((json) => Movie.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Không thể lấy danh sách phim sắp chiếu: $e');
    }
  }

  @override
  Future<Movie> getMovieById(int id) async {
    try {
      final response = await _supabase
          .from('movies')
          .select()
          .eq('id', id)
          .single();
      
      return Movie.fromJson(response);
    } catch (e) {
      throw DatabaseException('Không tìm thấy thông tin chi tiết phim: $e');
    }
  }

  @override
  Future<List<Cinema>> getCinemas() async {
    try {
      final response = await _supabase
          .from('cinemas')
          .select()
          .order('name');
      
      return (response as List).map((json) => Cinema.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Không thể tải danh sách rạp: $e');
    }
  }

  @override
  Future<List<Showtime>> getShowtimes({
    int? movieId,
    int? cinemaId,
    DateTime? date,
  }) async {
    try {
      var query = _supabase.from('showtimes').select('*, rooms(*, cinemas(*)), movies(*)');
      
      if (movieId != null) {
        query = query.eq('movie_id', movieId);
      }
      
      if (cinemaId != null) {
        // PostgREST lọc thông qua quan hệ bảng con
        query = query.eq('rooms.cinema_id', cinemaId);
      }
      
      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day).toUtc().toIso8601String();
        final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toUtc().toIso8601String();
        query = query.gte('start_time', startOfDay).lte('start_time', endOfDay);
      }

      final response = await query.order('start_time');
      
      // Lọc bỏ những lịch chiếu bị null room do điều kiện lọc
      return (response as List)
          .map((json) => Showtime.fromJson(json))
          .where((st) => st.room != null && (cinemaId == null || st.cinema?.id == cinemaId))
          .toList();
    } catch (e) {
      throw DatabaseException('Không thể lấy lịch chiếu phim: $e');
    }
  }

  @override
  Future<ShowtimeDetail> getShowtimeDetail(int id) async {
    try {
      // 1. Lấy thông tin showtime trước
      final showtimeJson = await _supabase
          .from('showtimes')
          .select('*, rooms(*, cinemas(*)), movies(*)')
          .eq('id', id)
          .single();
      final showtime = Showtime.fromJson(showtimeJson);

      // 2. Lấy tất cả ghế trong phòng chiếu đó
      final seatsResponse = await _supabase
          .from('seats')
          .select()
          .eq('room_id', showtime.roomId)
          .order('row')
          .order('number');

      // 3. Lấy tất cả ghế đã được đặt cho showtime này (bookings PENDING hoặc CONFIRMED)
      final bookedSeatsResponse = await _supabase
          .from('booking_seats')
          .select('seat_id, bookings!inner(status, showtime_id)')
          .eq('bookings.showtime_id', id)
          .inFilter('bookings.status', ['PENDING', 'CONFIRMED']);

      final bookedSeatIds = (bookedSeatsResponse as List)
          .map((item) => item['seat_id'] as int)
          .toList();

      // 4. Tạo sơ đồ ghế
      final seats = (seatsResponse as List)
          .map((json) => Seat.fromJson(json, bookedSeatIds: bookedSeatIds))
          .toList();

      return ShowtimeDetail(showtime: showtime, seats: seats);
    } catch (e) {
      throw DatabaseException('Không thể tải chi tiết sơ đồ ghế của lịch chiếu: $e');
    }
  }
}

final movieService = MovieService();
