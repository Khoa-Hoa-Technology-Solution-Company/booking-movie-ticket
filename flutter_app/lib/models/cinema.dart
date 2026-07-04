class Cinema {
  final int id;
  final String name;
  final String address;
  final String city;
  final String? imageUrl;

  const Cinema({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    this.imageUrl,
  });

  factory Cinema.fromJson(Map<String, dynamic> json) {
    return Cinema(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'city': city,
      'image_url': imageUrl,
    };
  }
}

class Room {
  final int id;
  final int cinemaId;
  final String name;
  final int totalSeats;
  final String roomType;

  const Room({
    required this.id,
    required this.cinemaId,
    required this.name,
    required this.totalSeats,
    required this.roomType,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as int,
      cinemaId: json['cinema_id'] as int,
      name: json['name'] as String? ?? '',
      totalSeats: json['total_seats'] as int? ?? 0,
      roomType: json['room_type'] as String? ?? '2D',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cinema_id': cinemaId,
      'name': name,
      'total_seats': totalSeats,
      'room_type': roomType,
    };
  }
}
