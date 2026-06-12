# AI_RULES.md

## 1. Core Behavior
- Always keep the movie ticket booking direction.
- Do not turn the project into a security-only app.
- Keep implementation practical for student demo.
- Prefer complete runnable code over theoretical explanation.
- Keep files modular but not over-engineered.
- Update docs when changing API or database design.

## 2. Implementation Order
1. Database and Prisma schema.
2. Backend APIs.
3. API testing.
4. Flutter services.
5. Flutter UI.
6. Android real phone support.
7. Demo script.

## 3. Security Requirements
### Password
- Use Argon2id.
- Minimum password strength:
  - 8 characters
  - uppercase
  - lowercase
  - number
  - special character
- Never log passwords.

### JWT
- Access token: 15 minutes.
- Refresh token: 7 days.
- Store only refresh token hash.
- Revoke refresh token on logout.
- Never return tokenHash.

### Email Verification and OTP
- Use 6-digit codes.
- Store only code hash.
- Email verification expires in 10 minutes.
- OTP login expires in 5 minutes.
- Limit attempts.
- Mark used after success.
- Local development can log raw code only if `LOG_EMAIL_CODES=true`.

### Account Protection
- Lock account for 5 minutes after 5 failed password attempts.
- Record successful and failed login history.
- Store IP, user-agent, and deviceName when available.
- Create security alerts for:
  - many failed attempts
  - account locked
  - new device login
  - 2FA disabled
  - password changed

### API Security
- Use Helmet.
- Use CORS config.
- Use express-rate-limit.
- Validate input with Zod or Joi.
- Use Prisma to avoid SQL injection.
- Do not expose internal errors to client.

## 4. Backend Structure
Use this structure:

```text
backend/
├── prisma/
│   ├── schema.prisma
│   └── seed.js
├── src/
│   ├── app.js
│   ├── server.js
│   ├── config/
│   │   ├── env.js
│   │   ├── prisma.js
│   │   └── cors.js
│   ├── middlewares/
│   │   ├── auth.middleware.js
│   │   ├── role.middleware.js
│   │   ├── validate.middleware.js
│   │   ├── rateLimit.middleware.js
│   │   └── error.middleware.js
│   ├── utils/
│   │   ├── apiResponse.js
│   │   ├── asyncHandler.js
│   │   ├── code.js
│   │   ├── email.js
│   │   ├── hash.js
│   │   ├── jwt.js
│   │   └── device.js
│   └── modules/
│       ├── auth/
│       ├── security/
│       ├── users/
│       ├── movies/
│       ├── cinemas/
│       ├── showtimes/
│       ├── bookings/
│       └── payments/
├── docker-compose.yml
├── .env.example
└── package.json
```

Each module should contain:
- `*.routes.js`
- `*.controller.js`
- `*.service.js`
- `*.validation.js`

## 5. Flutter Structure
Use this structure:

```text
flutter_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── app_config.dart
│   │   └── routes.dart
│   ├── core/
│   │   ├── api/
│   │   │   ├── api_client.dart
│   │   │   └── api_exception.dart
│   │   └── storage/
│   │       └── token_storage.dart
│   ├── models/
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── security_service.dart
│   │   ├── movie_service.dart
│   │   └── booking_service.dart
│   ├── screens/
│   │   ├── auth/
│   │   ├── security/
│   │   ├── movies/
│   │   ├── booking/
│   │   └── profile/
│   └── widgets/
└── pubspec.yaml
```

## 6. API Response Standard
Success:
```json
{
  "success": true,
  "message": "Success message",
  "data": {}
}
```

Error:
```json
{
  "success": false,
  "message": "Error message"
}
```

Pagination:
```json
{
  "success": true,
  "message": "Success",
  "data": {
    "items": [],
    "pagination": {
      "page": 1,
      "limit": 10,
      "total": 0,
      "totalPages": 0
    }
  }
}
```

## 7. UI Rules
- Material 3.
- Movie/cinema visual style.
- Security appears inside account/profile area.
- Use cards, icons, loading states, error states, and snackbars.
- Avoid default blank Flutter UI.
- Bottom navigation:
  - Home
  - Movies
  - Tickets
  - Security
  - Profile

## 8. Do Not Do
- Do not use mock data after backend endpoint exists.
- Do not leave required functions as TODO.
- Do not mix all backend logic inside one file.
- Do not call APIs directly in Flutter widgets when services exist.
- Do not hardcode laptop IP in many files; use `app_config.dart`.
- Do not break Android real phone support.
