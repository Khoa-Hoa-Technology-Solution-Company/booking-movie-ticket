// ============================================
// Auth Routes
// Định tuyến API cho module Auth
// ============================================
const { Router } = require('express');
const authController = require('./auth.controller');
const { validate, registerSchema, loginSchema, verifyEmailSchema, verifyOtpSchema, resendEmailCodeSchema, verifyPhoneSchema, resendPhoneCodeSchema, refreshTokenSchema, logoutSchema } = require('./auth.validator');
const { loginLimiter, registerLimiter, verifyEmailLimiter, verifyOtpLimiter, resendCodeLimiter } = require('../../middleware/rateLimiter');

const router = Router();

// POST /api/auth/register
// Rate limit: 5 lần / 15 phút
router.post(
  '/register',
  registerLimiter,
  validate(registerSchema),
  authController.register
);

// POST /api/auth/login
// Rate limit: 10 lần / 15 phút
router.post(
  '/login',
  loginLimiter,
  validate(loginSchema),
  authController.login
);

// POST /api/auth/verify-email
// Rate limit: 10 lần / 15 phút
router.post(
  '/verify-email',
  verifyEmailLimiter,
  validate(verifyEmailSchema),
  authController.verifyEmail
);

// POST /api/auth/resend-email-code
// Rate limit: 3 lần / 15 phút (chống spam email)
router.post(
  '/resend-email-code',
  resendCodeLimiter,
  validate(resendEmailCodeSchema),
  authController.resendEmailCode
);

// POST /api/auth/verify-otp
// Rate limit: 5 lần / 15 phút
router.post(
  '/verify-otp',
  verifyOtpLimiter,
  validate(verifyOtpSchema),
  authController.verifyOtp
);

// POST /api/auth/verify-phone
router.post(
  '/verify-phone',
  verifyEmailLimiter,
  validate(verifyPhoneSchema),
  authController.verifyPhone
);

// POST /api/auth/resend-phone-code
router.post(
  '/resend-phone-code',
  resendCodeLimiter,
  validate(resendPhoneCodeSchema),
  authController.resendPhoneCode
);

// POST /api/auth/refresh-token
router.post(
  '/refresh-token',
  validate(refreshTokenSchema),
  authController.refreshToken
);

// POST /api/auth/logout
router.post(
  '/logout',
  validate(logoutSchema),
  authController.logout
);

const { authenticate } = require('../../middleware/auth');

// POST /api/auth/record-login
router.post(
  '/record-login',
  authenticate,
  authController.recordFirebaseLogin
);

module.exports = router;
