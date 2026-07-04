-- ========================================================
-- 1. BỔ SUNG CỘT SOFT DELETE (XÓA ẢO)
-- ========================================================
ALTER TABLE movies ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE showtimes ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
ALTER TABLE bookings ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

-- ========================================================
-- 2. CẬP NHẬT CHÍNH SÁCH BẢO MẬT RLS (LỌC XÓA ẢO)
-- ========================================================
DROP POLICY IF EXISTS "Anyone can read movies" ON movies;
CREATE POLICY "Anyone can read movies" ON movies FOR SELECT USING (deleted_at IS NULL OR is_admin());

DROP POLICY IF EXISTS "Anyone can read showtimes" ON showtimes;
CREATE POLICY "Anyone can read showtimes" ON showtimes FOR SELECT USING (deleted_at IS NULL OR is_admin());

DROP POLICY IF EXISTS "Users read own bookings" ON bookings;
CREATE POLICY "Users read own bookings" ON bookings FOR SELECT USING ((auth.uid() = user_id AND deleted_at IS NULL) OR is_admin());

DROP POLICY IF EXISTS "Users update own bookings" ON bookings;
CREATE POLICY "Users update own bookings" ON bookings FOR UPDATE USING ((auth.uid() = user_id AND deleted_at IS NULL) OR is_admin());

-- ========================================================
-- 3. CẬP NHẬT TRÌNH XỬ LÝ XUNG ĐỘT SUẤT CHIẾU (TRÁNH OVERLAP PHIM CHƯA XÓA)
-- ========================================================
CREATE OR REPLACE FUNCTION check_showtime_conflict()
RETURNS TRIGGER AS $$
DECLARE
  v_conflict_count INT;
BEGIN
  -- Chỉ kiểm tra trùng phòng và trùng thời gian với những suất chưa xóa (deleted_at IS NULL)
  SELECT COUNT(*) INTO v_conflict_count
  FROM showtimes
  WHERE room_id = NEW.room_id
    AND id IS DISTINCT FROM NEW.id
    AND deleted_at IS NULL
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

-- ========================================================
-- 4. FUNCTION TRANSACTION-BASED CHECK-IN (CHỐNG NHÂN BẢN VÉ)
-- ========================================================
CREATE OR REPLACE FUNCTION check_in_ticket(p_ticket_code VARCHAR)
RETURNS JSON AS $$
DECLARE
  v_ticket RECORD;
  v_booking RECORD;
BEGIN
  -- Thực hiện khóa hàng với FOR UPDATE trong một transaction duy nhất để chặn các request quét vé đồng thời
  SELECT * INTO v_ticket 
  FROM tickets 
  WHERE ticket_code = p_ticket_code 
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Mã vé không tồn tại trên hệ thống!');
  END IF;

  IF v_ticket.status = 'USED' THEN
    -- Lấy thông tin chi tiết vé đã được sử dụng
    SELECT b.id, s.start_time, r.name as room_name, m.title as movie_title INTO v_booking
    FROM bookings b
    JOIN showtimes s ON b.showtime_id = s.id
    JOIN rooms r ON s.room_id = r.id
    JOIN movies m ON s.movie_id = m.id
    WHERE b.id = v_ticket.booking_id;

    RETURN json_build_object(
      'success', false, 
      'message', 'Vé này đã được sử dụng trước đó!',
      'ticket_code', v_ticket.ticket_code,
      'status', 'USED',
      'bookings', json_build_object(
        'showtimes', json_build_object(
          'start_time', v_booking.start_time,
          'rooms', json_build_object('name', v_booking.room_name),
          'movies', json_build_object('title', v_booking.movie_title)
        )
      )
    );
  END IF;

  IF v_ticket.status = 'EXPIRED' OR v_ticket.status = 'CANCELLED' THEN
    RETURN json_build_object('success', false, 'message', 'Vé này đã hết hạn hoặc bị hủy!');
  END IF;

  -- Đánh dấu vé thành USED
  UPDATE tickets 
  SET status = 'USED' 
  WHERE id = v_ticket.id;

  -- Lấy chi tiết thông tin vé để hiển thị thành công
  SELECT b.id, s.start_time, r.name as room_name, m.title as movie_title INTO v_booking
  FROM bookings b
  JOIN showtimes s ON b.showtime_id = s.id
  JOIN rooms r ON s.room_id = r.id
  JOIN movies m ON s.movie_id = m.id
  WHERE b.id = v_ticket.booking_id;

  RETURN json_build_object(
    'success', true, 
    'message', 'Check-in thành công! Vé hợp lệ.',
    'ticket_code', v_ticket.ticket_code,
    'status', 'USED',
    'bookings', json_build_object(
      'showtimes', json_build_object(
        'start_time', v_booking.start_time,
        'rooms', json_build_object('name', v_booking.room_name),
        'movies', json_build_object('title', v_booking.movie_title)
      )
    )
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION check_in_ticket TO authenticated, anon, service_role;

-- ========================================================
-- 5. KÍCH HOẠT SUPABASE REALTIME CHO SEAT_HOLDS VÀ BOOKINGS
-- ========================================================
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    -- Thêm bảng seat_holds vào publication realtime
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'seat_holds'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE seat_holds;
    END IF;

    -- Thêm bảng bookings vào publication realtime
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables 
      WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
    END IF;
  END IF;
END
$$;
