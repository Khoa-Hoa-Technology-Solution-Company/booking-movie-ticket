import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _emulatorUrl = 'http://10.0.2.2:3001/api';
  static const String _localHostUrl = 'http://localhost:3001/api';

  // Tự động phân tích môi trường:
  // - Nếu chạy trên Web (Chrome/Edge): sử dụng localhost
  // - Nếu chạy trên thiết bị di động (Android Emulator): sử dụng 10.0.2.2
  static String get baseUrl {
    if (kIsWeb) {
      return _localHostUrl;
    }
    return _emulatorUrl;
  }
}
