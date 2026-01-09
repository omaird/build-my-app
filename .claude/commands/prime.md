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

**iOS App (Swift/TCA):**
- Main entry: RIZQ-iOS/RIZQ/App/RIZQApp.swift
- App Feature: RIZQ-iOS/RIZQ/App/AppFeature.swift
- Package: RIZQ-iOS/Package.swift or RIZQ-iOS/RIZQ.xcodeproj
- Key models: RIZQ-iOS/RIZQKit/Models/
- Key services: RIZQ-iOS/RIZQKit/Services/

**Firebase:**
- Configuration: firebase.json, .firebaserc
- Rules: firestore.rules

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
- Testing approach
- State management patterns

### Current State
- Active branch
- Recent changes or development focus
- Any immediate observations or concerns

**Make this summary easy to scan - use bullet points and clear headers.**
