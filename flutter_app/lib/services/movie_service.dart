import 'package:cloud_firestore/cloud_firestore.dart';

class MovieService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Helper to convert Firestore timestamp to ISO string
  String? _formatTimestamp(Timestamp? ts) {
    if (ts == null) return null;
    return ts.toDate().toIso8601String();
  }

  /// Lấy danh sách phim đang chiếu
  Future<List<dynamic>> getNowShowing() async {
    try {
      final snap = await _db
          .collection('movies')
          .where('status', isEqualTo: 'ACTIVE')
          .get();
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách phim đang chiếu: $e');
    }
  }

  /// Lấy danh sách phim sắp chiếu
  Future<List<dynamic>> getComingSoon() async {
    try {
      final snap = await _db
          .collection('movies')
          .where('status', isEqualTo: 'COMING_SOON')
          .get();
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách phim sắp chiếu: $e');
    }
  }

  /// Lấy chi tiết phim theo ID (kèm danh sách lịch chiếu tương lai)
  Future<Map<String, dynamic>> getMovieById(String id) async {
    try {
      final movieDoc = await _db.collection('movies').doc(id).get();
      if (!movieDoc.exists) {
        throw Exception('Không tìm thấy phim.');
      }
      final movie = movieDoc.data()!;

      // Fetch showtimes for this movie
      final showtimesSnap = await _db
          .collection('showtimes')
          .where('movieId', isEqualTo: id)
          .get();

      final showtimes = showtimesSnap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'movieId': data['movieId'],
          'roomName': data['roomName'],
          'cinemaId': data['cinemaId'],
          'cinemaName': data['cinemaName'],
          'startTime': _formatTimestamp(data['startTime'] as Timestamp?),
          'endTime': _formatTimestamp(data['endTime'] as Timestamp?),
          'price': data['price'],
          'status': data['status'],
          // Mock structure mapping so that the UI can readroom & cinema details
          'room': {
            'name': data['roomName'],
            'cinema': {
              'name': data['cinemaName'],
            }
          }
        };
      }).toList();

      // Sort showtimes by start time
      showtimes.sort((a, b) => a['startTime'].compareTo(b['startTime']));

      movie['showtimes'] = showtimes;
      return movie;
    } catch (e) {
      throw Exception('Không thể tải chi tiết phim: $e');
    }
  }

  /// Lấy danh sách rạp chiếu phim
  Future<List<dynamic>> getCinemas() async {
    try {
      final snap = await _db.collection('cinemas').get();
      return snap.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Không thể tải danh sách rạp: $e');
    }
  }

  /// Lấy danh sách lịch chiếu
  Future<List<dynamic>> getShowtimes({
    String? movieId,
    String? cinemaId,
    String? date,
  }) async {
    try {
      Query query = _db.collection('showtimes');

      if (movieId != null) {
        query = query.where('movieId', isEqualTo: movieId);
      }
      if (cinemaId != null) {
        query = query.where('cinemaId', isEqualTo: cinemaId);
      }

      final snap = await query.get();
      var list = snap.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
          'startTime': _formatTimestamp(data['startTime'] as Timestamp?),
          'endTime': _formatTimestamp(data['endTime'] as Timestamp?),
        };
      }).toList();

      // Filter by date if provided (yyyy-MM-dd)
      if (date != null) {
        list = list.where((item) {
          final start = item['startTime'] as String;
          return start.startsWith(date);
        }).toList();
      }

      return list;
    } catch (e) {
      throw Exception('Không thể tải danh sách lịch chiếu: $e');
    }
  }

  /// Lấy chi tiết lịch chiếu và sơ đồ ghế trống/đã đặt
  Future<Map<String, dynamic>> getShowtimeById(String id) async {
    try {
      final showtimeDoc = await _db.collection('showtimes').doc(id).get();
      if (!showtimeDoc.exists) {
        throw Exception('Không tìm thấy lịch chiếu.');
      }
      final showtimeData = showtimeDoc.data()!;
      showtimeData['id'] = showtimeDoc.id;
      showtimeData['startTime'] = _formatTimestamp(showtimeData['startTime'] as Timestamp?);
      showtimeData['endTime'] = _formatTimestamp(showtimeData['endTime'] as Timestamp?);

      // Fetch booked seats for this showtime
      final bookedSnap = await _db
          .collection('booking_seats')
          .where('showtimeId', isEqualTo: id)
          .get();

      final Set<String> bookedSeats = bookedSnap.docs.map((doc) => doc.data()['seatId'] as String).toSet();

      // Generate standard seat layout: rows A to F, numbers 1 to 10
      final List<Map<String, dynamic>> seats = [];
      final rows = ['A', 'B', 'C', 'D', 'E', 'F'];
      
      int seatCounter = 1;
      for (final row in rows) {
        for (int num = 1; num <= 10; num++) {
          final seatId = '$row$num';
          
          String type = 'STANDARD';
          if (['B', 'C', 'D'].contains(row)) {
            type = 'VIP';
          } else if (row == 'F') {
            type = 'COUPLE';
          }

          seats.add({
            'id': seatCounter++,
            'seatId': seatId,
            'row': row,
            'number': num,
            'type': type,
            'status': 'AVAILABLE',
            'isBooked': bookedSeats.contains(seatId),
          });
        }
      }

      showtimeData['seats'] = seats;
      return showtimeData;
    } catch (e) {
      throw Exception('Không thể tải chi tiết lịch chiếu: $e');
    }
  }
}

final movieService = MovieService();
