# API_SPEC.md

Base URL:
```text
http://localhost:5000/api
```

For Flutter:
- Android emulator: `http://10.0.2.2:5000/api`
- Real Android phone: `http://<LAPTOP_IP>:5000/api`
- Production: `https://your-domain.com/api`

## Standard Response
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

Protected route header:
```text
Authorization: Bearer <accessToken>
```

## Auth

### POST /auth/register
Body:
```json
{
  "name": "Nguyen Duc Hoang",
  "email": "hoang@example.com",
  "phoneNumber": "0912345678",
  "password": "Password@123"
}
```

### POST /auth/login
Body:
```json
{
  "identifier": "hoang@example.com",
  "password": "Password@123",
  "deviceName": "Android Emulator"
}
```

If 2FA disabled: return tokens.  
If 2FA enabled: return `otpRequired: true`.

`identifier` can be email or Vietnamese phone number.

### POST /auth/verify-email
Body:
```json
{
  "email": "hoang@example.com",
  "code": "123456"
}
```

### POST /auth/resend-email-code
Body:
```json
{
  "email": "hoang@example.com"
}
```

### POST /auth/verify-phone
Body:
```json
{
  "phoneNumber": "0912345678",
  "code": "123456"
}
```

### POST /auth/resend-phone-code
Body:
```json
{
  "phoneNumber": "0912345678"
}
```

### POST /auth/verify-otp
Body:
```json
{
  "identifier": "hoang@example.com",
  "code": "123456",
  "deviceName": "Android Emulator"
}
```

### POST /auth/refresh-token
Body:
```json
{
  "refreshToken": "refresh_token_here"
}
```

### POST /auth/logout
Protected: yes

Body:
```json
{
  "refreshToken": "refresh_token_here"
}
```

## Security

### GET /security/dashboard
Protected: yes

Expected data:
```json
{
  "hasEmail": true,
  "hasPhoneNumber": false,
  "emailVerified": true,
  "phoneVerified": false,
  "twoFactorEnabled": false,
  "lastLoginAt": "2026-01-01T00:00:00.000Z",
  "failedLoginAttempts": 0,
  "accountLocked": false,
  "securityScore": 75,
  "recentAlerts": []
}
```

### GET /security/issues
Protected: yes

Expected data:
```json
[
  {
    "type": "TWO_FACTOR_DISABLED",
    "title": "Two-factor authentication is disabled",
    "description": "Enable 2FA to protect your account.",
    "severity": "MEDIUM"
  }
]
```

### GET /security/login-history?page=1&limit=10
Protected: yes

### GET /security/alerts
Protected: yes

### PATCH /security/toggle-2fa
Protected: yes

Body:
```json
{
  "enabled": true
}
```

## Movies

### GET /movies?status=ACTIVE&page=1&limit=10&search=avatar

### GET /movies/:id

### POST /movies
Protected: yes  
Role: ADMIN

Body:
```json
{
  "title": "Movie title",
  "description": "Description",
  "posterUrl": "https://example.com/poster.jpg",
  "duration": 120,
  "genre": "Action",
  "ageRating": "T13",
  "releaseDate": "2026-01-01T00:00:00.000Z",
  "status": "ACTIVE"
}
```

### PUT /movies/:id
Protected: yes  
Role: ADMIN

### DELETE /movies/:id
Protected: yes  
Role: ADMIN

## Cinemas

### GET /cinemas
### GET /cinemas/:id
### POST /cinemas
Protected: yes, ADMIN
### PUT /cinemas/:id
Protected: yes, ADMIN
### DELETE /cinemas/:id
Protected: yes, ADMIN

## Showtimes

### GET /showtimes?movieId=<id>&cinemaId=<id>&date=2026-01-01

### GET /showtimes/:id
Should include movie, cinema, room, seats, and seat availability.

### POST /showtimes
Protected: yes  
Role: ADMIN

Body:
```json
{
  "movieId": "movie_id",
  "roomId": "room_id",
  "startTime": "2026-01-01T10:00:00.000Z",
  "endTime": "2026-01-01T12:00:00.000Z",
  "price": 75000
}
```

## Bookings

### POST /bookings
Protected: yes

Body:
```json
{
  "showtimeId": "showtime_id",
  "seatIds": ["seat_id_1", "seat_id_2"],
  "promotionCode": "SALE10"
}
```

Rules:
- check showtime
- check seats
- prevent double booking
- create PENDING booking

### POST /payments/demo-confirm
Protected: yes

Body:
```json
{
  "bookingId": "booking_id"
}
```

Rules:
- create DEMO payment
- mark payment PAID
- mark booking CONFIRMED
- generate ticket

### GET /bookings/history
Protected: yes

### GET /bookings/:id
Protected: yes

### PATCH /bookings/:id/cancel
Protected: yes

## Profile

### GET /users/profile
Protected: yes

### PUT /users/profile
Protected: yes

Body:
```json
{
  "name": "Nguyen Duc Hoang"
}
```

### PUT /users/change-password
Protected: yes

Body:
```json
{
  "currentPassword": "Password@123",
  "newPassword": "NewPassword@123"
}
```
