import ComposableArchitecture
import Foundation
import RIZQKit
import UIKit

@Reducer
struct AuthFeature {
  @ObservableState
  struct State: Equatable {
    var email: String = ""
    var password: String = ""
    var name: String = ""
    var isSignUp: Bool = false
    var isLoading: Bool = false
    var errorMessage: String? = nil
    var user: AuthUser? = nil
  }

  enum Action: BindableAction {
    case binding(BindingAction<State>)
    case toggleAuthMode
    case signInWithEmail
    case signInWithGoogle
    case signInWithApple
    case checkExistingSession
    case authResponse(Result<AuthResponse, RIZQAuthError>)
    case authSuccess(AuthUser)
    case authFailure(String)
    case clearError
  }

  @Dependency(\.authClient) var authClient

  var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .binding:
        state.errorMessage = nil
        return .none

      case .toggleAuthMode:
        state.isSignUp.toggle()
        state.errorMessage = nil
        return .none

      case .checkExistingSession:
        // Try to restore existing session from Keychain
        if let (user, _) = authClient.restoreSession() {
          return .send(.authSuccess(user))
        }
        return .none

      case .signInWithEmail:
        guard !state.email.isEmpty, !state.password.isEmpty else {
          state.errorMessage = "Please enter email and password"
          return .none
        }
        state.isLoading = true
        state.errorMessage = nil

        let email = state.email
        let password = state.password
        let name = state.name.isEmpty ? nil : state.name
        let isSignUp = state.isSignUp

        return .run { send in
          do {
            let response: AuthResponse
            if isSignUp {
              response = try await authClient.signUp(email, password, name)
            } else {
              response = try await authClient.signIn(email, password)
            }
            await send(.authResponse(.success(response)))
          } catch let error as RIZQAuthError {
            await send(.authResponse(.failure(error)))
          } catch {
            await send(.authResponse(.failure(.unknown(error.localizedDescription))))
          }
        }

      case .signInWithGoogle:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            let response = try await authClient.signInWithOAuth(.google)
            await send(.authResponse(.success(response)))
          } catch let error as RIZQAuthError {
            await send(.authResponse(.failure(error)))
          } catch {
            await send(.authResponse(.failure(.unknown(error.localizedDescription))))
          }
        }

      case .signInWithApple:
        state.isLoading = true
        state.errorMessage = nil
        return .run { send in
          do {
            let response = try await authClient.signInWithOAuth(.apple)
            await send(.authResponse(.success(response)))
          } catch let error as RIZQAuthError {
            await send(.authResponse(.failure(error)))
          } catch {
            await send(.authResponse(.failure(.unknown(error.localizedDescription))))
          }
        }

      case .authResponse(.success(let response)):
        state.isLoading = false
        state.user = response.user
        return .send(.authSuccess(response.user))

      case .authResponse(.failure(let error)):
        state.isLoading = false
        state.errorMessage = error.localizedDescription
        return .none

      case .authSuccess(let user):
        state.isLoading = false
        state.user = user
        return .none

      case .authFailure(let message):
        state.isLoading = false
        state.errorMessage = message
        return .none

      case .clearError:
        state.errorMessage = nil
        return .none
      }
    }
  }
}

// MARK: - Auth Client Dependency

struct AuthClient: Sendable {
  var signIn: @Sendable (String, String) async throws -> AuthResponse
  var signUp: @Sendable (String, String, String?) async throws -> AuthResponse
  var signInWithOAuth: @Sendable (AuthProvider) async throws -> AuthResponse
  var signOut: @Sendable () async throws -> Void
  var restoreSession: @Sendable () -> (AuthUser, AuthSession)?
  var getCurrentUser: @Sendable () async throws -> AuthUser?
  var getLinkedAccounts: @Sendable () async throws -> [LinkedAccount]
}

extension AuthClient: DependencyKey {
  static let liveValue = AuthClient(
    signIn: { email, password in
      let service = ServiceContainer.shared.authService
      return try await service.signInWithEmail(email: email, password: password)
    },
    signUp: { email, password, name in
      let service = ServiceContainer.shared.authService
      return try await service.signUpWithEmail(email: email, password: password, name: name)
    },
    signInWithOAuth: { provider in
      let service = ServiceContainer.shared.authService
      // Get the key window from the active scene for OAuth presentation
      let presentingWindow = await MainActor.run {
        UIApplication.shared.connectedScenes
          .compactMap { $0 as? UIWindowScene }
          .flatMap { $0.windows }
          .first { $0.isKeyWindow }
      }
      return try await service.signInWithOAuth(provider: provider, presentingWindow: presentingWindow)
    },
    signOut: {
      let service = ServiceContainer.shared.authService
      try await service.signOut()
    },
    restoreSession: {
      let service = ServiceContainer.shared.authService
      return service.restoreSession()
    },
    getCurrentUser: {
      let service = ServiceContainer.shared.authService
      return try await service.getCurrentUser()
    },
    getLinkedAccounts: {
      let service = ServiceContainer.shared.authService
      return try await service.getLinkedAccounts()
    }
  )

  static let previewValue = AuthClient(
    signIn: { _, _ in
      AuthResponse(
        user: AuthUser(id: "preview", email: "test@example.com", name: "Test User"),
        session: AuthSession(id: "session", userId: "preview", token: "token", expiresAt: Date().addingTimeInterval(86400))
      )
    },
    signUp: { email, _, name in
      AuthResponse(
        user: AuthUser(id: "preview", email: email, name: name),
        session: AuthSession(id: "session", userId: "preview", token: "token", expiresAt: Date().addingTimeInterval(86400))
      )
    },
    signInWithOAuth: { provider in
      AuthResponse(
        user: AuthUser(id: "preview", email: "\(provider.rawValue)@example.com", name: "\(provider.displayName) User"),
        session: AuthSession(id: "session", userId: "preview", token: "token", expiresAt: Date().addingTimeInterval(86400))
      )
    },
    signOut: { },
    restoreSession: { nil },
    getCurrentUser: {
      AuthUser(id: "preview", email: "preview@example.com", name: "Preview User")
    },
    getLinkedAccounts: {
      [LinkedAccount(id: "preview-google", provider: .google, providerAccountId: "google-preview")]
    }
  )

  static let testValue = AuthClient(
    signIn: unimplemented("\(Self.self).signIn"),
    signUp: unimplemented("\(Self.self).signUp"),
    signInWithOAuth: unimplemented("\(Self.self).signInWithOAuth"),
    signOut: unimplemented("\(Self.self).signOut"),
    restoreSession: unimplemented("\(Self.self).restoreSession", placeholder: nil),
    getCurrentUser: unimplemented("\(Self.self).getCurrentUser", placeholder: nil),
    getLinkedAccounts: unimplemented("\(Self.self).getLinkedAccounts", placeholder: [])
  )
}

extension DependencyValues {
  var authClient: AuthClient {
    get { self[AuthClient.self] }
    set { self[AuthClient.self] = newValue }
  }
}
