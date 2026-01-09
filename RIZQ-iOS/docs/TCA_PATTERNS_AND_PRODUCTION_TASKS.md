# TCA Patterns & Production Readiness Tasks

This document captures architecture patterns learned during the admin panel integration and the TODO tasks needed to move from demo data to production Firebase integration.

---

## Table of Contents

1. [TCA Navigation Pattern](#1-tca-navigation-pattern)
2. [TCA Presentation Pattern](#2-tca-presentation-pattern)
3. [Production Readiness TODO Tasks](#3-production-readiness-todo-tasks)
4. [Code Changes Required](#4-code-changes-required)
5. [File Reference](#5-file-reference)
6. [Verification Checklist](#6-verification-checklist)

---

## 1. TCA Navigation Pattern

### Pattern: Child-to-Parent Navigation via Actions

In The Composable Architecture, child features communicate intent to parent features through actions. The child doesn't know how the parent will handle the action—it just signals what happened.

### Example: Settings → Admin Panel Navigation

**Child Feature (SettingsFeature.swift)**:
```swift
enum Action {
  // ... other actions
  case adminPanelTapped  // Child signals intent
}

// In reducer:
case .adminPanelTapped:
  // Parent will handle this - child does nothing
  return .none
```

**Parent Feature (AppFeature.swift)**:
```swift
// Parent catches the child action via scoped reducer
case .settings(.adminPanelTapped):
  state.admin = AdminFeature.State()  // Parent decides to present admin
  return .none
```

### Key Insight

> Child features communicate intent without knowing parent structure. The parent decides how to handle navigation.

This keeps features decoupled and testable. The child doesn't need to know if navigation happens via sheet, full screen cover, or push navigation.

---

## 2. TCA Presentation Pattern

### Pattern: Modal Presentation using `@Presents`, `PresentationAction`, and `ifLet`

TCA uses optional state to drive modal presentation. When the state is non-nil, the modal appears. When nil, it dismisses.

### Implementation Steps

**Step 1: Declare optional state with `@Presents`**
```swift
@ObservableState
struct State: Equatable {
  // ... other state
  @Presents var admin: AdminFeature.State?
}
```

**Step 2: Add `PresentationAction` to Action enum**
```swift
enum Action {
  // ... other actions
  case admin(PresentationAction<AdminFeature.Action>)
}
```

**Step 3: Add `ifLet` reducer for optional scoping**
```swift
var body: some ReducerOf<Self> {
  Reduce { state, action in
    // ... main reducer logic
  }

  // Scope into optional admin state when present
  .ifLet(\.$admin, action: \.admin) {
    AdminFeature()
  }
}
```

**Step 4: Catch presented actions to dismiss**
```swift
case .admin(.presented(.closeAdmin)):
  state.admin = nil  // Setting to nil dismisses the modal
  return .none

case .admin:
  return .none  // Pass through other admin actions
```

**Step 5: Bind to SwiftUI presentation**
```swift
// In AppView.swift
.fullScreenCover(
  item: $store.scope(state: \.admin, action: \.admin)
) { adminStore in
  AdminTabView(store: adminStore)
}
```

### Key Insight

> State presence drives presentation. When `admin` is non-nil, the sheet appears. Setting to `nil` dismisses it automatically.

This is declarative—you describe what state means (modal shown), not how to show/hide it.

---

## 3. Production Readiness TODO Tasks

The current implementation uses hardcoded demo data. These tasks replace it with real Firebase integration.

| # | Task | Priority | Status | Description |
|---|------|----------|--------|-------------|
| 1 | Load real user from Firebase Auth | 🔴 High | ⬜ TODO | Replace demo `AuthUser` with `Auth.auth().currentUser` |
| 2 | Fetch profile from Firestore | 🔴 High | ⬜ TODO | Load `UserProfile` including `isAdmin` flag from Firestore |
| 3 | Inject AuthService dependency | 🟡 Medium | ⬜ TODO | Use `@Dependency` for auth operations in SettingsFeature |
| 4 | Handle auth state changes | 🟡 Medium | ⬜ TODO | Listen for sign-in/sign-out events in AppFeature |
| 5 | Remove hardcoded demo data | 🟢 Low | ⬜ TODO | Clean up demo user/profile in `onAppear` |

### Task Details

#### Task 1: Load Real User from Firebase Auth

**Current Location**: `SettingsFeature.swift:143-150`

**What to Change**:
- Remove hardcoded `demoUser`
- Get current user from `Auth.auth().currentUser`
- Map Firebase user to `AuthUser` model

#### Task 2: Fetch Profile from Firestore

**Current Location**: `SettingsFeature.swift:152-160`

**What to Change**:
- Remove hardcoded `demoProfile`
- Call `neonService.fetchUserProfile(userId:)` with real Firebase UID
- Profile includes `isAdmin` flag for admin access control

#### Task 3: Inject AuthService Dependency

**Files**: `SettingsFeature.swift`

**What to Change**:
```swift
@Dependency(\.authService) var authService  // Add this
```

#### Task 4: Handle Auth State Changes

**Files**: `AppFeature.swift`

**What to Change**:
- Subscribe to `Auth.auth().addStateDidChangeListener`
- Update `isAuthenticated` state when auth changes
- Reset child feature states on sign-out

#### Task 5: Remove Hardcoded Demo Data

**Files**: `SettingsFeature.swift`

**What to Change**:
- Delete demo user/profile creation code
- Keep only real Firebase integration code

---

## 4. Code Changes Required

### SettingsFeature.swift - Replace Demo Data

**Current Implementation (Demo)**:
```swift
case .onAppear:
  state.isLoading = true
  state.isLoadingAccounts = true

  return .run { send in
    try await clock.sleep(for: .milliseconds(500))

    // DEMO DATA - TO BE REPLACED
    let demoUser = AuthUser(
      id: "demo-user-001",
      email: "omairdawood@gmail.com",
      name: "Omar Dawood",
      image: nil,
      emailVerified: true
    )
    await send(.userLoaded(demoUser))

    let demoProfile = UserProfile(
      id: "profile-001",
      userId: "demo-user-001",
      displayName: "Omar Dawood",
      streak: 5,
      totalXp: 350,
      level: 2,
      isAdmin: true  // Hardcoded for testing
    )
    await send(.profileLoaded(demoProfile))

    let demoAccounts: [LinkedAccount] = [
      LinkedAccount(
        id: "account-001",
        provider: .google,
        providerAccountId: "google-123"
      )
    ]
    await send(.linkedAccountsLoaded(demoAccounts))
  }
```

**Target Implementation (Production)**:
```swift
@Dependency(\.authService) var authService  // Add dependency

case .onAppear:
  state.isLoading = true
  state.isLoadingAccounts = true

  return .run { [authService] send in
    // 1. Get current Firebase user
    guard let firebaseUser = Auth.auth().currentUser else {
      await send(.loadFailed("Not authenticated"))
      return
    }

    // 2. Map Firebase user to AuthUser model
    let user = AuthUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? "",
      name: firebaseUser.displayName,
      image: firebaseUser.photoURL?.absoluteString,
      emailVerified: firebaseUser.isEmailVerified
    )
    await send(.userLoaded(user))

    // 3. Fetch profile from Firestore (includes isAdmin)
    do {
      if let profile = try await neonService.fetchUserProfile(userId: firebaseUser.uid) {
        await send(.profileLoaded(profile))
      } else {
        // Create default profile if none exists
        await send(.loadFailed("Profile not found"))
      }
    } catch {
      await send(.loadFailed(error.localizedDescription))
    }

    // 4. Fetch linked accounts from Firebase Auth
    do {
      let accounts = try await authService.fetchLinkedAccounts()
      await send(.linkedAccountsLoaded(accounts))
    } catch {
      await send(.linkedAccountsLoaded([]))  // Graceful fallback
    }
  }
```

---

## 5. File Reference

| File | Line Numbers | Purpose |
|------|--------------|---------|
| `SettingsFeature.swift` | 136-167 | Current demo data loading (to be replaced) |
| `AppFeature.swift` | 18-19 | `@Presents var admin` state declaration |
| `AppFeature.swift` | 63-64 | `PresentationAction` in Action enum |
| `AppFeature.swift` | 109-118 | Admin presentation handling |
| `AppView.swift` | 44-48 | `fullScreenCover` binding to admin state |
| `FirestoreService.swift` | - | Firestore operations for profile fetch |
| `FirebaseAuthService.swift` | - | Auth operations for linked accounts |
| `RIZQKit/Services/Dependencies.swift` | 73-176 | ServiceContainer configuration |

---

## 6. Verification Checklist

After implementing the production tasks:

### Authentication Flow
- [ ] Sign in with real Google account works
- [ ] User data loads from Firebase Auth (name, email, photo)
- [ ] Sign out clears all user state

### Profile Loading
- [ ] Profile loads from Firestore on Settings appear
- [ ] `isAdmin` flag is read from Firestore, not hardcoded
- [ ] Profile stats (XP, level, streak) display correctly

### Admin Access Control
- [ ] Admin section HIDDEN for non-admin users
- [ ] Admin section VISIBLE for users with `isAdmin: true` in Firestore
- [ ] Tapping "Admin Panel" opens full-screen admin interface
- [ ] Close button dismisses and returns to Settings

### Error Handling
- [ ] Graceful fallback if profile fetch fails
- [ ] Loading states display during async operations
- [ ] Error messages show for failures

---

## Summary

| Pattern | Purpose | Key File |
|---------|---------|----------|
| Child-to-Parent Actions | Decoupled navigation | `SettingsFeature.swift`, `AppFeature.swift` |
| `@Presents` + `ifLet` | State-driven modals | `AppFeature.swift`, `AppView.swift` |
| Firebase Integration | Production auth | `SettingsFeature.swift` (TODO) |

**Total Tasks**: 5
**High Priority**: 2
**Medium Priority**: 2
**Low Priority**: 1
