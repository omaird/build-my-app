import ComposableArchitecture
import Foundation
import os.log
import RIZQKit

private let logger = Logger(subsystem: "com.rizq.app", category: "ContentFeature")

// MARK: - ContentFeature
/// A shared TCA reducer that owns read-only content state (duas, journeys, categories)
/// for the app. Other features can observe this state instead of each fetching content
/// independently. Designed to be hosted by `AppFeature` and refreshed once on launch
/// (and on demand via `.refresh`).
///
/// ## Lifecycle
/// 1. Parent sends `.task` once on app launch.
/// 2. Reducer fires three parallel `.run` effects (duas, journeys, categories).
/// 3. Each fetch lands as `.duasLoaded`, `.journeysLoaded`, or `.categoriesLoaded`,
///    OR — on error — as `.loadFailed(.xxxFailed)`. Either counts as "settled".
/// 4. Once all three have settled, `isLoaded = true, isLoading = false`. Consumers
///    should also check `error` to know if data is partial (e.g. duas failed).
/// 5. Fetches run independently — one failing does not cancel the other two.
///
/// ## Dependency wiring
/// Consumes `\.cachedContentClient` so reads go through a last-known-good UserDefaults
/// cache layer that wraps `FirestoreContentClient`.
@Reducer
struct ContentFeature {
  // MARK: - State

  @ObservableState
  struct State: Equatable {
    /// All duas loaded from the content source.
    var duas: [Dua] = []
    /// All journeys loaded from the content source.
    var journeys: [Journey] = []
    /// All categories loaded from the content source.
    var categories: [DuaCategory] = []
    /// Every journey-dua mapping. Used by AdkharService (via Adkhar / Home) to
    /// construct user habits without re-fetching the master content.
    var journeyDuas: [JourneyDua] = []
    /// True once ALL FOUR fetches have settled (success or failure). Consumers
    /// should also inspect `error` — `isLoaded` can be true with empty `duas` if
    /// the duas fetch failed.
    var isLoaded: Bool = false
    /// True while at least one fetch in the current cycle is still in flight.
    var isLoading: Bool = false
    /// Last fetch error encountered. Nil when no error in the current cycle.
    var error: ContentError?

    // Per-type "settled" flags driving `isLoaded` / `isLoading`. Internal — exposed
    // so tests can assert against them if needed, but consumers should read
    // `isLoaded` / `isLoading` instead.
    var duasSettled: Bool = false
    var journeysSettled: Bool = false
    var categoriesSettled: Bool = false
    var journeyDuasSettled: Bool = false
  }

  // MARK: - Errors

  /// Identifies which content fetch failed. Equatable so it can be matched in tests.
  enum ContentError: Equatable {
    case duasFailed
    case journeysFailed
    case categoriesFailed
    case journeyDuasFailed
  }

  // MARK: - Actions

  enum Action {
    /// Sent by the parent (e.g. on app launch) to kick off the initial fetch.
    case task
    /// Sent by the parent (e.g. pull-to-refresh) to refetch all content.
    case refresh
    /// Internal: a duas fetch completed successfully.
    case duasLoaded([Dua])
    /// Internal: a journeys fetch completed successfully.
    case journeysLoaded([Journey])
    /// Internal: a categories fetch completed successfully.
    case categoriesLoaded([DuaCategory])
    /// Internal: a journey-duas fetch completed successfully.
    case journeyDuasLoaded([JourneyDua])
    /// Internal: one of the fetches threw.
    case loadFailed(ContentError)
  }

  // MARK: - Dependencies

  @Dependency(\.cachedContentClient) var content

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task, .refresh:
        state.isLoading = true
        state.isLoaded = false
        state.error = nil
        state.duasSettled = false
        state.journeysSettled = false
        state.categoriesSettled = false
        state.journeyDuasSettled = false
        logger.debug("Starting content fetch (task/refresh)")
        return .merge(
          .run { send in
            do {
              let duas = try await content.fetchAllDuas()
              await send(.duasLoaded(duas))
            } catch {
              logger.error("fetchAllDuas failed: \(error.localizedDescription, privacy: .public)")
              await send(.loadFailed(.duasFailed))
            }
          },
          .run { send in
            do {
              let journeys = try await content.fetchAllJourneys()
              await send(.journeysLoaded(journeys))
            } catch {
              logger.error("fetchAllJourneys failed: \(error.localizedDescription, privacy: .public)")
              await send(.loadFailed(.journeysFailed))
            }
          },
          .run { send in
            do {
              let categories = try await content.fetchAllCategories()
              await send(.categoriesLoaded(categories))
            } catch {
              logger.error("fetchAllCategories failed: \(error.localizedDescription, privacy: .public)")
              await send(.loadFailed(.categoriesFailed))
            }
          },
          .run { send in
            do {
              let mappings = try await content.fetchAllJourneyDuas()
              await send(.journeyDuasLoaded(mappings))
            } catch {
              logger.error("fetchAllJourneyDuas failed: \(error.localizedDescription, privacy: .public)")
              await send(.loadFailed(.journeyDuasFailed))
            }
          }
        )

      case let .duasLoaded(duas):
        state.duas = duas
        state.duasSettled = true
        Self.flipIfAllSettled(&state)
        return .none

      case let .journeysLoaded(journeys):
        state.journeys = journeys
        state.journeysSettled = true
        Self.flipIfAllSettled(&state)
        return .none

      case let .categoriesLoaded(categories):
        state.categories = categories
        state.categoriesSettled = true
        Self.flipIfAllSettled(&state)
        return .none

      case let .journeyDuasLoaded(mappings):
        state.journeyDuas = mappings
        state.journeyDuasSettled = true
        Self.flipIfAllSettled(&state)
        return .none

      case let .loadFailed(err):
        state.error = err
        switch err {
        case .duasFailed:        state.duasSettled = true
        case .journeysFailed:    state.journeysSettled = true
        case .categoriesFailed:  state.categoriesSettled = true
        case .journeyDuasFailed: state.journeyDuasSettled = true
        }
        Self.flipIfAllSettled(&state)
        return .none
      }
    }
  }

  /// Flip `isLoaded`/`isLoading` when all four fetches have settled (success or fail).
  private static func flipIfAllSettled(_ state: inout State) {
    if state.duasSettled
        && state.journeysSettled
        && state.categoriesSettled
        && state.journeyDuasSettled {
      state.isLoaded = true
      state.isLoading = false
    }
  }
}
