# Movie Ticket Agent Skill Pack v2

This package contains optimized AI agent instruction files for:

**Movie Ticket Booking App with Account Security**

## Files

```text
AGENTS.md
docs/
  PROJECT_CONTEXT.md
  AI_RULES.md
  DATABASE_DESIGN.md
  API_SPEC.md
skills/
  movie-ticket-fullstack/SKILL.md
  node-prisma-security/SKILL.md
  flutter-mobile-client/SKILL.md
  quality-gate/SKILL.md
prompts/
  ANTIGRAVITY_START_PROMPT.md
  SWITCH_TO_FLUTTER_PROMPT.md
  REAL_PHONE_PROMPT.md
checklists/
  DEMO_CHECKLIST.md
```

## Where to Put These Files

Put all files in the root of your project:

```text
project/
├── AGENTS.md
├── docs/
├── skills/
├── prompts/
├── checklists/
├── backend/
└── flutter_app/
```

## Antigravity Usage

Send this prompt:

```text
Before doing anything, read and follow:

AGENTS.md
docs/PROJECT_CONTEXT.md
docs/AI_RULES.md
docs/DATABASE_DESIGN.md
docs/API_SPEC.md

Also use relevant skills in the skills/ folder.

These files are the single source of truth.

Current phase:
Phase 1 - Auth + Account Security for Movie Ticket Booking App.

First analyze the architecture and implementation plan, then implement backend. After backend APIs are usable, continue Flutter frontend.
```

If Antigravity keeps doing only backend, send:

```text
Read prompts/SWITCH_TO_FLUTTER_PROMPT.md and follow it now.
```
