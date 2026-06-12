// ============================================
// Token Service
// Quản lý JWT access token và refresh token
// ============================================
const jwt = require('jsonwebtoken');
const config = require('../config/env');
const prisma = require('../config/database');
const { hashSHA256, generateRefreshToken } = require('../utils/crypto');

/**
 * Tạo JWT access token (hạn 15 phút)
 * Payload chứa: userId, email, role
 * KHÔNG chứa password hay sensitive data
 */
function generateAccessToken(user) {
  return jwt.sign(
    {
      userId: user.id,
      email: user.email,
      role: user.role,
    },
    config.jwt.accessSecret,
    { expiresIn: config.jwt.accessExpiresIn }
  );
}

/**
 * Tạo refresh token và lưu hash vào DB
 * - Token gốc gửi cho client
 * - Hash SHA-256 lưu trong DB (không lưu plain text)
 * - Hạn 7 ngày
 */
async function createRefreshToken(userId) {
  // Tạo token ngẫu nhiên
  const token = generateRefreshToken();

  // Hash token trước khi lưu DB
  const tokenHash = hashSHA256(token);

  // Tính thời gian hết hạn (7 ngày)
  const expiresAt = new Date();
  expiresAt.setDate(expiresAt.getDate() + 7);

  // Lưu vào DB
  await prisma.refreshToken.create({
    data: {
      userId,
      tokenHash,
      expiresAt,
    },
  });

  return token; // Trả token gốc cho client
}

/**
 * Verify refresh token
 * - Hash token client gửi lên
 * - Tìm trong DB, kiểm tra chưa revoke và chưa hết hạn
 */
async function verifyRefreshToken(token) {
  const tokenHash = hashSHA256(token);

  const storedToken = await prisma.refreshToken.findFirst({
    where: {
      tokenHash,
      revoked: false,
      expiresAt: { gt: new Date() },
    },
    include: {
      user: {
        select: {
          id: true,
          email: true,
          role: true,
          name: true,
        },
      },
    },
  });

  return storedToken;
}

/**
 * Revoke (thu hồi) một refresh token
 * Dùng khi logout hoặc phát hiện bất thường
 */
async function revokeRefreshToken(token) {
  const tokenHash = hashSHA256(token);

  await prisma.refreshToken.updateMany({
    where: { tokenHash },
    data: { revoked: true },
  });
}

/**
 * Revoke tất cả refresh token của user
 * Dùng khi thay đổi password hoặc bị hack
 */
async function revokeAllUserTokens(userId) {
  await prisma.refreshToken.updateMany({
    where: { userId, revoked: false },
    data: { revoked: true },
  });
}

/**
 * Dọn dẹp refresh token hết hạn hoặc đã revoke
 */
async function cleanupExpiredTokens() {
  await prisma.refreshToken.deleteMany({
    where: {
      OR: [
        { expiresAt: { lt: new Date() } },
        { revoked: true },
      ],
    },
  });
}

module.exports = {
  generateAccessToken,
  createRefreshToken,
  verifyRefreshToken,
  revokeRefreshToken,
  revokeAllUserTokens,
  cleanupExpiredTokens,
};
