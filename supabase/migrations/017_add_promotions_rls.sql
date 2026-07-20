-- ========================================================
-- Thêm quyền RLS cho phép Admin quản lý mã khuyến mãi (promotions)
-- ========================================================
DROP POLICY IF EXISTS "Admin can manage promotions" ON promotions;

CREATE POLICY "Admin can manage promotions" ON promotions
  FOR ALL USING (public.is_admin());
