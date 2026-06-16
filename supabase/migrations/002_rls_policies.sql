-- ========================================================
-- TRIGGER TỰ ĐỘNG THÊM USER VÀO public.users KHI SIGN UP
-- ========================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, name, email, role)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'name', 'Người dùng mới'),
    new.email,
    'USER'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger này chạy khi có record mới trong table auth.users của Supabase Auth
CREATE OR REPLACE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


-- ========================================================
-- KÍCH HOẠT ROW LEVEL SECURITY (RLS)
-- ========================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE security_alerts ENABLE ROW LEVEL SECURITY;
ALTER TABLE movies ENABLE ROW LEVEL SECURITY;
ALTER TABLE cinemas ENABLE ROW LEVEL SECURITY;
ALTER TABLE rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE showtimes ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_seats ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE promotions ENABLE ROW LEVEL SECURITY;

-- ========================================================
-- ĐỊNH NGHĨA POLICIES (CHÍNH SÁCH TRUY CẬP)
-- ========================================================

-- Helper function: Kiểm tra xem user có phải Admin không
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 1. Users table
CREATE POLICY "Users read own profile" ON users
  FOR SELECT USING (auth.uid() = id OR is_admin());

CREATE POLICY "Users update own profile" ON users
  FOR UPDATE USING (auth.uid() = id OR is_admin());

-- 2. Movies table
CREATE POLICY "Anyone can read movies" ON movies
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage movies" ON movies
  FOR ALL USING (is_admin());

-- 3. Cinemas table
CREATE POLICY "Anyone can read cinemas" ON cinemas
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage cinemas" ON cinemas
  FOR ALL USING (is_admin());

-- 4. Rooms table
CREATE POLICY "Anyone can read rooms" ON rooms
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage rooms" ON rooms
  FOR ALL USING (is_admin());

-- 5. Seats table
CREATE POLICY "Anyone can read seats" ON seats
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage seats" ON seats
  FOR ALL USING (is_admin());

-- 6. Showtimes table
CREATE POLICY "Anyone can read showtimes" ON showtimes
  FOR SELECT USING (true);

CREATE POLICY "Admin can manage showtimes" ON showtimes
  FOR ALL USING (is_admin());

-- 7. Bookings table
CREATE POLICY "Users read own bookings" ON bookings
  FOR SELECT USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Users insert own bookings" ON bookings
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users update own bookings" ON bookings
  FOR UPDATE USING (auth.uid() = user_id OR is_admin());

-- 8. Booking Seats table
CREATE POLICY "Users read own booking seats" ON booking_seats
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = booking_seats.booking_id AND (bookings.user_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Users insert own booking seats" ON booking_seats
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = booking_seats.booking_id AND bookings.user_id = auth.uid()
    )
  );

-- 9. Tickets table
CREATE POLICY "Users read own tickets" ON tickets
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = tickets.booking_id AND (bookings.user_id = auth.uid() OR is_admin())
    )
  );

-- 10. Payments table
CREATE POLICY "Users read own payments" ON payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = payments.booking_id AND (bookings.user_id = auth.uid() OR is_admin())
    )
  );

CREATE POLICY "Users insert own payments" ON payments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM bookings
      WHERE bookings.id = payments.booking_id AND bookings.user_id = auth.uid()
    )
  );

-- 11. Promotions table
CREATE POLICY "Anyone can read promotions" ON promotions
  FOR SELECT USING (true);

-- 12. Login History table
CREATE POLICY "Users read own login history" ON login_history
  FOR SELECT USING (auth.uid() = user_id OR is_admin());

-- Cho phép INSERT login history kể cả khi chưa login thành công (auth.uid() IS NULL hoặc khớp)
CREATE POLICY "Allow system/users to log login history" ON login_history
  FOR INSERT WITH CHECK (true);

-- 13. Security Alerts table
CREATE POLICY "Users read own security alerts" ON security_alerts
  FOR SELECT USING (auth.uid() = user_id OR is_admin());

CREATE POLICY "Allow system to create alerts" ON security_alerts
  FOR INSERT WITH CHECK (true);
