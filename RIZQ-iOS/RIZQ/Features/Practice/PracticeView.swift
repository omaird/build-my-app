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
        xpEarned: store.xpEarned > 0 ? store.xpEarned : (store.dua?.xpValue ?? 0),
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

      // Tap hint (when not completed)
      if !store.isCompleted && !store.alreadyCompletedToday {
        Text("Tap the card to count")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
          .padding(.top, -RIZQSpacing.md)
      }

      // Action Buttons
      actionButtons

      // XP Reward Badge
      xpRewardBadge
    }
    .padding(.horizontal)
  }

  // MARK: - Progress Indicator (Matches React design with circle indicator)

  private var progressIndicator: some View {
    VStack(spacing: RIZQSpacing.sm) {
      HStack {
        Text("PROGRESS")
          .font(.rizqSans(.caption))
          .fontWeight(.medium)
          .foregroundStyle(Color.rizqTextSecondary)
          .tracking(1.0)

        Spacer()

        Text("\(store.currentCount) / \(store.targetCount)")
          .font(.rizqMonoMedium(.headline))
          .foregroundStyle(Color.rizqText)
      }

      // Progress bar with circle indicator (matches React)
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          // Background track
          Capsule()
            .fill(LinearGradient.rizqPrimaryGradient.opacity(0.25))
            .frame(height: 6)

          // Progress fill
          Capsule()
            .fill(LinearGradient.rizqPrimaryGradient)
            .frame(
              width: max(geometry.size.width * store.progress, 6),
              height: 6
            )
            .animation(.easeInOut(duration: 0.3), value: store.progress)

          // Circle indicator at the start
          Circle()
            .fill(LinearGradient.rizqPrimaryGradient)
            .frame(width: 12, height: 12)
            .offset(x: -3) // Center the circle at the start
        }
      }
      .frame(height: 12)
    }
  }

  // MARK: - Dua Card (Clean reading layout matching React)

  private var duaCard: some View {
    VStack(spacing: RIZQSpacing.xl) {
      if let dua = store.dua {
        // Dua Text (Arabic, divider, transliteration, translation)
        DuaTextView(
          arabicText: dua.arabicText,
          transliteration: dua.transliteration,
          translation: dua.translationEn,
          showTransliteration: store.showTransliteration
        )
        .animation(.easeInOut(duration: 0.2), value: store.showTransliteration)
      } else {
        // Loading state
        ProgressView()
          .tint(Color.rizqPrimary)
          .scaleEffect(1.5)
          .padding(.vertical, RIZQSpacing.huge)
      }
    }
    .padding(.horizontal, RIZQSpacing.lg)
    .padding(.vertical, RIZQSpacing.xxl)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadow(color: .black.opacity(0.04), radius: 8, y: 4)
    .contentShape(Rectangle())
    .onTapGesture {
      store.send(.incrementCounter)
    }
  }

  // MARK: - Action Buttons (Matches React full-width Done button)

  private var actionButtons: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Done button (primary action - always visible)
      Button {
        store.send(.navigateToNext)
      } label: {
        Text("Done")
          .font(.rizqSansSemiBold(.headline))
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .padding(.vertical, RIZQSpacing.lg)
          .background(
            (store.isCompleted || store.alreadyCompletedToday)
              ? Color.rizqPrimary
              : Color.rizqPrimary.opacity(0.5)
          )
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      }
      .buttonStyle(.plain)
      .disabled(!store.isCompleted && !store.alreadyCompletedToday)

      // Reset button (only when in progress)
      if !store.isCompleted && !store.alreadyCompletedToday && store.currentCount > 0 {
        Button {
          store.send(.resetCounter)
        } label: {
          HStack(spacing: RIZQSpacing.sm) {
            Image(systemName: "arrow.counterclockwise")
            Text("Reset")
          }
          .font(.rizqSansMedium(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)
        }
        .buttonStyle(.plain)
      }
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
