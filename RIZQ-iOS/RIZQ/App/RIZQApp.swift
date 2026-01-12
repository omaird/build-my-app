import SwiftUI
import ComposableArchitecture
import RIZQKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn
import os.log

private let logger = Logger(subsystem: "com.rizq.app", category: "Config")

// MARK: - App Delegate for Firebase + Google Sign-In
final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    // Firebase is configured here instead of in RIZQApp.init()
    FirebaseApp.configure()

    // Configure emulator for local development (must happen after FirebaseApp.configure)
    #if DEBUG
    let useEmulator = ProcessInfo.processInfo.environment["USE_FIREBASE_EMULATOR"] == "true"
    if useEmulator {
      Auth.auth().useEmulator(withHost: "localhost", port: 9099)
      let settings = Firestore.firestore().settings
      settings.host = "localhost:8080"
      settings.isSSLEnabled = false
      Firestore.firestore().settings = settings
      logger.info("Firebase emulators configured")
    }
    #endif

    return true
  }

  func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // Handle Google Sign-In callback URLs
    return GIDSignIn.sharedInstance.handle(url)
  }
}

@main
struct RIZQApp: App {
  // Bridge SwiftUI with UIApplicationDelegate for Firebase/Google Sign-In
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

  @MainActor
  static let store = Store(initialState: AppFeature.State()) {
    AppFeature()
  }

  init() {
    // Note: Firebase is configured in AppDelegate.didFinishLaunchingWithOptions
    // Emulator configuration is also handled there (must happen after FirebaseApp.configure)

    // Configure ServiceContainer with Firebase only
    // Neon PostgreSQL is deprecated - all data now uses Firebase Firestore
    let firebaseConfig = FirebaseConfiguration(
      projectId: "rizq-app-c6468",
      useEmulator: false
    )
    let configuration = AppConfiguration(firebase: firebaseConfig)
    ServiceContainer.shared.configure(with: configuration)
    logger.info("ServiceContainer configured with Firebase: \(ServiceContainer.shared.isConfigured, privacy: .public)")
  }

  var body: some Scene {
    WindowGroup {
      AppView(store: Self.store)
    }
  }
}
