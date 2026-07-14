-- ========================================================
-- FIX TIMEZONE CALCULATION & MOVIE DISTRIBUTION IN generate_showtimes_for_next_days
-- ========================================================

CREATE OR REPLACE FUNCTION generate_showtimes_for_next_days(p_days_count INT)
RETURNS void AS $$
DECLARE
  v_movie_ids BIGINT[];
  v_movies_count INT;
  v_movie_id BIGINT;
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
  v_local_time TIMESTAMP;
  v_movie_index INT;
BEGIN
  -- 1. Kiểm tra quyền Admin của user đang gọi
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  -- Lấy danh sách ID phim đang chiếu vào mảng
  SELECT array_agg(id) INTO v_movie_ids 
  FROM movies 
  WHERE status = 'NOW_SHOWING' AND deleted_at IS NULL;
  
  v_movies_count := array_length(v_movie_ids, 1);
  
  IF v_movies_count IS NULL OR v_movies_count = 0 THEN
    RETURN; -- Không có phim nào đang chiếu để tạo lịch
  END IF;

  -- 2. Sinh lịch chiếu cho p_days_count ngày tiếp theo
  FOR v_day_offset IN 0..(p_days_count - 1) LOOP
    -- Lặp qua tất cả phòng chiếu
    FOR v_room IN SELECT * FROM rooms LOOP
      -- Mỗi phòng chiếu sẽ bắt đầu xoay vòng phim từ vị trí khác nhau để tránh trùng lặp
      v_movie_index := (v_room.id + v_day_offset) % v_movies_count;
      
      -- Duyệt qua các khung giờ chiếu tiêu chuẩn
      FOREACH v_time IN ARRAY v_times LOOP
        v_movie_id := v_movie_ids[v_movie_index + 1]; -- pgsql array is 1-indexed

        -- Lấy thông tin phim hiện tại (duration)
        SELECT * INTO v_movie FROM movies WHERE id = v_movie_id;

        v_hours := split_part(v_time, ':', 1)::INT;
        v_minutes := split_part(v_time, ':', 2)::INT;

        -- Tính toán thời gian bắt đầu chiếu theo giờ địa phương (Asia/Ho_Chi_Minh)
        v_local_time := date_trunc('day', now() AT TIME ZONE 'Asia/Ho_Chi_Minh') 
                        + (v_day_offset || ' day')::INTERVAL 
                        + (v_hours || ' hour')::INTERVAL 
                        + (v_minutes || ' minute')::INTERVAL;
                        
        -- Chuyển đổi timestamp không múi giờ về TIMESTAMPTZ tương ứng với múi giờ Việt Nam (+7)
        v_start_time := v_local_time AT TIME ZONE 'Asia/Ho_Chi_Minh';

        -- Bỏ qua suất chiếu trong quá khứ
        IF v_start_time < now() THEN
          -- Vẫn dịch chỉ mục phim để slot tiếp theo không bị lặp
          v_movie_index := (v_movie_index + 1) % v_movies_count;
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
          
          -- Xoay vòng sang phim tiếp theo cho slot sau
          v_movie_index := (v_movie_index + 1) % v_movies_count;
        END IF;
      END LOOP;
    END LOOP;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

GRANT EXECUTE ON FUNCTION generate_showtimes_for_next_days TO authenticated;
