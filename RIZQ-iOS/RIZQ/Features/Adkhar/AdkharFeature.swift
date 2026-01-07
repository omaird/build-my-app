import ComposableArchitecture
import Foundation
import SwiftUI
import RIZQKit

// MARK: - Adkhar Feature
@Reducer
struct AdkharFeature {
  @ObservableState
  struct State: Equatable {
    var morningHabits: [Habit] = []
    var anytimeHabits: [Habit] = []
    var eveningHabits: [Habit] = []
    var completedIds: Set<Int> = []
    var isLoading: Bool = false
    var streak: Int = 0

    // Quick Practice Sheet State
    var selectedHabit: Habit?
    var showQuickPractice: Bool = false
    var repetitionCount: Int = 0
    var showCelebration: Bool = false

    // Computed properties
    var totalHabits: Int {
      morningHabits.count + anytimeHabits.count + eveningHabits.count
    }

    var completedCount: Int {
      completedIds.count
    }

    var progressPercentage: Double {
      guard totalHabits > 0 else { return 0 }
      return Double(completedCount) / Double(totalHabits)
    }

    var totalXpAvailable: Int {
      (morningHabits + anytimeHabits + eveningHabits).reduce(0) { $0 + $1.xpValue }
    }

    var earnedXp: Int {
      (morningHabits + anytimeHabits + eveningHabits)
        .filter { completedIds.contains($0.id) }
        .reduce(0) { $0 + $1.xpValue }
    }

    // Progress by time slot - computed properties for TCA binding compatibility
    var morningProgress: TimeSlotProgress {
      let completed = morningHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .morning, completed: completed, total: morningHabits.count)
    }

    var anytimeProgress: TimeSlotProgress {
      let completed = anytimeHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .anytime, completed: completed, total: anytimeHabits.count)
    }

    var eveningProgress: TimeSlotProgress {
      let completed = eveningHabits.filter { completedIds.contains($0.id) }.count
      return TimeSlotProgress(slot: .evening, completed: completed, total: eveningHabits.count)
    }

    func isCompleted(_ habitId: Int) -> Bool {
      completedIds.contains(habitId)
    }

    // Quick practice progress
    var quickPracticeProgress: Double {
      guard let habit = selectedHabit, habit.repetitions > 0 else { return 0 }
      return min(Double(repetitionCount) / Double(habit.repetitions), 1.0)
    }

    var isQuickPracticeComplete: Bool {
      guard let habit = selectedHabit else { return false }
      return repetitionCount >= habit.repetitions || isCompleted(habit.id)
    }
  }

  enum Action {
    case onAppear
    case habitsLoaded(morning: [Habit], anytime: [Habit], evening: [Habit])
    case streakLoaded(Int)
    case toggleHabit(Habit)
    case habitCompleted(Habit)

    // Quick Practice Actions
    case quickPracticeRequested(Habit)
    case quickPracticeDismissed
    case setShowQuickPractice(Bool)
    case incrementRepetition
    case resetRepetitions
    case practiceCompleted
    case celebrationFinished
  }

  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.isLoading = true
        // Simulate loading habits for now
        return .run { send in
          // TODO: Load habits from journeys and custom habits via API
          try await Task.sleep(for: .milliseconds(500))

          // Demo data
          let morningHabits = [
            Habit(
              id: 1,
              duaId: 101,
              titleEn: "Morning Remembrance",
              arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
              transliteration: "Asbahna wa asbahal mulku lillah",
              translation: "We have reached the morning and at this very time unto Allah belongs all sovereignty",
              source: "Muslim",
              rizqBenefit: "Protection throughout the day",
              propheticContext: "The Prophet (PBUH) would say this every morning",
              timeSlot: .morning,
              xpValue: 10,
              repetitions: 3
            ),
            Habit(
              id: 2,
              duaId: 102,
              titleEn: "Seeking Refuge",
              arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
              transliteration: "A'udhu billahi minash shaytanir rajim",
              translation: "I seek refuge in Allah from the accursed devil",
              source: "Bukhari & Muslim",
              rizqBenefit: "Protection from evil",
              propheticContext: nil,
              timeSlot: .morning,
              xpValue: 5,
              repetitions: 1
            )
          ]

          let anytimeHabits = [
            Habit(
              id: 3,
              duaId: 103,
              titleEn: "Istighfar",
              arabicText: "أَسْتَغْفِرُ اللَّهَ",
              transliteration: "Astaghfirullah",
              translation: "I seek forgiveness from Allah",
              source: "Various",
              rizqBenefit: "Opens doors of provision and mercy",
              propheticContext: "The Prophet (PBUH) used to seek forgiveness 100 times a day",
              timeSlot: .anytime,
              xpValue: 15,
              repetitions: 100
            )
          ]

          let eveningHabits = [
            Habit(
              id: 4,
              duaId: 104,
              titleEn: "Evening Protection",
              arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
              transliteration: "Amsayna wa amsal mulku lillah",
              translation: "We have reached the evening and at this very time unto Allah belongs all sovereignty",
              source: "Muslim",
              rizqBenefit: "Protection throughout the night",
              propheticContext: nil,
              timeSlot: .evening,
              xpValue: 10,
              repetitions: 3
            )
          ]

          await send(.habitsLoaded(morning: morningHabits, anytime: anytimeHabits, evening: eveningHabits))
          await send(.streakLoaded(7))
        }

      case .habitsLoaded(let morning, let anytime, let evening):
        state.isLoading = false
        state.morningHabits = morning
        state.anytimeHabits = anytime
        state.eveningHabits = evening
        return .none

      case .streakLoaded(let streak):
        state.streak = streak
        return .none

      case .toggleHabit(let habit):
        if state.completedIds.contains(habit.id) {
          state.completedIds.remove(habit.id)
        } else {
          state.completedIds.insert(habit.id)
          return .send(.habitCompleted(habit))
        }
        return .none

      case .habitCompleted:
        // TODO: Award XP, update streak via API
        return .none

      case .quickPracticeRequested(let habit):
        state.selectedHabit = habit
        state.repetitionCount = 0
        state.showCelebration = false
        state.showQuickPractice = true
        return .none

      case .quickPracticeDismissed:
        state.showQuickPractice = false
        // Clear selected habit after animation
        return .run { send in
          try await Task.sleep(for: .milliseconds(300))
          // Note: We don't clear selectedHabit to preserve UI during dismiss animation
        }

      case .setShowQuickPractice(let show):
        state.showQuickPractice = show
        if !show {
          // Same cleanup as quickPracticeDismissed
          return .run { _ in
            try await Task.sleep(for: .milliseconds(300))
          }
        }
        return .none

      case .incrementRepetition:
        guard let habit = state.selectedHabit else { return .none }
        guard !state.isCompleted(habit.id) else { return .none }

        state.repetitionCount += 1

        // Check if completed all repetitions
        if state.repetitionCount >= habit.repetitions {
          state.showCelebration = true
          state.completedIds.insert(habit.id)

          return .run { send in
            try await Task.sleep(for: .milliseconds(1500))
            await send(.celebrationFinished)
          }
        }
        return .none

      case .resetRepetitions:
        state.repetitionCount = 0
        return .none

      case .practiceCompleted:
        guard let habit = state.selectedHabit else { return .none }
        state.completedIds.insert(habit.id)
        return .send(.habitCompleted(habit))

      case .celebrationFinished:
        state.showQuickPractice = false
        return .none
      }
    }
  }
}

// MARK: - Habit Model
struct Habit: Equatable, Identifiable {
  let id: Int
  let duaId: Int
  let titleEn: String
  let arabicText: String
  let transliteration: String?
  let translation: String
  let source: String?
  let rizqBenefit: String?
  let propheticContext: String?
  let timeSlot: TimeSlot
  let xpValue: Int
  let repetitions: Int
}

// MARK: - Greeting Helper
func getGreeting() -> String {
  let hour = Calendar.current.component(.hour, from: Date())
  if hour < 12 {
    return "Good Morning"
  } else if hour < 17 {
    return "Assalamu Alaikum"
  } else {
    return "Good Evening"
  }
}
