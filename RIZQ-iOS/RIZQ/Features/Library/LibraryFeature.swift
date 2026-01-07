import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - Library Feature
@Reducer
struct LibraryFeature {
  @ObservableState
  struct State: Equatable {
    var duas: [Dua] = []
    var categories: [CategoryDisplay] = CategoryDisplay.allCases
    var searchText: String = ""
    var selectedCategory: CategorySlug?
    var isLoading: Bool = false
    @Presents var addToAdkharSheet: AddToAdkharSheetFeature.State?

    /// Computed property for filtered duas based on search and category
    var filteredDuas: [Dua] {
      var result = duas

      // Filter by category (using bestTime as proxy for category)
      if let categorySlug = selectedCategory {
        result = result.filter { $0.bestTime?.rawValue == categorySlug.rawValue }
      }

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
    case duasLoaded([Dua])
    case categoriesLoaded([CategoryDisplay])
    case searchTextChanged(String)
    case categorySelected(CategorySlug?)
    case duaTapped(Dua)
    case addToAdkharTapped(Dua)
    case addToAdkharSheet(PresentationAction<AddToAdkharSheetFeature.Action>)
    case searchDebounced
  }

  @Dependency(\.continuousClock) var clock

  private enum CancelID { case search }

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding(\.searchText):
        // Debounce search by 300ms
        return .run { send in
          try await clock.sleep(for: .milliseconds(300))
          await send(.searchDebounced)
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)

      case .binding:
        return .none

      case .onAppear:
        guard state.duas.isEmpty else { return .none }
        state.isLoading = true

        // Load demo data
        return .run { send in
          // Simulate network delay
          try await clock.sleep(for: .milliseconds(300))
          await send(.duasLoaded(Dua.demoData))
        }

      case .duasLoaded(let duas):
        state.isLoading = false
        state.duas = duas
        return .none

      case .categoriesLoaded(let categories):
        state.categories = categories
        return .none

      case .searchTextChanged(let text):
        state.searchText = text
        return .run { send in
          try await clock.sleep(for: .milliseconds(300))
          await send(.searchDebounced)
        }
        .cancellable(id: CancelID.search, cancelInFlight: true)

      case .categorySelected(let category):
        state.selectedCategory = category
        return .none

      case .duaTapped:
        // TODO: Navigate to practice view
        return .none

      case .addToAdkharTapped(let dua):
        state.addToAdkharSheet = AddToAdkharSheetFeature.State(dua: dua)
        return .none

      case .addToAdkharSheet:
        return .none

      case .searchDebounced:
        // Search is handled via computed property
        return .none
      }
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
  }

  enum Action {
    case timeSlotSelected(TimeSlot)
    case confirmTapped
    case cancelTapped
  }

  @Dependency(\.dismiss) var dismiss

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .timeSlotSelected(let timeSlot):
        state.selectedTimeSlot = timeSlot
        return .none

      case .confirmTapped:
        // TODO: Add dua to user's adkhar
        return .run { _ in
          await dismiss()
        }

      case .cancelTapped:
        return .run { _ in
          await dismiss()
        }
      }
    }
  }
}

// MARK: - Display Models

/// Category display model for UI
struct CategoryDisplay: Equatable, Identifiable {
  let slug: CategorySlug
  let name: String
  let icon: String

  var id: String { slug.rawValue }

  static let allCases: [CategoryDisplay] = [
    CategoryDisplay(slug: .morning, name: "Morning", icon: "sun.max.fill"),
    CategoryDisplay(slug: .evening, name: "Evening", icon: "moon.fill"),
    CategoryDisplay(slug: .rizq, name: "Rizq", icon: "leaf.fill"),
    CategoryDisplay(slug: .gratitude, name: "Gratitude", icon: "heart.fill"),
  ]

  static func display(for slug: CategorySlug) -> CategoryDisplay {
    allCases.first { $0.slug == slug } ?? allCases[0]
  }
}

// MARK: - Demo Data
extension Dua {
  static let demoData: [Dua] = [
    Dua(
      id: 1,
      categoryId: 1,
      titleEn: "Morning Dhikr",
      arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
      transliteration: "Asbahna wa asbahal mulku lillah",
      translationEn: "We have entered upon morning and the whole kingdom belongs to Allah",
      source: "Muslim",
      repetitions: 1,
      bestTime: .morning,
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 2,
      categoryId: 2,
      titleEn: "Evening Protection",
      arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
      transliteration: "Amsayna wa amsal mulku lillah",
      translationEn: "We have entered upon evening and the whole kingdom belongs to Allah",
      source: "Muslim",
      repetitions: 1,
      bestTime: .evening,
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 3,
      categoryId: 3,
      titleEn: "Seeking Rizq",
      arabicText: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ",
      transliteration: "Allahumma akfini bihalalika an haramik",
      translationEn: "O Allah, suffice me with what You have allowed instead of what You have forbidden",
      source: "Tirmidhi",
      repetitions: 3,
      bestTime: .anytime,
      difficulty: .intermediate,
      xpValue: 20
    ),
    Dua(
      id: 4,
      categoryId: 4,
      titleEn: "Gratitude to Allah",
      arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا",
      transliteration: "Alhamdulillahil ladhi ahyana ba'da ma amatana",
      translationEn: "All praise is for Allah who gave us life after causing us to die",
      source: "Bukhari",
      repetitions: 1,
      bestTime: .anytime,
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 5,
      categoryId: 1,
      titleEn: "Seeking Protection",
      arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      transliteration: "A'udhu bikalimatillahit-tammaati min sharri ma khalaq",
      translationEn: "I seek refuge in the perfect words of Allah from the evil of what He has created",
      source: "Muslim",
      repetitions: 3,
      bestTime: .morning,
      difficulty: .beginner,
      xpValue: 15
    ),
    Dua(
      id: 6,
      categoryId: 2,
      titleEn: "Ayatul Kursi",
      arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
      transliteration: "Allahu la ilaha illa huwal hayyul qayyum",
      translationEn: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence",
      source: "Quran 2:255",
      repetitions: 1,
      bestTime: .evening,
      difficulty: .advanced,
      xpValue: 25
    ),
    Dua(
      id: 7,
      categoryId: 3,
      titleEn: "Abundance of Provision",
      arabicText: "اللَّهُمَّ أَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ",
      transliteration: "Allahumma aghnini bifadlika amman siwak",
      translationEn: "O Allah, enrich me with Your bounty above anyone other than You",
      source: "Tirmidhi",
      repetitions: 3,
      bestTime: .anytime,
      difficulty: .intermediate,
      xpValue: 20
    ),
    Dua(
      id: 8,
      categoryId: 4,
      titleEn: "Thanks for Blessings",
      arabicText: "اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ خَلْقِكَ فَمِنْكَ",
      transliteration: "Allahumma ma asbaha bi min ni'matin aw bi-ahadin min khalqika faminka",
      translationEn: "O Allah, whatever blessing I or any of Your creation have risen upon, is from You alone",
      source: "Abu Dawud",
      repetitions: 1,
      bestTime: .anytime,
      difficulty: .intermediate,
      xpValue: 15
    ),
  ]
}
