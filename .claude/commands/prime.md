---
description: Prime agent with codebase understanding
---

# Prime: Load Project Context

## Objective

Build comprehensive understanding of the RIZQ codebase by analyzing structure, documentation, and key files.

## Process

### 1. Analyze Project Structure

List all tracked files:
!`git ls-files`

Show directory structure:
```bash
find . -type d -name 'node_modules' -prune -o -type d -name '.git' -prune -o -type d -name 'dist' -prune -o -type d -name 'build' -prune -o -type d -name 'DerivedData' -prune -o -type d -print | head -50
```

### 2. Read Core Documentation

- Read CLAUDE.md (project-wide conventions and patterns)
- Read README.md at project root
- Read RIZQ-iOS/CLAUDE.md (iOS-specific conventions)
- Read PRD.md if it exists

### 3. Identify Key Files

**Web App (React/TypeScript):**
- Main entry: src/App.tsx, src/main.tsx
- Configuration: package.json, tsconfig.json, vite.config.ts, tailwind.config.ts
- Database: src/lib/db.ts
- Auth: src/lib/auth-client.ts, src/contexts/AuthContext.tsx
- Key types: src/types/dua.ts, src/types/habit.ts, src/types/admin.ts
- Admin hooks: src/hooks/admin/ (useAdminDuas, useAdminJourneys, etc.)
- Admin pages: src/pages/admin/ (including JourneyDuasManagerPage)
- E2E tests: e2e/ (admin-journeys.spec.ts, auth.spec.ts)

**iOS App (Swift/TCA):**
- Main entry: RIZQ-iOS/RIZQ/App/RIZQApp.swift
- App Feature: RIZQ-iOS/RIZQ/App/AppFeature.swift
- Key features: RIZQ-iOS/RIZQ/Features/ (Home, Journeys, Adkhar, Settings, etc.)
- Dependencies: RIZQ-iOS/RIZQ/Dependencies/ (FirestoreUserClient, FirestoreContentClient)
- Key models: RIZQ-iOS/RIZQKit/Models/ (Dua, Journey, User, Achievement, IslamicQuote)
- Key services: RIZQ-iOS/RIZQKit/Services/Firebase/ (FirebaseUserService, FirestoreContentService)
- Tests: RIZQ-iOS/RIZQTests/ (SettingsFeatureTests, FirebaseAuthTests)
- Build config: RIZQ-iOS/project.yml

**Firebase:**
- Configuration: firebase.json, .firebaserc
- Rules: firestore.rules
- Indexes: firestore.indexes.json
- Seeding: scripts/seed-firestore.cjs

**Infrastructure:**
- MCP servers: .mcp.json (Playwright + Firebase)
- Claude settings: .claude/settings.json
- Test config: playwright.config.ts

### 4. Understand Current State

Check recent activity:
!`git log -10 --oneline`

Check current branch and status:
!`git status`

## Output Report

Provide a concise summary covering:

### Project Overview
- Purpose and type of application (gamified Islamic dua practice app)
- Primary technologies and frameworks
- Current version/state

### Architecture
- Web app structure and organization
- iOS app structure (TCA pattern)
- Shared patterns and conventions
- Firebase integration

### Tech Stack

**Web:**
- React 18 + TypeScript + Vite
- Tailwind CSS + shadcn/ui
- TanStack React Query
- Framer Motion
- Neon PostgreSQL / Firebase

**iOS:**
- Swift + SwiftUI
- The Composable Architecture (TCA)
- Firebase (Auth, Firestore)

### Core Principles
- Code style and conventions observed
- Design system (warm Islamic aesthetic)
- Testing approach (Playwright E2E for web, TestStore + snapshots for iOS)
- State management patterns (React Query + Context for web, TCA for iOS)

### Infrastructure
- Firebase project: rizq-app-c6468 (Firestore location: nam5)
- MCP servers: Playwright (E2E), Firebase (admin ops)
- Dev server port: 8080 (Vite), Test base URL: localhost:8081

### Current State
- Active branch
- Recent changes or development focus
- Any immediate observations or concerns
- Unstaged changes and untracked files

**Make this summary easy to scan - use bullet points and clear headers.**
