import SwiftUI
import ComposableArchitecture
import RIZQKit

struct SettingsView: View {
  @Bindable var store: StoreOf<SettingsFeature>

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xl) {
          // Success/Error Messages
          messageView

          // Profile Header
          profileHeader

          // Linked Accounts Section
          linkedAccountsSection

          // Preferences Section
          preferencesSection

          // Admin Section (only visible for admins)
          adminSection

          // Account Section
          accountSection

          // Danger Zone Section
          dangerZoneSection

          // App Info
          appInfoView
        }
        .padding(RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.huge) // Bottom padding for tab bar
      }
      .scrollContentBackground(.hidden)
      .background(Color.rizqBackground)
      .navigationTitle("Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(Color.rizqBackground, for: .navigationBar)
      // Sign Out Alert
      .alert("Sign Out", isPresented: $store.showingSignOutAlert) {
        Button("Cancel", role: .cancel) {
          store.send(.cancelSignOut)
        }
        Button("Sign Out", role: .destructive) {
          store.send(.confirmSignOut)
        }
      } message: {
        Text("Are you sure you want to sign out? You will need to sign in again to access your data.")
      }
      // Unlink Account Alert
      .alert("Unlink Account", isPresented: $store.showingUnlinkAlert) {
        Button("Cancel", role: .cancel) {
          store.send(.cancelUnlinkAccount)
        }
        Button("Unlink", role: .destructive) {
          store.send(.confirmUnlinkAccount)
        }
      } message: {
        if let provider = store.providerToUnlink {
          Text("Are you sure you want to unlink your \(provider.displayName) account?")
        } else {
          Text("Are you sure you want to unlink this account?")
        }
      }
      // Reset Progress Alert
      .alert("Reset All Progress?", isPresented: $store.showingResetProgressAlert) {
        Button("Cancel", role: .cancel) {
          store.send(.cancelResetProgress)
        }
        Button("Reset Progress", role: .destructive) {
          store.send(.confirmResetProgress)
        }
      } message: {
        Text("This will reset your XP to 0, level to 1, and streak to 0. This action cannot be undone.")
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Message View

  @ViewBuilder
  private var messageView: some View {
    if let successMessage = store.successMessage {
      HStack(spacing: RIZQSpacing.sm) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.tealSuccess)

        Text(successMessage)
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqText)

        Spacer()

        Button {
          store.send(.clearSuccess)
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
      .padding(RIZQSpacing.md)
      .background(Color.tealSuccess.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.md))
      .transition(.move(edge: .top).combined(with: .opacity))
    }

    if let errorMessage = store.errorMessage {
      HStack(spacing: RIZQSpacing.sm) {
        Image(systemName: "exclamationmark.circle.fill")
          .foregroundStyle(.red)

        Text(errorMessage)
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqText)

        Spacer()

        Button {
          store.send(.clearError)
        } label: {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
      .padding(RIZQSpacing.md)
      .background(Color.red.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.md))
      .transition(.move(edge: .top).combined(with: .opacity))
    }
  }

  // MARK: - Profile Header

  @ViewBuilder
  private var profileHeader: some View {
    if store.isLoading {
      // Loading State
      VStack(spacing: RIZQSpacing.lg) {
        HStack(spacing: RIZQSpacing.lg) {
          Circle()
            .fill(Color.rizqMuted.opacity(0.3))
            .frame(width: 64, height: 64)

          VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
            RoundedRectangle(cornerRadius: 4)
              .fill(Color.rizqMuted.opacity(0.3))
              .frame(width: 120, height: 20)

            RoundedRectangle(cornerRadius: 4)
              .fill(Color.rizqMuted.opacity(0.3))
              .frame(width: 160, height: 14)
          }

          Spacer()
        }

        HStack(spacing: RIZQSpacing.lg) {
          ForEach(0..<3, id: \.self) { _ in
            VStack(spacing: RIZQSpacing.xs) {
              Circle()
                .fill(Color.rizqMuted.opacity(0.3))
                .frame(width: 40, height: 40)

              RoundedRectangle(cornerRadius: 4)
                .fill(Color.rizqMuted.opacity(0.3))
                .frame(width: 30, height: 16)

              RoundedRectangle(cornerRadius: 4)
                .fill(Color.rizqMuted.opacity(0.3))
                .frame(width: 50, height: 10)
            }
            .frame(maxWidth: .infinity)
          }
        }
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .redacted(reason: .placeholder)
      .shimmering()
    } else {
      ProfileHeaderView(
        displayName: store.displayName,
        email: store.email,
        profileImageUrl: store.profileImageUrl,
        level: store.profile?.level ?? 1,
        totalXp: store.profile?.totalXp ?? 0,
        streak: store.profile?.streak ?? 0,
        isEditing: store.isEditingDisplayName,
        editedName: $store.editedDisplayName,
        isSaving: store.isSavingDisplayName,
        onEditTapped: { store.send(.editDisplayNameTapped) },
        onSaveTapped: { store.send(.saveDisplayNameTapped) },
        onCancelTapped: { store.send(.cancelEditDisplayName) }
      )
    }
  }

  // MARK: - Linked Accounts Section

  private var linkedAccountsSection: some View {
    SettingsSection(title: "Linked Accounts") {
      if store.isLoadingAccounts {
        linkedAccountsLoadingContent
      } else {
        linkedAccountsContent
      }
    }
  }

  @ViewBuilder
  private var linkedAccountsLoadingContent: some View {
    ForEach(0..<3, id: \.self) { index in
      if index > 0 {
        Divider()
      }
      linkedAccountsSkeletonRow
    }
  }

  private var linkedAccountsSkeletonRow: some View {
    HStack {
      RoundedRectangle(cornerRadius: RIZQRadius.sm)
        .fill(Color.rizqMuted.opacity(0.3))
        .frame(width: 40, height: 40)

      VStack(alignment: .leading) {
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.rizqMuted.opacity(0.3))
          .frame(width: 80, height: 16)
      }

      Spacer()

      RoundedRectangle(cornerRadius: RIZQRadius.sm)
        .fill(Color.rizqMuted.opacity(0.3))
        .frame(width: 60, height: 32)
    }
    .padding(.vertical, RIZQSpacing.sm)
    .redacted(reason: .placeholder)
  }

  @ViewBuilder
  private var linkedAccountsContent: some View {
    let providers = store.availableProviders
    ForEach(providers.indices, id: \.self) { index in
      let provider = providers[index]
      if index > 0 {
        Divider()
      }
      makeLinkedAccountRow(for: provider)
    }
  }

  private func makeLinkedAccountRow(for provider: AuthProvider) -> some View {
    let linkedAccounts = store.linkedAccounts
    let isLinked = linkedAccounts.contains { $0.provider == provider }
    let canUnlink = linkedAccounts.count > 1
    let isLinking = store.isLinkingAccount == provider
    let isUnlinking = store.isUnlinkingAccount == provider

    return LinkedAccountRow(
      provider: provider,
      isLinked: isLinked,
      canUnlink: canUnlink,
      isLinking: isLinking,
      isUnlinking: isUnlinking,
      onLinkTapped: { store.send(.linkAccountTapped(provider)) },
      onUnlinkTapped: { store.send(.unlinkAccountTapped(provider)) }
    )
  }

  // MARK: - Preferences Section

  private var preferencesSection: some View {
    SettingsSection(title: "Preferences") {
      SettingsRow.toggle(
        icon: "moon.fill",
        iconColor: Color(hex: "6366F1"),
        title: "Dark Mode",
        isOn: Binding(
          get: { store.isDarkMode },
          set: { store.send(.darkModeToggled($0)) }
        )
      )

      Divider()

      SettingsRow.toggle(
        icon: "bell.fill",
        iconColor: Color.streakGlow,
        title: "Notifications",
        subtitle: "Daily reminders for your habits",
        isOn: Binding(
          get: { store.notificationsEnabled },
          set: { store.send(.notificationsToggled($0)) }
        )
      )
    }
  }

  // MARK: - Admin Section

  @ViewBuilder
  private var adminSection: some View {
    if store.profile?.isAdmin == true {
      SettingsSection(title: "Administration") {
        SettingsRow.navigation(
          icon: "slider.horizontal.3",
          iconColor: Color.rizqPrimary,
          title: "Admin Panel",
          subtitle: "Manage duas, journeys & users",
          action: { store.send(.adminPanelTapped) }
        )
      }
    }
  }

  // MARK: - Account Section

  private var accountSection: some View {
    SettingsSection(title: "Account") {
      SettingsRow.navigation(
        icon: "rectangle.portrait.and.arrow.right",
        iconColor: Color.rizqTextSecondary,
        title: "Sign Out",
        action: { store.send(.signOutTapped) }
      )
    }
  }

  // MARK: - Danger Zone Section

  private var dangerZoneSection: some View {
    SettingsSection(title: "Danger Zone") {
      SettingsRow.destructive(
        icon: "trash.fill",
        title: "Reset Progress",
        subtitle: "Reset XP, level, and streak to zero",
        isLoading: store.isResettingProgress,
        action: { store.send(.resetProgressTapped) }
      )
    }
  }

  // MARK: - App Info

  private var appInfoView: some View {
    VStack(spacing: RIZQSpacing.sm) {
      Text("RIZQ App v1.0.0")
        .font(.rizqSans(.footnote))
        .foregroundStyle(Color.rizqTextSecondary)

      Text("Built with love for the Ummah")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary.opacity(0.7))
    }
    .padding(.top, RIZQSpacing.lg)
  }
}

// MARK: - Shimmer Effect Modifier

extension View {
  func shimmering() -> some View {
    self.modifier(ShimmerModifier())
  }
}

struct ShimmerModifier: ViewModifier {
  @State private var isAnimating = false
  @Environment(\.colorScheme) private var colorScheme

  func body(content: Content) -> some View {
    content
      .overlay {
        GeometryReader { geometry in
          // Use adaptive shimmer color: white for light mode, lighter gray for dark mode
          let shimmerColor = colorScheme == .dark ? Color.gray : Color.white
          LinearGradient(
            colors: [
              shimmerColor.opacity(0),
              shimmerColor.opacity(0.3),
              shimmerColor.opacity(0)
            ],
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: geometry.size.width * 2)
          .offset(x: isAnimating ? geometry.size.width : -geometry.size.width)
        }
        .mask(content)
      }
      .onAppear {
        withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
          isAnimating = true
        }
      }
  }
}


// MARK: - Preview

#Preview("Settings - Loaded") {
  SettingsView(
    store: Store(
      initialState: SettingsFeature.State(
        user: AuthUser(
          id: "user-001",
          email: "omar@example.com",
          name: "Omar",
          image: nil,
          emailVerified: true
        ),
        profile: UserProfile(
          id: "profile-001",
          userId: "user-001",
          displayName: "Omar",
          streak: 5,
          totalXp: 350,
          level: 2
        ),
        linkedAccounts: [
          LinkedAccount(
            id: "account-001",
            provider: .google,
            providerAccountId: "google-123"
          )
        ]
      )
    ) {
      SettingsFeature()
    }
  )
}

#Preview("Settings - Loading") {
  SettingsView(
    store: Store(
      initialState: SettingsFeature.State(
        isLoading: true,
        isLoadingAccounts: true
      )
    ) {
      SettingsFeature()
    }
  )
}

#Preview("Settings - Editing Name") {
  SettingsView(
    store: Store(
      initialState: SettingsFeature.State(
        user: AuthUser(
          id: "user-001",
          email: "omar@example.com",
          name: "Omar"
        ),
        profile: UserProfile(
          id: "profile-001",
          userId: "user-001",
          displayName: "Omar",
          streak: 5,
          totalXp: 350,
          level: 2
        ),
        linkedAccounts: [
          LinkedAccount(id: "1", provider: .google, providerAccountId: "g1")
        ],
        isEditingDisplayName: true,
        editedDisplayName: "Omar"
      )
    ) {
      SettingsFeature()
    }
  )
}
