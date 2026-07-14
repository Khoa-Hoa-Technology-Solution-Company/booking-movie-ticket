-- ========================================================
-- ADD COORDINATES & EXPAND TO 10 CINEMAS SPANNING HCMC
-- ========================================================

-- 1. Add latitude and longitude columns
ALTER TABLE cinemas ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE cinemas ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- 2. Insert/Update 10 cinemas distributed evenly across different areas of Ho Chi Minh City:
INSERT INTO cinemas (id, name, address, city, image_url, latitude, longitude)
VALUES
-- Khu vực Trung tâm (Quận 1, Quận 5)
(1, 'CGV Vincom Center', 'Lầu 3, Vincom Center, 72 Lê Thánh Tôn, Bến Nghé, Quận 1', 'Hồ Chí Minh', 'https://citytowerbinhudong.com/wp-content/uploads/2025/10/rap-cgv-vincom-center-landmark-81-hien-dai.jpg', 10.7779, 106.7020),
(2, 'Lotte Cinema Nowzone', 'Lầu 5, TTTM Nowzone, 235 Nguyễn Văn Cừ, Nguyễn Cư Trinh, Quận 1', 'Hồ Chí Minh', 'https://toplist.vn/images/800px/lotte-cinema-nowzone-1000919.jpg', 10.7645, 106.6823),
(3, 'Galaxy Cinema Nguyễn Du', '116 Nguyễn Du, Phường Bến Thành, Quận 1', 'Hồ Chí Minh', 'https://tse3.mm.bing.net/th/id/OIP.6VROMp0ml2_9LxW4zklTFwHaE8?r=0&rs=1&pid=ImgDetMain&o=7&rm=3', 10.7744, 106.6946),
(4, 'BHD Star Cineplex Bitexco', 'Lầu 3 & 4, Bitexco Financial Tower, 2 Hải Triều, Bến Nghé, Quận 1', 'Hồ Chí Minh', 'https://www.bhdstar.com.vn/wp-content/uploads/2018/03/bhd-star-bitexco.jpg', 10.7715, 106.7042),

-- Khu vực Phía Nam (Quận 7)
(5, 'CGV Crescent Mall', 'Lầu 5, Crescent Mall, 101 Tôn Dật Tiên, Tân Phú, Quận 7', 'Hồ Chí Minh', 'https://images.foody.vn/res/g14/139369/prof/foody-profile-cgv-cinemas-crescen-635676356761168434.jpg', 10.7291, 106.7218),

-- Khu vực Phía Đông (Quận 2, Thủ Đức)
(6, 'Lotte Cinema Cantavil', 'Lầu 7, Cantavil Premier, Xa Lộ Hà Nội, An Phú, Quận 2', 'Hồ Chí Minh', 'https://lottecinemavn.com/LotteCinema/media/Cinema/Cantavil/Cantavil.jpg', 10.8016, 106.7423),
(7, 'CGV Giga Mall Thủ Đức', 'Lầu 6, Gigamall, 240-242 Phạm Văn Đồng, Hiệp Bình Chánh, Thủ Đức', 'Hồ Chí Minh', 'https://www.gigamall.com.vn/uploads/images/GIGAMALL-CGV-2.jpg', 10.8277, 106.7214),

-- Khu vực Phía Tây (Tân Bình)
(8, 'Galaxy Cinema Tân Bình', '246 Nguyễn Hồng Đào, Phường 14, Tân Bình', 'Hồ Chí Minh', 'https://www.galaxycine.vn/media/2019/3/25/tan-binh-1_1553503929424.jpg', 10.7963, 106.6433),

-- Khu vực Tây Nam (Bình Tân)
(9, 'CGV Aeon Mall Bình Tân', 'Đường Số 17A, Bình Trị Đông B, Bình Tân', 'Hồ Chí Minh', 'https://s3.ap-southeast-1.amazonaws.com/storage.thegioididong.com/2020/06/cgv-aeon-binh-tan-3.jpg', 10.7431, 106.6125),

-- Khu vực Phía Bắc (Gò Vấp)
(10, 'BHD Star Cineplex Quang Trung', 'Lầu B1, Vincom Plaza Quang Trung, 190 Quang Trung, Phường 10, Gò Vấp', 'Hồ Chí Minh', 'https://vietnammoi.vn/stores/news_dataimages/haianh/092017/04/16/in_bhd-quang-trung.jpg', 10.8267, 106.6783)
ON CONFLICT (id) DO UPDATE SET
  name = EXCLUDED.name,
  address = EXCLUDED.address,
  city = EXCLUDED.city,
  image_url = EXCLUDED.image_url,
  latitude = EXCLUDED.latitude,
  longitude = EXCLUDED.longitude;

-- Reset sequence for cinemas
SELECT setval('cinemas_id_seq', (SELECT MAX(id) FROM cinemas));

-- 3. Insert Rooms for new cinemas (id 4 to 10)
INSERT INTO rooms (id, cinema_id, name, total_seats, room_type)
VALUES
(10, 4, 'Room 1', 80, '2D'),
(11, 4, 'Room 2', 60, '3D'),
(12, 4, 'IMAX', 120, 'IMAX'),
(13, 5, 'Room 1', 80, '2D'),
(14, 5, 'Room 2', 60, '3D'),
(15, 5, 'IMAX', 120, 'IMAX'),
(16, 6, 'Room 1', 80, '2D'),
(17, 6, 'Room 2', 60, '3D'),
(18, 6, 'IMAX', 120, 'IMAX'),
(19, 7, 'Room 1', 80, '2D'),
(20, 7, 'Room 2', 60, '3D'),
(21, 7, 'IMAX', 120, 'IMAX'),
(22, 8, 'Room 1', 80, '2D'),
(23, 8, 'Room 2', 60, '3D'),
(24, 8, 'IMAX', 120, 'IMAX'),
(25, 9, 'Room 1', 80, '2D'),
(26, 9, 'Room 2', 60, '3D'),
(27, 9, 'IMAX', 120, 'IMAX'),
(28, 10, 'Room 1', 80, '2D'),
(29, 10, 'Room 2', 60, '3D'),
(30, 10, 'IMAX', 120, 'IMAX')
ON CONFLICT (id) DO UPDATE SET
  cinema_id = EXCLUDED.cinema_id,
  name = EXCLUDED.name,
  total_seats = EXCLUDED.total_seats,
  room_type = EXCLUDED.room_type;

-- Reset sequence for rooms
SELECT setval('rooms_id_seq', (SELECT MAX(id) FROM rooms));

-- 4. Generate Seats for new rooms (id >= 10)
DO $$
DECLARE
  v_room RECORD;
  v_rows TEXT[];
  v_row TEXT;
  v_seats_per_row INT;
  v_number INT;
  v_seat_type seat_type;
BEGIN
  FOR v_room IN SELECT * FROM rooms WHERE id >= 10 LOOP
    -- Chỉ chèn ghế nếu phòng này chưa có ghế nào
    IF NOT EXISTS (SELECT 1 FROM seats WHERE room_id = v_room.id) THEN
      -- Xác định số hàng ghế dựa trên tổng ghế
      IF v_room.total_seats <= 60 THEN
        v_rows := ARRAY['A', 'B', 'C', 'D', 'E', 'F'];
      ELSIF v_room.total_seats <= 80 THEN
        v_rows := ARRAY['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];
      ELSE
        v_rows := ARRAY['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J'];
      END IF;

      v_seats_per_row := CEIL(v_room.total_seats::FLOAT / array_length(v_rows, 1));

      FOREACH v_row IN ARRAY v_rows LOOP
        FOR v_number IN 1..v_seats_per_row LOOP
          v_seat_type := 'STANDARD';

          -- Hàng cuối cùng hoặc sát cuối là VIP
          IF v_row = v_rows[array_length(v_rows, 1)] OR v_row = v_rows[array_length(v_rows, 1) - 1] THEN
            v_seat_type := 'VIP';
          END IF;

          -- Ghế COUPLE ở các vị trí cuối cùng của hàng cuối
          IF v_row = v_rows[array_length(v_rows, 1)] AND v_number % 2 = 0 AND v_number > (v_seats_per_row - 4) THEN
            v_seat_type := 'COUPLE';
          END IF;

          INSERT INTO seats (room_id, "row", number, type, status)
          VALUES (v_room.id, v_row, v_number, v_seat_type, 'AVAILABLE')
          ON CONFLICT (room_id, "row", number) DO NOTHING;
        END LOOP;
      END LOOP;
    END IF;
  END LOOP;
END;
$$;
