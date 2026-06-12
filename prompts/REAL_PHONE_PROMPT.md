# Real Android Phone Prompt

Make the Flutter app work on a real Android phone.

Requirements:
- Do not use `localhost` for real phone.
- Add API config for laptop LAN IP.
- Keep API base URL in one file: `lib/config/app_config.dart`.
- Add Android cleartext config for local HTTP development if needed.
- Document how to find laptop IP.
- Document that phone and laptop must be on the same Wi-Fi.
- Backend must listen on `0.0.0.0` or be reachable from LAN.
