import ComposableArchitecture
import Foundation
import RIZQKit

/// Admin Categories Feature - CRUD operations for categories
@Reducer
struct AdminCategoriesFeature {
  @ObservableState
  struct State: Equatable {
    var categories: [DuaCategory] = []
    var searchQuery: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    var successMessage: String?

    // Form state
    var isFormPresented: Bool = false
    var formMode: FormMode = .create
    var formInput: CategoryInput = CategoryInput()
    var editingCategoryId: Int?
    var isSubmitting: Bool = false
    var formErrors: [String] = []

    // Delete confirmation
    var categoryToDelete: DuaCategory?
    var isDeleteConfirmationPresented: Bool = false

    // Filtered categories based on search
    var filteredCategories: [DuaCategory] {
      guard !searchQuery.isEmpty else { return categories }
      let query = searchQuery.lowercased()
      return categories.filter { category in
        category.name.lowercased().contains(query) ||
        category.slug.rawValue.lowercased().contains(query) ||
        (category.description?.lowercased().contains(query) ?? false)
      }
    }

    enum FormMode: Equatable {
      case create
      case edit
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case loadCategories
    case categoriesLoaded(Result<[DuaCategory], Error>)

    // Form actions
    case createCategoryTapped
    case editCategoryTapped(DuaCategory)
    case cancelForm
    case submitForm
    case formSubmitted(Result<DuaCategory, Error>)

    // Delete actions
    case deleteCategoryTapped(DuaCategory)
    case confirmDelete
    case cancelDelete
    case categoryDeleted(Result<Int, Error>)

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

      case .loadCategories:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            let categories = try await adminService.fetchAllCategoriesAdmin()
            await send(.categoriesLoaded(.success(categories)))
          } catch {
            await send(.categoriesLoaded(.failure(error)))
          }
        }

      case .categoriesLoaded(.success(let categories)):
        state.isLoading = false
        state.categories = categories
        return .none

      case .categoriesLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      // MARK: - Form Actions

      case .createCategoryTapped:
        state.formMode = .create
        state.formInput = CategoryInput()
        state.editingCategoryId = nil
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .editCategoryTapped(let category):
        state.formMode = .edit
        state.formInput = CategoryInput(from: category)
        state.editingCategoryId = category.id
        state.formErrors = []
        state.isFormPresented = true
        return .none

      case .cancelForm:
        state.isFormPresented = false
        state.formInput = CategoryInput()
        state.editingCategoryId = nil
        state.formErrors = []
        return .none

      case .submitForm:
        // Validate
        guard state.formInput.isValid else {
          state.formErrors = ["Name is required"]
          return .none
        }

        state.isSubmitting = true
        let input = state.formInput
        let categoryId = state.editingCategoryId
        let isEditing = state.formMode == .edit

        return .run { send in
          do {
            let category: DuaCategory
            if isEditing, let id = categoryId {
              category = try await adminService.updateCategory(id: id, input: input)
            } else {
              category = try await adminService.createCategory(input)
            }
            await send(.formSubmitted(.success(category)))
          } catch {
            await send(.formSubmitted(.failure(error)))
          }
        }

      case .formSubmitted(.success(let category)):
        state.isSubmitting = false
        state.isFormPresented = false

        // Update list
        if state.formMode == .edit {
          if let index = state.categories.firstIndex(where: { $0.id == category.id }) {
            state.categories[index] = category
          }
          state.successMessage = "Category updated successfully"
        } else {
          state.categories.append(category)
          // Re-sort by name
          state.categories.sort { $0.name < $1.name }
          state.successMessage = "Category created successfully"
        }

        state.formInput = CategoryInput()
        state.editingCategoryId = nil
        return .none

      case .formSubmitted(.failure(let error)):
        state.isSubmitting = false
        state.formErrors = [error.localizedDescription]
        return .none

      // MARK: - Delete Actions

      case .deleteCategoryTapped(let category):
        state.categoryToDelete = category
        state.isDeleteConfirmationPresented = true
        return .none

      case .confirmDelete:
        guard let category = state.categoryToDelete else { return .none }
        state.isDeleteConfirmationPresented = false
        state.isLoading = true

        let categoryId = category.id
        return .run { send in
          do {
            try await adminService.deleteCategory(id: categoryId)
            await send(.categoryDeleted(.success(categoryId)))
          } catch {
            await send(.categoryDeleted(.failure(error)))
          }
        }

      case .cancelDelete:
        state.isDeleteConfirmationPresented = false
        state.categoryToDelete = nil
        return .none

      case .categoryDeleted(.success(let categoryId)):
        state.isLoading = false
        state.categories.removeAll { $0.id == categoryId }
        state.categoryToDelete = nil
        state.successMessage = "Category deleted successfully"
        return .none

      case .categoryDeleted(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        state.categoryToDelete = nil
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
