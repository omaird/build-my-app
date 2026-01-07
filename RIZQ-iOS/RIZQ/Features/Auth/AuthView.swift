import SwiftUI
import ComposableArchitecture
import RIZQKit

struct AuthView: View {
  @Bindable var store: StoreOf<AuthFeature>

  var body: some View {
    ScrollView {
      VStack(spacing: 32) {
        // Logo and Welcome
        headerSection

        // Social Sign In Buttons
        socialSignInSection

        // Divider
        dividerSection

        // Email Sign In Form
        emailFormSection

        // Toggle Auth Mode
        toggleModeSection
      }
      .padding(24)
    }
    .rizqPageBackground()
  }

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(spacing: 16) {
      // App Icon/Logo
      ZStack {
        Circle()
          .fill(LinearGradient.rizqPrimaryGradient)
          .frame(width: 80, height: 80)

        Image(systemName: "hands.sparkles.fill")
          .font(.system(size: 36))
          .foregroundStyle(.white)
      }
      .shadowGlowPrimary()

      Text("RIZQ")
        .font(.rizqDisplayBold(.largeTitle))
        .foregroundStyle(Color.rizqText)

      Text(store.isSignUp ? "Create your account" : "Welcome back")
        .font(.rizqSans(.headline))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .padding(.top, 40)
  }

  // MARK: - Social Sign In Section
  private var socialSignInSection: some View {
    VStack(spacing: 12) {
      // Apple Button (primary option for iOS)
      Button {
        store.send(.signInWithApple)
      } label: {
        HStack {
          Image(systemName: "apple.logo")
            .font(.title2)
          Text("Continue with Apple")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.black)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      }
      .buttonStyle(.plain)

      // Google Button
      Button {
        store.send(.signInWithGoogle)
      } label: {
        HStack {
          Image(systemName: "g.circle.fill")
            .font(.title2)
          Text("Continue with Google")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.rizqCard)
        .foregroundStyle(Color.rizqText)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
        .overlay {
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
            .stroke(Color.rizqBorder, lineWidth: 1)
        }
      }
      .buttonStyle(.plain)

      // GitHub Button
      Button {
        store.send(.signInWithGitHub)
      } label: {
        HStack {
          Image(systemName: "chevron.left.forwardslash.chevron.right")
            .font(.title2)
          Text("Continue with GitHub")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.mochaDeep)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      }
      .buttonStyle(.plain)
    }
  }

  // MARK: - Divider Section
  private var dividerSection: some View {
    HStack {
      Rectangle()
        .fill(Color.rizqBorder)
        .frame(height: 1)

      Text("or")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqMuted)

      Rectangle()
        .fill(Color.rizqBorder)
        .frame(height: 1)
    }
  }

  // MARK: - Email Form Section
  private var emailFormSection: some View {
    VStack(spacing: 16) {
      // Email Field
      VStack(alignment: .leading, spacing: 8) {
        Text("Email")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        TextField("your@email.com", text: $store.email)
          .font(.rizqSans(.body))
          .textContentType(.emailAddress)
          .keyboardType(.emailAddress)
          .autocapitalization(.none)
          .padding()
          .background(Color.rizqCard)
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.md))
          .overlay {
            RoundedRectangle(cornerRadius: RIZQRadius.md)
              .stroke(Color.rizqBorder, lineWidth: 1)
          }
      }

      // Password Field
      VStack(alignment: .leading, spacing: 8) {
        Text("Password")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        SecureField("Enter password", text: $store.password)
          .font(.rizqSans(.body))
          .textContentType(store.isSignUp ? .newPassword : .password)
          .padding()
          .background(Color.rizqCard)
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.md))
          .overlay {
            RoundedRectangle(cornerRadius: RIZQRadius.md)
              .stroke(Color.rizqBorder, lineWidth: 1)
          }
      }

      // Error Message
      if let error = store.errorMessage {
        Text(error)
          .font(.rizqSans(.caption))
          .foregroundStyle(.red)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      // Submit Button
      Button {
        store.send(.signInWithEmail)
      } label: {
        Group {
          if store.isLoading {
            ProgressView()
              .tint(.white)
          } else {
            Text(store.isSignUp ? "Create Account" : "Sign In")
          }
        }
        .frame(maxWidth: .infinity)
        .rizqPrimaryButton()
      }
      .disabled(store.isLoading)
    }
  }

  // MARK: - Toggle Mode Section
  private var toggleModeSection: some View {
    Button {
      store.send(.toggleAuthMode)
    } label: {
      HStack(spacing: 4) {
        Text(store.isSignUp ? "Already have an account?" : "Don't have an account?")
          .foregroundStyle(Color.rizqTextSecondary)

        Text(store.isSignUp ? "Sign In" : "Sign Up")
          .foregroundStyle(Color.rizqPrimary)
      }
      .font(.rizqSans(.subheadline))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  AuthView(
    store: Store(initialState: AuthFeature.State()) {
      AuthFeature()
    }
  )
}
