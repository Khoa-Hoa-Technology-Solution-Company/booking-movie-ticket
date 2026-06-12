---
name: quality-gate
description: Use this skill before considering a feature complete. It checks runnable code, security, API consistency, and demo readiness.
---

# Quality Gate Skill

## Before Marking Done
Check:

### Backend
- `npm install` works.
- `npm run dev` works.
- Prisma migration instructions are provided.
- Docker Compose MySQL instructions are provided.
- Endpoint can be tested.
- Sensitive data is not exposed.

### Flutter
- `flutter pub get` works.
- `flutter run` works.
- API base URL can be changed in one file.
- Loading and error states exist.
- Android emulator works.
- Real phone setup is documented.

### Docs
- API changes are in `docs/API_SPEC.md`.
- DB changes are in `docs/DATABASE_DESIGN.md`.
- New commands are in README or response.

### Demo
- There is a simple step-by-step test flow.
- The feature can be explained in class.
