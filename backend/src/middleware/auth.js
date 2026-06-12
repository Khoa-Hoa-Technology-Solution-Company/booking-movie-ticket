// ============================================
// Auth Middleware
// Xác thực JWT và kiểm tra role
// ============================================
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const { errorResponse } = require('../utils/helpers');

/**
 * Middleware xác thực JWT access token
 * Kiểm tra header: Authorization: Bearer <token>
 * Nếu hợp lệ → gắn user info vào req.user
 */
function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Access token is required', 401);
    }

    const token = authHeader.split(' ')[1];

    // Verify JWT access token
    const decoded = jwt.verify(token, config.jwt.accessSecret);

    // Gắn thông tin user vào request
    req.user = {
      id: decoded.userId,
      email: decoded.email,
      role: decoded.role,
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Access token has expired', 401);
    }
    if (error.name === 'JsonWebTokenError') {
      return errorResponse(res, 'Invalid access token', 401);
    }
    return errorResponse(res, 'Authentication failed', 401);
  }
}

/**
 * Middleware kiểm tra role (Role-Based Access Control)
 * Dùng sau authenticate middleware
 * Ví dụ: authorize('ADMIN') → chỉ admin mới truy cập được
 */
function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required', 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return errorResponse(res, 'Insufficient permissions', 403);
    }

    next();
  };
}

module.exports = { authenticate, authorize };
