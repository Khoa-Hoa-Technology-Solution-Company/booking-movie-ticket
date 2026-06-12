// ============================================
// Auth Service
// Business logic cho Register, Login, Verify, OTP
// ============================================
const prisma = require('../../config/database');
const config = require('../../config/env');
const { hashPassword, verifyPassword, hashSHA256, generateVerificationCode } = require('../../utils/crypto');
const { getClientIP, parseDeviceName, isStrongPassword, normalizePhoneNumber } = require('../../utils/helpers');
const tokenService = require('../../services/token.service');
const emailService = require('../../services/email.service');

// ===================== REGISTER =====================

/**
 * Đăng ký tài khoản mới
 * Flow: validate → check email → hash password → create user → tạo code → gửi email
 */
async function register({ name, email, phoneNumber, password }) {
  const cleanEmail = email && email.trim() !== '' ? email.toLowerCase().trim() : null;
  const cleanPhone = phoneNumber && phoneNumber.trim() !== '' ? normalizePhoneNumber(phoneNumber) : null;

  // 1. Kiểm tra email đã tồn tại chưa
  if (cleanEmail) {
    const existingUserByEmail = await prisma.user.findUnique({
      where: { email: cleanEmail },
    });

    if (existingUserByEmail) {
      if (existingUserByEmail.emailVerified) {
        throw Object.assign(new Error('Email is already registered'), { statusCode: 409 });
      } else {
        // Nếu email đã đăng ký nhưng chưa xác minh, xóa user cũ để cho đăng ký mới
        await prisma.user.delete({
          where: { id: existingUserByEmail.id },
        });
      }
    }
  }

  // Kiểm tra số điện thoại đã tồn tại chưa
  if (cleanPhone) {
    const existingUserByPhone = await prisma.user.findUnique({
      where: { phoneNumber: cleanPhone },
    });

    if (existingUserByPhone) {
      if (existingUserByPhone.phoneVerified) {
        throw Object.assign(new Error('Phone number is already registered'), { statusCode: 409 });
      } else {
        // Nếu số điện thoại đã đăng ký nhưng chưa xác minh, xóa user cũ để cho đăng ký mới
        await prisma.user.delete({
          where: { id: existingUserByPhone.id },
        });
      }
    }
  }

  // 2. Hash password bằng Argon2id
  const passwordHash = await hashPassword(password);

  // 3. Tạo user mới
  const user = await prisma.user.create({
    data: {
      name,
      email: cleanEmail,
      phoneNumber: cleanPhone,
      passwordHash,
    },
  });

  // 4. Tạo mã xác minh (email hoặc phone)
  const code = generateVerificationCode();
  const codeHash = hashSHA256(code);
  const expiresAt = new Date(Date.now() + config.security.emailCodeExpiryMinutes * 60 * 1000);

  if (cleanEmail) {
    await prisma.verificationCode.create({
      data: {
        userId: user.id,
        codeHash,
        type: 'EMAIL_VERIFY',
        expiresAt,
      },
    });

    console.log(`\n🔑 VERIFICATION CODE for ${cleanEmail}: ${code}\n`);
    await emailService.sendVerificationEmail(cleanEmail, name, code);
  } else {
    // Nếu đăng ký bằng số điện thoại (không điền email)
    await prisma.verificationCode.create({
      data: {
        userId: user.id,
        codeHash,
        type: 'PHONE_VERIFY',
        expiresAt,
      },
    });

    console.log(`\n🔑 PHONE VERIFICATION CODE for ${cleanPhone}: ${code}\n`);
  }

  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phoneNumber: user.phoneNumber,
    emailVerified: user.emailVerified,
    phoneVerified: user.phoneVerified,
    message: cleanEmail
      ? 'Registration successful. Please verify your email.'
      : 'Registration successful. Please verify your phone number.',
  };
}

// ===================== LOGIN =====================

/**
 * Đăng nhập
 * Flow: check user → check lock → verify password → check 2FA → ghi history → trả token
 */
async function login({ identifier, password }, req) {
  const ipAddress = getClientIP(req);
  const userAgent = req.headers['user-agent'] || 'Unknown';
  const deviceName = parseDeviceName(userAgent);

  // 1. Tìm user theo email hoặc phone number
  const isEmail = identifier.includes('@');
  let user;

  if (isEmail) {
    user = await prisma.user.findUnique({
      where: { email: identifier.toLowerCase().trim() },
    });
  } else {
    const normalizedPhone = normalizePhoneNumber(identifier);
    user = await prisma.user.findUnique({
      where: { phoneNumber: normalizedPhone },
    });
  }

  if (!user) {
    throw Object.assign(new Error('Invalid email, phone number, or password'), { statusCode: 401 });
  }

  // 2. Kiểm tra tài khoản có bị khóa không
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    const remainingMinutes = Math.ceil((user.lockedUntil - new Date()) / 60000);

    // Ghi login history
    await recordLoginHistory(user.id, ipAddress, userAgent, deviceName, false, `Account locked (${remainingMinutes}min remaining)`);

    throw Object.assign(
      new Error(`Account is locked. Try again in ${remainingMinutes} minute(s).`),
      { statusCode: 423 }
    );
  }

  // 3. Verify password
  const isValidPassword = await verifyPassword(password, user.passwordHash);

  if (!isValidPassword) {
    // Tăng failed attempts
    const newAttempts = user.failedLoginAttempts + 1;
    const updateData = { failedLoginAttempts: newAttempts };

    // Khóa tài khoản nếu sai quá nhiều lần
    if (newAttempts >= config.security.maxFailedAttempts) {
      updateData.lockedUntil = new Date(Date.now() + config.security.lockoutDurationMinutes * 60 * 1000);

      // Tạo security alert
      await prisma.securityAlert.create({
        data: {
          userId: user.id,
          type: 'ACCOUNT_LOCKED',
          message: `Account locked after ${newAttempts} failed login attempts from ${deviceName} (${ipAddress})`,
          severity: 'HIGH',
        },
      });
    }

    await prisma.user.update({
      where: { id: user.id },
      data: updateData,
    });

    // Ghi login history
    await recordLoginHistory(user.id, ipAddress, userAgent, deviceName, false, 'Invalid password');

    const remaining = config.security.maxFailedAttempts - newAttempts;
    const lockMsg = remaining > 0
      ? ` ${remaining} attempt(s) remaining before account lockout.`
      : ' Account has been locked.';

    throw Object.assign(
      new Error(`Invalid email, phone number, or password.${lockMsg}`),
      { statusCode: 401 }
    );
  }

  // 4. Password đúng → kiểm tra verify chưa
  if (user.email && !user.emailVerified) {
    throw Object.assign(
      new Error('Please verify your email before logging in'),
      { statusCode: 403, requireEmailVerification: true, email: user.email }
    );
  }

  if (!user.email && user.phoneNumber && !user.phoneVerified) {
    throw Object.assign(
      new Error('Please verify your phone number before logging in'),
      { statusCode: 403, requirePhoneVerification: true, phoneNumber: user.phoneNumber }
    );
  }

  // 5. Kiểm tra 2FA
  if (user.twoFactorEnabled) {
    // Tạo OTP và gửi
    const otpCode = generateVerificationCode();
    const otpHash = hashSHA256(otpCode);
    const otpExpiresAt = new Date(Date.now() + config.security.otpExpiryMinutes * 60 * 1000);

    // Vô hiệu hóa OTP cũ chưa dùng
    await prisma.verificationCode.updateMany({
      where: {
        userId: user.id,
        type: 'OTP_LOGIN',
        used: false,
      },
      data: { used: true },
    });

    // Tạo OTP mới
    await prisma.verificationCode.create({
      data: {
        userId: user.id,
        codeHash: otpHash,
        type: 'OTP_LOGIN',
        expiresAt: otpExpiresAt,
      },
    });

    // Gửi OTP qua email hoặc SMS giả lập
    if (user.email) {
      console.log(`\n🔐 OTP CODE for ${user.email}: ${otpCode}\n`);
      await emailService.sendOtpEmail(user.email, user.name, otpCode);
    } else {
      console.log(`\n🔐 SMS OTP CODE for ${user.phoneNumber}: ${otpCode}\n`);
    }

    return {
      requireOtp: true,
      email: user.email || user.phoneNumber, // Trả về email/phone để client dùng gửi verifyOtp
      message: user.email 
        ? 'OTP has been sent to your email'
        : 'OTP has been sent to your phone number via SMS',
    };
  }

  // 6. Không có 2FA → cấp token
  return await completeLogin(user, ipAddress, userAgent, deviceName);
}

// ===================== VERIFY EMAIL =====================

/**
 * Xác minh email bằng code 6 số
 */
async function verifyEmail({ email, code }) {
  // 1. Tìm user
  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  if (user.emailVerified) {
    throw Object.assign(new Error('Email is already verified'), { statusCode: 400 });
  }

  // 2. Tìm verification code chưa dùng, chưa hết hạn
  const codeHash = hashSHA256(code);
  const verificationCode = await prisma.verificationCode.findFirst({
    where: {
      userId: user.id,
      type: 'EMAIL_VERIFY',
      used: false,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!verificationCode) {
    throw Object.assign(new Error('Invalid or expired verification code'), { statusCode: 400 });
  }

  // 3. Kiểm tra số lần nhập sai
  if (verificationCode.attempts >= 5) {
    throw Object.assign(new Error('Too many failed attempts. Please request a new code.'), { statusCode: 429 });
  }

  // 4. Verify code
  if (verificationCode.codeHash !== codeHash) {
    // Tăng attempts
    await prisma.verificationCode.update({
      where: { id: verificationCode.id },
      data: { attempts: { increment: 1 } },
    });

    throw Object.assign(new Error('Invalid verification code'), { statusCode: 400 });
  }

  // 5. Code đúng → đánh dấu đã dùng + verify email
  await prisma.$transaction([
    prisma.verificationCode.update({
      where: { id: verificationCode.id },
      data: { used: true },
    }),
    prisma.user.update({
      where: { id: user.id },
      data: { emailVerified: true },
    }),
  ]);

  return { message: 'Email verified successfully' };
}

// ===================== RESEND EMAIL CODE =====================

/**
 * Gửi lại mã xác minh email
 * Có cooldown chống spam
 */
async function resendEmailCode({ email }) {
  const user = await prisma.user.findUnique({
    where: { email },
  });

  if (!user) {
    // Không tiết lộ email có tồn tại không (bảo mật)
    return { message: 'If the email exists, a new code has been sent' };
  }

  if (user.emailVerified) {
    throw Object.assign(new Error('Email is already verified'), { statusCode: 400 });
  }

  // Kiểm tra cooldown: code gần nhất phải cách ít nhất X giây
  const lastCode = await prisma.verificationCode.findFirst({
    where: {
      userId: user.id,
      type: 'EMAIL_VERIFY',
    },
    orderBy: { createdAt: 'desc' },
  });

  if (lastCode) {
    const timeSinceLastCode = (Date.now() - lastCode.createdAt.getTime()) / 1000;
    if (timeSinceLastCode < config.security.resendCooldownSeconds) {
      const remaining = Math.ceil(config.security.resendCooldownSeconds - timeSinceLastCode);
      throw Object.assign(
        new Error(`Please wait ${remaining} seconds before requesting a new code`),
        { statusCode: 429 }
      );
    }
  }

  // Vô hiệu hóa code cũ
  await prisma.verificationCode.updateMany({
    where: {
      userId: user.id,
      type: 'EMAIL_VERIFY',
      used: false,
    },
    data: { used: true },
  });

  // Tạo code mới
  const code = generateVerificationCode();
  const codeHash = hashSHA256(code);
  const expiresAt = new Date(Date.now() + config.security.emailCodeExpiryMinutes * 60 * 1000);

  await prisma.verificationCode.create({
    data: {
      userId: user.id,
      codeHash,
      type: 'EMAIL_VERIFY',
      expiresAt,
    },
  });

  console.log(`\n🔑 NEW VERIFICATION CODE for ${email}: ${code}\n`);
  await emailService.sendVerificationEmail(email, user.name, code);

  return { message: 'A new verification code has been sent to your email' };
}

// ===================== VERIFY OTP =====================

/**
 * Xác minh OTP 2FA để hoàn tất đăng nhập
 */
async function verifyOtp({ email, code }, req) {
  const ipAddress = getClientIP(req);
  const userAgent = req.headers['user-agent'] || 'Unknown';
  const deviceName = parseDeviceName(userAgent);

  // Chấp nhận email làm identifier (email hoặc phone) để tương thích ngược
  const identifier = email;
  const isEmail = identifier.includes('@');
  let user;

  if (isEmail) {
    user = await prisma.user.findUnique({
      where: { email: identifier.toLowerCase().trim() },
    });
  } else {
    user = await prisma.user.findUnique({
      where: { phoneNumber: normalizePhoneNumber(identifier) },
    });
  }

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  // Tìm OTP chưa dùng, chưa hết hạn
  const otpCode = await prisma.verificationCode.findFirst({
    where: {
      userId: user.id,
      type: 'OTP_LOGIN',
      used: false,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!otpCode) {
    throw Object.assign(new Error('OTP expired or not found. Please login again.'), { statusCode: 400 });
  }

  // Kiểm tra số lần nhập sai (max 5)
  if (otpCode.attempts >= 5) {
    await prisma.verificationCode.update({
      where: { id: otpCode.id },
      data: { used: true },
    });

    // Tạo security alert
    await prisma.securityAlert.create({
      data: {
        userId: user.id,
        type: 'OTP_BRUTE_FORCE',
        message: `Too many failed OTP attempts from ${deviceName} (${ipAddress})`,
        severity: 'HIGH',
      },
    });

    throw Object.assign(
      new Error('Too many failed OTP attempts. Please login again.'),
      { statusCode: 429 }
    );
  }

  // Verify OTP
  const codeHash = hashSHA256(code);
  if (otpCode.codeHash !== codeHash) {
    await prisma.verificationCode.update({
      where: { id: otpCode.id },
      data: { attempts: { increment: 1 } },
    });

    const remaining = 5 - (otpCode.attempts + 1);
    throw Object.assign(
      new Error(`Invalid OTP. ${remaining} attempt(s) remaining.`),
      { statusCode: 400 }
    );
  }

  // OTP đúng → đánh dấu đã dùng
  await prisma.verificationCode.update({
    where: { id: otpCode.id },
    data: { used: true },
  });

  // Cấp token
  return await completeLogin(user, ipAddress, userAgent, deviceName);
}

// ===================== VERIFY PHONE =====================

async function verifyPhone({ phoneNumber, code }) {
  const normalizedPhone = normalizePhoneNumber(phoneNumber);

  const user = await prisma.user.findUnique({
    where: { phoneNumber: normalizedPhone },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  if (user.phoneVerified) {
    throw Object.assign(new Error('Phone number is already verified'), { statusCode: 400 });
  }

  const codeHash = hashSHA256(code);
  const verificationCode = await prisma.verificationCode.findFirst({
    where: {
      userId: user.id,
      type: 'PHONE_VERIFY',
      used: false,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
  });

  if (!verificationCode) {
    throw Object.assign(new Error('Invalid or expired verification code'), { statusCode: 400 });
  }

  if (verificationCode.attempts >= 5) {
    throw Object.assign(new Error('Too many failed attempts. Please request a new code.'), { statusCode: 429 });
  }

  if (verificationCode.codeHash !== codeHash) {
    await prisma.verificationCode.update({
      where: { id: verificationCode.id },
      data: { attempts: { increment: 1 } },
    });

    throw Object.assign(new Error('Invalid verification code'), { statusCode: 400 });
  }

  await prisma.$transaction([
    prisma.verificationCode.update({
      where: { id: verificationCode.id },
      data: { used: true },
    }),
    prisma.user.update({
      where: { id: user.id },
      data: { phoneVerified: true },
    }),
  ]);

  return { message: 'Phone number verified successfully' };
}

// ===================== RESEND PHONE CODE =====================

async function resendPhoneCode({ phoneNumber }) {
  const normalizedPhone = normalizePhoneNumber(phoneNumber);

  const user = await prisma.user.findUnique({
    where: { phoneNumber: normalizedPhone },
  });

  if (!user) {
    return { message: 'If the phone number exists, a new code has been sent' };
  }

  if (user.phoneVerified) {
    throw Object.assign(new Error('Phone number is already verified'), { statusCode: 400 });
  }

  const lastCode = await prisma.verificationCode.findFirst({
    where: {
      userId: user.id,
      type: 'PHONE_VERIFY',
    },
    orderBy: { createdAt: 'desc' },
  });

  if (lastCode) {
    const timeSinceLastCode = (Date.now() - lastCode.createdAt.getTime()) / 1000;
    if (timeSinceLastCode < config.security.resendCooldownSeconds) {
      const remaining = Math.ceil(config.security.resendCooldownSeconds - timeSinceLastCode);
      throw Object.assign(
        new Error(`Please wait ${remaining} seconds before requesting a new code`),
        { statusCode: 429 }
      );
    }
  }

  await prisma.verificationCode.updateMany({
    where: {
      userId: user.id,
      type: 'PHONE_VERIFY',
      used: false,
    },
    data: { used: true },
  });

  const code = generateVerificationCode();
  const codeHash = hashSHA256(code);
  const expiresAt = new Date(Date.now() + config.security.emailCodeExpiryMinutes * 60 * 1000);

  await prisma.verificationCode.create({
    data: {
      userId: user.id,
      codeHash,
      type: 'PHONE_VERIFY',
      expiresAt,
    },
  });

  console.log(`\n🔑 NEW PHONE VERIFICATION CODE for ${normalizedPhone}: ${code}\n`);

  return { message: 'A new verification code has been sent to your phone number' };
}

// ===================== REFRESH TOKEN =====================

/**
 * Làm mới access token bằng refresh token
 */
async function refreshToken({ refreshToken }) {
  // Verify refresh token
  const storedToken = await tokenService.verifyRefreshToken(refreshToken);

  if (!storedToken) {
    throw Object.assign(new Error('Invalid or expired refresh token'), { statusCode: 401 });
  }

  // Revoke refresh token cũ (rotation)
  await tokenService.revokeRefreshToken(refreshToken);

  // Tạo token mới
  const user = storedToken.user;
  const accessToken = tokenService.generateAccessToken(user);
  const newRefreshToken = await tokenService.createRefreshToken(user.id);

  return {
    accessToken,
    refreshToken: newRefreshToken,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
    },
  };
}

// ===================== LOGOUT =====================

/**
 * Đăng xuất - revoke refresh token
 */
async function logout({ refreshToken }) {
  await tokenService.revokeRefreshToken(refreshToken);
  return { message: 'Logged out successfully' };
}

// ===================== HELPER FUNCTIONS =====================

/**
 * Hoàn tất login: reset failed attempts, ghi history, kiểm tra thiết bị lạ, cấp token
 */
async function completeLogin(user, ipAddress, userAgent, deviceName) {
  // Reset failed attempts + cập nhật lastLoginAt
  await prisma.user.update({
    where: { id: user.id },
    data: {
      failedLoginAttempts: 0,
      lockedUntil: null,
      lastLoginAt: new Date(),
    },
  });

  // Kiểm tra thiết bị lạ
  const isSuspicious = await checkSuspiciousDevice(user.id, deviceName, ipAddress);

  // Ghi login history
  await recordLoginHistory(user.id, ipAddress, userAgent, deviceName, true, null, isSuspicious);

  // Nếu thiết bị lạ → gửi email cảnh báo
  if (isSuspicious) {
    await prisma.securityAlert.create({
      data: {
        userId: user.id,
        type: 'SUSPICIOUS_LOGIN',
        message: `New login from unrecognized device: ${deviceName} (${ipAddress})`,
        severity: 'MEDIUM',
      },
    });

    await emailService.sendSuspiciousLoginAlert(user.email, user.name, deviceName, ipAddress);
  }

  // Cấp tokens
  const accessToken = tokenService.generateAccessToken(user);
  const newRefreshToken = await tokenService.createRefreshToken(user.id);

  return {
    accessToken,
    refreshToken: newRefreshToken,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      role: user.role,
      emailVerified: user.emailVerified,
      twoFactorEnabled: user.twoFactorEnabled,
    },
  };
}

/**
 * Ghi lịch sử đăng nhập
 */
async function recordLoginHistory(userId, ipAddress, userAgent, deviceName, success, reason = null, suspicious = false) {
  await prisma.loginHistory.create({
    data: {
      userId,
      ipAddress,
      userAgent,
      deviceName,
      success,
      reason,
      suspicious,
    },
  });
}

/**
 * Kiểm tra thiết bị lạ
 * So sánh deviceName với các thiết bị đã đăng nhập thành công trước đó
 */
async function checkSuspiciousDevice(userId, deviceName, ipAddress) {
  // Lấy danh sách thiết bị đã login thành công
  const knownDevices = await prisma.loginHistory.findMany({
    where: {
      userId,
      success: true,
    },
    distinct: ['deviceName'],
    select: { deviceName: true },
  });

  // Nếu chưa có login history nào → không suspicious (lần đầu)
  if (knownDevices.length === 0) {
    return false;
  }

  // Kiểm tra deviceName có trong danh sách known devices không
  const isKnown = knownDevices.some(d => d.deviceName === deviceName);

  return !isKnown;
}

module.exports = {
  register,
  login,
  verifyEmail,
  resendEmailCode,
  verifyOtp,
  verifyPhone,
  resendPhoneCode,
  refreshToken,
  logout,
};
