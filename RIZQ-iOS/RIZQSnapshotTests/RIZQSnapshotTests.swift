import XCTest
import SnapshotTesting
import SwiftUI
import ComposableArchitecture
@testable import RIZQ

final class RIZQSnapshotTests: XCTestCase {

  override func setUpWithError() throws {
    // Set to true to record new snapshots
    // isRecording = true
  }

  func testHomeView() {
    let view = HomeView(
      store: Store(initialState: HomeFeature.State(
        streak: 7,
        totalXp: 450,
        level: 3,
        todaysProgress: 3,
        totalHabits: 5
      )) {
        HomeFeature()
      }
    )

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }

  func testAuthView() {
    let view = AuthView(
      store: Store(initialState: AuthFeature.State()) {
        AuthFeature()
      }
    )

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }

  func testAuthViewSignUp() {
    let view = AuthView(
      store: Store(initialState: AuthFeature.State(isSignUp: true)) {
        AuthFeature()
      }
    )

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }
}
