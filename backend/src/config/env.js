// ============================================
// Environment Configuration
// Validate biến môi trường bằng Zod
// ============================================
const { z } = require('zod');
require('dotenv').config();

// Schema validate cho environment variables
const envSchema = z.object({
  PORT: z.string().default('5000'),
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Database
  DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),

  // JWT
  JWT_ACCESS_SECRET: z.string().min(10, 'JWT_ACCESS_SECRET too short'),
  JWT_REFRESH_SECRET: z.string().min(10, 'JWT_REFRESH_SECRET too short'),
  JWT_ACCESS_EXPIRES_IN: z.string().default('15m'),
  JWT_REFRESH_EXPIRES_IN: z.string().default('7d'),

  // Email (optional - nếu không có sẽ log ra console)
  SMTP_HOST: z.string().default('smtp.gmail.com'),
  SMTP_PORT: z.string().default('587'),
  SMTP_USER: z.string().default(''),
  SMTP_PASS: z.string().default(''),
  SMTP_FROM: z.string().default('Account Security <noreply@example.com>'),

  // Security
  MAX_FAILED_ATTEMPTS: z.string().default('5'),
  LOCKOUT_DURATION_MINUTES: z.string().default('5'),
  EMAIL_CODE_EXPIRY_MINUTES: z.string().default('10'),
  OTP_EXPIRY_MINUTES: z.string().default('5'),
  RESEND_COOLDOWN_SECONDS: z.string().default('60'),
  
  // Firebase
  FIREBASE_PROJECT_ID: z.string().default('booking-movie-ticket-4ff5d'),
});

// Parse và validate
const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:');
  console.error(parsed.error.format());
  process.exit(1);
}

const env = parsed.data;

module.exports = {
  port: parseInt(env.PORT),
  nodeEnv: env.NODE_ENV,
  isDev: env.NODE_ENV === 'development',

  database: {
    url: env.DATABASE_URL,
  },

  jwt: {
    accessSecret: env.JWT_ACCESS_SECRET,
    refreshSecret: env.JWT_REFRESH_SECRET,
    accessExpiresIn: env.JWT_ACCESS_EXPIRES_IN,
    refreshExpiresIn: env.JWT_REFRESH_EXPIRES_IN,
  },

  email: {
    host: env.SMTP_HOST,
    port: parseInt(env.SMTP_PORT),
    user: env.SMTP_USER,
    pass: env.SMTP_PASS,
    from: env.SMTP_FROM,
    // Nếu SMTP_USER rỗng → chưa config email → log ra console
    enabled: env.SMTP_USER.length > 0 && env.SMTP_PASS.length > 0,
  },

  security: {
    maxFailedAttempts: parseInt(env.MAX_FAILED_ATTEMPTS),
    lockoutDurationMinutes: parseInt(env.LOCKOUT_DURATION_MINUTES),
    emailCodeExpiryMinutes: parseInt(env.EMAIL_CODE_EXPIRY_MINUTES),
    otpExpiryMinutes: parseInt(env.OTP_EXPIRY_MINUTES),
    resendCooldownSeconds: parseInt(env.RESEND_COOLDOWN_SECONDS),
  },
  firebase: {
    projectId: env.FIREBASE_PROJECT_ID,
  },
};
