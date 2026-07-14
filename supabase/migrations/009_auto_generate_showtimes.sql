-- ========================================================
-- 1. RPC FUNCTION TO AUTO-GENERATE SHOWTIMES FOR NOW_SHOWING MOVIES
-- ========================================================

CREATE OR REPLACE FUNCTION generate_showtimes_for_next_days(p_days_count INT)
RETURNS void AS $$
DECLARE
  v_movie RECORD;
  v_room RECORD;
  v_day_offset INT;
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
  v_time TEXT;
  -- Khung giờ chiếu tiêu chuẩn trong ngày
  v_times TEXT[] := ARRAY['09:00', '13:00', '16:30', '19:30', '22:00'];
  v_price FLOAT;
  v_hours INT;
  v_minutes INT;
BEGIN
  -- 1. Kiểm tra quyền Admin của user đang gọi
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  -- 2. Sinh lịch chiếu cho p_days_count ngày tiếp theo
  FOR v_day_offset IN 0..(p_days_count - 1) LOOP
    -- Lấy danh sách phim đang chiếu
    FOR v_movie IN SELECT * FROM movies WHERE status = 'NOW_SHOWING' AND deleted_at IS NULL LOOP
      -- Lặp qua tất cả phòng chiếu
      FOR v_room IN SELECT * FROM rooms LOOP
        -- Duyệt qua các khung giờ chiếu tiêu chuẩn
        FOREACH v_time IN ARRAY v_times LOOP
          v_hours := split_part(v_time, ':', 1)::INT;
          v_minutes := split_part(v_time, ':', 2)::INT;

          -- Tính toán thời gian bắt đầu chiếu (múi giờ Việt Nam +7)
          v_start_time := (date_trunc('day', now()) + (v_day_offset || ' day')::INTERVAL + (v_hours || ' hour')::INTERVAL + (v_minutes || ' minute')::INTERVAL) AT TIME ZONE 'Asia/Ho_Chi_Minh';

          -- Bỏ qua suất chiếu trong quá khứ
          IF v_start_time < now() THEN
            CONTINUE;
          END IF;

          -- Tính thời gian kết thúc = bắt đầu + thời lượng phim + 15 phút dọn phòng
          v_end_time := v_start_time + (v_movie.duration || ' minute')::INTERVAL + '15 minute'::INTERVAL;

          -- 3. Kiểm tra xem phòng chiếu này có bị trùng lịch chiếu khác trong khoảng thời gian này không
          IF NOT EXISTS (
            SELECT 1 FROM showtimes
            WHERE room_id = v_room.id
              AND deleted_at IS NULL
              AND (
                (start_time <= v_start_time AND end_time > v_start_time) OR
                (start_time < v_end_time AND end_time >= v_end_time) OR
                (start_time >= v_start_time AND end_time <= v_end_time)
              )
          ) THEN
            -- 4. Tính giá vé cơ bản dựa trên giờ chiếu và loại phòng
            v_price := 75000; -- Giá mặc định ban ngày
            
            -- Tăng giá vào khung giờ tối/cao điểm
            IF v_hours >= 17 THEN
              v_price := 95000;
            END IF;
            IF v_hours >= 19 THEN
              v_price := 120000;
            END IF;
            
            -- Tăng giá đối với phòng chiếu đặc biệt IMAX
            IF v_room.room_type = 'IMAX' THEN
              v_price := v_price + 30000;
            END IF;

            -- 5. Thực hiện thêm suất chiếu mới
            INSERT INTO showtimes (movie_id, room_id, start_time, end_time, price)
            VALUES (v_movie.id, v_room.id, v_start_time, v_end_time, v_price);
          END IF;
        END LOOP;
      END LOOP;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cấp quyền thực thi
GRANT EXECUTE ON FUNCTION generate_showtimes_for_next_days TO authenticated;
