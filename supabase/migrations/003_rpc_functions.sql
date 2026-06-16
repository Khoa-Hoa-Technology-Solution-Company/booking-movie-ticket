-- Atomic booking: kiểm tra ghế + tạo booking trong 1 transaction an toàn
CREATE OR REPLACE FUNCTION create_booking(
  p_user_id UUID,
  p_showtime_id BIGINT,
  p_seat_ids BIGINT[],
  p_total_amount FLOAT
)
RETURNS BIGINT AS $$
DECLARE
  v_booking_id BIGINT;
  v_seat_id BIGINT;
  v_conflict_count INT;
  v_ticket_code VARCHAR(20);
BEGIN
  -- 1. Kiểm tra ghế đã được đặt chưa (trong cùng showtime và status booking là PENDING/CONFIRMED)
  SELECT COUNT(*) INTO v_conflict_count
  FROM booking_seats bs
  JOIN bookings b ON b.id = bs.booking_id
  WHERE b.showtime_id = p_showtime_id
    AND b.status IN ('PENDING', 'CONFIRMED')
    AND bs.seat_id = ANY(p_seat_ids);

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected seats are already booked' USING ERRCODE = '23505'; -- Trả về mã trùng lặp dữ liệu để dễ bắt lỗi
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

  -- 5. Tạo payment record (DEMO) ở trạng thái PENDING
  INSERT INTO payments (booking_id, method, amount, status)
  VALUES (v_booking_id, 'DEMO', p_total_amount, 'PENDING');

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
