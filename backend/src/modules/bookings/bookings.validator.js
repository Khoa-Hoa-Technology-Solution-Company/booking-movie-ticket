// ============================================
// Bookings Validator
// ============================================
const { z } = require('zod');

const createBookingSchema = z.object({
  showtimeId: z
    .number({ required_error: 'showtimeId is required' })
    .int('showtimeId must be an integer')
    .positive('showtimeId must be a positive number'),
  seatIds: z
    .array(z.number().int().positive())
    .min(1, 'At least one seat must be selected'),
  promotionCode: z
    .string()
    .trim()
    .optional(),
});

/**
 * Middleware factory: validate request body bằng Zod schema
 */
function validate(schema) {
  return (req, res, next) => {
    try {
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: error.errors.map((e) => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      });
    }
  };
}

module.exports = {
  createBookingSchema,
  validate,
};
