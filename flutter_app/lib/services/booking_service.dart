import 'dart:math';
import 'movie_service.dart';

class BookingService {
  // Bộ lưu trữ đơn hàng tĩnh trong bộ nhớ
  static final List<Map<String, dynamic>> _bookings = [];

  /// Tạo một đơn đặt vé mới (PENDING)
  Future<Map<String, dynamic>> createBooking({
    required int showtimeId,
    required List<int> seatIds,
    String? promotionCode,
  }) async {
    // 1. Lấy chi tiết lịch chiếu để tính giá tiền
    final showtime = await movieService.getShowtimeById(showtimeId);
    final movie = showtime['movie'];
    final cinema = showtime['cinema'];
    final double basePrice = showtime['price'];

    // 2. Tính tiền (Ghế VIP phụ thu 20%)
    double totalAmount = 0;
    final List<Map<String, dynamic>> selectedSeats = [];

    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
    for (var seatId in seatIds) {
      // Tìm vị trí ghế
      final int rowIdx = (seatId - 1) ~/ 10;
      final int colIdx = (seatId - 1) % 10;
      final String row = rows[rowIdx.clamp(0, 7)];
      final int num = colIdx + 1;
      final bool isVip = row == 'E' || row == 'F';
      final seatPrice = basePrice * (isVip ? 1.2 : 1.0);

      totalAmount += seatPrice;
      selectedSeats.add({
        'id': seatId,
        'row': row,
        'number': num,
        'type': isVip ? 'VIP' : 'STANDARD',
        'price': seatPrice,
      });
    }

    // Áp mã giảm giá demo
    if (promotionCode != null && promotionCode.toUpperCase() == 'DISCOUNT50') {
      totalAmount *= 0.5;
    }

    // 3. Tạo booking map
    final int bookingId = _bookings.length + 5001;
    final Map<String, dynamic> newBooking = {
      'id': bookingId,
      'showtimeId': showtimeId,
      'status': 'PENDING',
      'totalAmount': totalAmount,
      'createdAt': DateTime.now().toIso8601String(),
      'showtime': showtime,
      'movie': movie,
      'cinema': cinema,
      'seats': selectedSeats,
      'tickets': [],
    };

    _bookings.insert(0, newBooking);
    return newBooking;
  }

  /// Xác nhận thanh toán Demo và xuất vé
  Future<Map<String, dynamic>> confirmDemoPayment(int bookingId) async {
    final index = _bookings.indexWhere((b) => b['id'] == bookingId);
    if (index == -1) {
      throw Exception('Không tìm thấy đơn đặt vé');
    }

    final booking = _bookings[index];
    if (booking['status'] != 'PENDING') {
      throw Exception('Đơn đặt vé này đã được xử lý trước đó');
    }

    final int showtimeId = booking['showtimeId'];
    final List<dynamic> seats = booking['seats'];
    final List<int> seatIds = seats.map((s) => s['id'] as int).toList();

    // 1. Đánh dấu ghế đã đặt trong MovieService để không ai đặt được nữa
    final List<int> alreadyBooked = MovieService.bookedSeatIdsByShowtime[showtimeId] ?? [];
    alreadyBooked.addAll(seatIds);
    MovieService.bookedSeatIdsByShowtime[showtimeId] = alreadyBooked;

    // 2. Tạo vé (Tickets) kèm mã vạch QR giả lập
    final String randomCode = (100000 + Random().nextInt(900000)).toString();
    final List<Map<String, dynamic>> tickets = seats.map((seat) {
      final String ticketCode = 'TKT-${seat['row']}${seat['number']}-$randomCode';
      return {
        'id': Random().nextInt(10000),
        'ticketCode': ticketCode,
        'qrCode': 'https://api.qrserver.com/v1/create-qr-code/?size=150x150&data=$ticketCode',
        'status': 'ACTIVE',
      };
    }).toList();

    // 3. Cập nhật trạng thái đơn đặt vé
    booking['status'] = 'CONFIRMED';
    booking['tickets'] = tickets;
    _bookings[index] = booking;

    return booking;
  }

  /// Lấy lịch sử đặt vé của user hiện tại
  Future<List<dynamic>> getBookingHistory() async {
    return _bookings;
  }

  /// Chi tiết đơn đặt vé
  Future<Map<String, dynamic>> getBookingById(int id) async {
    return _bookings.firstWhere((b) => b['id'] == id, orElse: () => throw Exception('Không tìm thấy đơn đặt vé'));
  }

  /// Hủy đặt vé (chỉ khi trạng thái là PENDING)
  Future<Map<String, dynamic>> cancelBooking(int id) async {
    final index = _bookings.indexWhere((b) => b['id'] == id);
    if (index == -1) {
      throw Exception('Không tìm thấy đơn đặt vé');
    }

    final booking = _bookings[index];
    if (booking['status'] != 'PENDING') {
      throw Exception('Chỉ có thể hủy đơn đặt vé ở trạng thái chờ thanh toán');
    }

    booking['status'] = 'CANCELLED';
    _bookings[index] = booking;

    return booking;
  }
}

final bookingService = BookingService();
