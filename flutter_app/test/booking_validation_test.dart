import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/utils/promotion_validator.dart';
import 'package:flutter_app/models/showtime.dart';
import 'package:flutter_app/models/cinema.dart';
import 'package:flutter_app/services/location_service.dart';

void main() {
  group('PromotionValidator Tests', () {
    final promoBase = {
      'code': 'SUMMER50',
      'discount_percent': 50,
      'max_discount': 50000.0,
      'min_purchase': 100000.0,
      'start_date': '2026-07-01',
      'end_date': '2026-07-31',
      'active': true,
      'usage_limit': 10,
      'usage_count': 0,
    };

    final now = DateTime(2026, 7, 14); // Giữa tháng 7/2026

    test('Valid promotion should be accepted', () {
      final result = PromotionValidator.validate(
        promo: promoBase,
        purchaseAmount: 120000.0,
        now: now,
      );
      expect(result.isValid, isTrue);
      expect(result.errorMessage, isNull);
    });

    test('Inactive promotion should be rejected', () {
      final inactivePromo = Map<String, dynamic>.from(promoBase)..['active'] = false;
      final result = PromotionValidator.validate(
        promo: inactivePromo,
        purchaseAmount: 120000.0,
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('bị vô hiệu hóa'));
    });

    test('Insufficient purchase amount should be rejected', () {
      final result = PromotionValidator.validate(
        promo: promoBase,
        purchaseAmount: 80000.0, // Thấp hơn min_purchase 100k
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('chưa đạt giá trị tối thiểu'));
    });

    test('Expired promotion should be rejected', () {
      final expiredNow = DateTime(2026, 8, 1); // 1/8/2026 đã hết hạn
      final result = PromotionValidator.validate(
        promo: promoBase,
        purchaseAmount: 120000.0,
        now: expiredNow,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('đã hết hạn sử dụng'));
    });

    test('Not yet active promotion should be rejected', () {
      final earlyNow = DateTime(2026, 6, 30); // 30/6/2026 chưa đến hạn
      final result = PromotionValidator.validate(
        promo: promoBase,
        purchaseAmount: 120000.0,
        now: earlyNow,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('chưa đến thời gian áp dụng'));
    });

    test('Promotion exceeding usage limit should be rejected', () {
      final exhaustedPromo = Map<String, dynamic>.from(promoBase)
        ..['usage_count'] = 10
        ..['usage_limit'] = 10;
      final result = PromotionValidator.validate(
        promo: exhaustedPromo,
        purchaseAmount: 120000.0,
        now: now,
      );
      expect(result.isValid, isFalse);
      expect(result.errorMessage, contains('đã hết lượt sử dụng'));
    });
  });

  group('Showtime Model and Date Validation Tests', () {
    test('Showtime is parsed correctly from JSON', () {
      final json = {
        'id': 42,
        'movie_id': 1,
        'room_id': 2,
        'start_time': '2026-07-14T19:30:00Z',
        'end_time': '2026-07-14T21:30:00Z',
        'price': 95000.0,
      };

      final showtime = Showtime.fromJson(json);
      expect(showtime.id, equals(42));
      expect(showtime.price, equals(95000.0));
      expect(showtime.startTime, equals(DateTime.parse('2026-07-14T19:30:00Z').toLocal()));
    });

    test('Past showtimes filter logic works correctly', () {
      final showtimes = [
        Showtime(
          id: 1,
          movieId: 1,
          roomId: 1,
          startTime: DateTime.now().subtract(const Duration(hours: 2)), // Đã bắt đầu từ 2 tiếng trước
          endTime: DateTime.now().subtract(const Duration(minutes: 15)),
          price: 75000.0,
        ),
        Showtime(
          id: 2,
          movieId: 1,
          roomId: 1,
          startTime: DateTime.now().add(const Duration(hours: 2)), // 2 tiếng nữa mới bắt đầu
          endTime: DateTime.now().add(const Duration(hours: 4)),
          price: 95000.0,
        ),
      ];

      final now = DateTime.now();
      // Lọc giống trong UI: st.startTime.isAfter(now)
      final futureShowtimes = showtimes.where((st) => st.startTime.isAfter(now)).toList();

      expect(futureShowtimes.length, equals(1));
      expect(futureShowtimes.first.id, equals(2));
    });
  });

  group('Cinema Model and Location Service Tests', () {
    test('Cinema model parses latitude and longitude correctly', () {
      final json = {
        'id': 1,
        'name': 'CGV Vincom Center',
        'address': '72 Lê Thánh Tôn, Quận 1',
        'city': 'Hồ Chí Minh',
        'image_url': 'http://image.jpg',
        'latitude': 10.7779,
        'longitude': 106.7020,
      };

      final cinema = Cinema.fromJson(json);
      expect(cinema.id, equals(1));
      expect(cinema.latitude, equals(10.7779));
      expect(cinema.longitude, equals(106.7020));
      expect(cinema.toJson()['latitude'], equals(10.7779));
    });

    test('LocationService Haversine calculation returns expected distance', () {
      // Tọa độ CGV Vincom Center: 10.7779, 106.7020
      // Tọa độ Lotte Nowzone: 10.7645, 106.6823
      // Khoảng cách thực tế chim bay khoảng ~2.6 km
      
      final cinemaVincom = Cinema(
        id: 1,
        name: 'CGV Vincom Center',
        address: '72 Lê Thánh Tôn',
        city: 'Hồ Chí Minh',
        latitude: 10.7779,
        longitude: 106.7020,
      );

      final cinemaNowzone = Cinema(
        id: 2,
        name: 'Lotte Nowzone',
        address: '235 Nguyễn Văn Cừ',
        city: 'Hồ Chí Minh',
        latitude: 10.7645,
        longitude: 106.6823,
      );

      // Chạy Haversine qua LocationService (bằng cách truyền api_key trống để kích hoạt fallback)
      // Tọa độ người dùng ở CGV Vincom Center
      final service = LocationService.instance;
      
      // Kiểm tra tính khoảng cách qua API fallback
      service.calculateDistances(
        userLat: 10.7779,
        userLng: 106.7020,
        cinemas: [cinemaVincom, cinemaNowzone],
      ).then((results) {
        expect(results[1]!.distanceKm, closeTo(0.0, 0.1));
        expect(results[2]!.distanceKm, closeTo(2.6, 0.2));
        expect(results[2]!.distanceText, contains('2.'));
      });
    });
  });
}
