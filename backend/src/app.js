// ============================================
// Express Application Setup
// Movie Ticket Booking App with Account Security
// ============================================
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const { generalLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

// Import routes
const authRoutes = require('./modules/auth/auth.routes');
const securityRoutes = require('./modules/security/security.routes');
const moviesRoutes = require('./modules/movies/movies.routes');
const cinemasRoutes = require('./modules/cinemas/cinemas.routes');
const showtimesRoutes = require('./modules/showtimes/showtimes.routes');
const bookingsRoutes = require('./modules/bookings/bookings.routes');
const paymentsRoutes = require('./modules/payments/payments.routes');

const app = express();

// ===================== SECURITY MIDDLEWARE =====================

// Helmet: set security HTTP headers
app.use(helmet());

// CORS: cho phép Flutter app kết nối
app.use(cors({
  origin: '*', // Development: cho phép tất cả. Production: chỉ định domain cụ thể
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

// Parse JSON body
app.use(express.json({ limit: '10mb' }));

// Parse URL-encoded body
app.use(express.urlencoded({ extended: true }));

// Trust proxy (cho đúng IP khi dùng reverse proxy)
app.set('trust proxy', 1);

// General rate limit: 100 requests / 15 phút
app.use(generalLimiter);

// ===================== ROUTES =====================

// Health check
app.get('/api/health', (req, res) => {
  res.json({
    success: true,
    message: '🎬 Movie Ticket Booking API is running',
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Auth module
app.use('/api/auth', authRoutes);

// Security module
app.use('/api/security', securityRoutes);

// Movie booking modules
app.use('/api/movies', moviesRoutes);
app.use('/api/cinemas', cinemasRoutes);
app.use('/api/showtimes', showtimesRoutes);
app.use('/api/bookings', bookingsRoutes);
app.use('/api/payments', paymentsRoutes);

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.method} ${req.path} not found`,
  });
});

// Global error handler (phải đặt cuối cùng)
app.use(errorHandler);

module.exports = app;
