-- ========================================================
-- 1. BỔ SUNG CỘT BẢNG ROOMS VÀ SEATS CHO SƠ ĐỒ GHẾ ĐỘNG
-- ========================================================
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS total_rows INT DEFAULT 10;
ALTER TABLE rooms ADD COLUMN IF NOT EXISTS total_columns INT DEFAULT 10;

ALTER TABLE seats ADD COLUMN IF NOT EXISTS position_x INT;
ALTER TABLE seats ADD COLUMN IF NOT EXISTS position_y INT;
ALTER TABLE seats ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;

-- ========================================================
-- 2. CẬP NHẬT TỌA ĐỘ GRID CHO GHẾ ĐÃ CÓ (MIGRATION)
-- ========================================================

-- Cập nhật kích thước lưới phòng chiếu dựa trên tổng số ghế
UPDATE rooms 
SET total_rows = 
  CASE 
    WHEN total_seats <= 60 THEN 6
    WHEN total_seats <= 80 THEN 8
    ELSE 10
  END,
  total_columns = CEIL(total_seats::FLOAT / 
    CASE 
      WHEN total_seats <= 60 THEN 6
      WHEN total_seats <= 80 THEN 8
      ELSE 10
    END
  );

-- Cập nhật tọa độ ghế mặc định cho các phòng chiếu (loại trừ phòng 2 để tạo demo đặc biệt)
UPDATE seats
SET position_x = number,
    position_y = ascii(upper("row")) - 64
WHERE room_id <> 2;

-- Cập nhật phòng chiếu 2: tạo một lối đi ở cột 5 (dịch chuyển tất cả ghế từ cột 5 sang phải 1 đơn vị)
UPDATE seats
SET position_x = number + CASE WHEN number >= 5 THEN 1 ELSE 0 END,
    position_y = ascii(upper("row")) - 64
WHERE room_id = 2;

-- Tăng kích thước cột của phòng chiếu 2 lên 11 để chứa cột trống
UPDATE rooms
SET total_columns = 11
WHERE id = 2;

-- Đánh dấu thử một số ghế là hỏng (MAINTENANCE/is_active = false) để test
UPDATE seats
SET is_active = false, status = 'MAINTENANCE'
WHERE room_id = 1 AND "row" = 'A' AND number = 3;

-- ========================================================
-- 3. TẠO CÁC BẢNG QUẢN LÝ POPCORN & ĐỒ UỐNG (COMBO BẮP NƯỚC)
-- ========================================================

-- Bảng sản phẩm (nước ngọt, bắp, kẹo...)
CREATE TABLE IF NOT EXISTS products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price FLOAT NOT NULL,
  image_url TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Bảng các gói Combo
CREATE TABLE IF NOT EXISTS combos (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  price FLOAT NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Chi tiết sản phẩm trong gói Combo
CREATE TABLE IF NOT EXISTS combo_items (
  id BIGSERIAL PRIMARY KEY,
  combo_id BIGINT REFERENCES combos(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE CASCADE,
  quantity INT NOT NULL DEFAULT 1,
  UNIQUE(combo_id, product_id)
);

-- Chi tiết mặt hàng bắp nước đi kèm hóa đơn đặt vé
CREATE TABLE IF NOT EXISTS order_items (
  id BIGSERIAL PRIMARY KEY,
  booking_id BIGINT REFERENCES bookings(id) ON DELETE CASCADE,
  product_id BIGINT REFERENCES products(id) ON DELETE SET NULL,
  combo_id BIGINT REFERENCES combos(id) ON DELETE SET NULL,
  quantity INT NOT NULL DEFAULT 1,
  price FLOAT NOT NULL, -- Giá tại thời điểm mua
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT chk_item_type CHECK (
    (product_id IS NOT NULL AND combo_id IS NULL) OR
    (product_id IS NULL AND combo_id IS NOT NULL)
  )
);

-- Bật Row Level Security (RLS)
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE combos ENABLE ROW LEVEL SECURITY;
ALTER TABLE combo_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;

-- Tạo các RLS Policy cho phép đọc công khai
DROP POLICY IF EXISTS "Anyone can read products" ON products;
CREATE POLICY "Anyone can read products" ON products FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can read combos" ON combos;
CREATE POLICY "Anyone can read combos" ON combos FOR SELECT USING (true);

DROP POLICY IF EXISTS "Anyone can read combo_items" ON combo_items;
CREATE POLICY "Anyone can read combo_items" ON combo_items FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can read own order_items" ON order_items;
CREATE POLICY "Users can read own order_items" ON order_items FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM bookings b
    WHERE b.id = order_items.booking_id AND (b.user_id = auth.uid() OR is_admin())
  )
);

-- Cấp quyền truy cập
GRANT ALL ON products TO authenticated, anon, service_role;
GRANT ALL ON combos TO authenticated, anon, service_role;
GRANT ALL ON combo_items TO authenticated, anon, service_role;
GRANT ALL ON order_items TO authenticated, anon, service_role;

-- ========================================================
-- 4. CẬP NHẬT RPC TRANSACTION CREATE_BOOKING VỚI THAM SỐ BẮP NƯỚC
-- ========================================================

-- Xóa RPC cũ (do thay đổi danh sách tham số truyền vào)
DROP FUNCTION IF EXISTS create_booking(UUID, BIGINT, BIGINT[], FLOAT, payment_method);

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

  -- 4. Thêm các sản phẩm/combo bắp nước vào order_items nếu có
  IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
    FOR v_item IN SELECT * FROM jsonb_to_recordset(p_items) AS x(product_id BIGINT, combo_id BIGINT, quantity INT, price FLOAT) LOOP
      INSERT INTO order_items (booking_id, product_id, combo_id, quantity, price)
      VALUES (v_booking_id, v_item.product_id, v_item.combo_id, v_item.quantity, v_item.price);
    END LOOP;
  END IF;

  -- 5. Tạo ticket tự động
  v_ticket_code := 'TKT-' || TO_CHAR(now(), 'YYYYMMDD') || '-' || LPAD(v_booking_id::TEXT, 5, '0');
  INSERT INTO tickets (booking_id, ticket_code, status)
  VALUES (v_booking_id, v_ticket_code, 'ACTIVE');

  -- 6. Tạo payment record ở trạng thái PENDING với phương thức truyền vào
  INSERT INTO payments (booking_id, method, amount, status)
  VALUES (v_booking_id, p_payment_method, p_total_amount, 'PENDING');

  -- 7. Xóa các seat holds tạm thời của những ghế vừa đặt thành công
  DELETE FROM seat_holds 
  WHERE user_id = p_user_id 
    AND showtime_id = p_showtime_id 
    AND seat_id = ANY(p_seat_ids);

  RETURN v_booking_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION create_booking TO authenticated, anon, service_role;

-- ========================================================
-- 5. SEEDING DỮ LIỆU BẮP NƯỚC MẪU
-- ========================================================

-- Nạp Products
INSERT INTO products (id, name, price, image_url) VALUES
(1, 'Bắp rang vị ngọt (L)', 45000, 'https://images.unsplash.com/photo-1578849278619-e73505e9610f?auto=format&fit=crop&q=80&w=400'),
(2, 'Bắp rang vị phô mai (L)', 50000, 'https://images.unsplash.com/photo-1585647347483-22b66260dfff?auto=format&fit=crop&q=80&w=400'),
(3, 'Nước ngọt Pepsi (L)', 30000, 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&q=80&w=400'),
(4, 'Nước ngọt 7Up (L)', 30000, 'https://images.unsplash.com/photo-1543257580-7269da773bf5?auto=format&fit=crop&q=80&w=400'),
(5, 'Nước suối Aquafina', 20000, 'https://images.unsplash.com/photo-1608885898957-a599fb1b4641?auto=format&fit=crop&q=80&w=400')
ON CONFLICT (id) DO NOTHING;

SELECT setval('products_id_seq', (SELECT MAX(id) FROM products));

-- Nạp Combos
INSERT INTO combos (id, name, price, description) VALUES
(1, 'Combo Solo', 65000, '1 Bắp ngọt (L) + 1 Pepsi (L). Tiết kiệm 10k!'),
(2, 'Combo Couple', 90000, '1 Bắp phô mai (L) + 2 Pepsi (L). Lý tưởng cho các cặp đôi!'),
(3, 'Combo Super Party', 140000, '2 Bắp ngọt (L) + 1 Bắp phô mai (L) + 4 Pepsi (L). Hoàn hảo cho nhóm bạn!')
ON CONFLICT (id) DO NOTHING;

SELECT setval('combos_id_seq', (SELECT MAX(id) FROM combos));

-- Chi tiết Combo items
INSERT INTO combo_items (combo_id, product_id, quantity) VALUES
(1, 1, 1),
(1, 3, 1),
(2, 2, 1),
(2, 3, 2),
(3, 1, 2),
(3, 2, 1),
(3, 3, 4)
ON CONFLICT DO NOTHING;
