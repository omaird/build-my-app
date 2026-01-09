# iOS Admin Panel Integration Specification

> **Status**: Ready for Implementation
> **Last Updated**: January 2026
> **Estimated Effort**: ~3 hours total

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Current State Analysis](#current-state-analysis)
3. [Admin Pages Reference](#admin-pages-reference)
4. [Implementation Phases](#implementation-phases)
5. [File Reference](#file-reference)
6. [Code Snippets](#code-snippets)
7. [Verification Checklist](#verification-checklist)
8. [Risk Considerations](#risk-considerations)

---

## Executive Summary

The iOS admin panel is **fully built** but **not accessible from the UI**. This specification documents the work required to:

1. Wire up admin access from the Settings screen
2. Build the missing Collections Manager (for feature parity with web)
3. Ensure all admin functionality works end-to-end

### Quick Status

| Component | Status | Notes |
|-----------|--------|-------|
| Admin Dashboard | ✅ Built | Stats + navigation |
| Duas Manager | ✅ Built | Full CRUD |
| Journeys Manager | ✅ Built | Full CRUD + dua assignment |
| Categories Manager | ✅ Built | Full CRUD |
| Collections Manager | ❌ Missing | **Must build** |
| Users Manager | ✅ Built | View + admin toggle |
| Settings → Admin Link | ❌ Missing | **Must wire up** |

---

## Current State Analysis

### What Exists (iOS)

```
RIZQ/Features/Admin/
├── AdminFeature.swift           # Root admin reducer with tab state
├── AdminTabView.swift           # Tab navigation UI
├── AdminDashboardFeature.swift  # Dashboard stats reducer
├── AdminDashboardView.swift     # Dashboard UI
├── AdminDuasFeature.swift       # Duas CRUD reducer
├── AdminDuasView.swift          # Duas manager UI
├── AdminJourneysFeature.swift   # Journeys CRUD reducer
├── AdminJourneysView.swift      # Journeys manager UI
├── AdminCategoriesFeature.swift # Categories CRUD reducer
├── AdminCategoriesView.swift    # Categories manager UI
├── AdminUsersFeature.swift      # Users management reducer
└── AdminUsersView.swift         # Users manager UI

RIZQKit/Services/Admin/
└── AdminService.swift           # Backend CRUD operations via Neon
```

### What's Missing

| Gap | Type | Description |
|-----|------|-------------|
| Settings → Admin | Navigation | No way to access admin panel from UI |
| Collections Manager | Feature | Web has it, iOS doesn't |
| Admin role check | Gate | Must verify `isAdmin` before showing access |

---

## Admin Pages Reference

### 1. Dashboard (`AdminDashboardView`)

**Purpose**: Overview of app content and quick navigation to other sections.

**Stats Displayed**:
- Total Duas count
- Total Journeys count
- Total Categories count
- Total Users count
- Active Users Today

**Quick Actions**:
| Button | Destination |
|--------|-------------|
| "Manage Duas" | Duas tab |
| "Manage Journeys" | Journeys tab |
| "Manage Categories" | Categories tab |

**Data Source**: `AdminService.fetchStats()`

---

### 2. Duas Manager (`AdminDuasView`)

**Purpose**: Create, read, update, delete duas (supplications).

#### List View
- Search by title or Arabic text
- Each row displays: title, Arabic preview, XP value, best time icon
- Actions: Edit, Delete (swipe or menu)

#### Create/Edit Form Fields

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| Title (English) | TextField | ✅ | min 3 chars | Primary identifier |
| Arabic Text | TextEditor | ✅ | non-empty | RTL display |
| Transliteration | TextField | ❌ | - | Latin pronunciation |
| Translation (English) | TextEditor | ✅ | non-empty | - |
| Repetitions | Stepper | ✅ | 1-100 | Default: 3 |
| XP Value | Stepper | ✅ | 1-100 | Default: 10 |
| Best Time | Picker | ❌ | enum | morning/anytime/evening |
| Difficulty | Picker | ❌ | enum | Beginner/Intermediate/Advanced |
| Source | TextField | ❌ | - | e.g., "Bukhari & Muslim" |
| Rizq Benefit | TextEditor | ❌ | - | Islamic benefit description |
| Prophetic Context | TextEditor | ❌ | - | Historical context |
| Category | Picker | ❌ | - | Link to existing category |

**Data Source**: `AdminService.fetchAllDuasAdmin()`, `AdminService.createDua()`, `AdminService.updateDua()`, `AdminService.deleteDua()`

---

### 3. Journeys Manager (`AdminJourneysView`)

**Purpose**: Manage themed dua collections that users subscribe to.

#### List View
- Search by name
- Each row displays: emoji, name, badges (featured/premium), daily XP, duration
- Actions: Edit, Delete, Manage Duas

#### Create/Edit Form Fields

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| Name | TextField | ✅ | min 3 chars | Display name |
| Slug | TextField | ✅ | lowercase-hyphen | Auto-generated from name |
| Emoji | TextField | ❌ | single emoji | Default: "📿" |
| Description | TextEditor | ❌ | - | Journey description |
| Estimated Duration | Stepper | ✅ | 1-120 min | Minutes per day |
| Daily XP | Stepper | ✅ | 0-500, step 10 | XP earned per day |
| Sort Order | Stepper | ❌ | 0-100 | Display ordering |
| Premium | Toggle | ❌ | - | Default: false |
| Featured | Toggle | ❌ | - | Default: false |

#### Manage Duas Sub-view
- View duas currently assigned to journey with time slots
- Add dua to journey with time slot picker (morning/anytime/evening)
- Remove dua from journey
- Reorder duas (sort_order)

**Data Source**: `AdminService.fetchAllJourneysAdmin()`, `AdminService.createJourney()`, `AdminService.updateJourney()`, `AdminService.deleteJourney()`, `AdminService.addDuaToJourney()`, `AdminService.removeDuaFromJourney()`

---

### 4. Categories Manager (`AdminCategoriesView`)

**Purpose**: Organize duas by thematic category.

#### List View
- Search by name
- Each row displays: colored icon, name, slug, description
- Color-coded by slug (morning=gold, evening=purple, rizq=green, gratitude=teal)

#### Create/Edit Form Fields

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| Name | TextField | ✅ | min 2 chars | Display name |
| Slug | Picker | ✅ | enum | morning/evening/rizq/gratitude |
| Description | TextEditor | ❌ | - | Category description |

**Business Rules**:
- Deleting a category makes associated duas uncategorized
- Slug determines the color scheme

**Data Source**: `AdminService.fetchAllCategoriesAdmin()`, `AdminService.createCategory()`, `AdminService.updateCategory()`, `AdminService.deleteCategory()`

---

### 5. Collections Manager (`AdminCollectionsView`) — TO BUILD

**Purpose**: Manage content tiers (premium vs free collections).

#### Model Reference

```swift
// Exists in RIZQKit/Models/Dua.swift:78
public struct DuaCollection: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let name: String
  public let slug: String
  public let description: String?
  public let isPremium: Bool
}
```

#### List View
- Search by name or slug
- Each row displays: name, slug (monospace), description preview, premium badge
- Actions: Edit, Delete, Toggle Premium

#### Create/Edit Form Fields

| Field | Type | Required | Validation | Notes |
|-------|------|----------|------------|-------|
| Name | TextField | ✅ | min 2 chars | Display name |
| Slug | TextField | ✅ | lowercase-hyphen, min 2 | Unique identifier |
| Description | TextEditor | ❌ | - | Collection description |
| Premium | Toggle | ❌ | - | Default: false |

**Business Rules**:
- Cannot delete collection if duas are assigned to it
- Duas in premium collections are marked as premium content
- Slug must be unique

**Data Source**: To be added to `AdminService`

---

### 6. Users Manager (`AdminUsersView`)

**Purpose**: View and manage user accounts.

#### Stats Section
- Total Users count
- Admin Count
- Active Today count

#### List View
- Search by name or userId
- Each row displays: avatar, name, admin badge, level/XP/streak stats
- Actions: View Details, Toggle Admin, Delete

#### User Detail Sheet
- Large avatar image
- Display name with admin badge (if applicable)
- Stats grid: Level, Total XP, Streak
- Account info: User ID, Last Active, Created date
- Actions:
  - Toggle Admin Rights (with confirmation)
  - Delete User (with confirmation)

**Business Rules**:
- Admin toggle requires confirmation dialog
- Cannot remove admin from the last admin user
- User deletion cascades to activity and progress records

**Data Source**: `AdminService.fetchAllUsersAdmin()`, `AdminService.updateUserAdminStatus()`, `AdminService.deleteUser()`

---

## Implementation Phases

### Phase 1: Wire Up Admin Access from Settings

**Effort**: ~30 minutes
**Files to Modify**: 4

#### TODO List

- [ ] **1.1** Add `adminPanelTapped` action to `SettingsFeature.Action`
- [ ] **1.2** Add admin section to `SettingsView` (only visible for admins)
- [ ] **1.3** Add `isShowingAdmin` and `admin` state to `AppFeature.State`
- [ ] **1.4** Add admin presentation actions to `AppFeature.Action`
- [ ] **1.5** Handle `settings(.adminPanelTapped)` in `AppFeature` reducer
- [ ] **1.6** Present `AdminTabView` in `AppView` using `.fullScreenCover`
- [ ] **1.7** Build and verify navigation works

---

### Phase 2: Verify Close Button Functionality

**Effort**: ~5 minutes
**Files to Verify**: 1-2

#### TODO List

- [ ] **2.1** Verify `AdminTabView` has "Done" button in toolbar
- [ ] **2.2** Ensure dismiss action propagates to parent (`AppFeature`)
- [ ] **2.3** Test dismiss clears admin state properly

---

### Phase 3: Build Collections Manager

**Effort**: ~2 hours
**Files to Create**: 2
**Files to Modify**: 3

#### TODO List

##### 3A: Add Collection CRUD to AdminService
- [ ] **3A.1** Add `CollectionInput` struct to `AdminService.swift`
- [ ] **3A.2** Add `fetchAllCollectionsAdmin()` method
- [ ] **3A.3** Add `createCollection()` method
- [ ] **3A.4** Add `updateCollection()` method
- [ ] **3A.5** Add `deleteCollection()` method
- [ ] **3A.6** Add methods to `AdminServiceProtocol`
- [ ] **3A.7** Add mock implementations

##### 3B: Add Collections Tab to AdminFeature
- [ ] **3B.1** Add `.collections` case to `AdminTab` enum
- [ ] **3B.2** Add tab title and icon
- [ ] **3B.3** Add `collections: AdminCollectionsFeature.State` to state
- [ ] **3B.4** Add `collections` action case
- [ ] **3B.5** Add `Scope` for collections reducer

##### 3C: Create AdminCollectionsFeature
- [ ] **3C.1** Create `AdminCollectionsFeature.swift`
- [ ] **3C.2** Define `State` with collections, search, form, loading states
- [ ] **3C.3** Define all `Action` cases
- [ ] **3C.4** Implement `body` reducer with all cases
- [ ] **3C.5** Add dependency on `AdminService`

##### 3D: Create AdminCollectionsView
- [ ] **3D.1** Create `AdminCollectionsView.swift`
- [ ] **3D.2** Implement search header
- [ ] **3D.3** Implement collections list with `CollectionRow`
- [ ] **3D.4** Implement create/edit form sheet
- [ ] **3D.5** Implement delete confirmation alert
- [ ] **3D.6** Implement empty state
- [ ] **3D.7** Implement loading state

##### 3E: Wire Up in AdminTabView
- [ ] **3E.1** Add `.collections` case to tab bar
- [ ] **3E.2** Add `AdminCollectionsView` destination

---

## File Reference

### Phase 1 Files

| File | Action | Purpose |
|------|--------|---------|
| `RIZQ/Features/Settings/SettingsFeature.swift` | Modify | Add admin action |
| `RIZQ/Features/Settings/SettingsView.swift` | Modify | Add admin section UI |
| `RIZQ/App/AppFeature.swift` | Modify | Add admin state + handling |
| `RIZQ/App/AppView.swift` | Modify | Present admin panel |

### Phase 2 Files

| File | Action | Purpose |
|------|--------|---------|
| `RIZQ/Features/Admin/AdminTabView.swift` | Verify | Check dismiss button |
| `RIZQ/Features/Admin/AdminFeature.swift` | Verify | Check dismiss action |

### Phase 3 Files

| File | Action | Purpose |
|------|--------|---------|
| `RIZQKit/Services/Admin/AdminService.swift` | Modify | Add collection CRUD |
| `RIZQ/Features/Admin/AdminFeature.swift` | Modify | Add collections tab |
| `RIZQ/Features/Admin/AdminTabView.swift` | Modify | Add collections destination |
| `RIZQ/Features/Admin/AdminCollectionsFeature.swift` | **Create** | Collections reducer |
| `RIZQ/Features/Admin/AdminCollectionsView.swift` | **Create** | Collections UI |

### Reference Files (Read Only)

| File | Purpose |
|------|---------|
| `RIZQKit/Models/Dua.swift:78` | `DuaCollection` model definition |
| `RIZQ/Features/Admin/AdminCategoriesFeature.swift` | Pattern reference for CRUD reducer |
| `RIZQ/Features/Admin/AdminCategoriesView.swift` | Pattern reference for manager UI |

---

## Code Snippets

### Phase 1: SettingsFeature Changes

```swift
// In SettingsFeature.swift

// Add to Action enum:
case adminPanelTapped

// Add to reducer body:
case .adminPanelTapped:
  // Handled by parent (AppFeature)
  return .none
```

### Phase 1: SettingsView Changes

```swift
// In SettingsView.swift

// Add new computed property:
@ViewBuilder
private var adminSection: some View {
  if store.profile?.isAdmin == true {
    SettingsSection(title: "Administration") {
      SettingsRow.navigation(
        icon: "slider.horizontal.3",
        iconColor: .rizqPrimary,
        title: "Admin Panel",
        subtitle: "Manage duas, journeys & users",
        action: { store.send(.adminPanelTapped) }
      )
    }
  }
}

// Add to main VStack (after preferencesSection):
adminSection
```

### Phase 1: AppFeature Changes

```swift
// In AppFeature.swift

// Add to State:
var isShowingAdmin: Bool = false
@Presents var admin: AdminFeature.State?

// Add to Action:
case settings(SettingsFeature.Action)
case dismissAdmin
case admin(PresentationAction<AdminFeature.Action>)

// Add to reducer body:
case .settings(.adminPanelTapped):
  state.admin = AdminFeature.State()
  state.isShowingAdmin = true
  return .none

case .dismissAdmin:
  state.isShowingAdmin = false
  state.admin = nil
  return .none

case .admin(.presented(.closeAdmin)):
  state.isShowingAdmin = false
  state.admin = nil
  return .none

case .admin:
  return .none
```

### Phase 1: AppView Changes

```swift
// In AppView.swift

// Add to main TabView:
.fullScreenCover(isPresented: $store.isShowingAdmin) {
  if let adminStore = store.scope(state: \.admin, action: \.admin) {
    NavigationStack {
      AdminTabView(store: adminStore)
        .toolbar {
          ToolbarItem(placement: .navigationBarTrailing) {
            Button("Done") {
              store.send(.dismissAdmin)
            }
          }
        }
    }
  }
}
```

### Phase 3: AdminService Collection Methods

```swift
// In AdminService.swift

// Add input struct:
public struct CollectionInput: Sendable {
  public var name: String
  public var slug: String
  public var description: String?
  public var isPremium: Bool

  public init(
    name: String = "",
    slug: String = "",
    description: String? = nil,
    isPremium: Bool = false
  ) {
    self.name = name
    self.slug = slug
    self.description = description
    self.isPremium = isPremium
  }
}

// Add to AdminServiceProtocol:
func fetchAllCollectionsAdmin() async throws -> [DuaCollection]
func createCollection(_ input: CollectionInput) async throws -> DuaCollection
func updateCollection(id: Int, input: CollectionInput) async throws -> DuaCollection
func deleteCollection(id: Int) async throws

// Implementation in AdminService:
public func fetchAllCollectionsAdmin() async throws -> [DuaCollection] {
  let sql = try await getSql()
  let result = try await sql("""
    SELECT id, name, slug, description, is_premium
    FROM collections
    ORDER BY name ASC
  """)
  return result.map { row in
    DuaCollection(
      id: row["id"] as! Int,
      name: row["name"] as! String,
      slug: row["slug"] as! String,
      description: row["description"] as? String,
      isPremium: row["is_premium"] as? Bool ?? false
    )
  }
}

public func createCollection(_ input: CollectionInput) async throws -> DuaCollection {
  let sql = try await getSql()
  let result = try await sql("""
    INSERT INTO collections (name, slug, description, is_premium)
    VALUES (\(input.name), \(input.slug), \(input.description), \(input.isPremium))
    RETURNING id, name, slug, description, is_premium
  """)
  guard let row = result.first else {
    throw AdminServiceError.createFailed("Collection")
  }
  return DuaCollection(
    id: row["id"] as! Int,
    name: row["name"] as! String,
    slug: row["slug"] as! String,
    description: row["description"] as? String,
    isPremium: row["is_premium"] as? Bool ?? false
  )
}

public func updateCollection(id: Int, input: CollectionInput) async throws -> DuaCollection {
  let sql = try await getSql()
  let result = try await sql("""
    UPDATE collections
    SET name = \(input.name),
        slug = \(input.slug),
        description = \(input.description),
        is_premium = \(input.isPremium)
    WHERE id = \(id)
    RETURNING id, name, slug, description, is_premium
  """)
  guard let row = result.first else {
    throw AdminServiceError.notFound("Collection", id)
  }
  return DuaCollection(
    id: row["id"] as! Int,
    name: row["name"] as! String,
    slug: row["slug"] as! String,
    description: row["description"] as? String,
    isPremium: row["is_premium"] as? Bool ?? false
  )
}

public func deleteCollection(id: Int) async throws {
  let sql = try await getSql()
  // Check if collection has duas assigned
  let duaCount = try await sql("""
    SELECT COUNT(*) as count FROM duas WHERE collection_id = \(id)
  """)
  if let count = duaCount.first?["count"] as? Int, count > 0 {
    throw AdminServiceError.deleteFailed("Collection has \(count) duas assigned")
  }
  try await sql("DELETE FROM collections WHERE id = \(id)")
}
```

### Phase 3: AdminCollectionsFeature

```swift
// AdminCollectionsFeature.swift

import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct AdminCollectionsFeature {
  @ObservableState
  struct State: Equatable {
    var collections: [DuaCollection] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var isFormPresented: Bool = false
    var editingCollection: DuaCollection?
    var formInput: CollectionFormInput = .init()
    var isDeleteConfirmationPresented: Bool = false
    var collectionToDelete: DuaCollection?
    var isSaving: Bool = false
    var isDeleting: Bool = false
    var errorMessage: String?
    var successMessage: String?

    var filteredCollections: [DuaCollection] {
      guard !searchQuery.isEmpty else { return collections }
      return collections.filter {
        $0.name.localizedCaseInsensitiveContains(searchQuery) ||
        $0.slug.localizedCaseInsensitiveContains(searchQuery)
      }
    }

    var isEditing: Bool { editingCollection != nil }
  }

  struct CollectionFormInput: Equatable {
    var name: String = ""
    var slug: String = ""
    var description: String = ""
    var isPremium: Bool = false

    var isValid: Bool {
      name.count >= 2 && slug.count >= 2
    }

    mutating func reset() {
      name = ""
      slug = ""
      description = ""
      isPremium = false
    }

    mutating func populate(from collection: DuaCollection) {
      name = collection.name
      slug = collection.slug
      description = collection.description ?? ""
      isPremium = collection.isPremium
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case collectionsLoaded(Result<[DuaCollection], Error>)

    // Form actions
    case addCollectionTapped
    case editCollectionTapped(DuaCollection)
    case formDismissed
    case submitForm
    case formSubmitted(Result<DuaCollection, Error>)

    // Delete actions
    case deleteCollectionTapped(DuaCollection)
    case confirmDelete
    case cancelDelete
    case deleteCompleted(Result<Void, Error>)

    // Message actions
    case clearMessages
  }

  @Dependency(\.adminService) var adminService
  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .onAppear:
        state.isLoading = true
        return .run { send in
          do {
            let collections = try await adminService.fetchAllCollectionsAdmin()
            await send(.collectionsLoaded(.success(collections)))
          } catch {
            await send(.collectionsLoaded(.failure(error)))
          }
        }

      case .collectionsLoaded(.success(let collections)):
        state.isLoading = false
        state.collections = collections
        return .none

      case .collectionsLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearMessages)
        }

      case .addCollectionTapped:
        state.editingCollection = nil
        state.formInput.reset()
        state.isFormPresented = true
        return .none

      case .editCollectionTapped(let collection):
        state.editingCollection = collection
        state.formInput.populate(from: collection)
        state.isFormPresented = true
        return .none

      case .formDismissed:
        state.isFormPresented = false
        state.editingCollection = nil
        state.formInput.reset()
        return .none

      case .submitForm:
        guard state.formInput.isValid else { return .none }
        state.isSaving = true

        let input = CollectionInput(
          name: state.formInput.name,
          slug: state.formInput.slug,
          description: state.formInput.description.isEmpty ? nil : state.formInput.description,
          isPremium: state.formInput.isPremium
        )
        let editingId = state.editingCollection?.id

        return .run { send in
          do {
            let collection: DuaCollection
            if let id = editingId {
              collection = try await adminService.updateCollection(id: id, input: input)
            } else {
              collection = try await adminService.createCollection(input)
            }
            await send(.formSubmitted(.success(collection)))
          } catch {
            await send(.formSubmitted(.failure(error)))
          }
        }

      case .formSubmitted(.success(let collection)):
        state.isSaving = false
        state.isFormPresented = false

        if let index = state.collections.firstIndex(where: { $0.id == collection.id }) {
          state.collections[index] = collection
          state.successMessage = "Collection updated"
        } else {
          state.collections.append(collection)
          state.collections.sort { $0.name < $1.name }
          state.successMessage = "Collection created"
        }

        state.editingCollection = nil
        state.formInput.reset()

        return .run { send in
          try await clock.sleep(for: .seconds(2))
          await send(.clearMessages)
        }

      case .formSubmitted(.failure(let error)):
        state.isSaving = false
        state.errorMessage = error.localizedDescription
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearMessages)
        }

      case .deleteCollectionTapped(let collection):
        state.collectionToDelete = collection
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let collection = state.collectionToDelete else { return .none }
        state.isDeleting = true
        state.isDeleteConfirmationPresented = false

        return .run { send in
          do {
            try await adminService.deleteCollection(id: collection.id)
            await send(.deleteCompleted(.success(())))
          } catch {
            await send(.deleteCompleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.collectionToDelete = nil
        return .none

      case .deleteCompleted(.success):
        state.isDeleting = false
        if let collection = state.collectionToDelete {
          state.collections.removeAll { $0.id == collection.id }
          state.successMessage = "Collection deleted"
        }
        state.collectionToDelete = nil
        return .run { send in
          try await clock.sleep(for: .seconds(2))
          await send(.clearMessages)
        }

      case .deleteCompleted(.failure(let error)):
        state.isDeleting = false
        state.collectionToDelete = nil
        state.errorMessage = error.localizedDescription
        return .run { send in
          try await clock.sleep(for: .seconds(3))
          await send(.clearMessages)
        }

      case .clearMessages:
        state.errorMessage = nil
        state.successMessage = nil
        return .none
      }
    }
  }
}
```

---

## Verification Checklist

### Build Verification

```bash
cd RIZQ-iOS && xcodebuild -scheme RIZQ -destination 'platform=iOS Simulator,name=iPhone 16' build
```

### Manual Testing Checklist

#### Admin Access Gate
- [ ] Non-admin user: "Admin Panel" NOT visible in Settings
- [ ] Admin user: "Admin Panel" row visible in Settings → Administration section

#### Navigation
- [ ] Tap "Admin Panel" → Opens AdminTabView in full screen
- [ ] Tap "Done" in admin → Returns to Settings
- [ ] State is properly cleared on dismiss

#### Dashboard
- [ ] Stats load correctly from database
- [ ] "Manage Duas" → navigates to Duas tab
- [ ] "Manage Journeys" → navigates to Journeys tab
- [ ] "Manage Categories" → navigates to Categories tab

#### Duas Manager
- [ ] List loads duas from Neon
- [ ] Search filters results correctly
- [ ] Create new dua → form validates → appears in list
- [ ] Edit dua → changes persist
- [ ] Delete dua → confirmation → removed from list

#### Journeys Manager
- [ ] List loads journeys from Neon
- [ ] Create/Edit/Delete work correctly
- [ ] "Manage Duas" opens journey dua assignment
- [ ] Can add dua to journey with time slot
- [ ] Can remove dua from journey

#### Categories Manager
- [ ] List loads categories
- [ ] CRUD operations work
- [ ] Color coding matches slug

#### Collections Manager (New)
- [ ] Tab appears in admin navigation
- [ ] List loads collections from Neon
- [ ] Search filters by name and slug
- [ ] Create new collection → validates → appears in list
- [ ] Edit collection → changes persist
- [ ] Premium toggle works
- [ ] Delete empty collection → succeeds
- [ ] Delete collection with duas → fails with message

#### Users Manager
- [ ] List loads users from Firestore
- [ ] Search works for name and userId
- [ ] User detail sheet opens
- [ ] Toggle admin role → confirmation → persists
- [ ] Delete user → confirmation → removed

---

## Risk Considerations

### 1. Admin Role Source

The `isAdmin` flag comes from `UserProfile.isAdmin`, fetched from Firestore via `SettingsFeature.onAppear`. Ensure:
- Profile is loaded before showing Settings
- `isAdmin` field exists in Firestore user_profiles

### 2. Service Configuration

`AdminService` requires Neon credentials. Verify:
- `ServiceContainer.shared.adminService` is properly configured at app launch
- Credentials exist in `Info.plist` (NeonHost, NeonApiKey, NeonProjectId)

### 3. Presentation Style

Using `.fullScreenCover` for admin to:
- Prevent accidental dismissal via swipe
- Provide clear navigation boundary
- Alternative: `.sheet` with `.interactiveDismissDisabled()`

### 4. Collection Deletion

Collections cannot be deleted if duas are assigned. The error message should clearly indicate how many duas need reassignment.

### 5. Data Consistency

When editing collections, ensure the `slug` uniqueness constraint is validated before submission to prevent database errors.

---

## Summary

| Phase | Effort | Files | Description |
|-------|--------|-------|-------------|
| Phase 1 | ~30 min | 4 modified | Wire up admin access from Settings |
| Phase 2 | ~5 min | 1-2 verified | Verify close button works |
| Phase 3 | ~2 hrs | 2 new, 3 modified | Build Collections Manager |

**Total Estimated Effort**: ~2.5-3 hours

---

## Appendix: Admin Tab Structure

```
Admin Panel (AdminTabView)
├── Dashboard Tab
│   └── AdminDashboardView
├── Duas Tab
│   └── AdminDuasView
│       └── DuaFormSheet
├── Journeys Tab
│   └── AdminJourneysView
│       ├── JourneyFormSheet
│       └── JourneyDuasSheet
├── Categories Tab
│   └── AdminCategoriesView
│       └── CategoryFormSheet
├── Collections Tab (NEW)
│   └── AdminCollectionsView
│       └── CollectionFormSheet
└── Users Tab
    └── AdminUsersView
        └── UserDetailSheet
```
