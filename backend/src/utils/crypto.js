// ============================================
// Crypto Utilities
// Hash và verify password (Argon2id), token, OTP
// ============================================
const argon2 = require('argon2');
const crypto = require('crypto');

/**
 * Hash password bằng Argon2id
 * Argon2id là algorithm được khuyến nghị cho password hashing
 * - memoryCost: 65536 KB (64 MB) RAM
 * - timeCost: 3 iterations  
 * - parallelism: 4 threads
 */
async function hashPassword(password) {
  return argon2.hash(password, {
    type: argon2.argon2id,
    memoryCost: 65536,
    timeCost: 3,
    parallelism: 4,
  });
}

/**
 * Verify password với Argon2id hash
 * @returns {boolean} true nếu password đúng
 */
async function verifyPassword(password, hash) {
  return argon2.verify(hash, password);
}

/**
 * Hash string bằng SHA-256
 * Dùng cho: refresh token, verification code, OTP
 * (Không cần Argon2 vì các giá trị này đã có entropy cao)
 */
function hashSHA256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

/**
 * Tạo mã xác minh 6 chữ số
 * Dùng crypto.randomInt để đảm bảo random an toàn
 */
function generateVerificationCode() {
  return crypto.randomInt(100000, 999999).toString();
}

/**
 * Tạo refresh token ngẫu nhiên (64 bytes → hex string)
 */
function generateRefreshToken() {
  return crypto.randomBytes(64).toString('hex');
}

module.exports = {
  hashPassword,
  verifyPassword,
  hashSHA256,
  generateVerificationCode,
  generateRefreshToken,
};
