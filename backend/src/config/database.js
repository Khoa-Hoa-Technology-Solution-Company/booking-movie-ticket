// ============================================
// Prisma Client Singleton
// Đảm bảo chỉ tạo 1 instance Prisma Client
// ============================================
const { PrismaClient } = require('@prisma/client');

// Singleton pattern: tránh tạo nhiều connection khi hot-reload
const globalForPrisma = globalThis;

const prisma =
  globalForPrisma.prisma ||
  new PrismaClient({
    log: process.env.NODE_ENV === 'development' 
      ? ['query', 'error', 'warn'] 
      : ['error'],
  });

if (process.env.NODE_ENV !== 'production') {
  globalForPrisma.prisma = prisma;
}

module.exports = prisma;
