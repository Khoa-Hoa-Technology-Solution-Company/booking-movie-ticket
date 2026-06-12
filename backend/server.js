// ============================================
// Server Entry Point
// Movie Ticket Booking App with Account Security
// ============================================
const app = require('./src/app');
const config = require('./src/config/env');
const prisma = require('./src/config/database');

async function startServer() {
  try {
    // Test database connection
    await prisma.$connect();
    console.log('✅ Database connected successfully');

    // Start HTTP server
    app.listen(config.port, () => {
      console.log('');
      console.log('='.repeat(55));
      console.log('🎬 Movie Ticket Booking App with Account Security');
      console.log('='.repeat(55));
      console.log(`🚀 Server running on http://localhost:${config.port}`);
      console.log(`📖 Environment: ${config.nodeEnv}`);
      console.log(`📧 Email: ${config.email.enabled ? 'SMTP configured' : 'Console mode (codes logged)'}`);
      console.log(`🔗 Health: http://localhost:${config.port}/api/health`);
      console.log('='.repeat(55));
      console.log('');
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error.message);
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGINT', async () => {
  console.log('\n🛑 Shutting down gracefully...');
  await prisma.$disconnect();
  process.exit(0);
});

process.on('SIGTERM', async () => {
  await prisma.$disconnect();
  process.exit(0);
});

startServer();
