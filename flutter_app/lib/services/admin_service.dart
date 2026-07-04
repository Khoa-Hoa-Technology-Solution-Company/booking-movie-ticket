import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/api/app_exception.dart';

abstract class IAdminService {
  // Movie CRUD
  Future<void> addMovie(Map<String, dynamic> movieData);
  Future<void> updateMovie(int id, Map<String, dynamic> movieData);
  Future<void> deleteMovie(int id);

  // Room & Showtime
  Future<List<Map<String, dynamic>>> getRooms();
  Future<void> addShowtime(Map<String, dynamic> showtimeData);
  Future<void> deleteShowtime(int id);

  // Analytics
  Future<Map<String, dynamic>> getAnalytics(DateTime start, DateTime end);

  // User Management
  Future<List<Map<String, dynamic>>> getUsers();
  Future<void> toggleUserLock(String userId, bool shouldLock);

  // Promotion Management
  Future<List<Map<String, dynamic>>> getPromotions();
  Future<void> addPromotion(Map<String, dynamic> promoData);
  Future<void> deletePromotion(int id);
}

class AdminService implements IAdminService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Future<void> addMovie(Map<String, dynamic> movieData) async {
    try {
      await _supabase.from('movies').insert(movieData);
    } catch (e) {
      throw DatabaseException('Không thể thêm phim: $e');
    }
  }

  @override
  Future<void> updateMovie(int id, Map<String, dynamic> movieData) async {
    try {
      await _supabase.from('movies').update(movieData).eq('id', id);
    } catch (e) {
      throw DatabaseException('Không thể cập nhật phim: $e');
    }
  }

  @override
  Future<void> deleteMovie(int id) async {
    try {
      await _supabase
          .from('movies')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseException('Không thể xóa phim: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRooms() async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('*, cinemas(name)')
          .order('name');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw DatabaseException('Không thể lấy danh sách phòng: $e');
    }
  }

  @override
  Future<void> addShowtime(Map<String, dynamic> showtimeData) async {
    try {
      await _supabase.from('showtimes').insert(showtimeData);
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('Xung đột thời gian')) {
        throw DatabaseException(
          'Suất chiếu bị trùng lịch với một suất chiếu khác trong phòng này.',
          'SHOWTIME_CONFLICT',
        );
      }
      throw DatabaseException('Không thể thêm suất chiếu: ${e.message}');
    } catch (e) {
      throw DatabaseException('Đã xảy ra lỗi khi thêm suất chiếu: $e');
    }
  }

  @override
  Future<void> deleteShowtime(int id) async {
    try {
      await _supabase
          .from('showtimes')
          .update({'deleted_at': DateTime.now().toUtc().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      throw DatabaseException('Không thể xóa suất chiếu: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getAnalytics(DateTime start, DateTime end) async {
    try {
      final response = await _supabase.rpc(
        'get_analytics_summary',
        params: {
          'p_start_date': start.toUtc().toIso8601String(),
          'p_end_date': end.toUtc().toIso8601String(),
        },
      );
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      throw DatabaseException('Không tải được số liệu thống kê: $e');
    }
  }

  // User Management
  @override
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw DatabaseException('Không tải được danh sách người dùng: $e');
    }
  }

  @override
  Future<void> toggleUserLock(String userId, bool shouldLock) async {
    try {
      final lockedUntil = shouldLock
          ? DateTime.now().add(const Duration(days: 36500)).toUtc().toIso8601String()
          : null;
      await _supabase.rpc('admin_update_user_status', params: {
        'p_user_id': userId,
        'p_locked_until': lockedUntil,
      });
    } catch (e) {
      throw DatabaseException('Khóa/Mở khóa người dùng thất bại: $e');
    }
  }

  // Promotion Management
  @override
  Future<List<Map<String, dynamic>>> getPromotions() async {
    try {
      final response = await _supabase
          .from('promotions')
          .select()
          .order('code');
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      throw DatabaseException('Không tải được danh sách khuyến mãi: $e');
    }
  }

  @override
  Future<void> addPromotion(Map<String, dynamic> promoData) async {
    try {
      await _supabase.from('promotions').insert(promoData);
    } catch (e) {
      throw DatabaseException('Không thể thêm mã khuyến mãi: $e');
    }
  }

  @override
  Future<void> deletePromotion(int id) async {
    try {
      await _supabase.from('promotions').delete().eq('id', id);
    } catch (e) {
      throw DatabaseException('Không thể xóa mã khuyến mãi: $e');
    }
  }
}

final adminService = AdminService();
