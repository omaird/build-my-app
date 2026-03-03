import ComposableArchitecture
import Foundation
import RIZQKit

@Reducer
struct JourneyDetailFeature {
  @ObservableState
  struct State: Equatable {
    var journeyWithDuas: JourneyWithDuas
    var isSubscribed: Bool
    var activeJourneysCount: Int
    var isLoading: Bool = false
    @Presents var practice: PracticeFeature.State?

    var journey: Journey {
      journeyWithDuas.journey
    }

    var duas: [JourneyDuaFull] {
      journeyWithDuas.duas
    }

    var duasByTimeSlot: [TimeSlot: [JourneyDuaFull]] {
      journeyWithDuas.duasByTimeSlot
    }

    var totalXp: Int {
      duas.reduce(0) { $0 + $1.dua.xpValue }
    }

    var morningDuas: [JourneyDuaFull] {
      duasByTimeSlot[.morning] ?? []
    }

    var anytimeDuas: [JourneyDuaFull] {
      duasByTimeSlot[.anytime] ?? []
    }

    var eveningDuas: [JourneyDuaFull] {
      duasByTimeSlot[.evening] ?? []
    }
  }

  enum Action {
    case onAppear
    case duasLoaded([JourneyDuaFull])
    case subscribeToggled
    case duaTapped(Dua)
    case practice(PresentationAction<PracticeFeature.Action>)
    case dismiss
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Duas are already loaded from the parent
        return .none

      case .duasLoaded(let duas):
        state.isLoading = false
        state.journeyWithDuas = JourneyWithDuas(
          journey: state.journey,
          duas: duas
        )
        return .none

      case .subscribeToggled:
        // Handled by parent reducer
        return .none

      case .duaTapped(let dua):
        state.practice = PracticeFeature.State(dua: dua, targetCount: dua.repetitions)
        return .none

      case .practice(.presented(.navigateBack)):
        state.practice = nil
        return .none

      case .practice(.presented(.navigateToNext)):
        state.practice = nil
        return .none

      case .practice:
        return .none

      case .dismiss:
        return .none
      }
    }
    .ifLet(\.$practice, action: \.practice) {
      PracticeFeature()
    }
  }
}
