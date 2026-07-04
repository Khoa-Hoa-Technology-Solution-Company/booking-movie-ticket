-- ========================================================
-- RPC FUNCTION FOR ADMIN TO LOCK/UNLOCK USER ACCOUNTS
-- ========================================================

CREATE OR REPLACE FUNCTION admin_update_user_status(
  p_user_id UUID,
  p_locked_until TIMESTAMPTZ
)
RETURNS void AS $$
BEGIN
  -- 1. Kiểm tra quyền Admin của user đang gọi
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  -- 2. Cập nhật trạng thái khóa tài khoản
  UPDATE public.users
  SET locked_until = p_locked_until, updated_at = now()
  WHERE id = p_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cấp quyền thực thi cho các tài khoản đã đăng nhập
GRANT EXECUTE ON FUNCTION admin_update_user_status TO authenticated;
