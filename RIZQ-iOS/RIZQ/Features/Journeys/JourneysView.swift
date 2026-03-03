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

          // Empty State - show when no journeys loaded and not loading
          if store.journeys.isEmpty && !store.isLoading && store.errorMessage == nil {
            emptyState
          }

          // Error State - show when there's an error
          if let errorMessage = store.errorMessage {
            errorState(message: errorMessage)
          }
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, 100) // Tab bar clearance
      }
      .rizqPageBackground()
      .navigationTitle("Journeys")
      .navigationBarTitleDisplayMode(.large)
      .overlay {
        if store.isLoading && store.journeys.isEmpty {
          loadingOverlay
        }
      }
      .sheet(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
        JourneyDetailView(store: detailStore)
      }
    }
    .task {
      store.send(.onAppear)
    }
    .onAppear {
      // Backup trigger for programmatic navigation from other tabs
      if store.journeys.isEmpty && !store.isLoading && store.errorMessage == nil {
        store.send(.onAppear)
      }
    }
    .refreshable {
      store.send(.refreshJourneys)
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

  // MARK: - Empty State

  private var emptyState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      ZStack {
        Circle()
          .fill(Color.rizqPrimary.opacity(0.1))
          .frame(width: 80, height: 80)

        Image(systemName: "map.fill")
          .font(.system(size: 36))
          .foregroundStyle(Color.rizqPrimary)
      }
      .accessibilityHidden(true)

      Text("No Journeys Available")
        .font(.rizqDisplaySemiBold(.title2))
        .foregroundStyle(Color.rizqText)

      Text("Check back soon for curated dua collections to guide your daily practice")
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button {
        store.send(.refreshJourneys)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "arrow.clockwise")
          Text("Refresh")
        }
        .rizqPrimaryButton()
      }
      .accessibilityLabel("Refresh journeys")
    }
    .padding(.top, 60)
  }

  // MARK: - Error State

  private func errorState(message: String) -> some View {
    VStack(spacing: RIZQSpacing.lg) {
      ZStack {
        Circle()
          .fill(Color.rizqPrimary.opacity(0.1))
          .frame(width: 80, height: 80)

        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 36))
          .foregroundStyle(Color.rizqPrimary)
      }
      .accessibilityHidden(true)

      Text("Something Went Wrong")
        .font(.rizqDisplaySemiBold(.title2))
        .foregroundStyle(Color.rizqText)

      Text(message)
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button {
        store.send(.refreshJourneys)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "arrow.clockwise")
          Text("Try Again")
        }
        .rizqPrimaryButton()
      }
      .accessibilityLabel("Try again")
    }
    .padding(.top, 60)
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
