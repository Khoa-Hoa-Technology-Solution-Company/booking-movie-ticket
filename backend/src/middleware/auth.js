// ============================================
// Auth Middleware
// Xác thực Firebase ID Token và kiểm tra role
// ============================================
const jwt = require('jsonwebtoken');
const https = require('https');
const config = require('../config/env');
const prisma = require('../config/database');
const { errorResponse } = require('../utils/helpers');

let googlePublicKeys = {};
let cacheExpiry = 0;

/**
 * Fetch Google public keys for Firebase ID token verification
 */
async function getGooglePublicKeys() {
  if (Date.now() < cacheExpiry && Object.keys(googlePublicKeys).length > 0) {
    return googlePublicKeys;
  }

  return new Promise((resolve, reject) => {
    https.get('https://www.googleapis.com/robot/v1/metadata/x509/securetoken-system@system.gserviceaccount.com', (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const cacheControl = res.headers['cache-control'] || '';
          const maxAgeMatch = cacheControl.match(/max-age=(\d+)/);
          const maxAge = maxAgeMatch ? parseInt(maxAgeMatch[1], 10) : 3600;
          
          googlePublicKeys = JSON.parse(data);
          cacheExpiry = Date.now() + maxAge * 1000;
          resolve(googlePublicKeys);
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Middleware xác thực Firebase ID Token (Bearer Token)
 * Gắn user info từ MySQL tương ứng vào req.user
 */
async function authenticate(req, res, next) {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Access token is required', 401);
    }

    const token = authHeader.split(' ')[1];

    // Decode token to inspect the header's kid
    const decodedTokenHeader = jwt.decode(token, { complete: true });
    if (!decodedTokenHeader || !decodedTokenHeader.header || !decodedTokenHeader.header.kid) {
      return errorResponse(res, 'Invalid token format', 401);
    }

    const kid = decodedTokenHeader.header.kid;
    const publicKeys = await getGooglePublicKeys();
    const publicCert = publicKeys[kid];

    if (!publicCert) {
      return errorResponse(res, 'Invalid token signature key', 401);
    }

    const projectId = config.firebase.projectId;
    if (!projectId) {
      return errorResponse(res, 'Firebase Project ID is not configured on backend', 500);
    }

    // Verify signature, audience, and issuer
    const decoded = jwt.verify(token, publicCert, {
      audience: projectId,
      issuer: `https://securetoken.google.com/${projectId}`,
      algorithms: ['RS256'],
    });

    const email = decoded.email;
    const name = decoded.name || email?.split('@')[0] || 'Firebase User';
    const emailVerified = decoded.email_verified || false;
    const phoneNumber = decoded.phone_number || null;

    if (!email && !phoneNumber) {
      return errorResponse(res, 'Token must contain an email or phone number', 401);
    }

    // Map user to MySQL Database
    let dbUser = null;
    if (email) {
      dbUser = await prisma.user.findUnique({
        where: { email: email.toLowerCase().trim() },
      });
    } else if (phoneNumber) {
      dbUser = await prisma.user.findUnique({
        where: { phoneNumber },
      });
    }

    if (!dbUser) {
      // Auto-create user in MySQL if they do not exist
      dbUser = await prisma.user.create({
        data: {
          name: name,
          email: email ? email.toLowerCase().trim() : null,
          phoneNumber: phoneNumber,
          emailVerified: emailVerified,
          passwordHash: 'FIREBASE_AUTH', // Placeholder
        },
      });
    } else {
      // Sync verification states if they changed
      let updated = false;
      const dataToUpdate = {};
      
      if (emailVerified !== dbUser.emailVerified) {
        dataToUpdate.emailVerified = emailVerified;
        updated = true;
      }
      if (phoneNumber && !dbUser.phoneVerified) {
        dataToUpdate.phoneVerified = true;
        updated = true;
      }

      if (updated) {
        dbUser = await prisma.user.update({
          where: { id: dbUser.id },
          data: dataToUpdate,
        });
      }
    }

    // Attach user to req
    req.user = {
      id: dbUser.id,
      email: dbUser.email,
      role: dbUser.role,
    };

    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return errorResponse(res, 'Access token has expired', 401);
    }
    return errorResponse(res, `Authentication failed: ${error.message}`, 401);
  }
}

/**
 * Middleware kiểm tra role (Role-Based Access Control)
 */
function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return errorResponse(res, 'Authentication required', 401);
    }

    if (!allowedRoles.includes(req.user.role)) {
      return errorResponse(res, 'Insufficient permissions', 403);
    }

    next();
  };
}

module.exports = { authenticate, authorize };
