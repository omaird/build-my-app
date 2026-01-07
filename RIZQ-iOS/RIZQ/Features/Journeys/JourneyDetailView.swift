import SwiftUI
import ComposableArchitecture
import RIZQKit

struct JourneyDetailView: View {
  @Bindable var store: StoreOf<JourneyDetailFeature>
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xxl) {
          // Journey Header
          journeyHeader

          // Stats Row
          statsRow

          // Divider
          islamicDivider

          // Duas by Time Slot
          if store.isLoading {
            duasLoadingView
          } else {
            duasSections
          }

          // Subscribe Button
          subscribeButton
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.xxxl)
      }
      .rizqPageBackground()
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Close") {
            store.send(.dismiss)
            dismiss()
          }
          .font(.rizqSansMedium(.body))
          .foregroundStyle(Color.rizqTextSecondary)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Duas Loading View

  private var duasLoadingView: some View {
    VStack(spacing: RIZQSpacing.md) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))

      Text("Loading duas...")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.xxxl)
  }

  // MARK: - Journey Header

  private var journeyHeader: some View {
    VStack(spacing: RIZQSpacing.md) {
      // Decorative emoji container
      ZStack {
        // Outer decorative ring
        Circle()
          .stroke(style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
          .foregroundStyle(Color.rizqPrimary.opacity(0.2))
          .frame(width: 100, height: 100)
          .rotationEffect(.degrees(animatingRing ? 360 : 0))
          .animation(.linear(duration: 20).repeatForever(autoreverses: false), value: animatingRing)

        // Inner glow
        Circle()
          .fill(Color.rizqPrimary.opacity(0.1))
          .frame(width: 80, height: 80)
          .blur(radius: 10)

        // Emoji frame
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [Color.cream, Color.cream.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
              )
            )
            .frame(width: 80, height: 80)
            .overlay(
              Circle()
                .stroke(Color.rizqPrimary.opacity(0.2), lineWidth: 2)
            )
            .shadowSoft()

          Text(store.journey.emoji)
            .font(.system(size: 40))
        }
      }
      .padding(.top, RIZQSpacing.xl)
      .onAppear { animatingRing = true }

      // Journey name
      Text(store.journey.name)
        .font(.rizqDisplayBold(.title2))
        .foregroundStyle(Color.rizqText)
        .multilineTextAlignment(.center)

      // Description
      if let description = store.journey.description {
        Text(description)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqTextSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, RIZQSpacing.xl)
      }

      // Premium badge if applicable
      if store.journey.isPremium {
        HStack(spacing: RIZQSpacing.xs) {
          Image(systemName: "lock.fill")
          Text("Premium")
        }
        .font(.rizqSansMedium(.caption))
        .foregroundStyle(Color.goldSoft)
        .padding(.horizontal, RIZQSpacing.md)
        .padding(.vertical, RIZQSpacing.xs)
        .background(Color.goldSoft.opacity(0.2))
        .clipShape(Capsule())
      }
    }
  }

  @State private var animatingRing = false

  // MARK: - Stats Row

  private var statsRow: some View {
    HStack(spacing: RIZQSpacing.xl) {
      statItem(
        icon: "book.fill",
        value: "\(store.duas.count)",
        label: "Duas"
      )

      statItem(
        icon: "clock.fill",
        value: "~\(store.journey.estimatedMinutes)",
        label: "Min/day"
      )

      statItem(
        icon: "star.fill",
        value: "+\(store.totalXp)",
        label: "XP/day",
        accentColor: Color.rizqPrimary
      )
    }
    .padding(.vertical, RIZQSpacing.md)
    .padding(.horizontal, RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
  }

  private func statItem(
    icon: String,
    value: String,
    label: String,
    accentColor: Color = Color.rizqTextSecondary
  ) -> some View {
    VStack(spacing: RIZQSpacing.xs) {
      Image(systemName: icon)
        .font(.system(size: 16))
        .foregroundStyle(accentColor)

      Text(value)
        .font(.rizqMonoMedium(.headline))
        .foregroundStyle(Color.rizqText)

      Text(label)
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - Islamic Divider

  private var islamicDivider: some View {
    HStack(spacing: RIZQSpacing.md) {
      Rectangle()
        .fill(Color.rizqBorder)
        .frame(height: 1)

      Text("\u{2726}") // Four-pointed star
        .foregroundStyle(Color.rizqPrimary.opacity(0.4))

      Rectangle()
        .fill(Color.rizqBorder)
        .frame(height: 1)
    }
    .padding(.horizontal, RIZQSpacing.xl)
  }

  // MARK: - Duas Sections

  private var duasSections: some View {
    VStack(spacing: RIZQSpacing.xl) {
      if !store.morningDuas.isEmpty {
        duaTimeSlotSection(slot: .morning, duas: store.morningDuas)
      }

      if !store.anytimeDuas.isEmpty {
        duaTimeSlotSection(slot: .anytime, duas: store.anytimeDuas)
      }

      if !store.eveningDuas.isEmpty {
        duaTimeSlotSection(slot: .evening, duas: store.eveningDuas)
      }
    }
  }

  private func duaTimeSlotSection(slot: TimeSlot, duas: [JourneyDuaFull]) -> some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      // Time slot header
      HStack(spacing: RIZQSpacing.sm) {
        ZStack {
          Circle()
            .fill(slotBackgroundColor(slot))
            .frame(width: 28, height: 28)

          Image(systemName: slot.icon)
            .font(.system(size: 14))
            .foregroundStyle(slotIconColor(slot))
        }

        Text(slot.displayName)
          .font(.rizqSansSemiBold(.subheadline))
          .foregroundStyle(Color.rizqText)

        Text("(\(duas.count) duas)")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }

      // Duas list
      VStack(spacing: 0) {
        ForEach(Array(duas.enumerated()), id: \.element.dua.id) { index, journeyDua in
          Button {
            store.send(.duaTapped(journeyDua.dua))
          } label: {
            HStack {
              Text(journeyDua.dua.titleEn)
                .font(.rizqSansMedium(.subheadline))
                .foregroundStyle(Color.rizqText)
                .lineLimit(1)

              Spacer()

              Text("+\(journeyDua.dua.xpValue) XP")
                .font(.rizqMonoMedium(.caption))
                .foregroundStyle(Color.rizqPrimary)
            }
            .padding(.horizontal, RIZQSpacing.lg)
            .padding(.vertical, RIZQSpacing.md)
            .background(Color.rizqCard)
          }
          .buttonStyle(.plain)

          if index < duas.count - 1 {
            Divider()
              .padding(.leading, RIZQSpacing.lg)
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
    }
  }

  private func slotBackgroundColor(_ slot: TimeSlot) -> Color {
    switch slot {
    case .morning:
      return Color.badgeMorning.opacity(0.15)
    case .anytime:
      return Color.tealMuted.opacity(0.15)
    case .evening:
      return Color.badgeEvening.opacity(0.15)
    }
  }

  private func slotIconColor(_ slot: TimeSlot) -> Color {
    switch slot {
    case .morning:
      return Color.badgeMorning
    case .anytime:
      return Color.tealMuted
    case .evening:
      return Color.badgeEvening
    }
  }

  // MARK: - Subscribe Button

  private var subscribeButton: some View {
    VStack(spacing: RIZQSpacing.md) {
      if store.isSubscribed {
        // Currently subscribed indicator
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.tealSuccess)

          if store.activeJourneysCount > 1 {
            Text("Active (1 of \(store.activeJourneysCount) journeys)")
              .font(.rizqSansMedium(.subheadline))
              .foregroundStyle(Color.tealSuccess)
          } else {
            Text("Currently active")
              .font(.rizqSansMedium(.subheadline))
              .foregroundStyle(Color.tealSuccess)
          }
        }

        // Remove button
        Button {
          store.send(.subscribeToggled)
        } label: {
          HStack {
            Image(systemName: "xmark.circle.fill")
            Text("Remove Journey")
          }
          .frame(maxWidth: .infinity)
          .font(.rizqSansSemiBold(.headline))
          .foregroundStyle(Color.red.opacity(0.8))
          .padding(.vertical, RIZQSpacing.md)
          .background(Color.red.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
          .overlay(
            RoundedRectangle(cornerRadius: RIZQRadius.btn)
              .stroke(Color.red.opacity(0.3), lineWidth: 1)
          )
        }
      } else {
        // Add journey button
        Button {
          store.send(.subscribeToggled)
        } label: {
          HStack {
            Image(systemName: "plus.circle.fill")
            Text(store.activeJourneysCount > 0 ? "Add to My Journeys" : "Start This Journey")
          }
          .frame(maxWidth: .infinity)
          .rizqPrimaryButton()
        }
      }
    }
    .padding(.top, RIZQSpacing.md)
  }
}

// MARK: - Preview

#Preview {
  JourneyDetailView(
    store: Store(
      initialState: JourneyDetailFeature.State(
        journeyWithDuas: JourneyWithDuas(
          journey: SampleData.journeys[0],
          duas: SampleData.journeyDuas.filter { $0.journeyDua.journeyId == 1 }
        ),
        isSubscribed: false,
        activeJourneysCount: 0
      )
    ) {
      JourneyDetailFeature()
    }
  )
}
