import SwiftUI
import RIZQKit

/// Bottom sheet for practicing a dua without leaving the current page
struct QuickPracticeSheet: View {
  let habit: Habit
  let repetitionCount: Int
  let isCompleted: Bool
  let showCelebration: Bool
  let progress: Double
  let onClose: () -> Void
  let onIncrement: () -> Void
  let onReset: () -> Void

  var body: some View {
    ZStack {
      // Main Content
      VStack(spacing: 0) {
        // Header
        sheetHeader

        ScrollView {
          VStack(spacing: 24) {
            // Arabic Text Card
            arabicTextCard

            // Transliteration
            if let transliteration = habit.transliteration {
              sectionView(title: "Transliteration") {
                Text(transliteration)
                  .font(.rizqSans(.body))
                  .foregroundStyle(Color.rizqText)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }

            // Translation
            sectionView(title: "Translation") {
              Text(habit.translation)
                .font(.rizqSans(.body))
                .foregroundStyle(Color.rizqTextSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            // Benefits
            if let benefit = habit.rizqBenefit {
              sectionView(title: "Benefits") {
                Text(benefit)
                  .font(.rizqSans(.body))
                  .foregroundStyle(Color.rizqText)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }

            // Prophetic Context
            if let propheticContext = habit.propheticContext {
              propheticContextCard(propheticContext)
            }

            // Source Reference
            if let source = habit.source {
              sourceCard(source)
            }

            // Progress Section
            progressSection

            // Action Buttons
            actionButtons

            Spacer().frame(height: 40)
          }
          .padding(.horizontal, 24)
          .padding(.top, 8)
        }
      }
      .background(Color.rizqCard)

      // Celebration Overlay
      if showCelebration {
        celebrationOverlay
      }
    }
  }

  // MARK: - Sheet Header
  private var sheetHeader: some View {
    HStack(alignment: .top) {
      VStack(alignment: .leading, spacing: 4) {
        Text(habit.titleEn)
          .font(.rizqDisplaySemiBold(.title2))
          .foregroundStyle(Color.rizqText)

        Text("+\(habit.xpValue) XP")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqPrimary)
      }

      Spacer()

      Button(action: onClose) {
        ZStack {
          Circle()
            .fill(Color.rizqMuted.opacity(0.2))
            .frame(width: 36, height: 36)

          Image(systemName: "xmark")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }
      .accessibilityLabel("Close")
      .accessibilityHint("Dismiss quick practice sheet")
    }
    .padding(.horizontal, 24)
    .padding(.top, 16)
    .padding(.bottom, 8)
  }

  // MARK: - Arabic Text Card
  private var arabicTextCard: some View {
    VStack(spacing: 0) {
      Text(habit.arabicText)
        .font(.rizqArabic(.title))
        .foregroundStyle(Color.rizqText)
        .multilineTextAlignment(.center)
        .lineSpacing(16)
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .environment(\.layoutDirection, .rightToLeft)
    }
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .fill(Color.rizqMuted.opacity(0.15))
    )
  }

  // MARK: - Section View Helper
  private func sectionView<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title.uppercased())
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Prophetic Context Card
  private func propheticContextCard(_ context: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("PROPHETIC GUIDANCE")
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      Text(context)
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqText)
        .italic()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .fill(Color.goldSoft.opacity(0.2))
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .stroke(Color.goldSoft.opacity(0.4), lineWidth: 1)
    )
  }

  // MARK: - Source Card
  private func sourceCard(_ source: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text("SOURCE")
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      Text(source)
        .font(.rizqSansMedium(.body))
        .foregroundStyle(Color.rizqText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .fill(Color.rizqPrimary.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .stroke(Color.rizqPrimary.opacity(0.15), lineWidth: 1)
    )
  }

  // MARK: - Progress Section
  private var progressSection: some View {
    VStack(spacing: 12) {
      HStack {
        Text("Progress")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        Spacer()

        Text("\(repetitionCount) / \(habit.repetitions)")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqText)
      }

      HabitProgressBar(
        progress: progress,
        color: isCompleted ? Color.tealSuccess : Color.rizqPrimary,
        height: 10
      )
    }
  }

  // MARK: - Action Buttons
  private var actionButtons: some View {
    HStack(spacing: 16) {
      // Reset Button (only show if not completed)
      if !isCompleted {
        Button(action: onReset) {
          ZStack {
            Circle()
              .fill(Color.rizqMuted.opacity(0.2))
              .frame(width: 56, height: 56)

            Image(systemName: "arrow.counterclockwise")
              .font(.system(size: 20, weight: .medium))
              .foregroundStyle(Color.rizqTextSecondary)
          }
        }
        .accessibilityLabel("Reset counter")
        .accessibilityHint("Start counting repetitions from zero")
      }

      // Main Action Button
      Button(action: onIncrement) {
        HStack(spacing: 12) {
          if isCompleted {
            Image(systemName: "checkmark")
              .font(.system(size: 18, weight: .bold))
          }

          Text(isCompleted ? "Completed!" : "Tap to Count (\(repetitionCount + 1)/\(habit.repetitions))")
            .font(.rizqSansSemiBold(.headline))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
            .fill(isCompleted ? Color.tealSuccess : Color.rizqPrimary)
        )
        .shadowGlowPrimary()
      }
      .disabled(isCompleted)
      .accessibilityLabel(mainButtonAccessibilityLabel)
      .accessibilityHint(isCompleted ? "" : "Tap to increment repetition counter")
    }
  }

  // MARK: - Accessibility Helpers
  private var mainButtonAccessibilityLabel: String {
    if isCompleted {
      return "Completed"
    } else {
      return "Count repetition \(repetitionCount + 1) of \(habit.repetitions)"
    }
  }

  // MARK: - Celebration Overlay
  private var celebrationOverlay: some View {
    ZStack {
      Color.tealSuccess
        .opacity(0.95)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        // Checkmark Circle
        ZStack {
          Circle()
            .fill(Color.white.opacity(0.2))
            .frame(width: 100, height: 100)

          Image(systemName: "checkmark")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.white)
        }
        .scaleEffect(showCelebration ? 1 : 0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: showCelebration)

        VStack(spacing: 8) {
          Text("MashaAllah!")
            .font(.rizqDisplayBold(.largeTitle))
            .foregroundStyle(.white)

          Text("+\(habit.xpValue) XP earned")
            .font(.rizqSans(.title3))
            .foregroundStyle(.white.opacity(0.8))
        }
        .opacity(showCelebration ? 1 : 0)
        .offset(y: showCelebration ? 0 : 20)
        .animation(.easeOut(duration: 0.3).delay(0.2), value: showCelebration)
      }
    }
    .transition(.opacity)
    .accessibilityElement(children: .ignore)
    .accessibilityLabel("Congratulations! MashaAllah! You earned \(habit.xpValue) XP")
    .accessibilityAddTraits(.isModal)
  }
}

#Preview {
  QuickPracticeSheet(
    habit: Habit(
      id: 1,
      duaId: 101,
      titleEn: "Morning Remembrance",
      arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ",
      transliteration: "Asbahna wa asbahal mulku lillah wal hamdu lillah",
      translation: "We have reached the morning and at this very time unto Allah belongs all sovereignty, and all praise is for Allah",
      source: "Muslim",
      rizqBenefit: "Protection throughout the day and blessings in your provision",
      propheticContext: "The Prophet (PBUH) would say this every morning upon waking",
      timeSlot: .morning,
      xpValue: 10,
      repetitions: 3
    ),
    repetitionCount: 1,
    isCompleted: false,
    showCelebration: false,
    progress: 0.33,
    onClose: {},
    onIncrement: {},
    onReset: {}
  )
}
