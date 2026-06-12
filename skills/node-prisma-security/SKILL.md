---
name: node-prisma-security
description: Use this skill for Node.js Express, Prisma, MySQL, JWT, refresh token, OTP, email verification, and backend security work.
---

# Node Prisma Security Skill

## Backend Stack
- Node.js
- Express
- Prisma
- MySQL
- JWT
- Argon2id
- Nodemailer
- Helmet
- CORS
- express-rate-limit
- Zod or Joi

## Security Checklist
Before finalizing backend changes, verify:
- Passwords use Argon2id.
- OTP codes are hashed.
- Refresh tokens are hashed.
- Sensitive fields are not returned.
- Input validation exists.
- Rate limit exists on auth endpoints.
- Errors are safe for clients.
- Prisma is used for DB operations.
- Login history is recorded.
- Security alerts are created when needed.

## Endpoint Pattern
Use:
- route
- controller
- service
- validation

Do not put all logic in route files.

## API Response
Use standard response:
```json
{
  "success": true,
  "message": "Message",
  "data": {}
}
```

## Local Email Rule
If SMTP is not configured and `LOG_EMAIL_CODES=true`, log verification/OTP codes to console for local testing only.
