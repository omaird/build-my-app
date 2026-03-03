import SwiftUI
import RIZQKit

/// A single habit row with completion toggle and practice button
struct HabitItemView: View {
  let habit: Habit
  let isCompleted: Bool
  let onSelect: () -> Void

  @State private var isPressed = false

  var body: some View {
    Button(action: onSelect) {
      HStack(spacing: RIZQSpacing.lg) {
        // Animated Checkbox
        checkboxView

        // Content
        VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
          // Title and XP
          HStack(alignment: .top) {
            Text(habit.titleEn)
              .font(.rizqSansMedium(.body))
              .foregroundStyle(isCompleted ? Color.rizqMuted : Color.rizqText)
              .strikethrough(isCompleted, color: Color.rizqMuted)
              .lineLimit(2)
              .multilineTextAlignment(.leading)

            Spacer()

            Text("+\(habit.xpValue) XP")
              .font(.rizqMono(.caption))
              .foregroundStyle(isCompleted ? Color.rizqMuted : Color.rizqPrimary)
          }

          // Category badge + source
          categorySourceRow

          // Purpose/benefit line
          Text(habit.rizqBenefit ?? habit.translation)
            .font(.rizqSans(.caption))
            .foregroundStyle(isCompleted ? Color.rizqMuted.opacity(0.6) : Color.rizqTextSecondary)
            .lineLimit(1)

          // Repetitions badge
          if habit.repetitions > 1 {
            Text("Repeat \(habit.repetitions)x")
              .font(.rizqSans(.caption2))
              .foregroundStyle(Color.rizqTextSecondary)
          }
        }
      }
      .padding(RIZQSpacing.lg)
      .background(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .fill(isCompleted ? Color.tealSuccess.opacity(0.05) : Color.rizqCard)
      )
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.islamic)
          .stroke(
            isCompleted ? Color.tealSuccess.opacity(0.3) : Color.rizqBorder.opacity(0.5),
            lineWidth: 1
          )
      )
      .shadowSoft()
      .scaleEffect(isPressed ? 0.98 : 1.0)
      .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(accessibilityLabel)
      .accessibilityValue(isCompleted ? "Completed" : "Not completed")
      .accessibilityHint("Double tap to practice this dua")
      .accessibilityAddTraits(isCompleted ? [.isButton, .isSelected] : .isButton)
    }
    .buttonStyle(.plain)
    .pressEvents {
      isPressed = true
    } onRelease: {
      isPressed = false
    }
  }

  // MARK: - Category + Source Row
  private var categorySourceRow: some View {
    HStack(spacing: RIZQSpacing.sm) {
      // Category badge pill
      HStack(spacing: 4) {
        Text(categoryEmoji(for: habit.categoryId))
          .font(.system(size: 10))

        Text(categoryName(for: habit.categoryId))
          .font(.rizqSans(.caption2))
      }
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(categoryColor(for: habit.categoryId).opacity(isCompleted ? 0.08 : 0.15))
      .foregroundStyle(isCompleted ? Color.rizqMuted : categoryColor(for: habit.categoryId))
      .clipShape(Capsule())

      // Source (if available)
      if let source = habit.source {
        Text("•")
          .font(.rizqSans(.caption2))
          .foregroundStyle(Color.rizqMuted)

        Text(source)
          .font(.rizqSans(.caption2))
          .foregroundStyle(isCompleted ? Color.rizqMuted : Color.rizqTextSecondary)
          .lineLimit(1)
      }
    }
  }

  // MARK: - Category Helpers

  private func categoryEmoji(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "🌅"
    case 2: return "🌙"
    case 3: return "💫"
    case 4: return "🤲"
    default: return "📿"
    }
  }

  private func categoryName(for categoryId: Int?) -> String {
    switch categoryId {
    case 1: return "Morning"
    case 2: return "Evening"
    case 3: return "Rizq"
    case 4: return "Gratitude"
    default: return "Dua"
    }
  }

  private func categoryColor(for categoryId: Int?) -> Color {
    switch categoryId {
    case 1: return .badgeMorning
    case 2: return .badgeEvening
    case 3: return .badgeRizq
    case 4: return .badgeGratitude
    default: return .rizqPrimary
    }
  }

  // MARK: - Checkbox View
  private var checkboxView: some View {
    ZStack {
      Circle()
        .stroke(
          isCompleted ? Color.tealSuccess : Color.rizqMuted.opacity(0.5),
          lineWidth: 2
        )
        .frame(width: 28, height: 28)

      if isCompleted {
        Circle()
          .fill(Color.tealSuccess)
          .frame(width: 28, height: 28)

        Image(systemName: "checkmark")
          .font(.system(size: 14, weight: .bold))
          .foregroundStyle(.white)
          .transition(.scale.combined(with: .opacity))
      }
    }
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isCompleted)
  }

  // MARK: - Accessibility Label
  private var accessibilityLabel: String {
    var components: [String] = [habit.titleEn]

    components.append(habit.rizqBenefit ?? habit.translation)

    if habit.repetitions > 1 {
      components.append("Repeat \(habit.repetitions) times")
    }

    components.append("\(habit.xpValue) XP")

    return components.joined(separator: ", ")
  }
}

// MARK: - Press Events Modifier
extension View {
  func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
    modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
  }
}

struct PressEventsModifier: ViewModifier {
  let onPress: () -> Void
  let onRelease: () -> Void

  func body(content: Content) -> some View {
    content
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in onPress() }
          .onEnded { _ in onRelease() }
      )
  }
}

#Preview {
  VStack(spacing: RIZQSpacing.lg) {
    // With rizqBenefit + source (morning category)
    HabitItemView(
      habit: Habit(
        id: 1,
        duaId: 101,
        categoryId: 1,
        titleEn: "Morning Remembrance",
        arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
        transliteration: "Asbahna wa asbahal mulku lillah",
        translation: "We have reached the morning and the dominion belongs to Allah",
        source: "Sahih Muslim",
        rizqBenefit: "Protection throughout the day",
        propheticContext: nil,
        timeSlot: .morning,
        xpValue: 15,
        repetitions: 3
      ),
      isCompleted: false,
      onSelect: {}
    )

    // Without rizqBenefit (falls back to translation), rizq category
    HabitItemView(
      habit: Habit(
        id: 2,
        duaId: 102,
        categoryId: 3,
        titleEn: "Seeking Rizq",
        arabicText: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ",
        transliteration: nil,
        translation: "O Allah, suffice me with what is lawful against what is unlawful",
        source: "Tirmidhi",
        rizqBenefit: nil,
        propheticContext: nil,
        timeSlot: .anytime,
        xpValue: 20,
        repetitions: 3
      ),
      isCompleted: false,
      onSelect: {}
    )

    // Completed state (evening category, no source)
    HabitItemView(
      habit: Habit(
        id: 3,
        duaId: 103,
        categoryId: 2,
        titleEn: "Evening Protection",
        arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
        transliteration: nil,
        translation: "We have reached the evening and the dominion belongs to Allah",
        source: nil,
        rizqBenefit: "Safety through the night",
        propheticContext: nil,
        timeSlot: .evening,
        xpValue: 10,
        repetitions: 1
      ),
      isCompleted: true,
      onSelect: {}
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
