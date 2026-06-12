// ============================================
// Cinemas Routes
// ============================================
const { Router } = require('express');
const cinemasController = require('./cinemas.controller');

const router = Router();

// GET /api/cinemas - Danh sách rạp
router.get('/', cinemasController.getCinemas);

// GET /api/cinemas/:id - Chi tiết rạp
router.get('/:id', cinemasController.getCinemaById);

module.exports = router;
