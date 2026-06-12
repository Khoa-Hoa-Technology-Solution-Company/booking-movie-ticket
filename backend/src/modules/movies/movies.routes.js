// ============================================
// Movies Routes
// Public: listing + detail
// Admin: CRUD (sau này mở rộng)
// ============================================
const { Router } = require('express');
const moviesController = require('./movies.controller');
const { authenticate, authorize } = require('../../middleware/auth');

const router = Router();

// --- Public routes (không cần đăng nhập) ---

// GET /api/movies/now-showing
router.get('/now-showing', moviesController.getNowShowing);

// GET /api/movies/coming-soon
router.get('/coming-soon', moviesController.getComingSoon);

// GET /api/movies/:id
router.get('/:id', moviesController.getMovieById);

// --- Admin routes (cần đăng nhập + quyền ADMIN) ---

// GET /api/movies (admin: danh sách tất cả phim)
router.get('/', authenticate, authorize('ADMIN'), moviesController.getAllMovies);

module.exports = router;
