// ============================================
// Payments Routes
// ============================================
const { Router } = require('express');
const paymentsController = require('./payments.controller');
const { authenticate } = require('../../middleware/auth');

const router = Router();

// Yêu cầu đăng nhập cho tất cả các thanh toán
router.use(authenticate);

// POST /api/payments/demo-confirm - Xác nhận thanh toán demo và xuất vé
router.post('/demo-confirm', paymentsController.confirmDemoPayment);

module.exports = router;
