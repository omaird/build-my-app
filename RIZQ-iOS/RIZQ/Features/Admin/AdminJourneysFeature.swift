import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Journeys Feature - CRUD operations for journeys
@Reducer
struct AdminJourneysFeature {
  @ObservableState
  struct State: Equatable {
    var journeys: [Journey] = []
    var availableDuas: [Dua] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    // Form state
    var isFormPresented: Bool = false
    var formMode: FormMode = .create
    var formInput: JourneyInput = JourneyInput()
    var editingJourneyId: Int?
    var isSubmitting: Bool = false
    var formErrors: [String] = []

    // Journey Duas management
    var selectedJourney: Journey?
    var journeyDuas: [JourneyDua] = []
    var isManagingDuas: Bool = false

    // Delete confirmation
    var journeyToDelete: Journey?
    var isDeleteConfirmationPresented: Bool = false

    // Filtered journeys based on search
    var filteredJourneys: [Journey] {
      guard !searchQuery.isEmpty else { return journeys }
      let query = searchQuery.lowercased()
      return journeys.filter { journey in
        journey.name.lowercased().contains(query) ||
        journey.slug.lowercased().contains(query) ||
        (journey.description?.lowercased().contains(query) ?? false)
      }
    }

    enum FormMode: Equatable {
      case create
      case edit
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case loadJourneys
    case journeysLoaded(Result<[Journey], Error>)
    case duasLoaded(Result<[Dua], Error>)

    // Form actions
    case createJourneyTapped
    case editJourneyTapped(Journey)
    case cancelForm
    case generateSlug
    case submitForm
    case formSubmitted(Result<Journey, Error>)

    // Journey Duas management
    case manageDuasTapped(Journey)
    case closeDuasManager
    case journeyDuasLoaded(Result<[JourneyDua], Error>)
    case addDuaToJourney(Dua, TimeSlot)
    case removeDuaFromJourney(Int)
    case duaAddedToJourney(Result<Void, Error>)
    case duaRemovedFromJourney(Result<Int, Error>)

    // Delete actions
    case deleteJourneyTapped(Journey)
    case confirmDelete
    case cancelDelete
    case journeyDeleted(Result<Int, Error>)

    // Messages
    case dismissError
    case dismissSuccess
  }

  @Dependency(\.adminService) var adminService

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        return .none

      case .loadJourneys:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          async let journeysResult = adminService.fetchAllJourneysAdmin()
          async let duasResult = adminService.fetchAllDuasAdmin()

          do {
            let journeys = try await journeysResult
            await send(.journeysLoaded(.success(journeys)))
          } catch {
            await send(.journeysLoaded(.failure(error)))
          }

          do {
            let duas = try await duasResult
            await send(.duasLoaded(.success(duas)))
          } catch {
            await send(.duasLoaded(.failure(error)))
          }
        }

      case .journeysLoaded(.success(let journeys)):
        state.isLoading = false
        state.journeys = journeys
        return .none

      case .journeysLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .duasLoaded(.success(let duas)):
        state.availableDuas = duas
        return .none

      case .duasLoaded(.failure):
        // Silently handle dua loading failure
        return .none

      // MARK: - Form Actions

      case .createJourneyTapped:
        state.formMode = .create
        state.formInput = JourneyInput()
        state.editingJourneyId = nil
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .editJourneyTapped(let journey):
        state.formMode = .edit
        state.formInput = JourneyInput(from: journey)
        state.editingJourneyId = journey.id
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .cancelForm:
        state.isFormPresented = false
        state.formInput = JourneyInput()
        state.editingJourneyId = nil
        state.formErrors = []
        return .none

      case .generateSlug:
        state.formInput.generateSlug()
        return .none

      case .submitForm:
        // Validate
        state.formErrors = state.formInput.validationErrors
        guard state.formInput.isValid else {
          return .none
        }

        state.isSubmitting = true
        let input = state.formInput
        let journeyId = state.editingJourneyId
        let isEditing = state.formMode == .edit

        return .run { send in
          do {
            let journey: Journey
            if isEditing, let id = journeyId {
              journey = try await adminService.updateJourney(id: id, input: input)
            } else {
              journey = try await adminService.createJourney(input)
            }
            await send(.formSubmitted(.success(journey)))
          } catch {
            await send(.formSubmitted(.failure(error)))
          }
        }

      case .formSubmitted(.success(let journey)):
        state.isSubmitting = false
        state.isFormPresented = false

        // Update list
        if state.formMode == .edit {
          if let index = state.journeys.firstIndex(where: { $0.id == journey.id }) {
            state.journeys[index] = journey
          }
          state.successMessage = "Journey updated successfully"
        } else {
          state.journeys.append(journey)
          // Re-sort by sort_order
          state.journeys.sort { $0.sortOrder < $1.sortOrder }
          state.successMessage = "Journey created successfully"
        }

        state.formInput = JourneyInput()
        state.editingJourneyId = nil
        return .none

      case .formSubmitted(.failure(let error)):
        state.isSubmitting = false
        state.formErrors = [error.localizedDescription]
        return .none

      // MARK: - Journey Duas Management

      case .manageDuasTapped(let journey):
        state.selectedJourney = journey
        state.isManagingDuas = true
        return .run { send in
          do {
            let journeyDuas = try await adminService.fetchJourneyDuasAdmin(journeyId: journey.id)
            await send(.journeyDuasLoaded(.success(journeyDuas)))
          } catch {
            await send(.journeyDuasLoaded(.failure(error)))
          }
        }

      case .closeDuasManager:
        state.isManagingDuas = false
        state.selectedJourney = nil
        state.journeyDuas = []
        return .none

      case .journeyDuasLoaded(.success(let journeyDuas)):
        state.journeyDuas = journeyDuas
        return .none

      case .journeyDuasLoaded(.failure(let error)):
        state.errorMessage = error.localizedDescription
        return .none

      case .addDuaToJourney(let dua, let timeSlot):
        guard let journey = state.selectedJourney else { return .none }

        // Check if already added
        guard !state.journeyDuas.contains(where: { $0.duaId == dua.id }) else { return .none }

        let sortOrder = state.journeyDuas.count
        let journeyId = journey.id
        let duaId = dua.id

        return .run { send in
          do {
            try await adminService.addDuaToJourney(
              journeyId: journeyId,
              duaId: duaId,
              timeSlot: timeSlot,
              sortOrder: sortOrder
            )
            await send(.duaAddedToJourney(.success(())))
          } catch {
            await send(.duaAddedToJourney(.failure(error)))
          }
        }

      case .removeDuaFromJourney(let duaId):
        guard let journey = state.selectedJourney else { return .none }

        let journeyId = journey.id

        return .run { send in
          do {
            try await adminService.removeDuaFromJourney(journeyId: journeyId, duaId: duaId)
            await send(.duaRemovedFromJourney(.success(duaId)))
          } catch {
            await send(.duaRemovedFromJourney(.failure(error)))
          }
        }

      case .duaAddedToJourney(.success):
        // Reload journey duas
        guard let journey = state.selectedJourney else { return .none }
        return .run { send in
          do {
            let journeyDuas = try await adminService.fetchJourneyDuasAdmin(journeyId: journey.id)
            await send(.journeyDuasLoaded(.success(journeyDuas)))
          } catch {
            await send(.journeyDuasLoaded(.failure(error)))
          }
        }

      case .duaAddedToJourney(.failure(let error)):
        state.errorMessage = error.localizedDescription
        return .none

      case .duaRemovedFromJourney(.success(let duaId)):
        state.journeyDuas.removeAll { $0.duaId == duaId }
        state.successMessage = "Dua removed from journey"
        return .none

      case .duaRemovedFromJourney(.failure(let error)):
        state.errorMessage = error.localizedDescription
        return .none

      // MARK: - Delete Actions

      case .deleteJourneyTapped(let journey):
        state.journeyToDelete = journey
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let journey = state.journeyToDelete else { return .none }
        state.isDeleteConfirmationPresented = false
        state.isLoading = true

        let journeyId = journey.id
        return .run { send in
          do {
            try await adminService.deleteJourney(id: journeyId)
            await send(.journeyDeleted(.success(journeyId)))
          } catch {
            await send(.journeyDeleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.journeyToDelete = nil
        return .none

      case .journeyDeleted(.success(let journeyId)):
        state.isLoading = false
        state.journeys.removeAll { $0.id == journeyId }
        state.journeyToDelete = nil
        state.successMessage = "Journey deleted successfully"
        return .none

      case .journeyDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.journeyToDelete = nil
        return .none

      // MARK: - Messages

      case .dismissError:
        state.errorMessage = nil
        return .none

      case .dismissSuccess:
        state.successMessage = nil
        return .none
      }
    }
  }
}
