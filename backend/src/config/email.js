// ============================================
// Nodemailer Email Configuration
// Nếu chưa config SMTP → log ra console để test
// ============================================
const nodemailer = require('nodemailer');
const config = require('./env');

let transporter = null;

if (config.email.enabled) {
  // Dùng Gmail SMTP thật
  transporter = nodemailer.createTransport({
    host: config.email.host,
    port: config.email.port,
    secure: false, // true cho port 465, false cho port 587
    auth: {
      user: config.email.user,
      pass: config.email.pass,
    },
  });

  console.log('📧 Email transporter configured (Gmail SMTP)');
} else {
  console.log('📧 Email not configured - codes will be logged to console');
}

module.exports = transporter;
