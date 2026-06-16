import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class BookingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Tạo một đơn đặt vé mới (Cloud Function)
  Future<Map<String, dynamic>> createBooking({
    required String showtimeId,
    required List<String> seatIds,
    String? promotionCode,
  }) async {
    debugPrint('[BookingService] Call createBooking: showtimeId=$showtimeId, seats=$seatIds, promo=$promotionCode');
    try {
      final callable = _functions.httpsCallable('createBooking');
      final result = await callable.call({
        'showtimeId': showtimeId,
        'seatIds': seatIds,
        'promotionCode': promotionCode,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      debugPrint('[BookingService] createBooking success: bookingId=${data['bookingId']}, amount=${data['totalAmount']}');
      return data;
    } catch (e) {
      debugPrint('[BookingService] createBooking failed (seat conflict or error): $e');
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Xác nhận thanh toán Demo và xuất vé (Cloud Function)
  Future<Map<String, dynamic>> confirmDemoPayment(String bookingId) async {
    debugPrint('[BookingService] Call confirmDemoPayment: bookingId=$bookingId');
    try {
      final callable = _functions.httpsCallable('confirmDemoPayment');
      final result = await callable.call({
        'bookingId': bookingId,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      debugPrint('[BookingService] confirmDemoPayment success for bookingId=$bookingId');
      return data;
    } catch (e) {
      debugPrint('[BookingService] confirmDemoPayment failed: $e');
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }

  /// Lấy lịch sử đặt vé của user hiện tại
  Future<List<dynamic>> getBookingHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Chưa đăng nhập');

      final snap = await _db
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .get();

      final List<dynamic> bookings = [];
      for (final doc in snap.docs) {
        final bookingData = doc.data();
        bookingData['id'] = doc.id;
        
        // Fetch showtime details
        final showtimeId = bookingData['showtimeId'] as String;
        final showtimeDoc = await _db.collection('showtimes').doc(showtimeId).get();
        if (showtimeDoc.exists) {
          final showtimeData = showtimeDoc.data()!;
          showtimeData['id'] = showtimeDoc.id;
          
          if (showtimeData['startTime'] != null) {
            showtimeData['startTime'] = (showtimeData['startTime'] as Timestamp).toDate().toIso8601String();
          }
          if (showtimeData['endTime'] != null) {
            showtimeData['endTime'] = (showtimeData['endTime'] as Timestamp).toDate().toIso8601String();
          }

          final movieDoc = await _db.collection('movies').doc(showtimeData['movieId']).get();
          showtimeData['movie'] = movieDoc.exists ? movieDoc.data() : null;
          showtimeData['room'] = {
            'name': showtimeData['roomName'],
            'cinema': {
              'name': showtimeData['cinemaName'],
            }
          };
          bookingData['showtime'] = showtimeData;
        }

        // Fetch tickets corresponding to this booking
        final ticketsSnap = await _db
            .collection('tickets')
            .where('bookingId', isEqualTo: doc.id)
            .get();
        bookingData['tickets'] = ticketsSnap.docs.map((d) => d.data()).toList();

        // Populate bookingSeats mock mapping for UI
        final List<Map<String, dynamic>> bookingSeats = [];
        final seatIds = bookingData['seatIds'] as List<dynamic>? ?? [];
        for (final seatId in seatIds) {
          final seatStr = seatId.toString();
          if (seatStr.isNotEmpty) {
            final row = seatStr.substring(0, 1);
            final number = int.tryParse(seatStr.substring(1)) ?? 1;
            bookingSeats.add({
              'seat': {
                'row': row,
                'number': number,
              }
            });
          }
        }
        bookingData['bookingSeats'] = bookingSeats;

        bookings.add(bookingData);
      }

      // Sort bookings by creation date descending
      bookings.sort((a, b) {
        final ta = a['createdAt'] as Timestamp?;
        final tb = b['createdAt'] as Timestamp?;
        if (ta == null || tb == null) return 0;
        return tb.compareTo(ta);
      });

      return bookings;
    } catch (e) {
      throw Exception('Không thể tải lịch sử đặt vé: $e');
    }
  }

  /// Chi tiết đơn đặt vé
  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      final doc = await _db.collection('bookings').doc(id).get();
      if (!doc.exists) throw Exception('Không tìm thấy thông tin đặt vé.');
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    } catch (e) {
      throw Exception('Không thể tải thông tin đặt vé: $e');
    }
  }

  /// Hủy đặt vé (Cloud Function)
  Future<Map<String, dynamic>> cancelBooking(String id) async {
    debugPrint('[BookingService] Call cancelBooking: bookingId=$id');
    try {
      final callable = _functions.httpsCallable('cancelBooking');
      final result = await callable.call({
        'bookingId': id,
      });
      final data = Map<String, dynamic>.from(result.data as Map);
      debugPrint('[BookingService] cancelBooking success for bookingId=$id');
      return data;
    } catch (e) {
      debugPrint('[BookingService] cancelBooking failed: $e');
      throw Exception(e.toString().replaceAll(RegExp(r'\[.*\]\s*'), ''));
    }
  }
}

final bookingService = BookingService();
