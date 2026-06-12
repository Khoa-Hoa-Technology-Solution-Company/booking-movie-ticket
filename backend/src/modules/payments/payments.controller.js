// ============================================
// Payments Controller
// ============================================
const paymentsService = require('./payments.service');
const { successResponse } = require('../../utils/helpers');

async function confirmDemoPayment(req, res, next) {
  try {
    const userId = req.user.id;
    const userRole = req.user.role;
    const { bookingId } = req.body;

    if (!bookingId) {
      return res.status(400).json({
        success: false,
        message: 'bookingId is required',
      });
    }

    const result = await paymentsService.confirmDemoPayment(userId, userRole, {
      bookingId: parseInt(bookingId),
    });

    return successResponse(res, 'Payment demo confirmed and ticket issued', result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  confirmDemoPayment,
};
