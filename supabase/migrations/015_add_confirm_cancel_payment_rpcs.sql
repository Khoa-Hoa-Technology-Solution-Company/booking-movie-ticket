-- ========================================================
-- RPC FUNCTIONS TO CONFIRM OR CANCEL BOOKINGS AND PAYMENTS IN A TRANSACTION (HARDENED)
-- ========================================================

-- 1. RPC to confirm payment
CREATE OR REPLACE FUNCTION confirm_booking_payment(p_booking_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  v_authorized BOOLEAN;
BEGIN
  -- Kiểm tra quyền sở hữu (auth.uid() = user_id của booking) hoặc vai trò Admin
  SELECT EXISTS (
    SELECT 1 FROM bookings
    WHERE id = p_booking_id AND (user_id = auth.uid() OR public.is_admin())
  ) INTO v_authorized;

  IF NOT v_authorized THEN
    RAISE EXCEPTION 'Bạn không có quyền thực hiện thao tác này cho đơn hàng này.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Cập nhật trạng thái đặt vé thành CONFIRMED
  UPDATE bookings 
  SET status = 'CONFIRMED', updated_at = now()
  WHERE id = p_booking_id;

  -- Cập nhật trạng thái thanh toán thành PAID
  UPDATE payments 
  SET status = 'PAID', updated_at = now()
  WHERE booking_id = p_booking_id;

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION confirm_booking_payment(BIGINT) TO authenticated, anon, service_role;


-- 2. RPC to cancel booking
CREATE OR REPLACE FUNCTION cancel_booking_payment(p_booking_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
  v_authorized BOOLEAN;
BEGIN
  -- Kiểm tra quyền sở hữu (auth.uid() = user_id của booking) hoặc vai trò Admin
  SELECT EXISTS (
    SELECT 1 FROM bookings
    WHERE id = p_booking_id AND (user_id = auth.uid() OR public.is_admin())
  ) INTO v_authorized;

  IF NOT v_authorized THEN
    RAISE EXCEPTION 'Bạn không có quyền thực hiện thao tác này cho đơn hàng này.' USING ERRCODE = 'insufficient_privilege';
  END IF;

  -- Cập nhật trạng thái đặt vé thành CANCELLED
  UPDATE bookings 
  SET status = 'CANCELLED', updated_at = now()
  WHERE id = p_booking_id;

  -- Cập nhật trạng thái thanh toán thành FAILED
  UPDATE payments 
  SET status = 'FAILED', updated_at = now()
  WHERE booking_id = p_booking_id;

  -- Cập nhật trạng thái vé thành CANCELLED
  UPDATE tickets 
  SET status = 'CANCELLED'
  WHERE booking_id = p_booking_id;

  RETURN TRUE;
EXCEPTION
  WHEN OTHERS THEN
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION cancel_booking_payment(BIGINT) TO authenticated, anon, service_role;
