# Switch to Flutter Prompt

Backend is now ready enough for frontend integration.

Stop focusing only on backend.

Now create or continue the Flutter frontend in `flutter_app/`.

Requirements:
- Use real backend APIs from `docs/API_SPEC.md`.
- Do not use mock data if API exists.
- Configure `lib/config/app_config.dart`.
- Support:
  - Android emulator: `http://10.0.2.2:5000/api`
  - real phone: `http://<LAPTOP_IP>:5000/api`
- Use Dio.
- Use flutter_secure_storage.
- Implement auth flow first:
  - Register
  - Verify Email
  - Login
  - OTP
  - Logout
- Then implement:
  - Security Dashboard
  - Movie List
  - Movie Detail
  - Showtimes
  - Seat Selection
  - Booking History

Before coding, show affected Flutter files and short plan.
