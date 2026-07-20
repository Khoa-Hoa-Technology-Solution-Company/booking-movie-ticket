-- ========================================================
-- 1. Thêm cột metadata động cho bảng security_alerts
-- ========================================================
ALTER TABLE security_alerts ADD COLUMN IF NOT EXISTS metadata JSONB;

-- ========================================================
-- 2. Định nghĩa trigger tự động thông báo đặt vé thành công
-- ========================================================
CREATE OR REPLACE FUNCTION after_booking_confirmed()
RETURNS TRIGGER AS $$
DECLARE
  v_movie_title VARCHAR(255);
  v_ticket_code VARCHAR(20);
BEGIN
  -- Chỉ kích hoạt khi trạng thái chuyển sang CONFIRMED
  IF NEW.status = 'CONFIRMED' AND (OLD.status IS NULL OR OLD.status <> 'CONFIRMED') THEN
    -- Lấy tiêu đề phim
    SELECT m.title INTO v_movie_title
    FROM showtimes s
    JOIN movies m ON m.id = s.movie_id
    WHERE s.id = NEW.showtime_id;

    -- Lấy mã vé đã sinh trước đó
    SELECT ticket_code INTO v_ticket_code
    FROM tickets
    WHERE booking_id = NEW.id;

    -- Thêm thông báo bảo mật/tác vụ với metadata liên kết booking
    INSERT INTO security_alerts (user_id, type, message, severity, metadata)
    VALUES (
      NEW.user_id,
      'BOOKING_SUCCESS',
      'Đặt vé thành công phim "' || COALESCE(v_movie_title, 'Phim') || '". Mã vé của bạn là: ' || COALESCE(v_ticket_code, '') || '.',
      'LOW',
      jsonb_build_object('booking_id', NEW.id)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Gắn trigger sau khi cập nhật bookings
DROP TRIGGER IF EXISTS trg_after_booking_confirmed ON bookings;
CREATE TRIGGER trg_after_booking_confirmed
AFTER UPDATE ON bookings
FOR EACH ROW
EXECUTE FUNCTION after_booking_confirmed();

-- ========================================================
-- 3. Kích hoạt Realtime trên Supabase cho bảng security_alerts
-- ========================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables 
    WHERE pubname = 'supabase_realtime' AND tablename = 'security_alerts'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE security_alerts;
  END IF;
END $$;
