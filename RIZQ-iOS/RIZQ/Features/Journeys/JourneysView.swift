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

      ForEach(store.activeJourneys) { journey in
        JourneyCardView(
          journey: journey,
          isSubscribed: true,
          isFeatured: journey.isFeatured
        ) {
          store.send(.journeyTapped(journey))
        }
      }
    }
  }

  // MARK: - Featured Section

  private var featuredSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      sectionHeader(title: "Featured Journeys", showStar: true)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: RIZQSpacing.md) {
          ForEach(store.availableFeaturedJourneys) { journey in
            FeaturedJourneyCardView(
              journey: journey,
              isSubscribed: store.subscribedJourneyIds.contains(journey.id)
            ) {
              store.send(.journeyTapped(journey))
            }
          }
        }
      }
    }
  }

  // MARK: - All Journeys Section

  private var allJourneysSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.md) {
      sectionHeader(title: "All Journeys")

      LazyVGrid(
        columns: [GridItem(.flexible()), GridItem(.flexible())],
        spacing: RIZQSpacing.md
      ) {
        ForEach(store.availableJourneys) { journey in
          JourneyCardView(
            journey: journey,
            isSubscribed: store.subscribedJourneyIds.contains(journey.id),
            isFeatured: false
          ) {
            store.send(.journeyTapped(journey))
          }
        }
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
