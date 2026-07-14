import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/cinema.dart';

class CinemaDistanceResult {
  final double distanceKm;
  final String distanceText;
  final String durationText;

  const CinemaDistanceResult({
    required this.distanceKm,
    required this.distanceText,
    required this.durationText,
  });
}

class LocationService {
  // Tránh tạo nhiều instance
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Vị trí fallback mặc định khi GPS không khả dụng (máy ảo / từ chối quyền).
  /// Tọa độ này được lấy từ vị trí thực tế của người dùng tại khu vực Thủ Đức, TP.HCM.
  /// Trên điện thoại thật, GPS thật sẽ luôn được ưu tiên sử dụng trước.
  static const double _fallbackLat = 10.8532;
  static const double _fallbackLng = 106.7898;

  /// Cờ cho biết vị trí hiện tại có phải là GPS thực không.
  bool isUsingFallback = false;

  /// Truy vấn tọa độ hiện tại của người dùng sau khi xin quyền định vị.
  /// Trả về vị trí mặc định (Quận 1, TP.HCM) nếu GPS thất bại để đảm bảo luôn hiển thị khoảng cách.
  Future<Position> getCurrentPosition() async {
    final defaultPosition = Position(
      latitude: _fallbackLat,
      longitude: _fallbackLng,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      altitudeAccuracy: 0.0,
      heading: 0.0,
      headingAccuracy: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
    );

    try {
      // 1. Kiểm tra dịch vụ định vị (GPS) có bật không
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[GPS] Dịch vụ định vị tắt → dùng fallback Quận 1.');
        isUsingFallback = true;
        return defaultPosition;
      }

      // 2. Kiểm tra và yêu cầu cấp quyền
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        debugPrint('[GPS] Quyền bị từ chối → dùng fallback Quận 1.');
        isUsingFallback = true;
        return defaultPosition;
      }

      // 3. Lấy vị trí bằng forceAndroidLocationManager = true
      //    Cách này bắt buộc Android dùng LocationManager thuần (không qua Google Play Services)
      //    → đảm bảo nhận được mock location từ Extended Controls trên máy ảo
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 8),
      );
      debugPrint('[GPS] Vị trí OK: ${pos.latitude}, ${pos.longitude}');
      isUsingFallback = false;
      return pos;
    } catch (e) {
      debugPrint('[GPS] Lỗi: $e → dùng fallback Quận 1.');
      isUsingFallback = true;
      return defaultPosition;
    }
  }

  /// Tính toán khoảng cách và thời gian di chuyển từ người dùng đến các rạp phim.
  /// Sử dụng Goong.io Distance Matrix API. Nếu thất bại hoặc chưa cấu hình API Key,
  /// tự động sử dụng công thức tính khoảng cách đường chim bay (Haversine) làm phương án dự phòng.
  Future<Map<int, CinemaDistanceResult>> calculateDistances({
    required double userLat,
    required double userLng,
    required List<Cinema> cinemas,
  }) async {
    final Map<int, CinemaDistanceResult> results = {};
    
    // Lọc danh sách rạp có tọa độ hợp lệ
    final validCinemas = cinemas.where((c) => c.latitude != null && c.longitude != null).toList();
    if (validCinemas.isEmpty) return results;

    final apiKey = AppConfig.goongApiKey;
    final isDefaultKey = apiKey == 'YOUR_GOONG_API_KEY' || apiKey.trim().isEmpty;

    if (!isDefaultKey) {
      try {
        // Chuẩn bị chuỗi điểm đến: "lat1,lng1|lat2,lng2|..."
        final destinationsStr = validCinemas
            .map((c) => '${c.latitude},${c.longitude}')
            .join('|');
        
        final url = Uri.parse(
          'https://rsapi.goong.io/DistanceMatrix?origins=$userLat,$userLng&destinations=$destinationsStr&vehicle=car&api_key=$apiKey',
        );

        final response = await http.get(url).timeout(const Duration(seconds: 4));
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['rows'] != null && data['rows'].isNotEmpty) {
            final elements = data['rows'][0]['elements'] as List;
            
            for (int i = 0; i < elements.length; i++) {
              final elem = elements[i];
              if (elem['status'] == 'OK') {
                final double distanceKm = (elem['distance']['value'] as num) / 1000.0;
                final String distanceText = elem['distance']['text'] as String? ?? '${distanceKm.toStringAsFixed(1)} km';
                final String durationText = elem['duration']['text'] as String? ?? '${(distanceKm * 2).ceil()} phút';
                
                results[validCinemas[i].id] = CinemaDistanceResult(
                  distanceKm: distanceKm,
                  distanceText: distanceText,
                  durationText: durationText,
                );
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Lỗi khi gọi Goong Distance Matrix API: $e. Sử dụng phương án dự phòng Haversine.');
      }
    }

    // Phương án dự phòng (Fallback): Tính Haversine cho những rạp chưa chèn được từ Goong API
    for (final cinema in validCinemas) {
      if (!results.containsKey(cinema.id)) {
        final double dist = _haversineDistance(userLat, userLng, cinema.latitude!, cinema.longitude!);
        // Ước lượng thời gian di chuyển với vận tốc trung bình xe máy/ô tô 30km/h: 1km đi hết khoảng 2 phút
        final int estimatedMinutes = (dist * 2.0).ceil();
        
        results[cinema.id] = CinemaDistanceResult(
          distanceKm: dist,
          distanceText: '${dist.toStringAsFixed(1)} km',
          durationText: estimatedMinutes > 60 
              ? '${estimatedMinutes ~/ 60} giờ ${estimatedMinutes % 60} phút'
              : '$estimatedMinutes phút',
        );
      }
    }

    return results;
  }

  /// Công thức Haversine tính khoảng cách đường chim bay giữa 2 điểm (km)
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Bán kính Trái Đất (km)
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
        
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;
}
