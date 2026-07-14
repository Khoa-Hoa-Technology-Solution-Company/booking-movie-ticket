-- ========================================================
-- UPDATE RPC create_booking TO BLOCK PAST SHOWTIMES BOOKINGS
-- ========================================================

CREATE OR REPLACE FUNCTION create_booking(
  p_user_id UUID,
  p_showtime_id BIGINT,
  p_seat_ids BIGINT[],
  p_total_amount FLOAT,
  p_payment_method payment_method DEFAULT 'DEMO',
  p_items JSONB DEFAULT '[]'::jsonb
)
RETURNS BIGINT AS $$
DECLARE
  v_booking_id BIGINT;
  v_seat_id BIGINT;
  v_conflict_count INT;
  v_ticket_code VARCHAR(20);
  v_item RECORD;
BEGIN
  -- Chạy dọn dẹp các booking đã quá hạn trước khi kiểm tra đặt chỗ mới
  PERFORM expire_old_bookings();

  -- 1. Kiểm tra xem suất chiếu đã bắt đầu/diễn ra chưa
  IF EXISTS (
    SELECT 1 FROM showtimes
    WHERE id = p_showtime_id AND start_time < now()
  ) THEN
    RAISE EXCEPTION 'Lịch chiếu này đã bắt đầu hoặc đã diễn ra. Không thể đặt vé nữa.' USING ERRCODE = 'check_violation';
  END IF;

  -- 2. Kiểm tra ghế đã được đặt chưa (trong cùng showtime và status booking là PENDING/CONFIRMED)
  SELECT COUNT(*) INTO v_conflict_count
  FROM booking_seats bs
  JOIN bookings b ON b.id = bs.booking_id
  WHERE b.showtime_id = p_showtime_id
    AND b.status IN ('PENDING', 'CONFIRMED')
    AND bs.seat_id = ANY(p_seat_ids);

  IF v_conflict_count > 0 THEN
    RAISE EXCEPTION 'One or more selected seats are already booked' USING ERRCODE = '23505';
  END IF;

  -- 3. Tạo booking
  INSERT INTO bookings (user_id, showtime_id, total_amount, status)
  VALUES (p_user_id, p_showtime_id, p_total_amount, 'PENDING')
  RETURNING id INTO v_booking_id;

  -- 4. Gán ghế vào booking
  FOREACH v_seat_id IN ARRAY p_seat_ids LOOP
    INSERT INTO booking_seats (booking_id, seat_id)
    VALUES (v_booking_id, v_seat_id);
  END LOOP;

  -- 5. Thêm các sản phẩm/combo bắp nước vào order_items nếu có
  IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id BIGINT, combo_id BIGINT, quantity INT, price FLOAT) LOOP
      INSERT INTO order_items (booking_id, product_id, combo_id, quantity, price)
      VALUES (v_booking_id, v_item.product_id, v_item.combo_id, v_item.quantity, v_item.price);
    END LOOP;
  END IF;

  -- 6. Tạo ticket tự động
  v_ticket_code := 'TKT-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(v_booking_id::TEXT, 5, '0');
  INSERT INTO tickets (booking_id, ticket_code, status)
  VALUES (v_booking_id, v_ticket_code, 'ACTIVE');

  -- 7. Tạo payment record ở trạng thái PENDING với phương thức truyền vào
  INSERT INTO payments (booking_id, method, amount, status)
  VALUES (v_booking_id, p_payment_method, p_total_amount, 'PENDING');

  -- 8. Xóa các seat holds tạm thời của những ghế vừa đặt thành công
  DELETE FROM seat_holds 
  WHERE user_id = p_user_id 
    AND showtime_id = p_showtime_id 
    AND seat_id = ANY(p_seat_ids);

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION create_booking TO authenticated, anon, service_role;
