-- ========================================================
-- 1. Cập nhật RPC expire_old_bookings() với thời hạn 5 phút
-- ========================================================

CREATE OR REPLACE FUNCTION expire_old_bookings()
RETURNS void AS $$
BEGIN
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

-- Cấp quyền thực thi RPC dọn dẹp cho các người dùng
GRANT EXECUTE ON FUNCTION expire_old_bookings TO authenticated, anon, service_role;
