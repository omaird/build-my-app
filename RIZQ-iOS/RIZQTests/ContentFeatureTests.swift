import ComposableArchitecture
import XCTest
@testable import RIZQ
@testable import RIZQKit

@MainActor
final class ContentFeatureTests: XCTestCase {

  // MARK: - Success path

  /// Sending `.task` kicks off four parallel fetches. Because they run via `.merge`
  /// their completion order is non-deterministic, so we use non-exhaustive testing
  /// to assert the final state rather than each intermediate transition.
  func testOnAppearLoadsContent() async {
    let mockDuas = [Dua.demoData[0]]

    let store = TestStore(initialState: ContentFeature.State()) {
      ContentFeature()
    } withDependencies: {
      $0.cachedContentClient.fetchAllDuas = { mockDuas }
      $0.cachedContentClient.fetchAllJourneys = { [] }
      $0.cachedContentClient.fetchAllCategories = { [] }
      $0.cachedContentClient.fetchAllJourneyDuas = { [] }
    }
    // Non-exhaustive: we only care about the eventual settled state.
    store.exhaustivity = .off

    await store.send(.task)
    await store.skipReceivedActions()

    store.assert {
      $0.duas = mockDuas
      $0.journeys = []
      $0.categories = []
      $0.journeyDuas = []
      $0.isLoaded = true
      $0.isLoading = false
      $0.error = nil
    }
  }

  // MARK: - Error path

  /// When `fetchAllDuas` throws, `.loadFailed(.duasFailed)` is emitted and `error`
  /// is set. The other three fetches still succeed in parallel; final state should
  /// reflect the error plus the partial success.
  func testFetchErrorSetsErrorState() async {
    struct TestError: Error {}

    let store = TestStore(initialState: ContentFeature.State()) {
      ContentFeature()
    } withDependencies: {
      $0.cachedContentClient.fetchAllDuas = { throw TestError() }
      $0.cachedContentClient.fetchAllJourneys = { [] }
      $0.cachedContentClient.fetchAllCategories = { [] }
      $0.cachedContentClient.fetchAllJourneyDuas = { [] }
    }
    store.exhaustivity = .off

    await store.send(.task)
    await store.skipReceivedActions()

    store.assert {
      $0.error = .duasFailed
      $0.isLoading = false
      $0.duas = []
      $0.journeys = []
      $0.categories = []
      $0.journeyDuas = []
      // All four fetches settled (one failure + three successes), so isLoaded is true
      // but `error` is set — consumers must check both.
      $0.isLoaded = true
      $0.duasSettled = true
      $0.journeysSettled = true
      $0.categoriesSettled = true
      $0.journeyDuasSettled = true
    }
  }

  // MARK: - Partial-loading state

  /// `.categoriesLoaded` alone must NOT flip `isLoaded`. Guards against the prior
  /// bug where receipt of categories was treated as "all done".
  func testCategoriesLoadedAloneDoesNotMarkLoaded() async {
    var initialState = ContentFeature.State()
    initialState.isLoading = true  // simulate mid-fetch

    let store = TestStore(initialState: initialState) {
      ContentFeature()
    }

    await store.send(.categoriesLoaded([])) { state in
      state.categories = []
      state.categoriesSettled = true
      // isLoaded MUST remain false — duas & journeys haven't settled yet.
      state.isLoaded = false
      state.isLoading = true
    }
  }

  /// Once all four settled flags are true (mixed success + failure), `isLoaded`
  /// flips true and `isLoading` flips false in the same step.
  func testAllFourSettledFlipsIsLoaded() async {
    var initialState = ContentFeature.State()
    initialState.isLoading = true
    initialState.duasSettled = true
    initialState.journeysSettled = true
    initialState.categoriesSettled = true
    // Only journey-duas outstanding.

    let store = TestStore(initialState: initialState) {
      ContentFeature()
    }

    await store.send(.journeyDuasLoaded([])) { state in
      state.journeyDuas = []
      state.journeyDuasSettled = true
      state.isLoaded = true
      state.isLoading = false
    }
  }
}
