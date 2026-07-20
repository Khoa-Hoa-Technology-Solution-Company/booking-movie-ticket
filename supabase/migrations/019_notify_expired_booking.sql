-- ========================================================
-- Cập nhật RPC expire_old_bookings() gửi thông báo BOOKING_EXPIRED
-- ========================================================

CREATE OR REPLACE FUNCTION expire_old_bookings()
RETURNS void AS $$
DECLARE
  v_rec RECORD;
  v_movie_title VARCHAR(255);
BEGIN
  -- Lặp qua các booking PENDING hết hạn 5 phút để tạo alert thông báo cho user
  FOR v_rec IN 
    SELECT b.id, b.user_id, b.showtime_id 
    FROM bookings b
    WHERE b.status = 'PENDING' AND b.created_at < (now() - INTERVAL '5 minutes')
  LOOP
    -- Lấy tiêu đề phim
    SELECT m.title INTO v_movie_title
    FROM showtimes s
    JOIN movies m ON m.id = s.movie_id
    WHERE s.id = v_rec.showtime_id;

    -- Thêm thông báo vé hết hạn vào bảng security_alerts
    INSERT INTO security_alerts (user_id, type, message, severity, metadata)
    VALUES (
      v_rec.user_id,
      'BOOKING_EXPIRED',
      'Đơn đặt vé phim "' || COALESCE(v_movie_title, 'Phim') || '" (Đơn hàng #' || v_rec.id || ') đã hết 5 phút giữ chỗ và tự động bị hủy.',
      'MEDIUM',
      jsonb_build_object('booking_id', v_rec.id)
    );
  END LOOP;

  -- A. Hủy các booking PENDING quá 5 phút
  UPDATE bookings
  SET status = 'EXPIRED', updated_at = now()
  WHERE status = 'PENDING' 
    AND created_at < (now() - INTERVAL '5 minutes');

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

  -- E. Dọn dẹp các seat_holds quá hạn
  DELETE FROM seat_holds
  WHERE expires_at < now();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
