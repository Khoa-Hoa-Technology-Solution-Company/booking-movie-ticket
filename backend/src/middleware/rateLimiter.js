// ============================================
// Rate Limiter Configuration
// Chống brute force và spam cho từng endpoint
// ============================================
const rateLimit = require('express-rate-limit');

/**
 * Tạo rate limiter với config tùy chỉnh
 * @param {number} windowMs - Thời gian window (ms)
 * @param {number} max - Số request tối đa trong window
 * @param {string} message - Thông báo khi bị limit
 */
function createLimiter(windowMs, max, message) {
  return rateLimit({
    windowMs,
    max,
    message: {
      success: false,
      message: message || 'Too many requests, please try again later',
    },
    standardHeaders: true, // Trả header RateLimit-*
    legacyHeaders: false,  // Tắt header X-RateLimit-*
  });
}

// --- Rate limiters cho từng endpoint ---

// Login: 10 lần / 15 phút (chống brute force password)
const loginLimiter = createLimiter(
  15 * 60 * 1000, // 15 phút
  10,
  'Too many login attempts. Please try again after 15 minutes.'
);

// Register: 5 lần / 15 phút (chống tạo account spam)
const registerLimiter = createLimiter(
  15 * 60 * 1000,
  5,
  'Too many registration attempts. Please try again after 15 minutes.'
);

// Verify email: 10 lần / 15 phút
const verifyEmailLimiter = createLimiter(
  15 * 60 * 1000,
  10,
  'Too many verification attempts. Please try again after 15 minutes.'
);

// Verify OTP: 5 lần / 15 phút (chống brute force OTP)
const verifyOtpLimiter = createLimiter(
  15 * 60 * 1000,
  5,
  'Too many OTP attempts. Please try again after 15 minutes.'
);

// Resend code: 3 lần / 15 phút (chống spam email)
const resendCodeLimiter = createLimiter(
  15 * 60 * 1000,
  3,
  'Too many resend requests. Please try again after 15 minutes.'
);

// General API: 100 requests / 15 phút
const generalLimiter = createLimiter(
  15 * 60 * 1000,
  100,
  'Too many requests. Please try again later.'
);

module.exports = {
  loginLimiter,
  registerLimiter,
  verifyEmailLimiter,
  verifyOtpLimiter,
  resendCodeLimiter,
  generalLimiter,
};
