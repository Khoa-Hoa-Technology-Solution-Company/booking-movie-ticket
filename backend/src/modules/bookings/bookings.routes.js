// ============================================
// Bookings Routes
// ============================================
const { Router } = require('express');
const bookingsController = require('./bookings.controller');
const { authenticate } = require('../../middleware/auth');
const { createBookingSchema, validate } = require('./bookings.validator');

const router = Router();

// Tất cả booking routes đều cần đăng nhập
router.use(authenticate);

// POST /api/bookings - Tạo đơn đặt vé mới
router.post('/', validate(createBookingSchema), bookingsController.createBooking);

// GET /api/bookings/history - Lịch sử đặt vé của user
router.get('/history', bookingsController.getBookingHistory);

// GET /api/bookings/:id - Chi tiết đặt vé theo ID
router.get('/:id', bookingsController.getBookingById);

// PATCH /api/bookings/:id/cancel - Hủy đặt vé ở trạng thái PENDING
router.patch('/:id/cancel', bookingsController.cancelBooking);

module.exports = router;
