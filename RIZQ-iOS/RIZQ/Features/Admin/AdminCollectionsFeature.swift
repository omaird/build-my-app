import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Collections Feature - CRUD operations for collections
@Reducer
struct AdminCollectionsFeature {
  @ObservableState
  struct State: Equatable {
    var collections: [DuaCollection] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    // Form state
    var isFormPresented: Bool = false
    var formMode: FormMode = .create
    var formInput: CollectionInput = CollectionInput()
    var editingCollectionId: Int?
    var isSubmitting: Bool = false
    var formErrors: [String] = []

    // Delete confirmation
    var collectionToDelete: DuaCollection?
    var isDeleteConfirmationPresented: Bool = false

    // Filtered collections based on search
    var filteredCollections: [DuaCollection] {
      guard !searchQuery.isEmpty else { return collections }
      let query = searchQuery.lowercased()
      return collections.filter { collection in
        collection.name.lowercased().contains(query) ||
        collection.slug.lowercased().contains(query)
      }
    }

    enum FormMode: Equatable {
      case create
      case edit
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case loadCollections
    case collectionsLoaded(Result<[DuaCollection], Error>)

    // Form actions
    case createCollectionTapped
    case editCollectionTapped(DuaCollection)
    case cancelForm
    case submitForm
    case formSubmitted(Result<DuaCollection, Error>)

    // Delete actions
    case deleteCollectionTapped(DuaCollection)
    case confirmDelete
    case cancelDelete
    case collectionDeleted(Result<Int, Error>)

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

      case .loadCollections:
        state.isLoading = true
        state.errorMessage = nil
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
        return .none

      // MARK: - Form Actions

      case .createCollectionTapped:
        state.formMode = .create
        state.formInput = CollectionInput()
        state.editingCollectionId = nil
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .editCollectionTapped(let collection):
        state.formMode = .edit
        state.formInput = CollectionInput(from: collection)
        state.editingCollectionId = collection.id
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .cancelForm:
        state.isFormPresented = false
        state.formInput = CollectionInput()
        state.editingCollectionId = nil
        state.formErrors = []
        return .none

      case .submitForm:
        // Validate
        guard state.formInput.isValid else {
          state.formErrors = state.formInput.validationErrors
          return .none
        }

        state.isSubmitting = true
        let input = state.formInput
        let collectionId = state.editingCollectionId
        let isEditing = state.formMode == .edit

        return .run { send in
          do {
            let collection: DuaCollection
            if isEditing, let id = collectionId {
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
        state.isSubmitting = false
        state.isFormPresented = false

        // Update list
        if state.formMode == .edit {
          if let index = state.collections.firstIndex(where: { $0.id == collection.id }) {
            state.collections[index] = collection
          }
          state.successMessage = "Collection updated successfully"
        } else {
          state.collections.append(collection)
          // Re-sort by name
          state.collections.sort { $0.name < $1.name }
          state.successMessage = "Collection created successfully"
        }

        state.formInput = CollectionInput()
        state.editingCollectionId = nil
        return .none

      case .formSubmitted(.failure(let error)):
        state.isSubmitting = false
        state.formErrors = [error.localizedDescription]
        return .none

      // MARK: - Delete Actions

      case .deleteCollectionTapped(let collection):
        state.collectionToDelete = collection
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let collection = state.collectionToDelete else { return .none }
        state.isDeleteConfirmationPresented = false
        state.isLoading = true

        let collectionId = collection.id
        return .run { send in
          do {
            try await adminService.deleteCollection(id: collectionId)
            await send(.collectionDeleted(.success(collectionId)))
          } catch {
            await send(.collectionDeleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.collectionToDelete = nil
        return .none

      case .collectionDeleted(.success(let collectionId)):
        state.isLoading = false
        state.collections.removeAll { $0.id == collectionId }
        state.collectionToDelete = nil
        state.successMessage = "Collection deleted successfully"
        return .none

      case .collectionDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.collectionToDelete = nil
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
