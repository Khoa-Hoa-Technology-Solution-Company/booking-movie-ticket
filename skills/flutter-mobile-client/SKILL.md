---
name: flutter-mobile-client
description: Use this skill when creating or modifying the Flutter mobile client, API services, auth flow, security screens, or movie booking UI.
---

# Flutter Mobile Client Skill

## Flutter Stack
- Flutter
- Dart
- Material 3
- Dio
- flutter_secure_storage

## Required App Config
Create or maintain:
`lib/config/app_config.dart`

Base URLs:
- emulator: `http://10.0.2.2:5000/api`
- real phone: `http://<LAPTOP_IP>:5000/api`
- production: `https://your-domain.com/api`

Never hardcode API URL in multiple widgets.

## API Layer
Use:
- `ApiClient`
- `TokenStorage`
- service classes

Do not call Dio directly from UI screens if service exists.

## Required Screens
Auth:
- LoginScreen
- RegisterScreen
- VerifyEmailScreen
- OtpScreen

Security:
- SecurityDashboardScreen
- SecurityIssuesScreen
- LoginHistoryScreen
- SecurityAlertsScreen

Movie:
- HomeMovieScreen
- MovieListScreen
- MovieDetailScreen
- ShowtimeScreen
- SeatSelectionScreen
- BookingHistoryScreen
- ProfileScreen

## Android Real Phone
Ensure development HTTP support:
- AndroidManifest may need `android:usesCleartextTraffic="true"`.
- Use laptop LAN IP for real phone testing.

## UI Rules
- Material 3.
- Cinema style, not plain default UI.
- Use loading indicators.
- Use snackbars.
- Show API errors clearly.
- Keep screens easy to demo.
