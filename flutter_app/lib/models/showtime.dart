import 'movie.dart';
import 'cinema.dart';

enum SeatType { standard, vip, couple }
enum SeatStatus { available, maintenance, booked, held }

class Seat {
  final int id;
  final int roomId;
  final String row;
  final int number;
  final SeatType type;
  final SeatStatus status;
  final int positionX;
  final int positionY;
  final bool isActive;

  const Seat({
    required this.id,
    required this.roomId,
    required this.row,
    required this.number,
    required this.type,
    required this.status,
    required this.positionX,
    required this.positionY,
    required this.isActive,
  });

  factory Seat.fromJson(Map<String, dynamic> json, {List<int>? bookedSeatIds, List<int>? heldSeatIds}) {
    SeatType parseType(String? typeStr) {
      switch (typeStr) {
        case 'VIP': return SeatType.vip;
        case 'COUPLE': return SeatType.couple;
        default: return SeatType.standard;
      }
    }

    final idVal = json['id'] as int;
    final isBooked = bookedSeatIds?.contains(idVal) ?? false;
    final isHeld = heldSeatIds?.contains(idVal) ?? false;
    
    SeatStatus parseStatus(String? statusStr) {
      if (isBooked) return SeatStatus.booked;
      if (isHeld) return SeatStatus.held;
      if (statusStr == 'MAINTENANCE') return SeatStatus.maintenance;
      return SeatStatus.available;
    }

    final rowStr = json['row'] as String? ?? '';
    final defaultY = rowStr.isNotEmpty ? rowStr.toUpperCase().codeUnitAt(0) - 64 : 1;

    return Seat(
      id: idVal,
      roomId: json['room_id'] as int,
      row: rowStr,
      number: json['number'] as int? ?? 0,
      type: parseType(json['type'] as String?),
      status: parseStatus(json['status'] as String?),
      positionX: json['position_x'] as int? ?? (json['number'] as int? ?? 0),
      positionY: json['position_y'] as int? ?? defaultY,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'row': row,
      'number': number,
      'type': type == SeatType.vip
          ? 'VIP'
          : type == SeatType.couple
              ? 'COUPLE'
              : 'STANDARD',
      'status': status == SeatStatus.booked
          ? 'BOOKED'
          : status == SeatStatus.held
              ? 'HELD'
              : status == SeatStatus.maintenance
                  ? 'MAINTENANCE'
                  : 'AVAILABLE',
      'position_x': positionX,
      'position_y': positionY,
      'is_active': isActive,
    };
  }
}

class Showtime {
  final int id;
  final int movieId;
  final int roomId;
  final DateTime startTime;
  final DateTime endTime;
  final double price;
  final Movie? movie;
  final Room? room;
  final Cinema? cinema;

  const Showtime({
    required this.id,
    required this.movieId,
    required this.roomId,
    required this.startTime,
    required this.endTime,
    required this.price,
    this.movie,
    this.room,
    this.cinema,
  });

  factory Showtime.fromJson(Map<String, dynamic> json) {
    return Showtime(
      id: json['id'] as int,
      movieId: json['movie_id'] as int,
      roomId: json['room_id'] as int,
      startTime: DateTime.parse(json['start_time'] as String).toLocal(),
      endTime: DateTime.parse(json['end_time'] as String).toLocal(),
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      movie: json['movies'] != null ? Movie.fromJson(json['movies'] as Map<String, dynamic>) : null,
      room: json['rooms'] != null ? Room.fromJson(json['rooms'] as Map<String, dynamic>) : null,
      cinema: json['rooms']?['cinemas'] != null 
          ? Cinema.fromJson(json['rooms']['cinemas'] as Map<String, dynamic>) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'movie_id': movieId,
      'room_id': roomId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'price': price,
      if (movie != null) 'movies': movie!.toJson(),
      if (room != null) 'rooms': room!.toJson(),
    };
  }
}

class ShowtimeDetail {
  final Showtime showtime;
  final List<Seat> seats;
  final List<int> currentUserHoldSeatIds;

  const ShowtimeDetail({
    required this.showtime,
    required this.seats,
    this.currentUserHoldSeatIds = const [],
  });
}
