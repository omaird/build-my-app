import SwiftUI
import ComposableArchitecture
import RIZQKit

struct AuthView: View {
  @Bindable var store: StoreOf<AuthFeature>

  var body: some View {
    ScrollView {
      VStack(spacing: 24) {
        // Bismillah at top
        bismillahSection

        // Illustration and Welcome
        headerSection

        // Email Sign In Form
        emailFormSection

        // Divider
        dividerSection

        // Social Sign In Buttons
        socialSignInSection

        // Toggle Auth Mode
        toggleModeSection
      }
      .padding(.horizontal, 24)
      .padding(.bottom, 24)
    }
    .scrollDismissesKeyboard(.interactively)
    .rizqPageBackground()
  }

  // MARK: - Bismillah Section
  private var bismillahSection: some View {
    Text("بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ")
      .font(.rizqArabic(.title2))
      .foregroundStyle(Color.rizqPrimary)
      .padding(.top, 20)
  }

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(spacing: 20) {
      // Meditation Illustration
      Image("meditation")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 280, maxHeight: 220)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))

      // Welcome Text
      VStack(spacing: 8) {
        Text(store.isSignUp ? "Join RIZQ" : "Welcome to RIZQ")
          .font(.rizqDisplayBold(.title))
          .foregroundStyle(Color.rizqText)

        Text(store.isSignUp
          ? "Create your account to start your journey"
          : "Sign in to continue your dua practice journey")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
          .multilineTextAlignment(.center)
      }
    }
  }

  // MARK: - Social Sign In Section
  private var socialSignInSection: some View {
    VStack(spacing: 12) {
      // Google Button
      googleSignInButton
    }
  }

  private var googleSignInButton: some View {
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
      .foregroundStyle(Color.rizqText)
    }
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
    .overlay {
      RoundedRectangle(cornerRadius: RIZQRadius.btn)
        .stroke(Color.rizqBorder, lineWidth: 1)
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

        HStack(spacing: 12) {
          Image(systemName: "envelope")
            .font(.system(size: 18))
            .foregroundStyle(Color.rizqMuted)

          TextField("you@example.com", text: $store.email)
            .font(.rizqSans(.body))
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
        }
        .padding()
        .background(Color.rizqCard)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
        .overlay {
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
            .stroke(Color.rizqBorder, lineWidth: 1)
        }
      }

      // Password Field
      VStack(alignment: .leading, spacing: 8) {
        Text("Password")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        HStack(spacing: 12) {
          Image(systemName: "lock")
            .font(.system(size: 18))
            .foregroundStyle(Color.rizqMuted)

          SecureField("Enter your password", text: $store.password)
            .font(.rizqSans(.body))
            .textContentType(store.isSignUp ? .newPassword : .password)
        }
        .padding()
        .background(Color.rizqCard)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
        .overlay {
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
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
      }
      .rizqPrimaryButton()
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
  }
}

#Preview {
  AuthView(
    store: Store(initialState: AuthFeature.State()) {
      AuthFeature()
    }
  )
}
