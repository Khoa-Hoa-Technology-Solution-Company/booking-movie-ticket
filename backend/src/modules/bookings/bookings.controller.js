// ============================================
// Bookings Controller
// ============================================
const bookingsService = require('./bookings.service');
const { successResponse } = require('../../utils/helpers');

async function createBooking(req, res, next) {
  try {
    const userId = req.user.id;
    const { showtimeId, seatIds, promotionCode } = req.body;
    const booking = await bookingsService.createBooking(userId, {
      showtimeId,
      seatIds,
      promotionCode,
    });
    return successResponse(res, 'Booking created successfully', {
      bookingId: booking.id,
      status: booking.status,
      totalAmount: booking.totalAmount,
    }, 201);
  } catch (error) {
    next(error);
  }
}

async function getBookingHistory(req, res, next) {
  try {
    const userId = req.user.id;
    const bookings = await bookingsService.getBookingHistory(userId);
    return successResponse(res, 'Booking history loaded', { bookings });
  } catch (error) {
    next(error);
  }
}

async function getBookingById(req, res, next) {
  try {
    const bookingId = parseInt(req.params.id);
    const userId = req.user.id;
    const userRole = req.user.role;
    const booking = await bookingsService.getBookingById(bookingId, userId, userRole);
    return successResponse(res, 'Booking detail loaded', { booking });
  } catch (error) {
    next(error);
  }
}

async function cancelBooking(req, res, next) {
  try {
    const bookingId = parseInt(req.params.id);
    const userId = req.user.id;
    const userRole = req.user.role;
    const booking = await bookingsService.cancelBooking(bookingId, userId, userRole);
    return successResponse(res, 'Booking cancelled successfully', {
      bookingId: booking.id,
      status: booking.status,
    });
  } catch (error) {
    next(error);
  }
}

module.exports = {
  createBooking,
  getBookingHistory,
  getBookingById,
  cancelBooking,
};
