import 'showtime.dart';

enum BookingStatus { pending, confirmed, cancelled, expired }
enum TicketStatus { active, used, cancelled, expired }

class Booking {
  final int id;
  final String userId;
  final int showtimeId;
  final BookingStatus status;
  final double totalAmount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Showtime? showtime;
  final List<Seat>? seats;
  final Ticket? ticket;

  const Booking({
    required this.id,
    required this.userId,
    required this.showtimeId,
    required this.status,
    required this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.showtime,
    this.seats,
    this.ticket,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    BookingStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'CONFIRMED': return BookingStatus.confirmed;
        case 'CANCELLED': return BookingStatus.cancelled;
        case 'EXPIRED': return BookingStatus.expired;
        default: return BookingStatus.pending;
      }
    }

    // Parse seats if present from join table
    List<Seat>? seatsList;
    if (json['booking_seats'] != null) {
      seatsList = (json['booking_seats'] as List)
          .map((bs) {
            final seatMap = bs['seats'] as Map<String, dynamic>?;
            return seatMap != null ? Seat.fromJson(seatMap) : null;
          })
          .whereType<Seat>()
          .toList();
    }

    return Booking(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      showtimeId: json['showtime_id'] as int,
      status: parseStatus(json['status'] as String?),
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      showtime: json['showtimes'] != null ? Showtime.fromJson(json['showtimes'] as Map<String, dynamic>) : null,
      seats: seatsList,
      ticket: json['tickets'] != null
          ? (json['tickets'] is List
              ? (json['tickets'] as List).isNotEmpty
                  ? Ticket.fromJson((json['tickets'] as List).first as Map<String, dynamic>)
                  : null
              : Ticket.fromJson(json['tickets'] as Map<String, dynamic>))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'showtime_id': showtimeId,
      'status': status == BookingStatus.confirmed
          ? 'CONFIRMED'
          : status == BookingStatus.cancelled
              ? 'CANCELLED'
              : status == BookingStatus.expired
                  ? 'EXPIRED'
                  : 'PENDING',
      'total_amount': totalAmount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      if (showtime != null) 'showtimes': showtime!.toJson(),
    };
  }
}

class Ticket {
  final int id;
  final int bookingId;
  final String ticketCode;
  final String? qrCode;
  final TicketStatus status;
  final DateTime createdAt;

  const Ticket({
    required this.id,
    required this.bookingId,
    required this.ticketCode,
    this.qrCode,
    required this.status,
    required this.createdAt,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) {
    TicketStatus parseStatus(String? statusStr) {
      switch (statusStr) {
        case 'USED': return TicketStatus.used;
        case 'CANCELLED': return TicketStatus.cancelled;
        case 'EXPIRED': return TicketStatus.expired;
        default: return TicketStatus.active;
      }
    }

    return Ticket(
      id: json['id'] as int,
      bookingId: json['booking_id'] as int,
      ticketCode: json['ticket_code'] as String? ?? '',
      qrCode: json['qr_code'] as String?,
      status: parseStatus(json['status'] as String?),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'ticket_code': ticketCode,
      'qr_code': qrCode,
      'status': status == TicketStatus.used
          ? 'USED'
          : status == TicketStatus.cancelled
              ? 'CANCELLED'
              : status == TicketStatus.expired
                  ? 'EXPIRED'
                  : 'ACTIVE',
      'created_at': createdAt.toIso8601String(),
    };
  }
}
