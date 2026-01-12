import SwiftUI
import UIKit
import ComposableArchitecture
import RIZQKit

struct AdkharView: View {
  @Bindable var store: StoreOf<AdkharFeature>

  var body: some View {
    NavigationStack {
      ZStack {
        ScrollView {
          VStack(spacing: RIZQSpacing.xxl) {
            // Header with greeting
            headerSection

            // Progress Summary Card
            if store.totalHabits > 0 {
              progressSummaryCard
            }

            // Time Slot Sections
            if !store.morningHabits.isEmpty {
              TimeSlotSectionView(
                slot: .morning,
                habits: store.morningHabits,
                completedIds: store.completedIds,
                progress: store.morningProgress,
                onSelect: { habit in
                  store.send(.quickPracticeRequested(habit))
                }
              )
            }

            if !store.anytimeHabits.isEmpty {
              TimeSlotSectionView(
                slot: .anytime,
                habits: store.anytimeHabits,
                completedIds: store.completedIds,
                progress: store.anytimeProgress,
                onSelect: { habit in
                  store.send(.quickPracticeRequested(habit))
                }
              )
            }

            if !store.eveningHabits.isEmpty {
              TimeSlotSectionView(
                slot: .evening,
                habits: store.eveningHabits,
                completedIds: store.completedIds,
                progress: store.eveningProgress,
                onSelect: { habit in
                  store.send(.quickPracticeRequested(habit))
                }
              )
            }

            if store.totalHabits == 0 && !store.isLoading {
              emptyState
            }

            // Bottom padding for tab bar
            Spacer().frame(height: 100)
          }
          .padding()
        }
        .rizqPageBackground()
        .navigationBarTitleDisplayMode(.inline)

        // Loading overlay
        if store.isLoading {
          loadingOverlay
        } else if let error = store.loadError {
          errorOverlay(error: error)
        }

        // Debug banner on top of everything
        #if DEBUG
        VStack {
          debugBanner
            .padding(.horizontal)
            .padding(.top, 50)
          Spacer()
        }
        #endif
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
    .refreshable {
      store.send(.refreshData)
    }
    .sheet(isPresented: $store.showQuickPractice.sending(\.setShowQuickPractice)) {
      if let habit = store.selectedHabit {
        QuickPracticeSheet(
          habit: habit,
          repetitionCount: store.repetitionCount,
          isCompleted: store.isQuickPracticeComplete,
          showCelebration: store.showCelebration,
          progress: store.quickPracticeProgress,
          onClose: { store.send(.quickPracticeDismissed) },
          onIncrement: { store.send(.incrementRepetition) },
          onReset: { store.send(.resetRepetitions) }
        )
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(store.showCelebration)
      }
    }
  }

  // MARK: - Debug Banner (DEBUG builds only)
  #if DEBUG
  private var debugBanner: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("DEBUG: Adkhar State")
        .font(.caption.bold())
      Text("isLoading: \(store.isLoading ? "true" : "false")")
        .font(.caption2)
      Text("totalHabits: \(store.totalHabits)")
        .font(.caption2)
      Text("morning: \(store.morningHabits.count), anytime: \(store.anytimeHabits.count), evening: \(store.eveningHabits.count)")
        .font(.caption2)
      Text("error: \(store.loadError ?? "none")")
        .font(.caption2)
    }
    .padding(8)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color.orange.opacity(0.3))
    .cornerRadius(8)
  }
  #endif

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
      Text(getGreeting())
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)

      Text("Daily Adkhar")
        .font(.rizqDisplayBold(.largeTitle))
        .foregroundStyle(Color.rizqText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Progress Summary Card
  private var progressSummaryCard: some View {
    VStack(spacing: RIZQSpacing.lg) {
      HStack {
        Text("Today's Progress")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        Spacer()

        // Streak Badge
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "flame.fill")
            .foregroundStyle(Color.streakGlow)
            .accessibilityHidden(true)

          Text("\(store.streak) day streak")
            .font(.rizqMono(.subheadline))
            .foregroundStyle(Color.rizqText)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(store.streak) day streak")
      }

      // Progress Bar
      HStack(spacing: RIZQSpacing.lg) {
        HabitProgressBar(
          progress: store.progressPercentage,
          color: Color.rizqPrimary
        )
        .frame(height: 10)
        .accessibilityHidden(true)

        Text("\(store.completedCount)/\(store.totalHabits)")
          .font(.rizqMonoMedium(.subheadline))
          .foregroundStyle(Color.rizqText)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(store.completedCount) of \(store.totalHabits) habits completed")

      // XP Earned
      if store.earnedXp > 0 {
        Text("+\(store.earnedXp) XP earned today")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(RIZQSpacing.xl)
    .rizqCard()
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Today's progress")
  }

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      ZStack {
        Circle()
          .fill(Color.rizqPrimary.opacity(0.1))
          .frame(width: 80, height: 80)

        Image(systemName: "sun.max.fill")
          .font(.system(size: 36))
          .foregroundStyle(Color.rizqPrimary)
      }
      .accessibilityHidden(true)

      Text("Begin Your Journey")
        .font(.rizqDisplaySemiBold(.title2))
        .foregroundStyle(Color.rizqText)

      Text("Choose a themed collection of duas below to build your daily practice routine")
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button {
        print("🔵 DEBUG: Browse Journeys button tapped!")
        // Trigger haptic feedback immediately
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        store.send(.navigateToJourneys)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Text("Browse Journeys")
          Image(systemName: "chevron.right")
        }
        .rizqPrimaryButton()
      }
      .accessibilityLabel("Browse Journeys")
      .accessibilityHint("Explore dua collections to add to your daily routine")
    }
    .padding(.top, 40)
  }

  // MARK: - Loading Overlay
  private var loadingOverlay: some View {
    ZStack {
      Color.rizqBackground.opacity(0.8)

      VStack(spacing: RIZQSpacing.lg) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
          .scaleEffect(1.5)

        Text("Loading your adkhar...")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }
      .accessibilityElement(children: .combine)
      .accessibilityLabel("Loading your daily adkhar")
      .accessibilityAddTraits(.isModal)
    }
    .ignoresSafeArea()
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
      .accessibilityLabel("Try again")
      .accessibilityHint("Reload your daily adkhar")
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.rizqBackground.opacity(0.95))
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Error: Something went wrong. \(error)")
    .accessibilityAddTraits(.isModal)
  }
}

#Preview {
  AdkharView(
    store: Store(initialState: AdkharFeature.State()) {
      AdkharFeature()
    }
  )
}
