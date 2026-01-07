import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Duas Feature - CRUD operations for duas
@Reducer
struct AdminDuasFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var categories: [DuaCategory] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    // Form state
    var isFormPresented: Bool = false
    var formMode: FormMode = .create
    var formInput: DuaInput = DuaInput()
    var editingDuaId: Int?
    var isSubmitting: Bool = false
    var formErrors: [String] = []

    // Delete confirmation
    var duaToDelete: Dua?
    var isDeleteConfirmationPresented: Bool = false

    // Filtered duas based on search
    var filteredDuas: [Dua] {
      guard !searchQuery.isEmpty else { return duas }
      let query = searchQuery.lowercased()
      return duas.filter { dua in
        dua.titleEn.lowercased().contains(query) ||
        dua.arabicText.contains(searchQuery) ||
        (dua.transliteration?.lowercased().contains(query) ?? false)
      }
    }

    enum FormMode: Equatable {
      case create
      case edit
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case loadDuas
    case duasLoaded(Result<[Dua], Error>)
    case categoriesLoaded(Result<[DuaCategory], Error>)

    // Form actions
    case createDuaTapped
    case editDuaTapped(Dua)
    case cancelForm
    case submitForm
    case formSubmitted(Result<Dua, Error>)

    // Delete actions
    case deleteDuaTapped(Dua)
    case confirmDelete
    case cancelDelete
    case duaDeleted(Result<Int, Error>)

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

      case .loadDuas:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          async let duasResult = adminService.fetchAllDuasAdmin()
          async let categoriesResult = adminService.fetchAllCategoriesAdmin()

          do {
            let duas = try await duasResult
            await send(.duasLoaded(.success(duas)))
          } catch {
            await send(.duasLoaded(.failure(error)))
          }

          do {
            let categories = try await categoriesResult
            await send(.categoriesLoaded(.success(categories)))
          } catch {
            await send(.categoriesLoaded(.failure(error)))
          }
        }

      case .duasLoaded(.success(let duas)):
        state.isLoading = false
        state.duas = duas
        return .none

      case .duasLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .categoriesLoaded(.success(let categories)):
        state.categories = categories
        return .none

      case .categoriesLoaded(.failure):
        // Silently handle category loading failure
        return .none

      // MARK: - Form Actions

      case .createDuaTapped:
        state.formMode = .create
        state.formInput = DuaInput()
        state.editingDuaId = nil
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .editDuaTapped(let dua):
        state.formMode = .edit
        state.formInput = DuaInput(from: dua)
        state.editingDuaId = dua.id
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .cancelForm:
        state.isFormPresented = false
        state.formInput = DuaInput()
        state.editingDuaId = nil
        state.formErrors = []
        return .none

      case .submitForm:
        // Validate
        state.formErrors = state.formInput.validationErrors
        guard state.formInput.isValid else {
          return .none
        }

        state.isSubmitting = true
        let input = state.formInput
        let duaId = state.editingDuaId
        let isEditing = state.formMode == .edit

        return .run { send in
          do {
            let dua: Dua
            if isEditing, let id = duaId {
              dua = try await adminService.updateDua(id: id, input: input)
            } else {
              dua = try await adminService.createDua(input)
            }
            await send(.formSubmitted(.success(dua)))
          } catch {
            await send(.formSubmitted(.failure(error)))
          }
        }

      case .formSubmitted(.success(let dua)):
        state.isSubmitting = false
        state.isFormPresented = false

        // Update list
        if state.formMode == .edit {
          if let index = state.duas.firstIndex(where: { $0.id == dua.id }) {
            state.duas[index] = dua
          }
          state.successMessage = "Dua updated successfully"
        } else {
          state.duas.insert(dua, at: 0)
          state.successMessage = "Dua created successfully"
        }

        state.formInput = DuaInput()
        state.editingDuaId = nil
        return .none

      case .formSubmitted(.failure(let error)):
        state.isSubmitting = false
        state.formErrors = [error.localizedDescription]
        return .none

      // MARK: - Delete Actions

      case .deleteDuaTapped(let dua):
        state.duaToDelete = dua
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let dua = state.duaToDelete else { return .none }
        state.isDeleteConfirmationPresented = false
        state.isLoading = true

        let duaId = dua.id
        return .run { send in
          do {
            try await adminService.deleteDua(id: duaId)
            await send(.duaDeleted(.success(duaId)))
          } catch {
            await send(.duaDeleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.duaToDelete = nil
        return .none

      case .duaDeleted(.success(let duaId)):
        state.isLoading = false
        state.duas.removeAll { $0.id == duaId }
        state.duaToDelete = nil
        state.successMessage = "Dua deleted successfully"
        return .none

      case .duaDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.duaToDelete = nil
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
