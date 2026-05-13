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
/// 3. Each fetch lands as `.duasLoaded`, `.journeysLoaded`, or `.categoriesLoaded`.
/// 4. Receipt of `.categoriesLoaded` flips `isLoaded = true, isLoading = false`.
/// 5. On any fetch error, `.loadFailed(.xxxFailed)` is emitted; `error` is set and
///    `isLoading` is cleared. The other two fetches still run independently.
///
/// ## Dependency wiring
/// Currently consumes `\.firestoreContentClient` directly. Task 5.4 (post-merge of the
/// Step-5 parallel branches) will rewire this to `\.cachedContentClient` so reads go
/// through the on-disk cache layer.
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
    /// True once all three content collections have arrived at least once.
    var isLoaded: Bool = false
    /// True while a fetch cycle is in flight.
    var isLoading: Bool = false
    /// Last fetch error encountered (per content type). Nil when no error.
    var error: ContentError?
  }

  // MARK: - Errors

  /// Identifies which content fetch failed. Equatable so it can be matched in tests.
  enum ContentError: Equatable {
    case duasFailed
    case journeysFailed
    case categoriesFailed
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
    /// Internal: one of the three fetches threw.
    case loadFailed(ContentError)
  }

  // MARK: - Dependencies

  // NOTE: temporarily wired against firestoreContentClient. Task 5.4 (after the
  // Step-5 parallel branches merge) will swap this to `\.cachedContentClient`.
  @Dependency(\.firestoreContentClient) var content

  // MARK: - Body

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task, .refresh:
        state.isLoading = true
        state.error = nil
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
          }
        )

      case let .duasLoaded(duas):
        state.duas = duas
        return .none

      case let .journeysLoaded(journeys):
        state.journeys = journeys
        return .none

      case let .categoriesLoaded(categories):
        state.categories = categories
        state.isLoaded = true
        state.isLoading = false
        return .none

      case let .loadFailed(err):
        state.error = err
        state.isLoading = false
        return .none
      }
    }
  }
}
