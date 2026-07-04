-- 1. Thêm giá trị 'SEPAY' vào enum payment_method nếu chưa tồn tại
-- Sử dụng khối vô danh DO để bắt lỗi nếu phần tử đã tồn tại, tránh lỗi dừng biên dịch
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type t 
    JOIN pg_enum e ON t.oid = e.enumtypid 
    WHERE t.typname = 'payment_method' AND e.enumlabel = 'SEPAY'
  ) THEN
    ALTER TYPE payment_method ADD VALUE 'SEPAY';
  END IF;
END
$$;

-- 2. Xóa RPC create_booking cũ để tránh xung đột signature
DROP FUNCTION IF EXISTS create_booking(UUID, BIGINT, BIGINT[], FLOAT);

-- 3. Định nghĩa lại RPC create_booking với tham số p_payment_method
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

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. Tạo hàm RPC Webhook SePay
-- Đầu tiên, xóa các hàm cũ có chữ ký khác để tránh xung đột
DROP FUNCTION IF EXISTS sepay_webhook;
DROP FUNCTION IF EXISTS sepay_webhook(BIGINT, VARCHAR, TIMESTAMPTZ, VARCHAR, VARCHAR, TEXT, VARCHAR, FLOAT, FLOAT, VARCHAR);
DROP FUNCTION IF EXISTS sepay_webhook(BIGINT, VARCHAR, TIMESTAMPTZ, VARCHAR, VARCHAR, VARCHAR, TEXT, VARCHAR, FLOAT, FLOAT, VARCHAR);

CREATE OR REPLACE FUNCTION sepay_webhook(jsonb)
RETURNS JSON AS $$
DECLARE
  v_booking_id BIGINT;
  v_booking_status booking_status;
  v_total_amount FLOAT;
  v_req_key TEXT;
  
  -- Các biến trích xuất từ payload JSON
  v_content TEXT;
  v_transfer_type VARCHAR(10);
  v_transfer_amount FLOAT;
  v_code VARCHAR(100);
BEGIN
  -- 1. Xác thực API Key từ header Authorization (SePay gửi dưới dạng "Apikey YOUR_KEY")
  -- Lấy từ HTTP request headers
  v_req_key := current_setting('request.headers', true)::json->>'authorization';
  
  -- Chấp nhận cả mã mặc định 123456 hoặc 12345 (người dùng tự đổi trên Dashboard)
  IF v_req_key IS NULL OR (
    v_req_key <> 'Apikey sepay_secret_token_123456' AND 
    v_req_key <> 'Apikey sepay_secret_token_12345'
  ) THEN
    RETURN json_build_object('success', false, 'message', 'Unauthorized');
  END IF;

  -- Trích xuất các trường dữ liệu cần thiết từ JSON payload ($1)
  v_content := $1->>'content';
  v_transfer_type := $1->>'transferType';
  v_transfer_amount := ($1->>'transferAmount')::FLOAT;
  v_code := $1->>'code';

  -- 2. Kiểm tra transferType phải là 'in' (nhận tiền)
  IF v_transfer_type <> 'in' THEN
    RETURN json_build_object('success', true, 'message', 'Ignored: Not an incoming transaction');
  END IF;

  -- 3. Trích xuất bookingId từ nội dung chuyển khoản (Ví dụ: VE123 hoặc VE 123)
  BEGIN
    v_booking_id := substring(v_content from '(?i)VE\s*(\d+)')::BIGINT;
  EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'message', 'Cannot parse booking ID from content: ' || v_content);
  END;

  IF v_booking_id IS NULL THEN
    RETURN json_build_object('success', false, 'message', 'Booking ID not found in content: ' || v_content);
  END IF;

  -- 4. Tìm kiếm booking
  SELECT status, total_amount INTO v_booking_status, v_total_amount
  FROM bookings
  WHERE id = v_booking_id;

  IF NOT FOUND THEN
    RETURN json_build_object('success', false, 'message', 'Booking #' || v_booking_id || ' not found');
  END IF;

  -- 5. Kiểm tra trạng thái booking
  IF v_booking_status = 'CONFIRMED' THEN
    RETURN json_build_object('success', true, 'message', 'Booking #' || v_booking_id || ' already confirmed');
  END IF;

  IF v_booking_status <> 'PENDING' THEN
    RETURN json_build_object('success', false, 'message', 'Booking #' || v_booking_id || ' status is ' || v_booking_status || ' (expected PENDING)');
  END IF;

  -- 6. Xác thực số tiền
  IF v_transfer_amount < v_total_amount THEN
    RETURN json_build_object('success', false, 'message', 'Insufficient transfer amount. Expected ' || v_total_amount || ', got ' || v_transfer_amount);
  END IF;

  -- 7. Cập nhật đơn hàng thành CONFIRMED
  UPDATE bookings
  SET status = 'CONFIRMED', updated_at = now()
  WHERE id = v_booking_id;

  -- 8. Cập nhật thông tin thanh toán thành PAID và lưu mã giao dịch ngân hàng
  INSERT INTO payments (booking_id, method, amount, status, transaction_code, updated_at)
  VALUES (v_booking_id, 'SEPAY', v_transfer_amount, 'PAID', v_code, now())
  ON CONFLICT (booking_id) DO UPDATE
  SET method = 'SEPAY', amount = v_transfer_amount, status = 'PAID', transaction_code = v_code, updated_at = now();

  -- 9. Cập nhật trạng thái vé và sinh mã QR code
  UPDATE tickets
  SET status = 'ACTIVE', qr_code = 'TKT-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(v_booking_id::TEXT, 5, '0')
  WHERE booking_id = v_booking_id;

  RETURN json_build_object('success', true, 'message', 'Payment confirmed for booking #' || v_booking_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Cấp quyền thực thi webhook cho vai trò ẩn danh (REST API)
GRANT EXECUTE ON FUNCTION sepay_webhook TO anon, authenticated, service_role;

-- 6. Kích hoạt realtime cho bảng bookings
-- Nếu chưa được đăng ký trong publication supabase_realtime thì thêm vào
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime'
  ) THEN
    IF NOT EXISTS (
      SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'bookings'
    ) THEN
      ALTER PUBLICATION supabase_realtime ADD TABLE bookings;
    END IF;
  END IF;
END
$$;
