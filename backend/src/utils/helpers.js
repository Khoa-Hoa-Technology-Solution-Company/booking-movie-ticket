// ============================================
// Helper Utilities
// Các hàm tiện ích dùng chung
// ============================================

/**
 * Lấy IP address từ request
 * Hỗ trợ proxy (X-Forwarded-For header)
 */
function getClientIP(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (forwarded) {
    return forwarded.split(',')[0].trim();
  }
  return req.socket?.remoteAddress || req.ip || 'unknown';
}

/**
 * Parse device name từ User-Agent string
 * Dùng ua-parser-js để phân tích
 */
function parseDeviceName(userAgentString) {
  const UAParser = require('ua-parser-js');
  const parser = new UAParser(userAgentString);
  const result = parser.getResult();

  const browser = result.browser.name || 'Unknown Browser';
  const os = result.os.name || 'Unknown OS';
  const osVersion = result.os.version || '';
  const device = result.device.model || '';

  if (device) {
    return `${device} - ${browser} on ${os} ${osVersion}`.trim();
  }
  return `${browser} on ${os} ${osVersion}`.trim();
}

/**
 * Tạo response chuẩn cho API
 */
function apiResponse(res, statusCode, data) {
  return res.status(statusCode).json(data);
}

/**
 * Tạo response thành công
 */
function successResponse(res, message, data = null, statusCode = 200) {
  const response = { success: true, message };
  if (data !== null) {
    response.data = data;
  }
  return apiResponse(res, statusCode, response);
}

/**
 * Tạo response lỗi
 */
function errorResponse(res, message, statusCode = 400, errors = null) {
  const response = { success: false, message };
  if (errors !== null) {
    response.errors = errors;
  }
  return apiResponse(res, statusCode, response);
}

/**
 * Kiểm tra password có đủ mạnh không
 * Yêu cầu: ít nhất 8 ký tự, có chữ hoa, chữ thường, và số
 */
function isStrongPassword(password) {
  if (password.length < 8) return false;
  if (!/[A-Z]/.test(password)) return false;
  if (!/[a-z]/.test(password)) return false;
  if (!/[0-9]/.test(password)) return false;
  return true;
}

/**
 * Kiểm tra số điện thoại Việt Nam hợp lệ
 */
function isValidVietnamesePhoneNumber(phone) {
  if (!phone) return false;
  const normalized = phone.trim().replace(/[\s.-]/g, '');
  const regex = /^(?:\+84|84|0)(3|5|7|8|9)\d{8}$/;
  return regex.test(normalized);
}

/**
 * Chuẩn hóa số điện thoại về dạng 84xxxxxxxxx
 */
function normalizePhoneNumber(phone) {
  if (!phone) return null;
  const normalizedInput = phone.trim().replace(/[\s.-]/g, '');
  if (/^\+84(3|5|7|8|9)\d{8}$/.test(normalizedInput)) {
    return normalizedInput.slice(1);
  }
  if (/^84(3|5|7|8|9)\d{8}$/.test(normalizedInput)) {
    return normalizedInput;
  }
  if (/^0(3|5|7|8|9)\d{8}$/.test(normalizedInput)) {
    return `84${normalizedInput.slice(1)}`;
  }
  return null;
}

module.exports = {
  getClientIP,
  parseDeviceName,
  apiResponse,
  successResponse,
  errorResponse,
  isStrongPassword,
  isValidVietnamesePhoneNumber,
  normalizePhoneNumber,
};
