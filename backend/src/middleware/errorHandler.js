// ============================================
// Global Error Handler
// Bắt tất cả lỗi, không expose lỗi hệ thống ra client
// ============================================
const config = require('../config/env');

/**
 * Middleware xử lý lỗi toàn cục
 * - Development: trả đầy đủ error stack
 * - Production: chỉ trả message chung
 * - KHÔNG BAO GIỜ log password, token, OTP
 */
function errorHandler(err, req, res, _next) {
  // Log lỗi server-side (không log sensitive data)
  console.error(`❌ [${new Date().toISOString()}] ${req.method} ${req.path}`);
  console.error(`   Error: ${err.message}`);

  if (config.isDev) {
    console.error(`   Stack: ${err.stack}`);
  }

  // Prisma known errors
  if (err.code === 'P2002') {
    return res.status(409).json({
      success: false,
      message: 'A record with this information already exists',
    });
  }

  if (err.code === 'P2025') {
    return res.status(404).json({
      success: false,
      message: 'Record not found',
    });
  }

  // Zod validation errors
  if (err.name === 'ZodError') {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: err.errors.map(e => ({
        field: e.path.join('.'),
        message: e.message,
      })),
    });
  }

  // JWT errors
  if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid or expired token',
    });
  }

  // Default server error
  const statusCode = err.statusCode || 500;
  res.status(statusCode).json({
    success: false,
    message: config.isDev ? err.message : 'Internal server error',
    // Chỉ trả stack trace trong development
    ...(config.isDev && { stack: err.stack }),
  });
}

module.exports = errorHandler;
