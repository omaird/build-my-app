import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct PracticeFeature {
  @ObservableState
  struct State: Equatable {
    // User ID for persisting XP (set by parent feature)
    var userId: String?

    var dua: Dua?
    var currentCount: Int = 0
    var targetCount: Int = 1
    var showCelebration: Bool = false
    var isCompleted: Bool = false
    var selectedTab: ContextTab = .practice
    var showTransliteration: Bool = true
    var alreadyCompletedToday: Bool = false

    // XP persistence state
    var isSavingCompletion: Bool = false
    var xpEarned: Int = 0

    // Computed properties
    var progress: Double {
      guard targetCount > 0 else { return 0 }
      return min(Double(currentCount) / Double(targetCount), 1.0)
    }

    var canTap: Bool {
      !isCompleted && !alreadyCompletedToday
    }

    var hasContext: Bool {
      guard let dua = dua else { return false }
      return dua.source != nil ||
             dua.rizqBenefit != nil ||
             dua.propheticContext != nil
    }
  }

  enum ContextTab: String, CaseIterable, Identifiable {
    case practice
    case context

    var id: String { rawValue }

    var title: String {
      switch self {
      case .practice: return "Practice"
      case .context: return "Context"
      }
    }

    var icon: String {
      switch self {
      case .practice: return "book.fill"
      case .context: return "info.circle.fill"
      }
    }
  }

  enum Action: Equatable {
    case onAppear
    case setDua(Dua)
    case setUserId(String?)
    case incrementCounter
    case decrementCounter
    case resetCounter
    case completionReached
    case completionSaved(UserProfile)
    case completionSaveFailed(String)
    case dismissCelebration
    case tabSelected(ContextTab)
    case toggleTransliteration
    case navigateBack
    case navigateToNext

    // Delegate action for parent to listen to
    case delegate(Delegate)

    enum Delegate: Equatable {
      case duaCompleted(duaId: Int, xpEarned: Int)
      case profileUpdated(UserProfile)
    }
  }

  @Dependency(\.continuousClock) var clock
  @Dependency(\.haptics) var haptics
  @Dependency(\.firestoreUserClient) var userClient

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Reset state when appearing
        return .none

      case .setDua(let dua):
        state.dua = dua
        state.targetCount = dua.repetitions
        state.currentCount = 0
        state.isCompleted = false
        state.showCelebration = false
        state.selectedTab = .practice
        state.xpEarned = 0
        return .none

      case .setUserId(let userId):
        state.userId = userId
        return .none

      case .incrementCounter:
        guard state.canTap else { return .none }

        state.currentCount += 1

        // Check if completed
        if state.currentCount >= state.targetCount {
          // Trigger completion haptic
          return .run { send in
            await send(.completionReached)
          }
        }

        // Trigger counter tap haptic
        return .run { _ in
          haptics.counterIncrement()
        }

      case .decrementCounter:
        guard state.currentCount > 0 else { return .none }
        state.currentCount -= 1
        return .run { _ in
          haptics.lightTap()
        }

      case .resetCounter:
        state.currentCount = 0
        state.isCompleted = false
        state.showCelebration = false
        state.xpEarned = 0
        return .run { _ in
          haptics.warning()
        }

      case .completionReached:
        state.isCompleted = true
        state.showCelebration = true

        guard let dua = state.dua else {
          // Trigger celebration even without dua
          return .run { _ in
            haptics.counterComplete()
            try? await clock.sleep(for: .milliseconds(300))
            haptics.celebration()
          }
        }

        let xp = dua.xpValue
        state.xpEarned = xp

        // Persist XP if we have a user ID
        guard let userId = state.userId else {
          // No user ID, just trigger celebration haptics
          return .run { send in
            haptics.counterComplete()
            try? await clock.sleep(for: .milliseconds(300))
            haptics.celebration()
            // Still notify delegate even without persistence
            await send(.delegate(.duaCompleted(duaId: dua.id, xpEarned: xp)))
          }
        }

        state.isSavingCompletion = true

        return .run { [userId, duaId = dua.id, xp] send in
          // Trigger celebration haptics immediately
          haptics.counterComplete()
          try? await clock.sleep(for: .milliseconds(300))
          haptics.celebration()

          // Persist completion to Firestore using recordPracticeCompletion
          // This atomically updates user_activity, user_progress, AND user_profiles.totalXp
          do {
            let updatedProfile = try await userClient.recordPracticeCompletion(userId, duaId, xp)
            await send(.completionSaved(updatedProfile))
            await send(.delegate(.duaCompleted(duaId: duaId, xpEarned: xp)))
            await send(.delegate(.profileUpdated(updatedProfile)))
          } catch {
            await send(.completionSaveFailed(error.localizedDescription))
            // Still notify delegate of completion even if save failed
            await send(.delegate(.duaCompleted(duaId: duaId, xpEarned: xp)))
          }
        }

      case .completionSaved(let profile):
        state.isSavingCompletion = false
        // Profile updated successfully - parent will be notified via delegate
        return .none

      case .completionSaveFailed(let error):
        state.isSavingCompletion = false
        // Log error but don't show to user - completion still counts locally
        print("[PracticeFeature] Failed to save completion: \(error)")
        return .none

      case .dismissCelebration:
        state.showCelebration = false
        return .none

      case .tabSelected(let tab):
        // Only allow context tab if there's context to show
        if tab == .context && !state.hasContext {
          return .none
        }
        state.selectedTab = tab
        return .run { _ in
          haptics.tabSwitch()
        }

      case .toggleTransliteration:
        state.showTransliteration.toggle()
        return .run { _ in
          haptics.selection()
        }

      case .navigateBack, .navigateToNext:
        // Handled by parent feature
        return .none

      case .delegate:
        // Delegate actions are handled by parent feature
        return .none
      }
    }
  }
}

// MARK: - Sample Data for Previews

extension PracticeFeature.State {
  static var preview: Self {
    var state = Self()
    state.dua = SampleData.duas.first
    state.targetCount = state.dua?.repetitions ?? 3
    return state
  }

  static var previewCompleted: Self {
    var state = Self()
    state.dua = SampleData.duas.first
    state.targetCount = state.dua?.repetitions ?? 3
    state.currentCount = state.targetCount
    state.isCompleted = true
    return state
  }
}
