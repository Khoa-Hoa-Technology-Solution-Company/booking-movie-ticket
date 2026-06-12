# AGENTS.md

## Project
Movie Ticket Booking App with Account Security

## First Read
Before making changes, read these files in order:
1. `docs/PROJECT_CONTEXT.md`
2. `docs/AI_RULES.md`
3. `docs/DATABASE_DESIGN.md`
4. `docs/API_SPEC.md`

Use these files as the single source of truth.

## Current Phase
Phase 1: Auth + Account Security, then connect Flutter UI to real APIs.

## Hard Rules
- Do not build a standalone security app.
- This is a movie ticket booking app with account security.
- Do not create mock-only features when a real API is required.
- Do not store raw passwords, raw OTP, raw refresh tokens, or secrets in code.
- Do not expose passwordHash, tokenHash, codeHash, stack traces, or internal errors.
- Backend first only until APIs are usable; then continue Flutter frontend.
- Flutter must work on Android emulator and real Android phone.
- Database is MySQL through Docker Compose.
- Backend uses Node.js Express + Prisma.
- Mobile uses Flutter + Dio + flutter_secure_storage.

## Required Work Style
Before coding:
1. State affected files.
2. State a short plan.
3. Mention whether backend, database, or Flutter is affected.

When coding:
1. Provide complete file content.
2. Include imports.
3. Do not leave TODOs for required functionality.
4. Keep code simple enough for a student demo.

After coding:
1. Give commands to run.
2. Give API or Flutter test steps.
3. Mention migrations/packages if needed.

## Priority Roadmap
1. Backend project skeleton.
2. Docker Compose MySQL.
3. Prisma schema + migration + seed.
4. Auth/security APIs.
5. Movie seed APIs.
6. Flutter auth flow.
7. Flutter security screens.
8. Flutter movie booking screens.
9. APK-ready Android config.
