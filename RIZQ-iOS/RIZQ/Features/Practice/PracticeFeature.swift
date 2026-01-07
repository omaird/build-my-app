import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct PracticeFeature {
  @ObservableState
  struct State: Equatable {
    var dua: Dua?
    var currentCount: Int = 0
    var targetCount: Int = 1
    var showCelebration: Bool = false
    var isCompleted: Bool = false
    var selectedTab: ContextTab = .practice
    var showTransliteration: Bool = true
    var alreadyCompletedToday: Bool = false

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
             dua.propheticContext != nil ||
             dua.context != nil
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
    case incrementCounter
    case decrementCounter
    case resetCounter
    case completionReached
    case dismissCelebration
    case tabSelected(ContextTab)
    case toggleTransliteration
    case navigateBack
    case navigateToNext
  }

  @Dependency(\.continuousClock) var clock

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
        return .none

      case .incrementCounter:
        guard state.canTap else { return .none }

        state.currentCount += 1

        // Check if completed
        if state.currentCount >= state.targetCount {
          return .send(.completionReached)
        }
        return .none

      case .decrementCounter:
        guard state.currentCount > 0 else { return .none }
        state.currentCount -= 1
        return .none

      case .resetCounter:
        state.currentCount = 0
        state.isCompleted = false
        state.showCelebration = false
        return .none

      case .completionReached:
        state.isCompleted = true
        state.showCelebration = true
        // TODO: In Phase 5+, integrate with activity tracking
        // markActivityCompleted, markProgressCompleted, markHabitCompleted
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
        return .none

      case .toggleTransliteration:
        state.showTransliteration.toggle()
        return .none

      case .navigateBack, .navigateToNext:
        // Handled by parent feature
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
