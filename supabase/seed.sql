-- ===================== SEED DATA =====================

-- 1. Movies
INSERT INTO movies (id, title, description, poster_url, trailer_url, duration, age_rating, genre, director, "cast", release_date, status, rating)
VALUES
(1, 'Avengers: Doomsday', 'The Avengers must assemble once more to face their most dangerous threat yet - Doctor Doom, who wields unimaginable power that threatens to unravel the very fabric of the multiverse.', 'https://images-wixmp-ed30a86b8c4ca887773594c2.wixmp.com/f/2e317a1c-f1ce-4a5f-90db-d88cc01db2d0/djyh7h2-d0dd3eb7-ade6-4245-ad14-f843b4cf7df2.png/v1/fill/w_1280,h_2027,q_80,strp/avengers_doomsday_poster_hd_2027_4k_by_mrandrew7w7_djyh7h2-fullview.jpg?token=eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ1cm46YXBwOjdlMGQxODg5ODIyNjQzNzNhNWYwZDQxNWVhMGQyNmUwIiwiaXNzIjoidXJuOmFwcDo3ZTBkMTg4OTgyMjY0MzczYTVmMGQ0MTVlYTBkMjZlMCIsIm9iaiI6W1t7ImhlaWdodCI6Ijw9MjAyNyIsInBhdGgiOiJcL2ZcLzJlMzE3YTFjLWYxY2UtNGE1Zi05MGRiLWQ4OGNjMDFkYjJkMFwvZGp5aDdoMi1kMGRkM2ViNy1hZGU2LTQyNDUtYWQxNC1mODQzYjRjZjdkZjIucG5nIiwid2lkdGgiOiI8PTEyODAifV1dLCJhdWQiOlsidXJuOnNlcnZpY2U6aW1hZ2Uub3BlcmF0aW9ucyJdfQ.F0tPUEt8UhfhosZKOzP0IZAPNtpsQKR-ZKR0RKiukQQ', 'https://youtube.com/watch?v=example1', 150, 'C13', 'Action, Sci-Fi, Adventure', 'Joe Russo, Anthony Russo', 'Robert Downey Jr., Chris Evans, Scarlett Johansson', '2026-05-01', 'NOW_SHOWING', 8.5),
(2, 'Inside Out 3', 'Riley is now in college and encounters a whole new set of emotions as she navigates adult life, friendships, and the challenges of growing up.', 'https://tse2.mm.bing.net/th/id/OIP.23N9PBfGye0SMsaYqGHX9QHaJ4?r=0&rs=1&pid=ImgDetMain&o=7&rm=3', NULL, 105, 'P', 'Animation, Comedy, Family', 'Kelsey Mann', 'Amy Poehler, Phyllis Smith, Lewis Black', '2026-06-20', 'NOW_SHOWING', 8.2),
(3, 'The Batman 2', 'Bruce Wayne continues his crusade against crime in Gotham City, facing a new villain who threatens to expose the dark secrets of the Wayne family.', 'https://tse1.mm.bing.net/th/id/OIP.iIIjvG_ZpyoZA_ex8hmwwwHaKb?r=0&rs=1&pid=ImgDetMain&o=7&rm=3', 'https://youtube.com/watch?v=example3', 165, 'C16', 'Action, Crime, Drama', 'Matt Reeves', 'Robert Pattinson, Zoë Kravitz, Colin Farrell', '2026-07-15', 'COMING_SOON', 0.0),
(4, 'Spirited Away 2: Return to the Spirit World', 'Chihiro, now an adult, is mysteriously drawn back to the spirit world when strange events begin occurring in the real world.', 'https://musicart.xboxlive.com/7/aa355100-0000-0000-0000-000000000002/504/image.jpg?w=1920&h=1080', NULL, 130, 'P', 'Animation, Fantasy, Adventure', 'Hayao Miyazaki', 'Rumi Hiiragi, Miyu Irino', '2026-06-01', 'NOW_SHOWING', 9.0),
(5, 'Fast & Furious 11', 'Dom Toretto and his family face their ultimate challenge as a global conspiracy threatens everything they have built.', 'https://th.bing.com/th/id/R.df69bcfaab035f431d8bc7ed1abf0b40?rik=TVbgQr0ELDnXZw&pid=ImgRaw&r=0', NULL, 140, 'C13', 'Action, Thriller', 'Louis Leterrier', 'Vin Diesel, Michelle Rodriguez, Jason Momoa', '2026-08-01', 'COMING_SOON', 0.0),
(6, 'Doraemon: Nobita và Cuộc Phiêu Lưu Vũ Trụ', 'Nobita và nhóm bạn cùng Doraemon khám phá một hành tinh bí ẩn nơi có một nền văn minh cổ đại đang đối mặt với nguy hiểm.', 'https://i.vietgiaitri.com/2022/4/28/phim-dien-anh-doraemon-nobita-va-cuoc-chien-vu-tru-ti-hon-2021-san-sang-ra-mat-mua-he-nay-e19-6423605.png', NULL, 100, 'P', 'Animation, Adventure, Comedy', 'Shinnosuke Yakuwa', 'Wasabi Mizuta, Megumi Ohara', '2026-05-25', 'NOW_SHOWING', 7.8)
ON CONFLICT (id) DO NOTHING;

-- Reset sequence for movies
SELECT setval('movies_id_seq', (SELECT MAX(id) FROM movies));

-- 2. Cinemas
INSERT INTO cinemas (id, name, address, city, image_url)
VALUES
(1, 'CGV Vincom Center', '72 Lê Thánh Tôn, Quận 1', 'Hồ Chí Minh', 'https://citytowerbinhudong.com/wp-content/uploads/2025/10/rap-cgv-vincom-center-landmark-81-hien-dai.jpg'),
(2, 'Lotte Cinema Nowzone', '235 Nguyễn Văn Cừ, Quận 1', 'Hồ Chí Minh', 'https://toplist.vn/images/800px/lotte-cinema-nowzone-1000919.jpg'),
(3, 'Galaxy Cinema Nguyễn Du', '116 Nguyễn Du, Quận 1', 'Hồ Chí Minh', 'https://tse3.mm.bing.net/th/id/OIP.6VROMp0ml2_9LxW4zklTFwHaE8?r=0&rs=1&pid=ImgDetMain&o=7&rm=3')
ON CONFLICT (id) DO NOTHING;

-- Reset sequence for cinemas
SELECT setval('cinemas_id_seq', (SELECT MAX(id) FROM cinemas));

-- 3. Rooms
INSERT INTO rooms (id, cinema_id, name, total_seats, room_type)
VALUES
(1, 1, 'Room 1', 80, '2D'),
(2, 1, 'Room 2', 60, '3D'),
(3, 1, 'IMAX', 120, 'IMAX'),
(4, 2, 'Room 1', 80, '2D'),
(5, 2, 'Room 2', 60, '3D'),
(6, 2, 'IMAX', 120, 'IMAX'),
(7, 3, 'Room 1', 80, '2D'),
(8, 3, 'Room 2', 60, '3D'),
(9, 3, 'IMAX', 120, 'IMAX')
ON CONFLICT (id) DO NOTHING;

-- Reset sequence for rooms
SELECT setval('rooms_id_seq', (SELECT MAX(id) FROM rooms));

-- 4. Promotions
INSERT INTO promotions (id, code, discount_percent, max_discount, min_purchase, start_date, end_date, active, usage_limit)
VALUES
(1, 'WELCOME10', 10, 30000, 100000, '2026-01-01', '2026-12-31', true, 1000),
(2, 'STUDENT20', 20, 50000, 75000, '2026-01-01', '2026-12-31', true, 500),
(3, 'WEEKEND15', 15, 40000, NULL, '2026-06-01', '2026-08-31', true, NULL)
ON CONFLICT (id) DO NOTHING;

-- Reset sequence for promotions
SELECT setval('promotions_id_seq', (SELECT MAX(id) FROM promotions));

-- ========================================================
-- PL/PGSQL PROCEDURES TO GENERATE SEATS & SHOWTIMES
-- ========================================================

-- Generate Seats
DO $$
DECLARE
  v_room RECORD;
  v_rows TEXT[];
  v_row TEXT;
  v_seats_per_row INT;
  v_number INT;
  v_seat_type seat_type;
BEGIN
  -- Chỉ chạy khi chưa có ghế nào
  IF (SELECT COUNT(*) FROM seats) = 0 THEN
    FOR v_room IN SELECT * FROM rooms LOOP
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
    END LOOP;
  END IF;
END;
$$;

-- Generate Showtimes
DO $$
DECLARE
  v_movie RECORD;
  v_room RECORD;
  v_day_offset INT;
  v_start_time TIMESTAMPTZ;
  v_end_time TIMESTAMPTZ;
  v_time TEXT;
  v_times TEXT[] := ARRAY['09:00', '13:00', '16:30', '19:30', '22:00'];
  v_price FLOAT;
  v_hours INT;
  v_minutes INT;
BEGIN
  -- Chỉ chạy khi chưa có showtimes
  IF (SELECT COUNT(*) FROM showtimes) = 0 THEN
    FOR v_day_offset IN 0..2 LOOP
      FOR v_movie IN SELECT * FROM movies WHERE status = 'NOW_SHOWING' LOOP
        -- Mỗi phim chiếu ở một số phòng đại diện
        FOR v_room IN SELECT * FROM rooms WHERE id IN (1 + v_day_offset, 4 + v_day_offset, 7 + v_day_offset) LOOP
          FOREACH v_time IN ARRAY v_times LOOP
            v_hours := split_part(v_time, ':', 1)::INT;
            v_minutes := split_part(v_time, ':', 2)::INT;

            -- Khởi tạo thời gian chiếu (theo múi giờ địa phương)
            v_start_time := (date_trunc('day', now()) + (v_day_offset || ' day')::INTERVAL + (v_hours || ' hour')::INTERVAL + (v_minutes || ' minute')::INTERVAL) AT TIME ZONE 'Asia/Ho_Chi_Minh';

            -- Bỏ qua các suất chiếu trong quá khứ
            IF v_start_time < now() THEN
              CONTINUE;
            END IF;

            v_end_time := v_start_time + (v_movie.duration || ' minute')::INTERVAL + '15 minute'::INTERVAL;

            -- Tính giá vé
            v_price := 75000;
            IF v_hours >= 17 THEN
              v_price := 95000;
            END IF;
            IF v_hours >= 19 THEN
              v_price := 120000;
            END IF;
            IF v_room.name = 'IMAX' THEN
              v_price := v_price + 30000;
            END IF;

            INSERT INTO showtimes (movie_id, room_id, start_time, end_time, price)
            VALUES (v_movie.id, v_room.id, v_start_time, v_end_time, v_price);
          END LOOP;
        END LOOP;
      END LOOP;
    END LOOP;
  END IF;
END;
$$;
