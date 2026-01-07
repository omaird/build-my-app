import SwiftUI
import ComposableArchitecture
import RIZQKit

struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  // Animation namespace for matched geometry effects
  @Namespace private var animation

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xxl) {
          // Welcome Header with greeting
          welcomeHeader
            .modifier(StaggeredAnimationModifier(index: 0))

          // Stats Cards Grid (Streak + Level)
          statsCardsGrid
            .modifier(StaggeredAnimationModifier(index: 1))

          // XP Progress Bar
          xpProgressSection
            .modifier(StaggeredAnimationModifier(index: 2))

          // Habits Summary Card
          habitsSummarySection
            .modifier(StaggeredAnimationModifier(index: 3))

          // Today's Practice Quick Actions
          todaysPracticeSection
            .modifier(StaggeredAnimationModifier(index: 4))

          // Browse Library CTA
          browseLibraryCTA
            .modifier(StaggeredAnimationModifier(index: 5))
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.top, RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.huge)
      }
      .refreshable {
        store.send(.refreshData)
      }
      .rizqPageBackground()
      .overlay {
        if store.isLoading {
          loadingOverlay
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Welcome Header

  private var welcomeHeader: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      Text(store.greeting)
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)

      Text(store.displayName.isEmpty ? "Welcome" : store.displayName)
        .font(.rizqDisplayBold(.largeTitle))
        .foregroundStyle(Color.rizqText)

      Text(store.motivationalPhrase)
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Stats Cards Grid

  private var statsCardsGrid: some View {
    HStack(spacing: RIZQSpacing.lg) {
      // Streak Card with animation
      StreakBadge(
        streak: store.streak,
        isAnimating: store.isStreakAnimating
      )

      // Level Card with circular progress
      VStack {
        CircularXpProgress(
          level: store.level,
          percentage: store.xpProgress.percentage,
          size: 80,
          strokeWidth: 6
        )
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, RIZQSpacing.xl)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
  }

  // MARK: - XP Progress Section

  private var xpProgressSection: some View {
    XpProgressBar(
      current: store.xpProgress.current,
      needed: store.xpProgress.needed,
      level: store.level,
      xpToNextLevel: store.xpProgress.xpToNextLevel
    )
  }

  // MARK: - Habits Summary Section

  private var habitsSummarySection: some View {
    HabitsSummaryCard(
      completed: store.todaysProgress.completed,
      total: store.todaysProgress.total,
      percentage: store.todaysProgress.percentage,
      xpEarned: store.todaysProgress.xpEarned,
      onTap: {
        store.send(.navigateToAdkhar)
      }
    )
  }

  // MARK: - Today's Practice Section

  private var todaysPracticeSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.lg) {
      Text("Today's Practice")
        .font(.rizqDisplayMedium(.headline))
        .foregroundStyle(Color.rizqText)

      VStack(spacing: RIZQSpacing.md) {
        // Morning Adhkar
        practiceActionRow(
          icon: "sun.max.fill",
          iconColor: .badgeMorning,
          title: "Morning Adhkar",
          subtitle: "Start your day with remembrance",
          timeSlot: .morning
        )

        // Anytime Duas
        practiceActionRow(
          icon: "clock.fill",
          iconColor: .tealMuted,
          title: "Anytime Duas",
          subtitle: "Supplications for any moment",
          timeSlot: .anytime
        )

        // Evening Adhkar
        practiceActionRow(
          icon: "moon.fill",
          iconColor: .badgeEvening,
          title: "Evening Adhkar",
          subtitle: "End your day with gratitude",
          timeSlot: .evening
        )
      }
    }
  }

  private func practiceActionRow(
    icon: String,
    iconColor: Color,
    title: String,
    subtitle: String,
    timeSlot: TimeSlot
  ) -> some View {
    Button {
      store.send(.navigateToPractice(timeSlot))
    } label: {
      HStack(spacing: RIZQSpacing.md) {
        ZStack {
          Circle()
            .fill(iconColor.opacity(0.15))
            .frame(width: 44, height: 44)

          Image(systemName: icon)
            .font(.title3)
            .foregroundStyle(iconColor)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.rizqSansSemiBold(.body))
            .foregroundStyle(Color.rizqText)

          Text(subtitle)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(Color.rizqMuted)
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
    .buttonStyle(ScaleButtonStyle())
  }

  // MARK: - Browse Library CTA

  private var browseLibraryCTA: some View {
    Button {
      store.send(.navigateToLibrary)
    } label: {
      HStack(spacing: RIZQSpacing.md) {
        ZStack {
          Circle()
            .fill(Color.rizqPrimary.opacity(0.2))
            .frame(width: 44, height: 44)

          Image(systemName: "book.fill")
            .font(.title3)
            .foregroundStyle(Color.rizqPrimary)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text("Browse Library")
            .font(.rizqSansSemiBold(.body))
            .foregroundStyle(Color.rizqText)

          Text("Explore all duas and journeys")
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        Spacer()

        Image(systemName: "chevron.right")
          .font(.subheadline.weight(.medium))
          .foregroundStyle(Color.rizqPrimary)
      }
      .padding(RIZQSpacing.lg)
      .background(Color.rizqPrimary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 1)
      )
    }
    .buttonStyle(ScaleButtonStyle())
  }

  // MARK: - Loading Overlay

  private var loadingOverlay: some View {
    ZStack {
      Color.rizqBackground.opacity(0.8)
        .ignoresSafeArea()

      VStack(spacing: RIZQSpacing.lg) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: .rizqPrimary))
          .scaleEffect(1.2)

        Text("Loading...")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }
      .padding(RIZQSpacing.xxl)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowElevated()
    }
    .transition(.opacity)
  }
}

// MARK: - Staggered Animation Modifier

/// Modifier for staggered entry animations (matches Framer Motion staggerChildren)
struct StaggeredAnimationModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double {
    0.1 + Double(index) * 0.08
  }

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 20)
      .onAppear {
        withAnimation(
          .spring(response: 0.4, dampingFraction: 0.75)
          .delay(delay)
        ) {
          isVisible = true
        }
      }
  }
}

// MARK: - Scale Button Style

/// Button style with scale animation on press
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Preview

#Preview("Home View - Default") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      displayName: "Omar",
      streak: 7,
      totalXp: 450,
      level: 3,
      todaysProgress: TodayProgress(completed: 3, total: 5, xpEarned: 45)
    )) {
      HomeFeature()
    }
  )
}

#Preview("Home View - New User") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      displayName: "Friend",
      streak: 0,
      totalXp: 0,
      level: 1,
      todaysProgress: TodayProgress(completed: 0, total: 0, xpEarned: 0)
    )) {
      HomeFeature()
    }
  )
}

#Preview("Home View - Streak Animation") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      displayName: "Omar",
      streak: 7,
      totalXp: 450,
      level: 3,
      todaysProgress: TodayProgress(completed: 5, total: 5, xpEarned: 75),
      isStreakAnimating: true
    )) {
      HomeFeature()
    }
  )
}
