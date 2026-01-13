import SwiftUI
import RIZQKit

// MARK: - Linked Account Row
// Displays a single auth provider with link/unlink action

struct LinkedAccountRow: View {
  let provider: AuthProvider
  let isLinked: Bool
  let canUnlink: Bool
  let isLinking: Bool
  let isUnlinking: Bool
  let onLinkTapped: () -> Void
  let onUnlinkTapped: () -> Void

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Provider Icon
      providerIcon

      // Provider Name
      VStack(alignment: .leading, spacing: 2) {
        Text(provider.displayName)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)

        if isLinked {
          Text("Connected")
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.tealSuccess)
        }
      }

      Spacer()

      // Link/Unlink Button
      if isLinked {
        unlinkButton
      } else {
        linkButton
      }
    }
    .padding(.vertical, RIZQSpacing.sm)
  }

  // MARK: - Provider Icon

  private var providerIcon: some View {
    Group {
      switch provider {
      case .google:
        googleIcon
      case .apple:
        appleIcon
      case .github:
        githubIcon
      case .email:
        emailIcon
      }
    }
    .frame(width: 40, height: 40)
    .background(providerBackgroundColor.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
  }

  private var providerBackgroundColor: Color {
    switch provider {
    case .google: return Color(hex: "4285F4")
    case .apple: return Color.primary // Adapts to dark mode
    case .github: return Color.primary // Adapts to dark mode
    case .email: return Color.rizqPrimary
    }
  }

  private var googleIcon: some View {
    // Google "G" logo approximation
    Text("G")
      .font(.system(size: 20, weight: .bold))
      .foregroundStyle(
        LinearGradient(
          colors: [
            Color(hex: "4285F4"),
            Color(hex: "34A853"),
            Color(hex: "FBBC05"),
            Color(hex: "EA4335")
          ],
          startPoint: .topLeading,
          endPoint: .bottomTrailing
        )
      )
  }

  private var appleIcon: some View {
    Image(systemName: "apple.logo")
      .font(.system(size: 20))
      .foregroundStyle(.primary) // Adapts to dark mode
  }

  private var githubIcon: some View {
    Image(systemName: "chevron.left.forwardslash.chevron.right")
      .font(.system(size: 16, weight: .semibold))
      .foregroundStyle(.primary) // Adapts to dark mode
  }

  private var emailIcon: some View {
    Image(systemName: "envelope.fill")
      .font(.system(size: 18))
      .foregroundStyle(Color.rizqPrimary)
  }

  // MARK: - Buttons

  private var linkButton: some View {
    Button(action: onLinkTapped) {
      HStack(spacing: RIZQSpacing.xs) {
        if isLinking {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "link")
            .font(.system(size: 12, weight: .semibold))
        }
        Text("Link")
          .font(.rizqSansSemiBold(.subheadline))
      }
      .foregroundStyle(Color.rizqPrimary)
      .padding(.horizontal, RIZQSpacing.md)
      .padding(.vertical, RIZQSpacing.sm)
      .background(Color.rizqPrimary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
    }
    .disabled(isLinking)
  }

  private var unlinkButton: some View {
    Button(action: onUnlinkTapped) {
      HStack(spacing: RIZQSpacing.xs) {
        if isUnlinking {
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .red))
            .scaleEffect(0.7)
        } else {
          Image(systemName: "link.badge.plus")
            .font(.system(size: 12, weight: .semibold))
            .symbolRenderingMode(.palette)
            .foregroundStyle(.red, .red)
        }
        Text("Unlink")
          .font(.rizqSansSemiBold(.subheadline))
      }
      .foregroundStyle(canUnlink ? .red : Color.rizqTextSecondary)
      .padding(.horizontal, RIZQSpacing.md)
      .padding(.vertical, RIZQSpacing.sm)
      .background(canUnlink ? Color.red.opacity(0.1) : Color.rizqMuted.opacity(0.3))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
    }
    .disabled(!canUnlink || isUnlinking)
  }
}

// MARK: - Preview

#Preview {
  VStack(spacing: 0) {
    LinkedAccountRow(
      provider: .google,
      isLinked: true,
      canUnlink: true,
      isLinking: false,
      isUnlinking: false,
      onLinkTapped: {},
      onUnlinkTapped: {}
    )
    Divider()
    LinkedAccountRow(
      provider: .apple,
      isLinked: false,
      canUnlink: false,
      isLinking: false,
      isUnlinking: false,
      onLinkTapped: {},
      onUnlinkTapped: {}
    )
    Divider()
    LinkedAccountRow(
      provider: .github,
      isLinked: false,
      canUnlink: false,
      isLinking: true,
      isUnlinking: false,
      onLinkTapped: {},
      onUnlinkTapped: {}
    )
  }
  .padding()
  .background(Color.rizqCard)
  .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
  .padding()
  .background(Color.rizqBackground)
}
