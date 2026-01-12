import SwiftUI
import ComposableArchitecture
import RIZQKit

struct JourneysView: View {
  @Bindable var store: StoreOf<JourneysFeature>

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xxl) {
          // Header description
          headerSection

          // Active Journeys Section
          if !store.activeJourneys.isEmpty {
            activeJourneysSection
          }

          // Featured Journeys Section
          if !store.availableFeaturedJourneys.isEmpty {
            featuredSection
          }

          // All Journeys Section
          if !store.availableJourneys.isEmpty {
            allJourneysSection
          }
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, 100) // Tab bar clearance
      }
      .rizqPageBackground()
      .navigationTitle("Journeys")
      .navigationBarTitleDisplayMode(.large)
      .overlay {
        if store.isLoading {
          loadingOverlay
        }
      }
      .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
        JourneyDetailView(store: detailStore)
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  // MARK: - Header Section

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      Text("Choose your path")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)

      if store.subscribedJourneyIds.count > 0 {
        HStack(spacing: RIZQSpacing.xs) {
          Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(Color.tealSuccess)
          Text("\(store.subscribedJourneyIds.count) active journey\(store.subscribedJourneyIds.count == 1 ? "" : "s")")
            .font(.rizqSansMedium(.caption))
            .foregroundStyle(Color.tealSuccess)
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Active Journeys Section

  private var activeJourneysSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      sectionHeader(
        title: "Your Active Journeys",
        count: store.activeJourneys.count
      )

      ForEach(Array(store.activeJourneys.enumerated()), id: \.element.id) { index, journey in
        JourneyCardView(
          journey: journey,
          isSubscribed: true,
          isFeatured: journey.isFeatured
        ) {
          store.send(.journeyTapped(journey))
        }
        .modifier(JourneyStaggeredItemModifier(index: index))
      }
    }
  }

  // MARK: - Featured Section

  private var featuredSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      sectionHeader(title: "Featured Journeys", showStar: true)

      // Vertical full-width cards (matching React app design)
      ForEach(Array(store.availableFeaturedJourneys.enumerated()), id: \.element.id) { index, journey in
        JourneyCardView(
          journey: journey,
          isSubscribed: store.subscribedJourneyIds.contains(journey.id),
          isFeatured: true
        ) {
          store.send(.journeyTapped(journey))
        }
        .modifier(JourneyStaggeredItemModifier(index: index))
      }
    }
  }

  // MARK: - All Journeys Section

  private var allJourneysSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      sectionHeader(title: "All Journeys")

      // Vertical full-width cards (matching React app design)
      ForEach(Array(store.availableJourneys.enumerated()), id: \.element.id) { index, journey in
        JourneyCardView(
          journey: journey,
          isSubscribed: store.subscribedJourneyIds.contains(journey.id),
          isFeatured: false
        ) {
          store.send(.journeyTapped(journey))
        }
        .modifier(JourneyStaggeredItemModifier(index: index))
      }
    }
  }

  // MARK: - Section Header

  private func sectionHeader(
    title: String,
    count: Int? = nil,
    showStar: Bool = false
  ) -> some View {
    HStack(spacing: RIZQSpacing.sm) {
      if showStar {
        Image(systemName: "star.fill")
          .font(.caption)
          .foregroundStyle(Color.rizqPrimary)
      }

      Text(title)
        .font(.rizqDisplayMedium(.headline))
        .foregroundStyle(Color.rizqText)

      if let count = count {
        Text("(\(count))")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }

      Spacer()
    }
  }

  // MARK: - Loading Overlay

  private var loadingOverlay: some View {
    ZStack {
      Color.rizqBackground.opacity(0.8)
        .ignoresSafeArea()

      VStack(spacing: RIZQSpacing.md) {
        ProgressView()
          .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
          .scaleEffect(1.2)

        Text("Loading journeys...")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
  }
}

// MARK: - Staggered Animation Modifier

/// Modifier for staggered entry animations (matches LibraryView and Framer Motion staggerChildren)
struct JourneyStaggeredItemModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double {
    0.05 * Double(min(index, 10))  // Cap delay to prevent too long waits
  }

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 15)
      .onAppear {
        withAnimation(
          .easeOut(duration: 0.3)
          .delay(delay)
        ) {
          isVisible = true
        }
      }
  }
}

// MARK: - Preview

#Preview {
  JourneysView(
    store: Store(
      initialState: JourneysFeature.State(
        journeys: SampleData.journeys,
        subscribedJourneyIds: [1]
      )
    ) {
      JourneysFeature()
    }
  )
}
