// ============================================
// Security Controller
// Xử lý request/response cho security endpoints
// ============================================
const securityService = require('./security.service');
const { successResponse } = require('../../utils/helpers');

/**
 * GET /api/security/dashboard
 * Lấy tổng quan bảo mật
 */
async function getDashboard(req, res, next) {
  try {
    const result = await securityService.getDashboard(req.user.id);
    return successResponse(res, 'Security dashboard', result);
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/security/issues
 * Lấy danh sách vấn đề bảo mật
 */
async function getSecurityIssues(req, res, next) {
  try {
    const result = await securityService.getSecurityIssues(req.user.id);
    return successResponse(res, 'Security issues', result);
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/security/login-history
 * Lấy lịch sử đăng nhập
 */
async function getLoginHistory(req, res, next) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await securityService.getLoginHistory(req.user.id, page, limit);
    return successResponse(res, 'Login history', result);
  } catch (error) {
    next(error);
  }
}

/**
 * GET /api/security/alerts
 * Lấy security alerts
 */
async function getSecurityAlerts(req, res, next) {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const result = await securityService.getSecurityAlerts(req.user.id, page, limit);
    return successResponse(res, 'Security alerts', result);
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/security/toggle-2fa
 * Bật/tắt 2FA
 */
async function toggle2FA(req, res, next) {
  try {
    const result = await securityService.toggle2FA(req.user.id);
    return successResponse(res, result.message, result);
  } catch (error) {
    next(error);
  }
}

/**
 * PATCH /api/security/alerts/:id/read
 * Đánh dấu alert đã đọc
 */
async function markAlertAsRead(req, res, next) {
  try {
    const alertId = parseInt(req.params.id);
    const result = await securityService.markAlertAsRead(req.user.id, alertId);
    return successResponse(res, result.message);
  } catch (error) {
    next(error);
  }
}

module.exports = {
  getDashboard,
  getSecurityIssues,
  getLoginHistory,
  getSecurityAlerts,
  toggle2FA,
  markAlertAsRead,
};
