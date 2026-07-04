-- ========================================================
-- RPC FUNCTION FOR ADMIN ANALYTICS
-- ========================================================

CREATE OR REPLACE FUNCTION get_analytics_summary(
  p_start_date TIMESTAMPTZ,
  p_end_date TIMESTAMPTZ
)
RETURNS JSON AS $$
DECLARE
  v_total_revenue FLOAT;
  v_total_tickets INT;
  v_top_movies JSON;
  v_room_occupancy JSON;
BEGIN
  -- 1. Kiểm tra quyền Admin của user đang gọi
  IF NOT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role = 'ADMIN'
  ) THEN
    RAISE EXCEPTION 'Access denied. Administrator privileges required.';
  END IF;

  -- 2. Tính tổng doanh thu từ payments đã hoàn thành (PAID)
  SELECT COALESCE(SUM(amount), 0) INTO v_total_revenue
  FROM payments
  WHERE status = 'PAID'
    AND created_at >= p_start_date
    AND created_at <= p_end_date;

  -- 3. Tính tổng số vé bán được (của các booking CONFIRMED)
  SELECT COUNT(*) INTO v_total_tickets
  FROM tickets t
  JOIN bookings b ON t.booking_id = b.id
  WHERE b.status = 'CONFIRMED'
    AND b.created_at >= p_start_date
    AND b.created_at <= p_end_date;

  -- 4. Top 5 phim có doanh thu cao nhất
  SELECT json_agg(t) INTO v_top_movies
  FROM (
    SELECT m.title, COALESCE(SUM(p.amount), 0) AS revenue
    FROM movies m
    JOIN showtimes s ON m.id = s.movie_id
    JOIN bookings b ON s.id = b.showtime_id
    JOIN payments p ON b.id = p.booking_id
    WHERE b.status = 'CONFIRMED'
      AND b.created_at >= p_start_date
      AND b.created_at <= p_end_date
    GROUP BY m.id, m.title
    ORDER BY revenue DESC
    LIMIT 5
  ) t;

  -- 5. Tỷ lệ lấp đầy ghế theo suất chiếu (top 10 suất chiếu trong khoảng thời gian)
  SELECT json_agg(t) INTO v_room_occupancy
  FROM (
    SELECT 
      c.name AS cinema_name,
      m.title AS movie_title,
      s.start_time,
      r.total_seats,
      COUNT(bs.id) AS booked_seats,
      ROUND((COUNT(bs.id)::DECIMAL / NULLIF(r.total_seats, 0) * 100), 2) AS occupancy_rate
    FROM showtimes s
    JOIN movies m ON s.movie_id = m.id
    JOIN rooms r ON s.room_id = r.id
    JOIN cinemas c ON r.cinema_id = c.id
    LEFT JOIN bookings b ON s.id = b.showtime_id AND b.status = 'CONFIRMED'
    LEFT JOIN booking_seats bs ON b.id = bs.booking_id
    WHERE s.start_time >= p_start_date
      AND s.start_time <= p_end_date
    GROUP BY s.id, c.name, m.title, s.start_time, r.total_seats
    ORDER BY occupancy_rate DESC, s.start_time DESC
    LIMIT 10
  ) t;

  RETURN json_build_object(
    'total_revenue', v_total_revenue,
    'total_tickets', v_total_tickets,
    'top_movies', COALESCE(v_top_movies, '[]'::json),
    'room_occupancy', COALESCE(v_room_occupancy, '[]'::json)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Cấp quyền thực thi
GRANT EXECUTE ON FUNCTION get_analytics_summary TO authenticated;
