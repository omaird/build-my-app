import SwiftUI
import UIKit
import ComposableArchitecture
import RIZQKit

// MARK: - HomeView
/// The main dashboard view displaying user progress and gamification elements.
///
/// ## Layout Structure (Top to Bottom)
/// 1. Header - Avatar, greeting, name, motivational phrase, streak badge (index 0)
/// 2. Daily Quote - Inspirational Islamic quote with RTL Arabic support (index 1)
/// 3. Hero Stats Card - Circular XP progress with level indicator (index 2)
/// 4. Week Calendar - 7-day activity history with completion dots (index 3)
/// 5. Motivational Progress - Dynamic encouragement with next achievement preview (index 4)
/// 6. Daily Adkhar Section - Summary card linking to habits (index 5)
/// 7. Bottom CTAs - Browse Journeys (primary) and Explore Duas (secondary) (index 6)
///
/// ## Overlays
/// - Loading overlay when `isLoading` is true
/// - Error overlay with retry button when `loadError` is present
///
/// ## Animations
/// - Staggered entry animations on each section (0.08s delay per item)
/// - Spring animations for smooth, natural motion
/// - Pull-to-refresh triggers data reload
///
/// ## New Components Integrated (Feature 5)
/// - DailyQuoteView: Islamic quote card with share callback to TCA action
/// - MotivationalProgressView: Contextual motivation with action callback to TCA
///
/// ## Feature 5 Acceptance Criteria
/// 1. ✅ DailyQuoteView integrated at index 1 with share callback
/// 2. ✅ MotivationalProgressView integrated at index 4 with action callback
/// 3. ✅ All 7 sections have StaggeredAnimationModifier
/// 4. ✅ Computed properties used for dailyQuote, motivationState, nextAchievement
/// 5. ✅ Pull-to-refresh updates all data
/// 6. ✅ Accessibility hint corrected for avatar button
/// 7. ✅ Force unwrap removed from preview with nil-coalescing
/// 8. ✅ All previews render correctly (Default, New User, Streak Animation)
/// 9. ✅ Build compiles without errors
///
/// ## Related Files
/// - HomeFeature.swift: TCA reducer with state, actions, and effects
/// - DailyQuoteView.swift: Islamic quote card component
/// - MotivationalProgressView.swift: Dynamic motivation section
/// - RIZQTests/RIZQTests.swift: Unit tests for HomeFeature integration
struct HomeView: View {
  @Bindable var store: StoreOf<HomeFeature>

  // Animation namespace for matched geometry effects
  @Namespace private var animation

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.lg) {
          // Header with avatar, greeting, and streak
          headerSection
            .modifier(StaggeredAnimationModifier(index: 0))

          // Daily Quote - inspirational Islamic quote for the day
          DailyQuoteView(
            quote: store.dailyQuote,
            onShareTapped: {
              store.send(.shareQuoteTapped)
            }
          )
          .modifier(StaggeredAnimationModifier(index: 1))

          // Hero Stats Card with Circular XP Progress
          heroStatsCard
            .modifier(StaggeredAnimationModifier(index: 2))

          // Week Calendar
          WeekCalendarView(activities: store.weekActivityItems)
            .modifier(StaggeredAnimationModifier(index: 3))

          // Motivational Progress - dynamic encouragement with next achievement preview
          MotivationalProgressView(
            motivationState: store.motivationState,
            streak: store.streak,
            nextAchievement: store.nextAchievement,
            habitsCompleted: store.todaysProgress.completed,
            totalHabits: store.todaysProgress.total,
            onActionTapped: {
              store.send(.motivationActionTapped)
            }
          )
          .modifier(StaggeredAnimationModifier(index: 4))

          // Daily Adkhar Section
          dailyAdkharSection
            .modifier(StaggeredAnimationModifier(index: 5))

          // Bottom CTA Buttons
          bottomCTAButtons
            .modifier(StaggeredAnimationModifier(index: 6))
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
        } else if let error = store.loadError {
          errorOverlay(error: error)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Error Overlay

  private func errorOverlay(error: String) -> some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(Color.rizqPrimary)
        .accessibilityHidden(true)

      Text("Something went wrong")
        .font(.rizqDisplayMedium(.headline))
        .foregroundStyle(Color.rizqText)

      Text(error)
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, RIZQSpacing.xl)

      Button {
        store.send(.refreshData)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "arrow.clockwise")
          Text("Try Again")
        }
        .font(.rizqSansMedium(.subheadline))
        .foregroundStyle(.white)
        .padding(.horizontal, RIZQSpacing.xl)
        .padding(.vertical, RIZQSpacing.md)
        .background(Color.rizqPrimary)
        .clipShape(Capsule())
      }
      .buttonStyle(ScaleButtonStyle())
      .accessibilityLabel("Try again")
      .accessibilityHint("Reload your dashboard")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.rizqBackground.opacity(0.95))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Error: Something went wrong. \(error)")
    .accessibilityAddTraits(.isModal)
  }

  // MARK: - Header Section

  private var headerSection: some View {
    HStack(alignment: .top) {
      // Left side: Avatar + Greeting + Name + Phrase
      HStack(spacing: RIZQSpacing.md) {
        // Profile Avatar - navigates to Daily Adkhar for quick habit access
        Button {
          store.send(.navigateToAdkhar)
        } label: {
          UserAvatar(
            imageURL: store.profileImageURL,
            displayName: store.displayName.isEmpty ? "Friend" : store.displayName,
            size: 56
          )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Profile")
        .accessibilityHint("Opens your daily adkhar habits")

        // Text content
        VStack(alignment: .leading, spacing: 2) {
          Text(store.greeting)
            .font(.rizqSans(.subheadline))
            .foregroundStyle(Color.rizqTextSecondary)

          Text(store.displayName.isEmpty ? "Welcome" : store.displayName)
            .font(.rizqDisplayBold(.title2))
            .foregroundStyle(Color.rizqText)

          Text(store.motivationalPhrase)
            .font(.rizqSans(.subheadline))
            .foregroundStyle(Color.rizqPrimary.opacity(0.7))
        }
      }

      Spacer()

      // Right side: Streak badge
      CompactStreakBadge(streak: store.streak)
        .accessibilityLabel("\(store.streak) day streak")
        .accessibilityHint("Your consecutive days of practice")
    }
  }

  // MARK: - Hero Stats Card

  private var heroStatsCard: some View {
    HStack(spacing: RIZQSpacing.lg) {
      // Circular XP Progress
      CircularXpProgress(
        level: store.level,
        percentage: store.xpProgress.percentage,
        size: 90,
        strokeWidth: 8
      )

      // Progress details
      VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
        VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
          Text("Level \(store.level)")
            .font(.rizqDisplayMedium(.title3))
            .foregroundStyle(Color.rizqText)

          Text("\(store.xpProgress.current) / \(store.xpProgress.needed) XP to next level")
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }

        // Linear progress bar with animation
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            // Track
            Capsule()
              .fill(Color.rizqMuted.opacity(0.3))
              .frame(height: 8)

            // Progress fill
            Capsule()
              .fill(
                LinearGradient(
                  colors: [Color.rizqPrimary, Color.rizqPrimary.opacity(0.8)],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(width: geometry.size.width * store.xpProgress.percentage, height: 8)
              .animation(.easeOut(duration: 0.8).delay(0.3), value: store.xpProgress.percentage)
          }
        }
        .frame(height: 8)
      }
    }
    .padding(RIZQSpacing.xl)
    .background(Color.rizqCard)
    .overlay(
      // Subtle pattern overlay
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.rizqPrimary.opacity(0.1), lineWidth: 2)
    )
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowElevated()
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Level \(store.level), \(store.xpProgress.current) of \(store.xpProgress.needed) XP to next level")
  }

  // MARK: - Daily Adkhar Section

  private var dailyAdkharSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      Text("DAILY ADKHAR")
        .font(.rizqSansSemiBold(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

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
  }

  // MARK: - Bottom CTA Buttons

  private var bottomCTAButtons: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Browse Journeys - Primary button
      Button {
        print("🔵 DEBUG: Home -> Browse Journeys button tapped!")
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        store.send(.navigateToJourneys)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "compass")
            .font(.body.weight(.medium))

          Text("Browse Journeys")
            .font(.rizqDisplayMedium(.subheadline))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .padding(.vertical, RIZQSpacing.md)
        .background(
          LinearGradient(
            colors: [Color.rizqPrimary, Color.sandDeep],
            startPoint: .leading,
            endPoint: .trailing
          )
        )
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
        .shadow(color: Color.rizqPrimary.opacity(0.3), radius: 8, y: 4)
      }
      .buttonStyle(ScaleButtonStyle())
      .accessibilityLabel("Browse Journeys")
      .accessibilityHint("Explore themed dua collections to practice")

      // Explore All Duas - Secondary button
      Button {
        store.send(.navigateToLibrary)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Text("Explore All Duas")
            .font(.rizqDisplayMedium(.subheadline))

          Image(systemName: "arrow.right")
            .font(.body.weight(.medium))
        }
        .foregroundStyle(Color.rizqText)
        .frame(maxWidth: .infinity)
        .padding(.vertical, RIZQSpacing.md)
        .background(Color.rizqCard)
        .overlay(
          RoundedRectangle(cornerRadius: RIZQRadius.islamic)
            .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      }
      .buttonStyle(ScaleButtonStyle())
      .accessibilityLabel("Explore All Duas")
      .accessibilityHint("Browse the complete dua library")
    }
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
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Loading your dashboard")
      .accessibilityAddTraits(.isModal)
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

/// Button style with scale and press animation (matches React whileHover and whileTap)
/// Provides clear visual feedback when buttons are pressed
struct ScaleButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
      .offset(y: configuration.isPressed ? 1 : 0)
      .opacity(configuration.isPressed ? 0.9 : 1.0)
      .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
  }
}

// MARK: - Preview

#Preview("Home View - Default") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      displayName: "Omair",
      streak: 7,
      totalXp: 450,
      level: 3,
      todayActivity: UserActivity(
        id: 1,
        userId: "test",
        date: Date(),
        duasCompleted: [1, 2, 3, 4, 5],
        xpEarned: 160
      ),
      weekActivities: [
        UserActivity(id: 2, userId: "test", date: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date(), duasCompleted: [1, 2, 3], xpEarned: 125),
        UserActivity(id: 3, userId: "test", date: Date(), duasCompleted: [1, 2, 3, 4, 5], xpEarned: 160),
      ],
      todaysProgress: TodayProgress(completed: 3, total: 6, xpEarned: 95)
    )) {
      HomeFeature()
    }
  )
}

#Preview("Home View - New User") {
  HomeView(
    store: Store(initialState: HomeFeature.State(
      displayName: "",
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
      displayName: "Omair",
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
