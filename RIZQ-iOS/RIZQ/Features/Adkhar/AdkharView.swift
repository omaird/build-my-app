import SwiftUI
import ComposableArchitecture
import RIZQKit

struct AdkharView: View {
  @Bindable var store: StoreOf<AdkharFeature>

  var body: some View {
    NavigationStack {
      ZStack {
        ScrollView {
          VStack(spacing: 24) {
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
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
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

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 4) {
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
    VStack(spacing: 16) {
      HStack {
        Text("Today's Progress")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        Spacer()

        // Streak Badge
        HStack(spacing: 6) {
          Image(systemName: "flame.fill")
            .foregroundStyle(Color.streakGlow)

          Text("\(store.streak) day streak")
            .font(.rizqMono(.subheadline))
            .foregroundStyle(Color.rizqText)
        }
      }

      // Progress Bar
      HStack(spacing: 16) {
        HabitProgressBar(
          progress: store.progressPercentage,
          color: Color.rizqPrimary
        )
        .frame(height: 10)

        Text("\(store.completedCount)/\(store.totalHabits)")
          .font(.rizqMonoMedium(.subheadline))
          .foregroundStyle(Color.rizqText)
      }

      // XP Earned
      if store.earnedXp > 0 {
        Text("+\(store.earnedXp) XP earned today")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqPrimary)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .padding(20)
    .rizqCard()
  }

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: 16) {
      ZStack {
        Circle()
          .fill(Color.rizqPrimary.opacity(0.1))
          .frame(width: 80, height: 80)

        Image(systemName: "sun.max.fill")
          .font(.system(size: 36))
          .foregroundStyle(Color.rizqPrimary)
      }

      Text("No habits yet")
        .font(.rizqDisplaySemiBold(.title2))
        .foregroundStyle(Color.rizqText)

      Text("Join a journey to start building your daily adhkar routine")
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      NavigationLink {
        // TODO: Navigate to journeys
        EmptyView()
      } label: {
        HStack(spacing: 8) {
          Text("Browse Journeys")
          Image(systemName: "chevron.right")
        }
        .rizqPrimaryButton()
      }
    }
    .padding(.top, 40)
  }

  // MARK: - Loading Overlay
  private var loadingOverlay: some View {
    ZStack {
      Color.rizqBackground.opacity(0.8)

      VStack(spacing: 16) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
          .scaleEffect(1.5)

        Text("Loading your adkhar...")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .ignoresSafeArea()
  }
}

#Preview {
  AdkharView(
    store: Store(initialState: AdkharFeature.State()) {
      AdkharFeature()
    }
  )
}
