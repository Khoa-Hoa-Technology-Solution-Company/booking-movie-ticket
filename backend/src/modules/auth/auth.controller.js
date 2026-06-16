// ============================================
// Auth Controller
// Xử lý request/response cho auth endpoints
// ============================================
const authService = require('./auth.service');
const { successResponse, errorResponse } = require('../../utils/helpers');

/**
 * POST /api/auth/register
 * Đăng ký tài khoản mới
 */
async function register(req, res, next) {
  try {
    const result = await authService.register(req.body);
    return successResponse(res, result.message, result, 201);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/login
 * Đăng nhập
 */
async function login(req, res, next) {
  try {
    const result = await authService.login(req.body, req);

    // Nếu cần OTP → trả status 200 với requireOtp flag
    if (result.requireOtp) {
      return successResponse(res, result.message, {
        requireOtp: true,
        identifier: result.identifier,
        email: result.email,
      });
    }

    // Login thành công → trả token
    return successResponse(res, 'Login successful', result);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/verify-email
 * Xác minh email bằng code 6 số
 */
async function verifyEmail(req, res, next) {
  try {
    const result = await authService.verifyEmail(req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/resend-email-code
 * Gửi lại mã xác minh email
 */
async function resendEmailCode(req, res, next) {
  try {
    const result = await authService.resendEmailCode(req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/verify-otp
 * Xác minh OTP 2FA
 */
async function verifyOtp(req, res, next) {
  try {
    const result = await authService.verifyOtp(req.body, req);
    return successResponse(res, 'OTP verified. Login successful', result);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/refresh-token
 * Làm mới access token
 */
async function refreshToken(req, res, next) {
  try {
    const result = await authService.refreshToken(req.body);
    return successResponse(res, 'Token refreshed', result);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/logout
 * Đăng xuất - revoke refresh token
 */
async function logout(req, res, next) {
  try {
    const result = await authService.logout(req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/verify-phone
 * Xác minh số điện thoại
 */
async function verifyPhone(req, res, next) {
  try {
    const result = await authService.verifyPhone(req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/resend-phone-code
 * Gửi lại mã xác minh số điện thoại
 */
async function resendPhoneCode(req, res, next) {
  try {
    const result = await authService.resendPhoneCode(req.body);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

/**
 * POST /api/auth/record-login
 * Ghi nhận login Firebase thành công (thiết bị lạ, history, alert)
 */
async function recordFirebaseLogin(req, res, next) {
  try {
    const { getClientIP, parseDeviceName } = require('../../utils/helpers');
    const ipAddress = getClientIP(req);
    const userAgent = req.headers['user-agent'] || 'Unknown';
    const deviceName = req.body?.deviceName || parseDeviceName(userAgent);

    const result = await authService.recordFirebaseLogin({
      userId: req.user.id,
      deviceName,
      ipAddress,
      userAgent,
    });

    return successResponse(res, 'Login recorded successfully', result);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  register,
  login,
  verifyEmail,
  resendEmailCode,
  verifyOtp,
  verifyPhone,
  resendPhoneCode,
  refreshToken,
  logout,
  recordFirebaseLogin,
};
