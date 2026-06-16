-- ===================== ENUMS =====================

CREATE TYPE user_role AS ENUM ('USER', 'ADMIN');
CREATE TYPE movie_status AS ENUM ('COMING_SOON', 'NOW_SHOWING', 'ENDED');
CREATE TYPE seat_type AS ENUM ('STANDARD', 'VIP', 'COUPLE');
CREATE TYPE seat_status AS ENUM ('AVAILABLE', 'MAINTENANCE');
CREATE TYPE booking_status AS ENUM ('PENDING', 'CONFIRMED', 'CANCELLED', 'EXPIRED');
CREATE TYPE payment_method AS ENUM ('CASH', 'DEMO');
CREATE TYPE payment_status AS ENUM ('PENDING', 'PAID', 'FAILED', 'REFUNDED');
CREATE TYPE ticket_status AS ENUM ('ACTIVE', 'USED', 'CANCELLED', 'EXPIRED');
CREATE TYPE alert_severity AS ENUM ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL');

-- ===================== TABLES =====================

-- users: link với Supabase Auth qua auth.uid()
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT auth.uid(),   -- Dùng Supabase Auth UID
  name VARCHAR(100) NOT NULL,
  email VARCHAR(255) UNIQUE,
  role user_role DEFAULT 'USER',
  email_verified BOOLEAN DEFAULT false,
  two_factor_enabled BOOLEAN DEFAULT false,
  failed_login_attempts INT DEFAULT 0,
  locked_until TIMESTAMPTZ,
  last_login_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- login_history
CREATE TABLE login_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  email VARCHAR(255),
  device_name VARCHAR(255),
  user_agent VARCHAR(500),
  success BOOLEAN NOT NULL,
  reason VARCHAR(255),
  suspicious BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- security_alerts
CREATE TABLE security_alerts (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL,
  message VARCHAR(500) NOT NULL,
  severity alert_severity DEFAULT 'MEDIUM',
  read BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- movies
CREATE TABLE movies (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  description TEXT NOT NULL,
  poster_url TEXT,
  trailer_url TEXT,
  duration INT NOT NULL,            -- phút
  age_rating VARCHAR(10),           -- P, C13, C16, C18
  genre VARCHAR(255),
  director VARCHAR(255),
  "cast" TEXT,
  release_date DATE,
  status movie_status DEFAULT 'NOW_SHOWING',
  rating FLOAT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- cinemas
CREATE TABLE cinemas (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  address VARCHAR(500) NOT NULL,
  city VARCHAR(100) NOT NULL,
  image_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- rooms
CREATE TABLE rooms (
  id BIGSERIAL PRIMARY KEY,
  cinema_id BIGINT REFERENCES cinemas(id) ON DELETE CASCADE,
  name VARCHAR(50) NOT NULL,
  total_seats INT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- seats
CREATE TABLE seats (
  id BIGSERIAL PRIMARY KEY,
  room_id BIGINT REFERENCES rooms(id) ON DELETE CASCADE,
  "row" VARCHAR(5) NOT NULL,
  number INT NOT NULL,
  type seat_type DEFAULT 'STANDARD',
  status seat_status DEFAULT 'AVAILABLE',
  UNIQUE(room_id, "row", number)
);

-- showtimes
CREATE TABLE showtimes (
  id BIGSERIAL PRIMARY KEY,
  movie_id BIGINT REFERENCES movies(id) ON DELETE CASCADE,
  room_id BIGINT REFERENCES rooms(id) ON DELETE CASCADE,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  price FLOAT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- bookings
CREATE TABLE bookings (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  showtime_id BIGINT REFERENCES showtimes(id) ON DELETE CASCADE,
  status booking_status DEFAULT 'PENDING',
  total_amount FLOAT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- booking_seats
CREATE TABLE booking_seats (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT REFERENCES bookings(id) ON DELETE CASCADE,
  seat_id BIGINT REFERENCES seats(id) ON DELETE CASCADE,
  UNIQUE(booking_id, seat_id)
);
-- Prevent double booking: same seat + same showtime
-- Sử dụng trigger thay cho conditional index vì PostgreSQL không cho phép subquery trong index predicate
CREATE OR REPLACE FUNCTION check_double_booking()
RETURNS TRIGGER AS $$
DECLARE
  v_showtime_id BIGINT;
  v_conflict_count INT;
BEGIN
  -- Lấy showtime_id của đơn đặt vé hiện tại
  SELECT showtime_id INTO v_showtime_id
  FROM bookings
  WHERE id = NEW.booking_id;

  -- Kiểm tra xem ghế đã được đặt cho showtime này bởi đơn đặt vé PENDING hoặc CONFIRMED khác chưa
  SELECT COUNT(*) INTO v_conflict_count
  FROM booking_seats bs
  JOIN bookings b ON b.id = bs.booking_id
  WHERE b.showtime_id = v_showtime_id
    AND b.status IN ('PENDING', 'CONFIRMED')
    AND bs.seat_id = NEW.seat_id
    AND bs.booking_id <> NEW.booking_id;

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Ghế này đã được đặt cho suất chiếu này bởi đơn đặt vé khác.';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_double_booking
BEFORE INSERT ON booking_seats
FOR EACH ROW
EXECUTE FUNCTION check_double_booking();

-- tickets
CREATE TABLE tickets (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
  ticket_code VARCHAR(20) UNIQUE NOT NULL,
  qr_code TEXT,
  status ticket_status DEFAULT 'ACTIVE',
  created_at TIMESTAMPTZ DEFAULT now()
);

-- payments
CREATE TABLE payments (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
  method payment_method DEFAULT 'DEMO',
  amount FLOAT NOT NULL,
  status payment_status DEFAULT 'PENDING',
  transaction_code VARCHAR(50) UNIQUE,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- promotions
CREATE TABLE promotions (
  id BIGSERIAL PRIMARY KEY,
  code VARCHAR(50) UNIQUE NOT NULL,
  discount_percent INT NOT NULL CHECK (discount_percent BETWEEN 1 AND 100),
  max_discount FLOAT,
  min_purchase FLOAT,
  start_date DATE NOT NULL,
  end_date DATE NOT NULL,
  active BOOLEAN DEFAULT true,
  usage_limit INT,
  usage_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
