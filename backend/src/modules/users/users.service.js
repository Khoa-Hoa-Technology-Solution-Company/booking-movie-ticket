// ============================================
// Users Service
// ============================================
const prisma = require('../../config/database');
const { verifyPassword, hashPassword } = require('../../utils/crypto');
const { isStrongPassword } = require('../../utils/helpers');

function toProfileResponse(user) {
  return {
    id: user.id,
    name: user.name,
    email: user.email,
    phoneNumber: user.phoneNumber,
    role: user.role,
    emailVerified: user.emailVerified,
    phoneVerified: user.phoneVerified,
    twoFactorEnabled: user.twoFactorEnabled,
    lastLoginAt: user.lastLoginAt,
    createdAt: user.createdAt,
    updatedAt: user.updatedAt,
  };
}

async function getProfile(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      phoneNumber: true,
      role: true,
      emailVerified: true,
      phoneVerified: true,
      twoFactorEnabled: true,
      lastLoginAt: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  return { user: toProfileResponse(user) };
}

async function updateProfile(userId, { name }) {
  const updatedUser = await prisma.user.update({
    where: { id: userId },
    data: {
      name: name.trim(),
    },
    select: {
      id: true,
      name: true,
      email: true,
      phoneNumber: true,
      role: true,
      emailVerified: true,
      phoneVerified: true,
      twoFactorEnabled: true,
      lastLoginAt: true,
      createdAt: true,
      updatedAt: true,
    },
  });

  return {
    message: 'Profile updated successfully',
    user: toProfileResponse(updatedUser),
  };
}

async function changePassword(userId, { currentPassword, newPassword }) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      passwordHash: true,
      role: true,
    },
  });

  if (!user) {
    throw Object.assign(new Error('User not found'), { statusCode: 404 });
  }

  const isValidCurrentPassword = await verifyPassword(currentPassword, user.passwordHash);
  if (!isValidCurrentPassword) {
    throw Object.assign(new Error('Current password is incorrect'), { statusCode: 400 });
  }

  if (!isStrongPassword(newPassword) || !/[^A-Za-z0-9]/.test(newPassword)) {
    throw Object.assign(new Error('New password is too weak'), { statusCode: 400 });
  }

  const newPasswordHash = await hashPassword(newPassword);

  await prisma.$transaction([
    prisma.user.update({
      where: { id: userId },
      data: {
        passwordHash: newPasswordHash,
        failedLoginAttempts: 0,
        lockedUntil: null,
      },
    }),
    prisma.refreshToken.updateMany({
      where: { userId },
      data: { revoked: true },
    }),
    prisma.securityAlert.create({
      data: {
        userId,
        type: 'PASSWORD_CHANGED',
        message: 'Your password has been changed successfully',
        severity: 'HIGH',
      },
    }),
  ]);

  return { message: 'Password changed successfully. Please sign in again on other devices.' };
}

module.exports = {
  getProfile,
  updateProfile,
  changePassword,
};