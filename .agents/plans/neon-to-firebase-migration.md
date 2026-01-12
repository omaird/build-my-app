# Plan: Migrate iOS App from Neon to Firebase

## Overview

Remove Neon PostgreSQL as a data source for the iOS app and migrate all operations to Firebase Firestore. The Neon code will be preserved (not deleted) in case we want to switch back in the future.

**Current State:**
- Content data (duas, journeys, categories) → Already using Firebase via `FirestoreContentService`
- User data (profiles, activity, completions) → Mixed: `NeonClient` wraps `FirebaseNeonService` which routes user ops to Firestore but still requires Neon config
- Admin operations → Using `AdminService` which directly queries Neon PostgreSQL

**Target State:**
- All iOS operations use Firebase Firestore exclusively
- Neon code preserved but disabled/deprecated
- Admin panel works with Firebase user data

---

## Features

### 1. Create FirebaseAdminService for User Management
**Files:** `RIZQ-iOS/RIZQKit/Services/Admin/FirebaseAdminService.swift` (new)
**Acceptance Criteria:**
- [ ] Implements `AdminServiceProtocol` for user-related operations
- [ ] Uses Firestore to fetch all user profiles from `user_profiles` collection
- [ ] Supports `updateUserAdmin` to toggle admin status
- [ ] Supports `deleteUserAdmin` to remove user data
- [ ] Includes proper error handling and logging

### 2. Create FirebaseUserService for User Data Operations
**Files:** `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseUserService.swift` (new)
**Acceptance Criteria:**
- [ ] Implements all user profile operations (fetch, create, update, addXp)
- [ ] Implements all user activity operations (fetch, record completions)
- [ ] Uses `user_profiles/{userId}` document structure
- [ ] Uses `user_activity/{userId}/dates/{date}` subcollection structure
- [ ] Handles streak calculation and level-up logic

### 3. Update FirestoreService with Complete User Operations
**Files:** `RIZQ-iOS/RIZQKit/Services/Firebase/FirestoreService.swift`
**Acceptance Criteria:**
- [ ] Ensure all user profile CRUD operations are fully implemented
- [ ] Ensure all user activity operations are fully implemented
- [ ] Add `fetchAllUserProfiles()` for admin listing
- [ ] Add `deleteUserProfile()` for admin deletion
- [ ] Verify Firestore security rules allow these operations

### 4. Create FirestoreUserClient TCA Dependency
**Files:** `RIZQ-iOS/RIZQ/Dependencies/FirestoreUserClient.swift` (new)
**Acceptance Criteria:**
- [ ] Mirrors `NeonClient` API for user operations only
- [ ] Uses `FirebaseUserService` for live implementation
- [ ] Provides test and preview values with mock data
- [ ] Dependency key registered in `DependencyValues`

### 5. Update Features to Use FirestoreUserClient
**Files:**
- `RIZQ-iOS/RIZQ/Features/Home/HomeFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Library/LibraryFeature.swift`
- `RIZQ-iOS/RIZQ/Features/Practice/PracticeFeature.swift`
**Acceptance Criteria:**
- [ ] Replace `@Dependency(\.neonClient)` with `@Dependency(\.firestoreUserClient)`
- [ ] Update all method calls to use new client
- [ ] Verify user profile fetching works
- [ ] Verify XP and completion recording works
- [ ] Verify activity fetching works

### 6. Update AdminService Dependency to Use Firebase
**Files:** `RIZQ-iOS/RIZQ/Features/Admin/AdminDashboardFeature.swift`
**Acceptance Criteria:**
- [ ] Update `AdminServiceKey.liveValue` to use `FirebaseAdminService`
- [ ] Remove dependency on `APIConfiguration`
- [ ] Verify admin stats load correctly
- [ ] Verify user listing works
- [ ] Verify admin toggle works

### 7. Update ServiceContainer to Remove Neon Configuration
**Files:** `RIZQ-iOS/RIZQKit/Services/Dependencies.swift`
**Acceptance Criteria:**
- [ ] Remove `_neonService` property
- [ ] Remove `NeonService` and `FirebaseNeonService` initialization
- [ ] Remove `APIConfiguration` from `AppConfiguration` (make optional/deprecated)
- [ ] Update `configure()` to not require Neon credentials
- [ ] Keep `neonService` property returning mock for backwards compatibility

### 8. Deprecate Neon Files (Keep but Mark Deprecated)
**Files:**
- `RIZQ-iOS/RIZQKit/Services/API/NeonService.swift`
- `RIZQ-iOS/RIZQKit/Services/API/APIClient.swift`
- `RIZQ-iOS/RIZQKit/Services/Firebase/FirebaseNeonService.swift`
- `RIZQ-iOS/RIZQ/Dependencies/NeonClient.swift`
- `RIZQ-iOS/RIZQKit/Services/Admin/AdminService.swift`
**Acceptance Criteria:**
- [ ] Add `@available(*, deprecated, message: "Use Firebase services instead")` to each file/type
- [ ] Add file header comments explaining deprecation
- [ ] Keep code functional for potential rollback
- [ ] Update NeonClient.liveValue to use MockNeonService

### 9. Update App Configuration and Environment
**Files:**
- `RIZQ-iOS/RIZQ/App/RIZQApp.swift`
- `RIZQ-iOS/Info.plist`
**Acceptance Criteria:**
- [ ] Remove Neon environment variable checks
- [ ] Remove NeonHost, NeonApiKey, NeonProjectId from Info.plist
- [ ] Simplify `ServiceContainer.configure()` call
- [ ] Ensure Firebase-only initialization path

### 10. Update Tests to Use Firebase Mocks
**Files:**
- `RIZQ-iOS/RIZQTests/RIZQTests.swift`
- `RIZQ-iOS/RIZQTests/NeonServiceTests.swift`
**Acceptance Criteria:**
- [ ] Update tests to use Firebase mocks instead of Neon mocks
- [ ] Rename/deprecate `NeonServiceTests.swift`
- [ ] Create `FirestoreUserServiceTests.swift` if needed
- [ ] Verify all tests pass

### 11. Verify Build and Runtime Functionality
**Files:** N/A (verification step)
**Acceptance Criteria:**
- [ ] Build succeeds with `xcodebuild -scheme RIZQ`
- [ ] App launches without Neon configuration errors
- [ ] Home screen loads user profile from Firebase
- [ ] Practice completion records to Firebase
- [ ] Admin panel lists users from Firebase
- [ ] No Neon-related errors in console logs

### 12. Update Documentation
**Files:**
- `RIZQ-iOS/CLAUDE.md`
- `RIZQ-iOS/docs/` (relevant docs)
**Acceptance Criteria:**
- [ ] Update architecture documentation to reflect Firebase-only setup
- [ ] Remove Neon configuration instructions
- [ ] Document rollback procedure if needed
- [ ] Update data flow diagrams if present

---

## Implementation Notes

### Firestore Collection Structure (Target)

```
user_profiles/
  {userId}/
    displayName: string?
    streak: number
    totalXp: number
    level: number
    lastActiveDate: timestamp?
    isAdmin: boolean
    createdAt: timestamp
    updatedAt: timestamp

user_activity/
  {userId}/
    dates/
      {yyyy-MM-dd}/
        duasCompleted: number[]
        xpEarned: number
        userId: string
```

### Model Changes (if needed)

The `UserProfile` model may need adjustments for Firestore:
- Change `id_` to use `userId` as document ID
- Ensure date fields use Firestore Timestamp

### Security Rules

Ensure Firestore rules allow:
```javascript
match /user_profiles/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth.uid == userId;
}

// Admin can read all users
match /user_profiles/{userId} {
  allow read: if get(/databases/$(database)/documents/user_profiles/$(request.auth.uid)).data.isAdmin == true;
}
```

### Rollback Plan

If issues arise:
1. Revert `AdminServiceKey.liveValue` to use `AdminService`
2. Revert feature files to use `neonClient`
3. Restore `ServiceContainer` Neon initialization
4. Re-add Neon environment variables

---

## Risk Assessment

| Risk | Mitigation |
|------|------------|
| Data format mismatch between Neon and Firestore | Use same model types, custom decoders handle both |
| Missing user data in Firestore | Seed script or lazy migration on first access |
| Admin operations fail | Firebase Admin SDK has same capabilities |
| Performance regression | Firestore has local caching, should be faster |

---

## Estimated Scope

- **New files:** 3 (FirebaseAdminService, FirebaseUserService, FirestoreUserClient)
- **Modified files:** ~15
- **Deprecated files:** 5 (kept for rollback)
- **Deleted files:** 0
