import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _emulatorUrl = 'http://10.0.2.2:5000/api';
  static const String _localHostUrl = 'http://localhost:5000/api';
  static const String _overrideUrl = String.fromEnvironment('API_BASE_URL');

  // Tự động phân tích môi trường:
  // - Nếu có `--dart-define=API_BASE_URL=...` thì ưu tiên URL đó
  // - Nếu chạy trên Web (Chrome/Edge): sử dụng localhost
  // - Nếu chạy trên Android emulator: sử dụng 10.0.2.2
  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) {
      return _overrideUrl;
    }
    if (kIsWeb) {
      return _localHostUrl;
    }
    return _emulatorUrl;
  }

  // Google OAuth 2.0 Web Client ID để Flutter lấy idToken gửi lên backend
  static const String googleWebClientId = '275549574877-j7oiulmv5kffq6okddf673klrtqsctdr.apps.googleusercontent.com';
}
