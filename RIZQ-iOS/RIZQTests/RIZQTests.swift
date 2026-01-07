import XCTest
import ComposableArchitecture
@testable import RIZQ

final class RIZQTests: XCTestCase {

  @MainActor
  func testHomeFeatureOnAppear() async {
    let store = TestStore(initialState: HomeFeature.State()) {
      HomeFeature()
    }

    await store.send(.onAppear) {
      $0.isLoading = true
    }
  }

  @MainActor
  func testTabSelection() async {
    let store = TestStore(initialState: AppFeature.State()) {
      AppFeature()
    }

    await store.send(.tabSelected(.library)) {
      $0.selectedTab = .library
    }

    await store.send(.tabSelected(.adkhar)) {
      $0.selectedTab = .adkhar
    }
  }

  @MainActor
  func testAuthToggleMode() async {
    let store = TestStore(initialState: AuthFeature.State()) {
      AuthFeature()
    }

    XCTAssertFalse(store.state.isSignUp)

    await store.send(.toggleAuthMode) {
      $0.isSignUp = true
    }

    await store.send(.toggleAuthMode) {
      $0.isSignUp = false
    }
  }
}
