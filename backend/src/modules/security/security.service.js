// ============================================
// Security Service
// Dashboard, issues, login history, alerts, 2FA toggle
// ============================================
const prisma = require('../../config/database');
const { isStrongPassword } = require('../../utils/helpers');

/**
 * Lấy dữ liệu Security Dashboard
 * Trả về overview bảo mật cho user
 */
async function getDashboard(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      phoneNumber: true,
      emailVerified: true,
      phoneVerified: true,
      twoFactorEnabled: true,
      role: true,
      failedLoginAttempts: true,
      lockedUntil: true,
      lastLoginAt: true,
      createdAt: true,
    },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  // Đếm unread alerts
  const unreadAlerts = await prisma.securityAlert.count({
    where: { userId, read: false },
  });

  // Đếm login suspicious
  const suspiciousLogins = await prisma.loginHistory.count({
    where: { userId, suspicious: true },
  });

  // Lấy 5 login gần nhất
  const recentLogins = await prisma.loginHistory.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 5,
    select: {
      id: true,
      email: true,
      ipAddress: true,
      deviceName: true,
      success: true,
      suspicious: true,
      createdAt: true,
    },
  });

  // Tính Security Score
  const { score, issues } = calculateSecurityScore(user, suspiciousLogins);

  const recentAlerts = await prisma.securityAlert.findMany({
    where: { userId },
    orderBy: { createdAt: 'desc' },
    take: 5,
    select: {
      id: true,
      type: true,
      message: true,
      severity: true,
      read: true,
      createdAt: true,
    },
  });

  return {
    hasEmail: !!user.email,
    hasPhoneNumber: !!user.phoneNumber,
    accountVerified: !!user.emailVerified || !!user.phoneVerified,
    emailVerified: user.emailVerified,
    phoneVerified: user.phoneVerified,
    twoFactorEnabled: user.twoFactorEnabled,
    lastLoginAt: user.lastLoginAt,
    failedLoginAttempts: user.failedLoginAttempts,
    accountLocked: user.lockedUntil ? user.lockedUntil > new Date() : false,
    securityScore: score,
    recentAlerts,
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role,
      createdAt: user.createdAt,
    },
    security: {
      emailVerified: user.emailVerified,
      phoneVerified: user.phoneVerified,
      hasEmail: !!user.email,
      hasPhoneNumber: !!user.phoneNumber,
      twoFactorEnabled: user.twoFactorEnabled,
      lastLogin: user.lastLoginAt,
      failedLoginAttempts: user.failedLoginAttempts,
      accountLocked: user.lockedUntil ? user.lockedUntil > new Date() : false,
      lockedUntil: user.lockedUntil,
      securityScore: score,
      unreadAlerts,
      suspiciousLogins,
    },
    securityIssues: issues,
    recentLogins,
  };
}

/**
 * Tính Security Score (0-100)
 * Bắt đầu từ 100, trừ điểm theo từng vấn đề
 */
function calculateSecurityScore(user, suspiciousLogins) {
  let score = 100;
  const issues = [];

  // Email chưa xác minh: -30 điểm (nếu có email)
  if (user.email && !user.emailVerified) {
    score -= 30;
    issues.push({
      type: 'EMAIL_NOT_VERIFIED',
      title: 'Email not verified',
      description: 'Verify your email to secure your account',
      severity: 'HIGH',
      impact: -30,
    });
  }

  // Số điện thoại chưa xác minh: -25 điểm (nếu có phone)
  if (user.phoneNumber && !user.phoneVerified) {
    score -= 25;
    issues.push({
      type: 'PHONE_NOT_VERIFIED',
      title: 'Phone number not verified',
      description: 'Verify your phone number to secure your account',
      severity: 'HIGH',
      impact: -25,
    });
  }

  // Chưa thêm số điện thoại: -15 điểm
  if (!user.phoneNumber) {
    score -= 15;
    issues.push({
      type: 'NO_PHONE_NUMBER',
      title: 'Phone number missing',
      description: 'Add a phone number for fallback security option',
      severity: 'MEDIUM',
      impact: -15,
    });
  }

  // Chưa bật 2FA: -20 điểm
  if (!user.twoFactorEnabled) {
    score -= 20;
    issues.push({
      type: 'TWO_FACTOR_DISABLED',
      title: 'Two-factor authentication disabled',
      description: 'Enable 2FA for an extra layer of security',
      severity: 'MEDIUM',
      impact: -20,
    });
  }

  // Nhiều lần đăng nhập thất bại (>3): -15 điểm
  if (user.failedLoginAttempts > 3) {
    score -= 15;
    issues.push({
      type: 'MULTIPLE_FAILED_LOGINS',
      title: 'Multiple failed login attempts',
      description: `${user.failedLoginAttempts} failed login attempts detected`,
      severity: 'HIGH',
      impact: -15,
    });
  }

  // Có đăng nhập từ thiết bị lạ: -15 điểm
  if (suspiciousLogins > 0) {
    score -= 15;
    issues.push({
      type: 'SUSPICIOUS_LOGINS',
      title: 'Suspicious login detected',
      description: `${suspiciousLogins} login(s) from unrecognized devices`,
      severity: 'MEDIUM',
      impact: -15,
    });
  }

  // Tài khoản đang bị khóa: -20 điểm
  if (user.lockedUntil && user.lockedUntil > new Date()) {
    score -= 20;
    issues.push({
      type: 'ACCOUNT_LOCKED',
      title: 'Account is currently locked',
      description: 'Your account has been temporarily locked due to security concerns',
      severity: 'CRITICAL',
      impact: -20,
    });
  }

  // Đảm bảo score không âm
  score = Math.max(0, score);

  return { score, issues };
}

/**
 * Lấy danh sách security issues
 */
async function getSecurityIssues(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  const suspiciousLogins = await prisma.loginHistory.count({
    where: { userId, suspicious: true },
  });

  const { issues } = calculateSecurityScore(user, suspiciousLogins);

  return issues;
}

/**
 * Lấy lịch sử đăng nhập
 */
async function getLoginHistory(userId, page = 1, limit = 20) {
  const skip = (page - 1) * limit;

  const [history, total] = await Promise.all([
    prisma.loginHistory.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
      select: {
        id: true,
        email: true,
        ipAddress: true,
        userAgent: true,
        deviceName: true,
        success: true,
        reason: true,
        suspicious: true,
        createdAt: true,
      },
    }),
    prisma.loginHistory.count({ where: { userId } }),
  ]);

  return {
    history,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

/**
 * Lấy security alerts
 */
async function getSecurityAlerts(userId, page = 1, limit = 20) {
  const skip = (page - 1) * limit;

  const [alerts, total] = await Promise.all([
    prisma.securityAlert.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      skip,
      take: limit,
      select: {
        id: true,
        type: true,
        message: true,
        severity: true,
        read: true,
        createdAt: true,
      },
    }),
    prisma.securityAlert.count({ where: { userId } }),
  ]);

  return {
    alerts,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
    },
  };
}

/**
 * Bật/tắt 2FA
 */
async function toggle2FA(userId, enabled) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  // Yêu cầu email hoặc số điện thoại phải được verify trước khi bật 2FA
  if (!user.emailVerified && !user.phoneVerified && !user.twoFactorEnabled) {
    throw Object.assign(
      new Error('Please verify your email or phone number before enabling 2FA'),
      { statusCode: 400 }
    );
  }

  const newStatus = typeof enabled === 'boolean' ? enabled : !user.twoFactorEnabled;

  await prisma.user.update({
    where: { id: userId },
    data: { twoFactorEnabled: newStatus },
  });

  // Tạo security alert
  await prisma.securityAlert.create({
    data: {
      userId,
      type: newStatus ? 'TWO_FACTOR_ENABLED' : 'TWO_FACTOR_DISABLED',
      message: newStatus
        ? 'Two-factor authentication has been enabled'
        : 'Two-factor authentication has been disabled',
      severity: newStatus ? 'LOW' : 'MEDIUM',
    },
  });

  return {
    twoFactorEnabled: newStatus,
    message: newStatus
      ? '2FA has been enabled. You will need to enter OTP when logging in.'
      : '2FA has been disabled.',
  };
}

/**
 * Đánh dấu alert đã đọc
 */
async function markAlertAsRead(userId, alertId) {
  await prisma.securityAlert.updateMany({
    where: {
      id: alertId,
      userId,
    },
    data: { read: true },
  });

  return { message: 'Alert marked as read' };
}

module.exports = {
  getDashboard,
  getSecurityIssues,
  getLoginHistory,
  getSecurityAlerts,
  toggle2FA,
  markAlertAsRead,
};
