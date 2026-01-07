import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin Dashboard View showing stats overview
struct AdminDashboardView: View {
  @Bindable var store: StoreOf<AdminDashboardFeature>

  var body: some View {
    ScrollView {
      VStack(spacing: RIZQSpacing.xl) {
        // Stats Grid
        LazyVGrid(columns: [
          GridItem(.flexible()),
          GridItem(.flexible())
        ], spacing: RIZQSpacing.lg) {
          StatCard(
            title: "Total Duas",
            value: "\(store.stats.totalDuas)",
            icon: "book.fill",
            color: .badgeMorning
          )

          StatCard(
            title: "Journeys",
            value: "\(store.stats.totalJourneys)",
            icon: "map.fill",
            color: .tealMuted
          )

          StatCard(
            title: "Categories",
            value: "\(store.stats.totalCategories)",
            icon: "folder.fill",
            color: .badgeGratitude
          )

          StatCard(
            title: "Users",
            value: "\(store.stats.totalUsers)",
            icon: "person.2.fill",
            color: .badgeEvening
          )
        }

        // Active Users Today
        HStack {
          Image(systemName: "person.badge.clock.fill")
            .foregroundStyle(Color.rizqPrimary)
          Text("Active users today: \(store.stats.activeUsersToday)")
            .font(.rizqSans(.body))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.rizqCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))

        // Quick Actions
        VStack(alignment: .leading, spacing: RIZQSpacing.md) {
          Text("Quick Actions")
            .font(.rizqDisplayMedium(.headline))

          VStack(spacing: RIZQSpacing.sm) {
            QuickActionRow(
              title: "Manage Duas",
              icon: "book.fill",
              color: .badgeMorning
            ) {
              store.send(.navigateToSection(.duas))
            }

            QuickActionRow(
              title: "Manage Journeys",
              icon: "map.fill",
              color: .tealMuted
            ) {
              store.send(.navigateToSection(.journeys))
            }

            QuickActionRow(
              title: "Manage Categories",
              icon: "folder.fill",
              color: .badgeGratitude
            ) {
              store.send(.navigateToSection(.categories))
            }
          }
        }
      }
      .padding()
    }
    .navigationTitle("Dashboard")
    .rizqPageBackground()
    .overlay {
      if store.isLoading {
        ProgressView()
          .scaleEffect(1.5)
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") {
        store.send(.dismissError)
      }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .onAppear {
      store.send(.loadStats)
    }
  }
}

// MARK: - Stat Card

private struct StatCard: View {
  let title: String
  let value: String
  let icon: String
  let color: Color

  var body: some View {
    VStack(spacing: RIZQSpacing.md) {
      ZStack {
        Circle()
          .fill(color.opacity(0.15))
          .frame(width: 48, height: 48)

        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(color)
      }

      Text(value)
        .font(.rizqMono(.title))
        .foregroundStyle(Color.rizqText)

      Text(title)
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

// MARK: - Quick Action Row

private struct QuickActionRow: View {
  let title: String
  let icon: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: RIZQSpacing.md) {
        Image(systemName: icon)
          .foregroundStyle(color)

        Text(title)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)

        Spacer()

        Image(systemName: "chevron.right")
          .font(.caption)
          .foregroundStyle(Color.rizqTextSecondary)
      }
      .padding()
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .buttonStyle(.plain)
  }
}

#Preview {
  NavigationStack {
    AdminDashboardView(
      store: Store(initialState: AdminDashboardFeature.State()) {
        AdminDashboardFeature()
      }
    )
  }
}
