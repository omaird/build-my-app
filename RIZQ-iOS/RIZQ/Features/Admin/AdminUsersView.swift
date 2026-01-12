import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin view for managing users
struct AdminUsersView: View {
  @Bindable var store: StoreOf<AdminUsersFeature>

  var body: some View {
    List {
      // Stats Section
      Section {
        HStack(spacing: RIZQSpacing.md) {
          StatItem(title: "Total", value: "\(store.totalUsers)", icon: "person.2.fill", color: .rizqPrimary)
          StatItem(title: "Admins", value: "\(store.adminCount)", icon: "shield.fill", color: .badgeEvening)
          StatItem(title: "Premium", value: "\(store.premiumCount)", icon: "crown.fill", color: .goldSoft)
          StatItem(title: "Active", value: "\(store.activeToday)", icon: "checkmark.circle.fill", color: .tealMuted)
        }
        .padding(.vertical, 8)
      }

      // Search
      Section {
        HStack {
          Image(systemName: "magnifyingglass")
            .foregroundStyle(Color.rizqTextSecondary)
          TextField("Search users...", text: $store.searchQuery)
            .textFieldStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color.rizqSurface)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.md))
      }
      .listRowInsets(EdgeInsets())
      .listRowBackground(Color.clear)

      // Users List
      Section {
        ForEach(store.filteredUsers) { user in
          UserAdminRow(
            user: user,
            onToggleAdmin: { store.send(.toggleAdminTapped(user)) },
            onTogglePremium: { store.send(.togglePremiumTapped(user)) },
            onDelete: { store.send(.deleteUserTapped(user)) },
            onTap: { store.send(.userTapped(user)) }
          )
        }
      }
    }
    .listStyle(.insetGrouped)
    .navigationTitle("Users")
    .rizqPageBackground()
    .overlay {
      if store.isLoading {
        ProgressView()
      } else if store.filteredUsers.isEmpty && !store.searchQuery.isEmpty {
        ContentUnavailableView(
          "No Results",
          systemImage: "magnifyingglass",
          description: Text("No users match '\(store.searchQuery)'")
        )
      } else if store.users.isEmpty {
        ContentUnavailableView(
          "No Users",
          systemImage: "person.2",
          description: Text("No users registered yet")
        )
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") { store.send(.dismissError) }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .alert("Success", isPresented: .constant(store.successMessage != nil)) {
      Button("OK") { store.send(.dismissSuccess) }
    } message: {
      Text(store.successMessage ?? "")
    }
    .alert("Toggle Admin Rights", isPresented: $store.isToggleAdminConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelToggleAdmin) }
      Button(store.userToToggleAdmin?.isAdmin == true ? "Remove Admin" : "Make Admin",
             role: store.userToToggleAdmin?.isAdmin == true ? .destructive : .none) {
        store.send(.confirmToggleAdmin)
      }
    } message: {
      if let user = store.userToToggleAdmin {
        Text(user.isAdmin
             ? "Remove admin rights from \(user.displayName ?? user.userId)?"
             : "Grant admin rights to \(user.displayName ?? user.userId)?")
      }
    }
    .alert("Toggle Premium Status", isPresented: $store.isTogglePremiumConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelTogglePremium) }
      Button(store.userToTogglePremium?.isPremium == true ? "Remove Premium" : "Make Premium",
             role: store.userToTogglePremium?.isPremium == true ? .destructive : .none) {
        store.send(.confirmTogglePremium)
      }
    } message: {
      if let user = store.userToTogglePremium {
        Text(user.isPremium
             ? "Remove premium status from \(user.displayName ?? user.userId)?"
             : "Upgrade \(user.displayName ?? user.userId) to premium?")
      }
    }
    .alert("Delete User", isPresented: $store.isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelDelete) }
      Button("Delete", role: .destructive) { store.send(.confirmDelete) }
    } message: {
      if let user = store.userToDelete {
        Text("Are you sure you want to delete \(user.displayName ?? user.userId)? This action cannot be undone.")
      }
    }
    .sheet(isPresented: $store.isShowingUserDetail) {
      if let user = store.selectedUser {
        UserDetailSheet(user: user, store: store)
      }
    }
    .onAppear {
      store.send(.loadUsers)
    }
  }
}

// MARK: - Stat Item

private struct StatItem: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: 4) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.caption)
        Text(value)
          .font(.rizqDisplay(.title2))
      }
      .foregroundStyle(color)

      Text(title)
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
  }
}

// MARK: - User Admin Row

private struct UserAdminRow: View {
  let user: UserProfile
  let onToggleAdmin: () -> Void
  let onTogglePremium: () -> Void
  let onDelete: () -> Void
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: RIZQSpacing.md) {
        // Avatar
        ZStack {
          Circle()
            .fill(avatarColor.opacity(0.15))
            .frame(width: 48, height: 48)

          Text(initials)
            .font(.rizqSansSemiBold(.body))
            .foregroundStyle(avatarColor)
        }

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(user.displayName ?? "Anonymous")
              .font(.rizqSans(.body))
              .foregroundStyle(Color.rizqText)

            if user.isAdmin {
              Text("ADMIN")
                .font(.rizqMono(.caption2))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.badgeEvening)
                .clipShape(Capsule())
            }

            if user.isPremium {
              Text("PREMIUM")
                .font(.rizqMono(.caption2))
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.goldSoft)
                .clipShape(Capsule())
            }
          }

          HStack(spacing: 8) {
            Label("\(user.level)", systemImage: "star.fill")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.goldSoft)

            Label("\(user.totalXp) XP", systemImage: "bolt.fill")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqPrimary)

            if user.streak > 0 {
              Label("\(user.streak)", systemImage: "flame.fill")
                .font(.rizqSans(.caption))
                .foregroundStyle(Color.badgeMorning)
            }
          }

          Text(user.userId.prefix(8) + "...")
            .font(.rizqMono(.caption2))
            .foregroundStyle(Color.rizqTextTertiary)
        }

        Spacer()

        Menu {
          Button(user.isAdmin ? "Remove Admin" : "Make Admin",
                 systemImage: user.isAdmin ? "shield.slash" : "shield.fill") {
            onToggleAdmin()
          }

          Button(user.isPremium ? "Remove Premium" : "Make Premium",
                 systemImage: user.isPremium ? "crown" : "crown.fill") {
            onTogglePremium()
          }

          Divider()

          Button("Delete", systemImage: "trash", role: .destructive) {
            onDelete()
          }
        } label: {
          Image(systemName: "ellipsis.circle")
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
      .padding(.vertical, 8)
    }
    .buttonStyle(.plain)
  }

  private var initials: String {
    if let name = user.displayName, !name.isEmpty {
      let words = name.split(separator: " ")
      if words.count >= 2 {
        return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
      }
      return String(name.prefix(2)).uppercased()
    }
    return "?"
  }

  private var avatarColor: Color {
    // Generate consistent color based on userId hash
    let hash = abs(user.userId.hashValue)
    let colors: [Color] = [.rizqPrimary, .tealMuted, .badgeMorning, .badgeEvening, .badgeGratitude]
    return colors[hash % colors.count]
  }
}

// MARK: - User Detail Sheet

private struct UserDetailSheet: View {
  let user: UserProfile
  @Bindable var store: StoreOf<AdminUsersFeature>
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      List {
        Section {
          // Avatar and basic info
          VStack(spacing: RIZQSpacing.md) {
            ZStack {
              Circle()
                .fill(Color.rizqPrimary.opacity(0.15))
                .frame(width: 80, height: 80)

              Text(initials)
                .font(.rizqDisplay(.title))
                .foregroundStyle(Color.rizqPrimary)
            }

            Text(user.displayName ?? "Anonymous")
              .font(.rizqDisplay(.title2))

            HStack(spacing: 8) {
              if user.isAdmin {
                Text("Administrator")
                  .font(.rizqSans(.caption))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 4)
                  .background(Color.badgeEvening)
                  .clipShape(Capsule())
              }

              if user.isPremium {
                Text("Premium")
                  .font(.rizqSans(.caption))
                  .foregroundStyle(.white)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 4)
                  .background(Color.goldSoft)
                  .clipShape(Capsule())
              }

              if !user.isAdmin && !user.isPremium {
                Text("Free User")
                  .font(.rizqSans(.caption))
                  .foregroundStyle(Color.rizqTextSecondary)
                  .padding(.horizontal, 10)
                  .padding(.vertical, 4)
                  .background(Color.rizqSurface)
                  .clipShape(Capsule())
              }
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical)
        }
        .listRowBackground(Color.clear)

        Section("Stats") {
          LabeledContent("Level", value: "\(user.level)")
          LabeledContent("Total XP", value: "\(user.totalXp)")
          LabeledContent("Current Streak", value: "\(user.streak) days")
        }

        Section("Account") {
          LabeledContent("User ID") {
            Text(user.userId)
              .font(.rizqMono(.caption))
              .foregroundStyle(Color.rizqTextSecondary)
          }

          if let lastActive = user.lastActiveDate {
            LabeledContent("Last Active") {
              Text(lastActive, style: .relative)
            }
          }

          LabeledContent("Created") {
            Text(user.createdAt, style: .date)
          }
        }

        Section("Role Management") {
          Button(user.isAdmin ? "Remove Admin Rights" : "Grant Admin Rights") {
            store.send(.toggleAdminTapped(user))
            dismiss()
          }
          .foregroundStyle(user.isAdmin ? Color.red : Color.rizqPrimary)

          Button(user.isPremium ? "Remove Premium Status" : "Upgrade to Premium") {
            store.send(.togglePremiumTapped(user))
            dismiss()
          }
          .foregroundStyle(user.isPremium ? Color.red : Color.goldSoft)
        }

        Section {
          Button("Delete User", role: .destructive) {
            store.send(.deleteUserTapped(user))
            dismiss()
          }
        }
      }
      .navigationTitle("User Details")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") { store.send(.closeUserDetail) }
        }
      }
    }
  }

  private var initials: String {
    if let name = user.displayName, !name.isEmpty {
      let words = name.split(separator: " ")
      if words.count >= 2 {
        return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
      }
      return String(name.prefix(2)).uppercased()
    }
    return "?"
  }
}

#Preview {
  NavigationStack {
    AdminUsersView(
      store: Store(initialState: AdminUsersFeature.State()) {
        AdminUsersFeature()
      }
    )
  }
}
