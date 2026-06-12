# DATABASE_DESIGN.md

Database: `account_security_db`  
ORM: Prisma  
Engine: MySQL

## Enums
Recommended Prisma enums:
- Role: USER, ADMIN
- VerificationCodeType: EMAIL_VERIFY, PHONE_VERIFY, OTP_LOGIN, PASSWORD_RESET
- SecurityAlertType: NEW_DEVICE_LOGIN, MANY_FAILED_ATTEMPTS, EMAIL_NOT_VERIFIED, TWO_FACTOR_DISABLED, PASSWORD_CHANGED, ACCOUNT_LOCKED
- Severity: LOW, MEDIUM, HIGH, CRITICAL
- MovieStatus: ACTIVE, INACTIVE, COMING_SOON, ENDED
- SeatType: STANDARD, VIP, COUPLE
- SeatStatus: ACTIVE, BROKEN, DISABLED
- ShowtimeStatus: OPEN, CLOSED, CANCELLED
- BookingStatus: PENDING, CONFIRMED, CANCELLED, EXPIRED
- TicketStatus: VALID, USED, CANCELLED
- PaymentMethod: CASH, DEMO, VNPAY, MOMO
- PaymentStatus: PENDING, PAID, FAILED, REFUNDED

## Security Tables

### users
Purpose: store account data.

Fields:
- id
- name
- email nullable unique
- phoneNumber nullable unique
- passwordHash
- emailVerified default false
- phoneVerified default false
- twoFactorEnabled default false
- role default USER
- failedLoginAttempts default 0
- lockedUntil nullable
- lastLoginAt nullable
- createdAt
- updatedAt

Relations:
- verificationCodes
- refreshTokens
- loginHistory
- securityAlerts
- bookings

### verification_codes
Purpose: store hashed verification/OTP/password reset codes.

Fields:
- id
- userId
- codeHash
- type
- expiresAt
- used default false
- attempts default 0
- createdAt

Rules:
- Store only hashed code.
- Check expiration.
- Limit attempts.
- Mark as used after success.

### refresh_tokens
Purpose: store hashed refresh tokens.

Fields:
- id
- userId
- tokenHash
- expiresAt
- revoked default false
- createdAt

Rules:
- Store only token hash.
- Revoke on logout.
- Check expiration on refresh.

### login_history
Purpose: store login attempts.

Fields:
- id
- userId nullable
- email nullable
- ipAddress nullable
- userAgent nullable
- deviceName nullable
- success
- reason nullable
- suspicious default false
- createdAt

Rules:
- Log both success and failure.
- Never log password.

### security_alerts
Purpose: store account warning events.

Fields:
- id
- userId
- type
- message
- severity
- read default false
- createdAt

## Movie Booking Tables

### movies
Fields:
- id
- title
- description
- posterUrl nullable
- backdropUrl nullable
- trailerUrl nullable
- duration
- genre
- ageRating nullable
- language nullable
- releaseDate nullable
- status
- createdAt
- updatedAt

### cinemas
Fields:
- id
- name
- address
- city
- phone nullable
- createdAt
- updatedAt

### rooms
Fields:
- id
- cinemaId
- name
- totalSeats
- createdAt
- updatedAt

### seats
Fields:
- id
- roomId
- row
- seatNumber
- type
- status
- createdAt
- updatedAt

Unique:
- roomId + row + seatNumber

### showtimes
Fields:
- id
- movieId
- roomId
- startTime
- endTime
- price
- status
- createdAt
- updatedAt

Rules:
- price > 0
- one movie + one room
- should avoid overlapping room schedule when implemented

### bookings
Fields:
- id
- userId
- showtimeId
- totalAmount
- status
- expiresAt nullable
- createdAt
- updatedAt

Rules:
- user must be authenticated
- starts as PENDING
- confirmed after payment/demo payment

### booking_seats
Fields:
- id
- bookingId
- seatId
- showtimeId
- price
- createdAt

Unique:
- showtimeId + seatId

Rule:
- prevents double booking the same seat for the same showtime

### tickets
Fields:
- id
- bookingId unique
- ticketCode unique
- qrCode nullable
- status
- createdAt
- updatedAt

### payments
Fields:
- id
- bookingId unique
- method
- amount
- status
- transactionCode nullable
- createdAt
- updatedAt

### promotions
Fields:
- id
- code unique
- discountPercent
- startDate
- endDate
- active default true
- createdAt
- updatedAt

Rule:
- discountPercent from 1 to 100
