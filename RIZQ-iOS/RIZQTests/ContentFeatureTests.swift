import ComposableArchitecture
import XCTest
@testable import RIZQ
@testable import RIZQKit

@MainActor
final class ContentFeatureTests: XCTestCase {

  // MARK: - Success path

  /// Sending `.task` kicks off three parallel fetches. Because they run via `.merge`
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
    }
    // Non-exhaustive: we only care about the eventual settled state.
    store.exhaustivity = .off

    await store.send(.task)
    await store.skipReceivedActions()

    store.assert {
      $0.duas = mockDuas
      $0.journeys = []
      $0.categories = []
      $0.isLoaded = true
      $0.isLoading = false
      $0.error = nil
    }
  }

  // MARK: - Error path

  /// When `fetchAllDuas` throws, `.loadFailed(.duasFailed)` is emitted and `error`
  /// is set. Journeys & categories still succeed in parallel; final state should
  /// reflect the error plus the partial success.
  func testFetchErrorSetsErrorState() async {
    struct TestError: Error {}

    let store = TestStore(initialState: ContentFeature.State()) {
      ContentFeature()
    } withDependencies: {
      $0.cachedContentClient.fetchAllDuas = { throw TestError() }
      $0.cachedContentClient.fetchAllJourneys = { [] }
      $0.cachedContentClient.fetchAllCategories = { [] }
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
      // All three fetches settled (one failure + two successes), so isLoaded is true
      // but `error` is set — consumers must check both.
      $0.isLoaded = true
      $0.duasSettled = true
      $0.journeysSettled = true
      $0.categoriesSettled = true
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

  /// Once all three settled flags are true (mixed success + failure), `isLoaded`
  /// flips true and `isLoading` flips false in the same step.
  func testAllThreeSettledFlipsIsLoaded() async {
    var initialState = ContentFeature.State()
    initialState.isLoading = true
    initialState.duasSettled = true
    initialState.journeysSettled = true
    // Only categories outstanding.

    let store = TestStore(initialState: initialState) {
      ContentFeature()
    }

    await store.send(.categoriesLoaded([])) { state in
      state.categories = []
      state.categoriesSettled = true
      state.isLoaded = true
      state.isLoading = false
    }
  }
}
