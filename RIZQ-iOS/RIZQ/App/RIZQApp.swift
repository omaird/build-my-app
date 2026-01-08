import SwiftUI
import ComposableArchitecture
import RIZQKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct RIZQApp: App {
  @MainActor
  static let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  init() {
    // Initialize Firebase (must be called before any Firebase services)
    FirebaseApp.configure()

    // Check if using emulator for local development
    #if DEBUG
    let useEmulator = ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
    if useEmulator {
      Auth.auth().useEmulator(withHost: "localhost", port: 9099)
      let settings = Firestore.firestore().settings
      settings.host = "localhost:8080"
      settings.isSSLEnabled = false
      Firestore.firestore().settings = settings
    }
    #endif

    // Configure ServiceContainer with Firebase
    let firebaseConfig = FirebaseConfiguration(
      projectId: "rizq-app-c6468",
      useEmulator: false
    )
    let configuration = AppConfiguration(firebase: firebaseConfig)
    ServiceContainer.shared.configure(with: configuration)
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
