// ============================================
// Security Routes
// API endpoints cho module Security
// Tất cả đều yêu cầu authentication
// ============================================
const { Router } = require('express');
const securityController = require('./security.controller');
const { authenticate } = require('../../middleware/auth');

const router = Router();

// Tất cả routes trong module này đều cần đăng nhập
router.use(authenticate);

// GET /api/security/dashboard
router.get('/dashboard', securityController.getDashboard);

// GET /api/security/issues
router.get('/issues', securityController.getSecurityIssues);

// GET /api/security/login-history
router.get('/login-history', securityController.getLoginHistory);

// GET /api/security/alerts
router.get('/alerts', securityController.getSecurityAlerts);

// PATCH /api/security/toggle-2fa
router.patch('/toggle-2fa', securityController.toggle2FA);

// PATCH /api/security/alerts/:id/read
router.patch('/alerts/:id/read', securityController.markAlertAsRead);

module.exports = router;
