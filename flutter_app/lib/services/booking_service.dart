import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../core/api/app_exception.dart';
import '../models/booking.dart';
import '../models/food.dart';

abstract class IBookingService {
  /// Đặt vé (Gọi transaction RPC của Supabase)
  Future<Booking> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    List<CartItem>? foodItems,
    String? promotionCode,
    String paymentMethod = 'DEMO',
  });

  /// Xác nhận thanh toán Demo và kích hoạt vé
  Future<Booking> confirmPayment(int bookingId);

  /// Hủy đặt vé (chỉ khi ở trạng thái PENDING)
  Future<Booking> cancelBooking(int bookingId);

  /// Lấy lịch sử đặt vé của user hiện tại
  Future<List<Booking>> getBookingHistory();

  /// Lấy chi tiết đơn đặt vé
  Future<Booking> getBookingById(int id);
}

class BookingService implements IBookingService {
  final _supabase = sb.Supabase.instance.client;

  @override
  Future<Booking> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    List<CartItem>? foodItems,
    String? promotionCode,
    String paymentMethod = 'DEMO',
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để đặt vé');
      }

      // 1. Tính tổng tiền dựa trên giá vé của showtime & loại ghế
      final showtimeJson = await _supabase
          .from('showtimes')
          .select('price')
          .eq('id', showtimeId)
          .single();
      final basePrice = (showtimeJson['price'] as num).toDouble();

      final seatsJson = await _supabase
          .from('seats')
          .select('id, type')
          .inFilter('id', seatIds);

      double totalAmount = 0.0;
      for (var seat in seatsJson) {
        final type = seat['type'] as String;
        if (type == 'VIP') {
          totalAmount += basePrice + 20000; // VIP thêm 20k
        } else if (type == 'COUPLE') {
          totalAmount += basePrice * 2; // Ghế đôi tính bằng 2 vé
        } else {
          totalAmount += basePrice;
        }
      }

      // 2. Áp dụng mã khuyến mãi nếu có
      if (promotionCode != null && promotionCode.isNotEmpty) {
        final promoJson = await _supabase
            .from('promotions')
            .select()
            .eq('code', promotionCode)
            .eq('active', true)
            .maybeSingle();

        if (promoJson != null) {
          final discountPercent = promoJson['discount_percent'] as int;
          final maxDiscount = (promoJson['max_discount'] as num?)?.toDouble();
          final minPurchase =
              (promoJson['min_purchase'] as num?)?.toDouble() ?? 0.0;

          if (totalAmount >= minPurchase) {
            double discount = totalAmount * (discountPercent / 100);
            if (maxDiscount != null && discount > maxDiscount) {
              discount = maxDiscount;
            }
            totalAmount -= discount;

            // Tăng lượt sử dụng của mã khuyến mãi qua RPC bảo mật
            await _supabase.rpc('increment_promotion_usage', params: {
              'p_code': promotionCode,
            });
          }
        }
      }

      // 2.5. Cộng thêm tiền bắp nước (Food & Beverages)
      final double foodTotal = foodItems?.fold<double>(
            0.0,
            (sum, item) => sum + item.totalAmount,
          ) ??
          0.0;
      totalAmount += foodTotal;

      final pItemsJson = foodItems?.map((item) => item.toRpcJson()).toList() ?? [];

      // 3. Gọi RPC transaction để tạo booking an toàn ở DB
      final bookingId =
          await _supabase.rpc(
                'create_booking',
                params: {
                  'p_user_id': currentUserId,
                  'p_showtime_id': showtimeId,
                  'p_seat_ids': seatIds,
                  'p_total_amount': totalAmount,
                  'p_payment_method': paymentMethod,
                  'p_items': pItemsJson,
                },
              )
              as int;

      return await getBookingById(bookingId);
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('seats are already booked') || e.code == '23505') {
        throw DatabaseException(
          'Một hoặc nhiều ghế đã được đặt.',
          'SEAT_ALREADY_BOOKED',
        );
      }
      throw DatabaseException('Đơn đặt vé thất bại: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw DatabaseException('Đã xảy ra lỗi khi đặt vé: $e');
    }
  }

  @override
  Future<Booking> confirmPayment(int bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'CONFIRMED'})
          .eq('id', bookingId);
      await _supabase
          .from('payments')
          .update({'status': 'PAID'})
          .eq('booking_id', bookingId);
      return await getBookingById(bookingId);
    } catch (e) {
      throw DatabaseException('Thanh toán thất bại: $e');
    }
  }

  @override
  Future<Booking> cancelBooking(int bookingId) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': 'CANCELLED'})
          .eq('id', bookingId);
      await _supabase
          .from('payments')
          .update({'status': 'FAILED'})
          .eq('booking_id', bookingId);
      return await getBookingById(bookingId);
    } catch (e) {
      throw DatabaseException('Không thể hủy đặt vé: $e');
    }
  }

  @override
  Future<List<Booking>> getBookingHistory() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw AuthException('Vui lòng đăng nhập để xem lịch sử');
      }

      final response = await _supabase
          .from('bookings')
          .select(
            '*, showtimes(*, rooms(*, cinemas(*)), movies(*)), booking_seats(*, seats(*)), tickets(*), order_items(*, products(*), combos(*))',
          )
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List).map((json) => Booking.fromJson(json)).toList();
    } catch (e) {
      throw DatabaseException('Không thể tải lịch sử đặt vé: $e');
    }
  }

  @override
  Future<Booking> getBookingById(int id) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select(
            '*, showtimes(*, rooms(*, cinemas(*)), movies(*)), booking_seats(*, seats(*)), tickets(*), order_items(*, products(*), combos(*))',
          )
          .eq('id', id)
          .single();

      return Booking.fromJson(response);
    } catch (e) {
      throw DatabaseException('Không tìm thấy chi tiết đơn đặt vé: $e');
    }
  }
}

final bookingService = BookingService();
