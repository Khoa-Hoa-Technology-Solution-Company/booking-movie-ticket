// ============================================
// Email Service
// Gửi email verification, OTP, security alerts
// Nếu chưa config SMTP → log ra console
// ============================================
const transporter = require('../config/email');
const config = require('../config/env');

/**
 * Gửi email (hoặc log ra console nếu chưa config SMTP)
 * @param {string} to - Email người nhận
 * @param {string} subject - Tiêu đề
 * @param {string} html - Nội dung HTML
 */
async function sendEmail(to, subject, html) {
  if (!config.email.enabled) {
    // Chưa config SMTP → log ra console để test
    console.log('\n' + '='.repeat(50));
    console.log('📧 EMAIL (Console Mode)');
    console.log(`   To: ${to}`);
    console.log(`   Subject: ${subject}`);
    console.log(`   Content: ${html.replace(/<[^>]*>/g, '')}`);
    console.log('='.repeat(50) + '\n');
    return;
  }

  // Gửi email thật qua SMTP
  await transporter.sendMail({
    from: config.email.from,
    to,
    subject,
    html,
  });

  console.log(`📧 Email sent to: ${to}`);
}

/**
 * Gửi mã xác minh email sau khi đăng ký
 */
async function sendVerificationEmail(to, name, code) {
  const subject = '🎬 Movie App - Verify Your Email';
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
      <h2 style="color: #6C63FF;">🎬 Movie Ticket Booking</h2>
      <p>Hi <strong>${name}</strong>,</p>
      <p>Welcome! Please verify your email with this code:</p>
      <div style="background: #f4f4f4; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #6C63FF;">${code}</span>
      </div>
      <p style="color: #888;">This code expires in 10 minutes.</p>
      <p style="color: #888;">If you didn't create an account, please ignore this email.</p>
    </div>
  `;

  await sendEmail(to, subject, html);
}

/**
 * Gửi OTP cho 2FA login
 */
async function sendOtpEmail(to, name, code) {
  const subject = '🔐 Movie App - Login OTP';
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
      <h2 style="color: #6C63FF;">🔐 Two-Factor Authentication</h2>
      <p>Hi <strong>${name}</strong>,</p>
      <p>Your login OTP code is:</p>
      <div style="background: #f4f4f4; padding: 20px; text-align: center; border-radius: 8px; margin: 20px 0;">
        <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #FF6B6B;">${code}</span>
      </div>
      <p style="color: #888;">This code expires in 5 minutes.</p>
      <p style="color: #888;">If you didn't attempt to login, please change your password immediately.</p>
    </div>
  `;

  await sendEmail(to, subject, html);
}

/**
 * Gửi cảnh báo đăng nhập từ thiết bị lạ
 */
async function sendSuspiciousLoginAlert(to, name, deviceName, ipAddress) {
  const subject = '⚠️ Movie App - Suspicious Login Detected';
  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto;">
      <h2 style="color: #FF6B6B;">⚠️ Security Alert</h2>
      <p>Hi <strong>${name}</strong>,</p>
      <p>A new login was detected from an unrecognized device:</p>
      <div style="background: #fff3f3; padding: 15px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #FF6B6B;">
        <p><strong>Device:</strong> ${deviceName}</p>
        <p><strong>IP Address:</strong> ${ipAddress}</p>
        <p><strong>Time:</strong> ${new Date().toLocaleString()}</p>
      </div>
      <p>If this wasn't you, please change your password and enable 2FA immediately.</p>
    </div>
  `;

  await sendEmail(to, subject, html);
}

module.exports = {
  sendEmail,
  sendVerificationEmail,
  sendOtpEmail,
  sendSuspiciousLoginAlert,
};
