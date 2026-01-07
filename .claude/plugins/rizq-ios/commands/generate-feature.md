---
name: generate-feature
description: Create a new TCA Feature module from scratch
allowed_tools:
  - Read
  - Write
  - Edit
  - Glob
arguments:
  - name: name
    description: Name of the feature (e.g., "Profile", "Settings")
    required: true
  - name: dependencies
    description: Comma-separated list of dependencies (e.g., "apiClient,authClient")
    required: false
---

# Generate TCA Feature Module

Create a complete TCA Feature module with Reducer, View, and optional Tests.

## Files Created

For feature `{{ name }}`:

```
Features/{{ name }}/
├── {{ name }}Feature.swift   # TCA Reducer
├── {{ name }}View.swift      # SwiftUI View
└── {{ name }}Tests.swift     # Unit tests
```

## Feature Template

### {{ name }}Feature.swift

```swift
import ComposableArchitecture
import Foundation

@Reducer
struct {{ name }}Feature {
  // MARK: - State
  @ObservableState
  struct State: Equatable {
    var isLoading = false
    var errorMessage: String?
    // Add your state properties here
  }

  // MARK: - Action
  enum Action: Equatable {
    // Lifecycle
    case onAppear

    // User Interactions
    // Add your actions here

    // Responses
    // case dataResponse(Result<DataType, Error>)

    // Delegate (for parent communication)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      // Add delegate cases for navigation/parent communication
    }
  }

  // MARK: - Dependencies
  {{ #each dependencies }}
  @Dependency(\.{{ this }}) var {{ this }}
  {{ /each }}

  // MARK: - Reducer Body
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none

      case .delegate:
        return .none
      }
    }
  }
}
```

### {{ name }}View.swift

```swift
import ComposableArchitecture
import SwiftUI

struct {{ name }}View: View {
  @Bindable var store: StoreOf<{{ name }}Feature>

  var body: some View {
    ZStack {
      Color.rizqBackground
        .ignoresSafeArea()
        .islamicPatternBackground()

      if store.isLoading {
        LoadingView()
      } else if let error = store.errorMessage {
        ErrorView(message: error) {
          // Retry action
        }
      } else {
        content
      }
    }
    .task {
      store.send(.onAppear)
    }
  }

  @ViewBuilder
  private var content: some View {
    ScrollView {
      VStack(spacing: RIZQSpacing.lg) {
        // Your content here
      }
      .padding(.horizontal, RIZQSpacing.lg)
      .padding(.bottom, RIZQSpacing.navSafeArea)
    }
  }
}

#Preview {
  {{ name }}View(
    store: Store(initialState: {{ name }}Feature.State()) {
      {{ name }}Feature()
    } withDependencies: {
      // Add preview dependencies
    }
  )
}
```

## Common Dependencies

| Dependency | Purpose |
|------------|---------|
| apiClient | Network requests |
| authClient | Authentication |
| persistenceClient | Local storage |
| hapticsClient | Haptic feedback |
| notificationClient | Push notifications |

## Next Steps

1. Add state properties for your feature's data
2. Define actions for user interactions
3. Implement reducer logic
4. Build out the view content
5. Add to parent feature's navigation
