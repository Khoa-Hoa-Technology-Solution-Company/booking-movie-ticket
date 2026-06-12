// ============================================
// Showtimes Routes
// ============================================
const { Router } = require('express');
const showtimesController = require('./showtimes.controller');

const router = Router();

// GET /api/showtimes - Lấy lịch chiếu theo bộ lọc (movieId, cinemaId, date)
router.get('/', showtimesController.getShowtimes);

// GET /api/showtimes/:id - Chi tiết lịch chiếu và trạng thái ghế
router.get('/:id', showtimesController.getShowtimeById);

module.exports = router;
