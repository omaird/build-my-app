import XCTest
import SnapshotTesting
import SwiftUI
import ComposableArchitecture
import Dependencies
@testable import RIZQ
@testable import RIZQKit

final class RIZQSnapshotTests: XCTestCase {

  override func setUpWithError() throws {
    // Set to true to record new snapshots
    // isRecording = true
  }

  func testHomeView() {
    // Wrap Store construction in withDependencies so the reducer can't
    // accidentally fire a live Firestore/Auth call during snapshot rendering.
    // Tests that don't dispatch actions still benefit — any onAppear effect
    // that the view triggers under the hood gets the test doubles.
    let view = withDependencies {
      $0.firestoreUserClient = .testValue
      $0.authClient = .testValue
    } operation: {
      HomeView(
        store: Store(initialState: HomeFeature.State(
          streak: 7,
          totalXp: 450,
          level: 3,
          todaysProgress: TodayProgress(completed: 3, total: 5, xpEarned: 30),
          todaysHabits: []
        )) {
          HomeFeature()
        }
      )
    }

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }

  func testAuthView() {
    let view = withDependencies {
      $0.authClient = .testValue
    } operation: {
      AuthView(
        store: Store(initialState: AuthFeature.State()) {
          AuthFeature()
        }
      )
    }

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }

  func testAuthViewSignUp() {
    let view = withDependencies {
      $0.authClient = .testValue
    } operation: {
      AuthView(
        store: Store(initialState: AuthFeature.State(isSignUp: true)) {
          AuthFeature()
        }
      )
    }

    assertSnapshot(
      of: view,
      as: .image(layout: .device(config: .iPhone13Pro))
    )
  }
}
