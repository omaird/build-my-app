import SwiftUI
import RIZQKit

// TimeSlot extensions are defined in TimeSlot+SwiftUI.swift
// Color.init(hex:) is defined in RIZQKit/Design/Colors.swift

/// A section displaying habits for a specific time slot (morning, anytime, evening)
struct TimeSlotSectionView: View {
  let slot: TimeSlot
  let habits: [Habit]
  let completedIds: Set<Int>
  let progress: TimeSlotProgress
  let onSelect: (Habit) -> Void

  @State private var isExpanded = true

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Section Header
      sectionHeader

      // Progress Bar
      HabitProgressBar(
        progress: progress.percentage,
        color: slot.color
      )
      .frame(height: 6)

      // Habit Items
      if isExpanded {
        VStack(spacing: 12) {
          ForEach(habits) { habit in
            HabitItemView(
              habit: habit,
              isCompleted: completedIds.contains(habit.id),
              onSelect: { onSelect(habit) }
            )
          }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
      }
    }
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isExpanded)
  }

  // MARK: - Section Header
  private var sectionHeader: some View {
    Button {
      withAnimation {
        isExpanded.toggle()
      }
    } label: {
      HStack(spacing: 12) {
        // Time Slot Icon
        ZStack {
          Circle()
            .fill(slot.backgroundColor)
            .frame(width: 36, height: 36)

          Image(systemName: slot.icon)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(slot.color)
        }

        // Title
        Text(slot.displayName)
          .font(.rizqDisplayMedium(.headline))
          .foregroundStyle(Color.rizqText)

        Spacer()

        // Progress Count
        Text("\(progress.completed)/\(progress.total)")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        // Expand/Collapse Chevron
        Image(systemName: "chevron.down")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color.rizqMuted)
          .rotationEffect(.degrees(isExpanded ? 0 : -90))
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel("\(slot.displayName), \(progress.completed) of \(progress.total) completed")
    .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
    .accessibilityHint(isExpanded ? "Double tap to collapse section" : "Double tap to expand section")
  }
}

#Preview {
  ScrollView {
    VStack(spacing: 24) {
      TimeSlotSectionView(
        slot: .morning,
        habits: [
          Habit(
            id: 1,
            duaId: 101,
            titleEn: "Morning Remembrance",
            arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
            transliteration: "Asbahna wa asbahal mulku lillah",
            translation: "We have reached the morning",
            source: "Muslim",
            rizqBenefit: nil,
            propheticContext: nil,
            timeSlot: .morning,
            xpValue: 10,
            repetitions: 3
          ),
          Habit(
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
          )
        ],
        completedIds: [2],
        progress: TimeSlotProgress(slot: .morning, completed: 1, total: 2),
        onSelect: { _ in }
      )

      TimeSlotSectionView(
        slot: .evening,
        habits: [
          Habit(
            id: 4,
            duaId: 104,
            titleEn: "Evening Protection",
            arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ",
            transliteration: nil,
            translation: "We have reached the evening",
            source: nil,
            rizqBenefit: nil,
            propheticContext: nil,
            timeSlot: .evening,
            xpValue: 10,
            repetitions: 3
          )
        ],
        completedIds: [],
        progress: TimeSlotProgress(slot: .evening, completed: 0, total: 1),
        onSelect: { _ in }
      )
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
