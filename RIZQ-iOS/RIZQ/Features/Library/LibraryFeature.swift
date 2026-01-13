import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - Category Display Model (matches React design)

/// Category display model for UI with emoji support
struct CategoryDisplay: Equatable, Identifiable {
  let slug: CategorySlug?  // nil = "All"
  let name: String
  let emoji: String

  var id: String { slug?.rawValue ?? "all" }

  /// SF Symbol icon for the category (used in badges)
  var icon: String {
    switch slug {
    case .morning: return "sun.max.fill"
    case .evening: return "moon.fill"
    case .rizq: return "sparkles"
    case .gratitude: return "heart.fill"
    case nil: return "square.grid.2x2"
    }
  }

  /// All categories including "All" option (matches React emojis)
  static let allCategories: [CategoryDisplay] = [
    CategoryDisplay(slug: nil, name: "All", emoji: "📿"),
    CategoryDisplay(slug: .morning, name: "Morning", emoji: "🌅"),
    CategoryDisplay(slug: .evening, name: "Evening", emoji: "🌙"),
    CategoryDisplay(slug: .rizq, name: "Rizq", emoji: "💫"),
    CategoryDisplay(slug: .gratitude, name: "Gratitude", emoji: "🤲"),
  ]

  /// Get display for a specific slug
  static func display(for slug: CategorySlug?) -> CategoryDisplay {
    allCategories.first { $0.slug == slug } ?? allCategories[0]
  }
}

// MARK: - Library Feature

@Reducer
struct LibraryFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var allDuas: [Dua] = []  // Cache of all duas for filtering
    var categories: [CategoryDisplay] = CategoryDisplay.allCategories
    var searchText: String = ""
    var selectedCategory: CategorySlug?
    var isLoading: Bool = false
    var errorMessage: String?
    var activeHabitDuaIds: Set<Int> = []   // Track which duas are in user's habits
    var userId: String?

    // Reference sheet for educational dua detail view (replaces practice sheet)
    @Presents var referenceSheet: DuaReferenceSheetFeature.State?
    @Presents var addToAdkharSheet: AddToAdkharSheetFeature.State?

    /// Computed property for filtered duas based on search and category
    var filteredDuas: [Dua] {
      var result = selectedCategory == nil ? allDuas : duas

      // Filter by search text
      if !searchText.isEmpty {
        let query = searchText.lowercased()
        result = result.filter {
          $0.titleEn.lowercased().contains(query) ||
          $0.arabicText.contains(query) ||
          ($0.transliteration?.lowercased().contains(query) ?? false) ||
          $0.translationEn.lowercased().contains(query)
        }
      }

      return result
    }
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case onAppear
    case setUserId(String?)
    case duasLoaded(Result<[Dua], Error>)
    case categorySelected(CategorySlug?)
    case categoryDuasLoaded(Result<[Dua], Error>)
    case duaTapped(Dua)
    case addToAdkharTapped(Dua)
    case referenceSheet(PresentationAction<DuaReferenceSheetFeature.Action>)
    case addToAdkharSheet(PresentationAction<AddToAdkharSheetFeature.Action>)
    case retryTapped
  }

  @Dependency(\.firestoreContentClient) var contentClient
  @Dependency(\.continuousClock) var clock

  private enum CancelID { case search }

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding(\.searchText):
        // Search filtering is handled by computed property
        return .none

      case .binding:
        return .none

      case .onAppear:
        guard state.allDuas.isEmpty else { return .none }
        state.isLoading = true
        state.errorMessage = nil

        return .run { send in
          do {
            let duas = try await contentClient.fetchAllDuas()
            await send(.duasLoaded(.success(duas)))
          } catch {
            await send(.duasLoaded(.failure(error)))
          }
        }

      case .setUserId(let userId):
        state.userId = userId
        return .none

      case .duasLoaded(.success(let duas)):
        state.isLoading = false
        state.errorMessage = nil
        state.duas = duas
        state.allDuas = duas
        return .none

      case .duasLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .categorySelected(let category):
        state.selectedCategory = category

        guard let categorySlug = category else {
          // "All" selected - restore cached duas
          state.duas = state.allDuas
          return .none
        }

        // Fetch category-specific duas from Firestore
        state.isLoading = true
        return .run { send in
          do {
            let duas = try await contentClient.fetchDuasByCategory(categorySlug)
            await send(.categoryDuasLoaded(.success(duas)))
          } catch {
            await send(.categoryDuasLoaded(.failure(error)))
          }
        }

      case .categoryDuasLoaded(.success(let duas)):
        state.isLoading = false
        state.duas = duas
        return .none

      case .categoryDuasLoaded(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        // Fallback to client-side filtering on error
        if let categorySlug = state.selectedCategory {
          state.duas = state.allDuas.filter { dua in
            // Match by category ID based on slug
            switch categorySlug {
            case .morning: return dua.categoryId == 1
            case .evening: return dua.categoryId == 2
            case .rizq: return dua.categoryId == 3
            case .gratitude: return dua.categoryId == 4
            }
          }
        }
        return .none

      case .duaTapped(let dua):
        // Present reference sheet for educational dua detail (not practice)
        let isActive = state.activeHabitDuaIds.contains(dua.id)
        state.referenceSheet = DuaReferenceSheetFeature.State(
          dua: dua,
          isAlreadyInAdkhar: isActive
        )
        return .none

      case .referenceSheet(.presented(.delegate(.duaAddedToAdkhar(let duaId, _)))):
        // Update active habits when dua is added from reference sheet
        state.activeHabitDuaIds.insert(duaId)
        return .none

      case .referenceSheet:
        return .none

      case .addToAdkharTapped(let dua):
        state.addToAdkharSheet = AddToAdkharSheetFeature.State(dua: dua)
        return .none

      case .addToAdkharSheet(.presented(.delegate(.habitAdded(let duaId, _)))):
        state.activeHabitDuaIds.insert(duaId)
        return .none

      case .addToAdkharSheet:
        return .none

      case .retryTapped:
        state.errorMessage = nil
        state.selectedCategory = nil
        return .send(.onAppear)
      }
    }
    .ifLet(\.$referenceSheet, action: \.referenceSheet) {
      DuaReferenceSheetFeature()
    }
    .ifLet(\.$addToAdkharSheet, action: \.addToAdkharSheet) {
      AddToAdkharSheetFeature()
    }
  }
}

// MARK: - Add to Adkhar Sheet Feature

@Reducer
struct AddToAdkharSheetFeature {
  @ObservableState
  struct State: Equatable {
    let dua: Dua
    var selectedTimeSlot: TimeSlot = .morning
    var isSaving: Bool = false
    var errorMessage: String?
  }

  enum Action {
    case timeSlotSelected(TimeSlot)
    case confirmTapped
    case cancelTapped
    case customHabitSaved(Result<CustomHabit, Error>)
    case delegate(Delegate)

    @CasePathable
    enum Delegate: Equatable {
      case habitAdded(duaId: Int, timeSlot: TimeSlot)
    }
  }

  @Dependency(\.dismiss) var dismiss
  @Dependency(\.userHabitsClient) var userHabitsClient
  @Dependency(HapticClient.self) var haptics

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .timeSlotSelected(let timeSlot):
        state.selectedTimeSlot = timeSlot
        return .none

      case .confirmTapped:
        state.isSaving = true
        state.errorMessage = nil
        let duaId = state.dua.id
        let timeSlot = state.selectedTimeSlot

        return .run { send in
          do {
            let habit = try await userHabitsClient.addCustomHabit(duaId, timeSlot)
            await send(.customHabitSaved(.success(habit)))
          } catch {
            await send(.customHabitSaved(.failure(error)))
          }
        }

      case .customHabitSaved(.success):
        state.isSaving = false
        return .run { [timeSlot = state.selectedTimeSlot, duaId = state.dua.id] send in
          haptics.habitComplete()
          await send(.delegate(.habitAdded(duaId: duaId, timeSlot: timeSlot)))
          await dismiss()
        }

      case .customHabitSaved(.failure(let error)):
        state.isSaving = false
        state.errorMessage = error.localizedDescription
        return .run { _ in
          haptics.warning()
        }

      case .cancelTapped:
        return .run { _ in
          await dismiss()
        }

      case .delegate:
        return .none
      }
    }
  }
}
