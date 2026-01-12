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
              .foregroundStyle(Color.rizqPrimary)
          }

          // Arabic text preview
          Text(habit.arabicText)
            .font(.rizqArabic(.subheadline))
            .foregroundStyle(isCompleted ? Color.rizqMuted.opacity(0.6) : Color.rizqTextSecondary)
            .lineLimit(1)
            .environment(\.layoutDirection, .rightToLeft)

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
    HabitItemView(
      habit: Habit(
        id: 1,
        duaId: 101,
        titleEn: "Morning Remembrance",
        arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
        transliteration: "Asbahna wa asbahal mulku lillah",
        translation: "We have reached the morning",
        source: "Muslim",
        rizqBenefit: "Protection throughout the day",
        propheticContext: nil,
        timeSlot: .morning,
        xpValue: 10,
        repetitions: 3
      ),
      isCompleted: false,
      onSelect: {}
    )

    HabitItemView(
      habit: Habit(
        id: 2,
        duaId: 102,
        titleEn: "Seeking Refuge",
        arabicText: "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ",
        transliteration: nil,
        translation: "I seek refuge in Allah",
        source: nil,
        rizqBenefit: nil,
        propheticContext: nil,
        timeSlot: .morning,
        xpValue: 5,
        repetitions: 1
      ),
      isCompleted: true,
      onSelect: {}
    )
  }
  .padding()
  .background(Color.rizqBackground)
}
