-- ==========================================
-- 0. CẬP NHẬT CẤU TRÚC PHÒNG CHIẾU (ROOM TYPE)
-- ==========================================
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS room_type VARCHAR(20) DEFAULT '2D';

-- Cập nhật loại phòng cho các phòng hiện tại
UPDATE rooms SET room_type = 'IMAX' WHERE name = 'IMAX';
UPDATE rooms SET room_type = '3D' WHERE name = 'Room 2';

-- ==========================================
-- 0.5. BẢNG GIỮ GHẾ TẠM THỜI (SEAT HOLD)
-- ==========================================
CREATE TABLE IF NOT EXISTS seat_holds (
  id BIGSERIAL PRIMARY KEY,
  seat_id BIGINT REFERENCES seats(id) ON DELETE CASCADE,
  showtime_id BIGINT REFERENCES showtimes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT now(),
  expires_at TIMESTAMPTZ DEFAULT (now() + INTERVAL '5 minutes'),
  UNIQUE(showtime_id, seat_id)
);

-- Kích hoạt RLS cho seat_holds
ALTER TABLE seat_holds ENABLE ROW LEVEL SECURITY;

-- Xóa các policy cũ để tránh lỗi trùng lặp khi chạy lại
DROP POLICY IF EXISTS "Anyone can select seat holds" ON seat_holds;
DROP POLICY IF EXISTS "Users can insert own seat holds" ON seat_holds;
DROP POLICY IF EXISTS "Users can delete own seat holds" ON seat_holds;

-- Cấp quyền truy cập RLS cho seat_holds
CREATE POLICY "Anyone can select seat holds" ON seat_holds FOR SELECT USING (true);
CREATE POLICY "Users can insert own seat holds" ON seat_holds FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete own seat holds" ON seat_holds FOR DELETE USING (auth.uid() = user_id);

-- Cấp quyền truy cập bảng cho authenticated/anon/service_role
GRANT ALL ON seat_holds TO authenticated, anon, service_role;

-- ==========================================
-- 1. HÀM DỌN DẸP / HẾT HẠN ĐƠN HÀNG VÀ VÉ
-- ==========================================

CREATE OR REPLACE FUNCTION expire_old_bookings()
RETURNS void AS $$
BEGIN
  -- A. Hủy các booking PENDING quá 10 phút
  UPDATE bookings
  SET status = 'EXPIRED', updated_at = now()
  WHERE status = 'PENDING' 
    AND created_at < (now() - INTERVAL '10 minutes');

  -- B. Cập nhật payments tương ứng thành FAILED
  UPDATE payments
  SET status = 'FAILED', updated_at = now()
  FROM bookings
  WHERE payments.booking_id = bookings.id
    AND bookings.status = 'EXPIRED'
    AND payments.status = 'PENDING';

  -- C. Cập nhật tickets tương ứng thành EXPIRED
  UPDATE tickets
  SET status = 'EXPIRED'
  FROM bookings
  WHERE tickets.booking_id = bookings.id
    AND bookings.status = 'EXPIRED'
    AND tickets.status = 'ACTIVE';

  -- D. Hết hạn các vé ACTIVE của các suất chiếu đã kết thúc
  UPDATE tickets
  SET status = 'EXPIRED'
  FROM bookings
  JOIN showtimes ON bookings.showtime_id = showtimes.id
  WHERE tickets.booking_id = bookings.id
    AND tickets.status = 'ACTIVE'
    AND now() > showtimes.end_time;

  -- E. Xóa các giữ ghế tạm thời (seat holds) đã hết hạn (sau 5 phút)
  DELETE FROM seat_holds WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==========================================
-- 2. TRIGGER KIỂM TRA XUNG ĐỘT SUẤT CHIẾU
-- ==========================================

CREATE OR REPLACE FUNCTION check_showtime_conflict()
RETURNS TRIGGER AS $$
DECLARE
  v_conflict_count INT;
BEGIN
  -- Kiểm tra trùng phòng và trùng thời gian (bỏ qua chính nó khi update)
  SELECT COUNT(*) INTO v_conflict_count
  FROM showtimes
  WHERE room_id = NEW.room_id
    AND id IS DISTINCT FROM NEW.id
    AND (
      (NEW.start_time >= start_time AND NEW.start_time < end_time) OR  -- Bắt đầu nằm trong suất chiếu khác
      (NEW.end_time > start_time AND NEW.end_time <= end_time) OR      -- Kết thúc nằm trong suất chiếu khác
      (NEW.start_time <= start_time AND NEW.end_time >= end_time)      -- Bao trùm suất chiếu khác
    );

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'Xung đột thời gian: Phòng này đã có suất chiếu khác trong khoảng thời gian từ % đến %', 
      NEW.start_time, NEW.end_time;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_check_showtime_conflict ON showtimes;
CREATE TRIGGER trg_check_showtime_conflict
BEFORE INSERT OR UPDATE ON showtimes
FOR EACH ROW
EXECUTE FUNCTION check_showtime_conflict();


-- ==========================================
-- 3. TÍCH HỢP DỌN DẸP JIT VÀO create_booking
-- ==========================================

CREATE OR REPLACE FUNCTION create_booking(
  p_user_id UUID,
  p_showtime_id BIGINT,
  p_seat_ids BIGINT[],
  p_total_amount FLOAT,
  p_payment_method payment_method DEFAULT 'DEMO'
)
RETURNS BIGINT AS $$
DECLARE
  v_booking_id BIGINT;
  v_seat_id BIGINT;
  v_conflict_count INT;
  v_ticket_code VARCHAR(20);
BEGIN
  -- Chạy dọn dẹp các booking đã quá hạn trước khi kiểm tra đặt chỗ mới
  PERFORM expire_old_bookings();

  -- 1. Kiểm tra ghế đã được đặt chưa (trong cùng showtime và status booking là PENDING/CONFIRMED)
  SELECT COUNT(*) INTO v_conflict_count
  FROM booking_seats bs
  JOIN bookings b ON b.id = bs.booking_id
  WHERE b.showtime_id = p_showtime_id
    AND b.status IN ('PENDING', 'CONFIRMED')
    AND bs.seat_id = ANY(p_seat_ids);

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected seats are already booked' USING ERRCODE = '23505';
  END IF;

  -- 2. Tạo booking
  INSERT INTO bookings (user_id, showtime_id, total_amount, status)
  VALUES (p_user_id, p_showtime_id, p_total_amount, 'PENDING')
  RETURNING id INTO v_booking_id;

  -- 3. Gán ghế vào booking
  FOREACH v_seat_id IN ARRAY p_seat_ids LOOP
    INSERT INTO booking_seats (booking_id, seat_id)
    VALUES (v_booking_id, v_seat_id);
  END LOOP;

  -- 4. Tạo ticket tự động
  v_ticket_code := 'TKT-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(v_booking_id::TEXT, 5, '0');
  INSERT INTO tickets (booking_id, ticket_code, status)
  VALUES (v_booking_id, v_ticket_code, 'ACTIVE');

  -- 5. Tạo payment record ở trạng thái PENDING với phương thức truyền vào
  INSERT INTO payments (booking_id, method, amount, status)
  VALUES (v_booking_id, p_payment_method, p_total_amount, 'PENDING');

  -- 6. Xóa các seat holds tạm thời của những ghế vừa đặt thành công
  DELETE FROM seat_holds 
  WHERE user_id = p_user_id 
    AND showtime_id = p_showtime_id 
    AND seat_id = ANY(p_seat_ids);

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ==========================================
-- 4. KÍCH HOẠT PG_CRON HÀNG PHÚT (NẾU ĐƯỢC PHÉP)
-- ==========================================
DO $$
BEGIN
  -- Kiểm tra xem pg_cron có được cài đặt hay không
  IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
    -- Hủy job cũ nếu đã tồn tại để tránh trùng lặp
    PERFORM cron.unschedule('expire-bookings-cron');
    -- Đăng ký job chạy mỗi phút
    PERFORM cron.schedule('expire-bookings-cron', '*/1 * * * *', 'SELECT expire_old_bookings()');
  END IF;
EXCEPTION WHEN OTHERS THEN
  -- Bỏ qua lỗi nếu dự án không hỗ trợ pg_cron (đã có cơ chế dọn dẹp JIT bổ trợ)
  NULL;
END
$$;

-- ==========================================
-- 5. TĂNG LƯỢT SỬ DỤNG MÃ KHUYẾN MÃI
-- ==========================================
CREATE OR REPLACE FUNCTION increment_promotion_usage(p_code VARCHAR)
RETURNS void AS $$
BEGIN
  UPDATE promotions
  SET usage_count = usage_count + 1
  WHERE code = p_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION increment_promotion_usage TO anon, authenticated, service_role;
