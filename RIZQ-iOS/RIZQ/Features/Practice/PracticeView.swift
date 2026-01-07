import SwiftUI
import ComposableArchitecture
import RIZQKit

struct PracticeView: View {
  @Bindable var store: StoreOf<PracticeFeature>

  var body: some View {
    ZStack {
      // Main content
      mainContent

      // Celebration overlay
      CelebrationOverlayView(
        isVisible: store.showCelebration,
        title: "Masha'Allah!",
        subtitle: "Dua completed",
        xpEarned: store.dua?.xpValue ?? 0,
        onDismiss: { store.send(.dismissCelebration) }
      )
      .animation(.easeInOut(duration: 0.3), value: store.showCelebration)
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Main Content

  private var mainContent: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xl) {
          // Context Tabs
          ContextTabsView(
            selectedTab: Binding(
              get: { store.selectedTab },
              set: { store.send(.tabSelected($0)) }
            ),
            hasContext: store.hasContext
          )
          .padding(.horizontal)

          // Tab Content
          tabContent
        }
        .padding(.vertical)
      }
      .rizqPageBackground()
      .navigationTitle(store.dua?.titleEn ?? "Practice")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            store.send(.navigateBack)
          } label: {
            Image(systemName: "chevron.left")
              .foregroundStyle(Color.rizqText)
          }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            store.send(.toggleTransliteration)
          } label: {
            Image(systemName: store.showTransliteration ? "eye.fill" : "eye.slash.fill")
              .foregroundStyle(Color.rizqText)
          }
        }
      }
    }
  }

  // MARK: - Tab Content

  @ViewBuilder
  private var tabContent: some View {
    switch store.selectedTab {
    case .practice:
      practiceContent
        .transition(.asymmetric(
          insertion: .move(edge: .leading).combined(with: .opacity),
          removal: .move(edge: .trailing).combined(with: .opacity)
        ))

    case .context:
      if let dua = store.dua {
        DuaContextView(dua: dua)
          .padding(.horizontal)
          .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
          ))
      }
    }
  }

  // MARK: - Practice Content

  private var practiceContent: some View {
    VStack(spacing: RIZQSpacing.xl) {
      // Progress indicator
      progressIndicator

      // Dua Card (Tappable)
      duaCard

      // Action Buttons
      actionButtons

      // XP Reward Badge
      xpRewardBadge
    }
    .padding(.horizontal)
  }

  // MARK: - Progress Indicator

  private var progressIndicator: some View {
    VStack(spacing: RIZQSpacing.sm) {
      HStack {
        Text("PROGRESS")
          .font(.rizqSans(.caption))
          .fontWeight(.medium)
          .foregroundStyle(Color.rizqTextSecondary)
          .tracking(0.5)

        Spacer()

        Text("\(store.currentCount) / \(store.targetCount)")
          .font(.rizqMonoMedium(.subheadline))
          .foregroundStyle(Color.rizqPrimary)
      }

      // Progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Capsule()
            .fill(Color.rizqMuted.opacity(0.3))
            .frame(height: 8)

          Capsule()
            .fill(LinearGradient.rizqPrimaryGradient)
            .frame(
              width: geometry.size.width * store.progress,
              height: 8
            )
            .animation(.easeInOut(duration: 0.3), value: store.progress)
        }
      }
      .frame(height: 8)
    }
  }

  // MARK: - Dua Card

  private var duaCard: some View {
    VStack(spacing: RIZQSpacing.xl) {
      if let dua = store.dua {
        // Dua Text
        DuaTextView(
          arabicText: dua.arabicText,
          transliteration: dua.transliteration,
          translation: dua.translationEn,
          showTransliteration: store.showTransliteration
        )
        .animation(.easeInOut(duration: 0.2), value: store.showTransliteration)

        // Counter
        VStack(spacing: RIZQSpacing.md) {
          CounterView(
            currentCount: store.currentCount,
            targetCount: store.targetCount,
            isCompleted: store.isCompleted || store.alreadyCompletedToday,
            onTap: { store.send(.incrementCounter) }
          )

          if !store.isCompleted && !store.alreadyCompletedToday {
            Text("Tap anywhere to count")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqTextSecondary)
          } else {
            Text(store.alreadyCompletedToday && !store.isCompleted
                 ? "Completed Today"
                 : "Completed!")
              .font(.rizqSansMedium(.subheadline))
              .foregroundStyle(Color.rizqPrimary)
          }
        }
      } else {
        // Loading state
        ProgressView()
          .tint(Color.rizqPrimary)
          .scaleEffect(1.5)
          .padding(.vertical, RIZQSpacing.huge)
      }
    }
    .padding(RIZQSpacing.xl)
    .rizqCard()
    .contentShape(Rectangle())
    .onTapGesture {
      store.send(.incrementCounter)
    }
  }

  // MARK: - Action Buttons

  private var actionButtons: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Reset button (only when not completed)
      if !store.isCompleted && !store.alreadyCompletedToday {
        Button {
          store.send(.resetCounter)
        } label: {
          HStack(spacing: RIZQSpacing.sm) {
            Image(systemName: "arrow.counterclockwise")
            Text("Reset")
          }
          .frame(maxWidth: .infinity)
          .rizqSecondaryButton()
        }
        .buttonStyle(.plain)
      }

      // Next/Done button
      Button {
        store.send(.navigateToNext)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Text(store.isCompleted || store.alreadyCompletedToday ? "Done" : "Next Dua")
          if !store.isCompleted && !store.alreadyCompletedToday {
            Image(systemName: "chevron.right")
          }
        }
        .frame(maxWidth: .infinity)
        .rizqPrimaryButton()
      }
      .buttonStyle(.plain)
      .disabled(!store.isCompleted && !store.alreadyCompletedToday)
      .opacity(store.isCompleted || store.alreadyCompletedToday ? 1.0 : 0.5)
    }
  }

  // MARK: - XP Reward Badge

  private var xpRewardBadge: some View {
    HStack(spacing: RIZQSpacing.sm) {
      Image(systemName: "sparkles")
        .foregroundStyle(Color.rizqPrimary)

      Text("Complete to earn")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)

      Text("+\(store.dua?.xpValue ?? 0) XP")
        .font(.rizqMonoMedium(.subheadline))
        .foregroundStyle(Color.rizqPrimary)
    }
    .padding(.horizontal, RIZQSpacing.lg)
    .padding(.vertical, RIZQSpacing.md)
    .background(
      Capsule()
        .fill(Color.rizqMuted.opacity(0.2))
    )
  }
}

// MARK: - Previews

#Preview("Practice View - In Progress") {
  PracticeView(
    store: Store(initialState: PracticeFeature.State.preview) {
      PracticeFeature()
    }
  )
}

#Preview("Practice View - Completed") {
  PracticeView(
    store: Store(initialState: PracticeFeature.State.previewCompleted) {
      PracticeFeature()
    }
  )
}

#Preview("Practice View - With Celebration") {
  let state: PracticeFeature.State = {
    var s = PracticeFeature.State.previewCompleted
    s.showCelebration = true
    return s
  }()

  PracticeView(
    store: Store(initialState: state) {
      PracticeFeature()
    }
  )
}
