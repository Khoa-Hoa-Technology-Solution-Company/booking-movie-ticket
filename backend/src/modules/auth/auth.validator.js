// ============================================
// Auth Validator
// Validate input bằng Zod cho tất cả auth endpoints
// ============================================
const { z } = require('zod');
const { isValidVietnamesePhoneNumber } = require('../../utils/helpers');

// --- Register ---
const registerSchema = z.object({
  name: z
    .string()
    .min(2, 'Name must be at least 2 characters')
    .max(100, 'Name must be at most 100 characters')
    .trim(),
  email: z
    .string()
    .email('Invalid email address')
    .max(255)
    .toLowerCase()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  phoneNumber: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  confirmPassword: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  password: z
    .string()
    .min(8, 'Password must be at least 8 characters')
    .max(100, 'Password must be at most 100 characters')
    .regex(/[A-Z]/, 'Password must contain at least one uppercase letter')
    .regex(/[a-z]/, 'Password must contain at least one lowercase letter')
    .regex(/[0-9]/, 'Password must contain at least one number')
    .regex(/[^A-Za-z0-9]/, 'Password must contain at least one special character'),
}).refine((data) => {
  const hasEmail = data.email && data.email.trim() !== '';
  const hasPhone = data.phoneNumber && data.phoneNumber.trim() !== '';
  return hasEmail || hasPhone;
}, {
  message: 'Either email or phone number is required',
  path: ['email'],
}).refine((data) => {
  const hasPhone = data.phoneNumber && data.phoneNumber.trim() !== '';
  if (hasPhone) {
    return isValidVietnamesePhoneNumber(data.phoneNumber);
  }
  return true;
}, {
  message: 'Invalid Vietnamese phone number format',
  path: ['phoneNumber'],
}).refine((data) => {
  // If confirmPassword is provided, it must match password
  const cp = data.confirmPassword;
  if (cp && cp.trim() !== '') {
    return data.password === cp;
  }
  return true;
}, {
  message: 'Confirm password does not match password',
  path: ['confirmPassword'],
});

// --- Login ---
const loginSchema = z.object({
  identifier: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  email: z
    .string()
    .email('Invalid email address')
    .max(255)
    .toLowerCase()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  password: z
    .string()
    .min(1, 'Password is required'),
  deviceName: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
}).refine((data) => {
  const hasIdentifier = data.identifier && data.identifier.trim() !== '';
  const hasEmail = data.email && data.email.trim() !== '';
  return hasIdentifier || hasEmail;
}, {
  message: 'Identifier is required',
  path: ['identifier'],
});

// --- Verify Phone ---
const verifyPhoneSchema = z.object({
  phoneNumber: z
    .string()
    .min(1, 'Phone number is required')
    .trim(),
  code: z
    .string()
    .length(6, 'Verification code must be 6 digits')
    .regex(/^\d{6}$/, 'Verification code must be 6 digits'),
});

// --- Resend Phone Code ---
const resendPhoneCodeSchema = z.object({
  phoneNumber: z
    .string()
    .min(1, 'Phone number is required')
    .trim(),
});

// --- Verify Email ---
const verifyEmailSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
  code: z
    .string()
    .length(6, 'Verification code must be 6 digits')
    .regex(/^\d{6}$/, 'Verification code must be 6 digits'),
});

// --- Verify OTP ---
// Accept either `identifier` (email or phone) OR `email` explicitly. One is required.
const verifyOtpSchema = z.object({
  identifier: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  email: z
    .string()
    .email('Invalid email address')
    .max(255)
    .toLowerCase()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
  code: z
    .string()
    .length(6, 'OTP must be 6 digits')
    .regex(/^\d{6}$/, 'OTP must be 6 digits'),
  deviceName: z
    .string()
    .trim()
    .optional()
    .or(z.literal(''))
    .or(z.null()),
}).refine((data) => {
  const hasIdentifier = data.identifier && data.identifier.trim() !== '';
  const hasEmail = data.email && data.email.trim() !== '';
  return hasIdentifier || hasEmail;
}, {
  message: 'Identifier or email is required',
  path: ['identifier'],
});

// --- Resend Email Code ---
const resendEmailCodeSchema = z.object({
  email: z
    .string()
    .email('Invalid email address')
    .toLowerCase()
    .trim(),
});

// --- Refresh Token ---
const refreshTokenSchema = z.object({
  refreshToken: z
    .string()
    .min(1, 'Refresh token is required'),
});

// --- Logout ---
const logoutSchema = z.object({
  refreshToken: z
    .string()
    .min(1, 'Refresh token is required'),
});

/**
 * Middleware factory: validate request body bằng Zod schema
 * Nếu invalid → trả lỗi 400 với chi tiết
 */
function validate(schema) {
  return (req, res, next) => {
    try {
      // Parse và sanitize input
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: error.errors.map(e => ({
          field: e.path.join('.'),
          message: e.message,
        })),
      });
    }
  };
}

module.exports = {
  registerSchema,
  loginSchema,
  verifyEmailSchema,
  verifyOtpSchema,
  resendEmailCodeSchema,
  verifyPhoneSchema,
  resendPhoneCodeSchema,
  refreshTokenSchema,
  logoutSchema,
  validate,
};
