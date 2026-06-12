# PROJECT_CONTEXT.md

## Project Name
Movie Ticket Booking App with Account Security

## Goal
Build a real Flutter mobile app for booking movie tickets, backed by a real Node.js API and MySQL database. The app must include modern account security features and be easy to demo for Flutter Mobile Programming.

## Product Direction
This is not just an account security demo. Account security is the login/profile protection module of a movie ticket booking app.

## Stack
### Flutter
- Flutter
- Dart
- Material 3
- Dio
- flutter_secure_storage
- Android emulator and real Android phone support

### Backend
- Node.js
- Express.js
- Prisma ORM
- MySQL
- Docker Compose for MySQL
- JWT access token
- Refresh token
- Argon2id
- Nodemailer
- Helmet
- CORS
- express-rate-limit
- Zod or Joi validation

## Main Navigation
Recommended bottom navigation:
- Home
- Movies
- Tickets
- Security
- Profile

## Current Phase
Phase 1: Account Security
- Register
- Login
- Email verification
- OTP / 2FA
- Refresh token
- Logout
- Security dashboard
- Security issues
- Login history
- Security alerts

## Next Phase
Phase 2: Movie Booking
- Movie list
- Movie detail
- Cinema list
- Showtime list
- Seat selection
- Booking creation
- Demo payment
- Ticket generation
- QR placeholder

## Roles
### USER
- Register/login
- Verify email
- Enable 2FA
- View security dashboard
- Browse movies
- Book tickets
- View booking history

### ADMIN
- Manage movies
- Manage cinemas
- Manage rooms
- Manage seats
- Manage showtimes
- Manage bookings
- Manage promotions

## Demo Flow
1. Start backend and MySQL.
2. Register account on Flutter app.
3. Copy verification code from backend console if SMTP is not configured.
4. Verify email.
5. Login.
6. View security dashboard.
7. Enable 2FA.
8. Logout.
9. Login again and verify OTP.
10. Browse movie list.
11. View movie detail.
12. Choose showtime.
13. Choose seats.
14. Create booking.
15. Confirm demo payment.
16. View ticket/booking history.

## Real Phone Requirement
Flutter must not use `localhost` when running on a real phone.

API base URLs:
- Android emulator: `http://10.0.2.2:5000/api`
- Real Android phone on same Wi-Fi: `http://<LAPTOP_IP>:5000/api`
- Production: `https://your-domain.com/api`

Android development may require:
`android:usesCleartextTraffic="true"`
