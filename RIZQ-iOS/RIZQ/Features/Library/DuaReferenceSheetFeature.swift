import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - Dua Reference Sheet Feature

/// A read-only educational view for browsing dua details in the Library.
/// Unlike PracticeSheet, this has no counter, no XP tracking - purely reference.
@Reducer
struct DuaReferenceSheetFeature {
  @ObservableState
  struct State: Equatable {
    let dua: Dua

    @Presents var addToAdkharSheet: AddToAdkharSheetFeature.State?

    /// Whether this dua is already in the user's daily adkhar
    var isAlreadyInAdkhar: Bool = false
  }

  enum Action {
    case addToAdkharTapped
    case closeTapped
    case addToAdkharSheet(PresentationAction<AddToAdkharSheetFeature.Action>)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case duaAddedToAdkhar(duaId: Int, timeSlot: TimeSlot)
    }
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .addToAdkharTapped:
        state.addToAdkharSheet = AddToAdkharSheetFeature.State(dua: state.dua)
        return .none

      case .closeTapped:
        return .run { _ in await dismiss() }

      case .addToAdkharSheet(.presented(.delegate(.habitAdded(let duaId, let timeSlot)))):
        state.isAlreadyInAdkhar = true
        return .send(.delegate(.duaAddedToAdkhar(duaId: duaId, timeSlot: timeSlot)))

      case .addToAdkharSheet:
        return .none

      case .delegate:
        return .none
      }
    }
    .ifLet(\.$addToAdkharSheet, action: \.addToAdkharSheet) {
      AddToAdkharSheetFeature()
    }
  }
}
