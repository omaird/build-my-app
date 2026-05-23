import ComposableArchitecture
import Foundation
import RIZQKit
import os.log

private let journeyLogger = Logger(subsystem: "com.rizq.app", category: "Journeys")

@Reducer
struct JourneysFeature {
  @ObservableState
  struct State: Equatable {
    /// Content pushed by AppFeature from the shared ContentFeature. Empty until
    /// the parent's first fetch settles (CachedContentClient typically returns
    /// cached data within milliseconds on warm launches).
    var journeys: [Journey] = []
    var subscribedJourneyIds: Set<Int> = []
    var isLoading: Bool = false
    var errorMessage: String? = nil
    @Presents var detail: JourneyDetailFeature.State?

    var featuredJourneys: [Journey] {
      journeys.filter { $0.isFeatured }
    }

    var activeJourneys: [Journey] {
      journeys.filter { subscribedJourneyIds.contains($0.id) }
    }

    var availableJourneys: [Journey] {
      journeys
        .filter { !subscribedJourneyIds.contains($0.id) && !$0.isFeatured }
        .sorted { $0.sortOrder < $1.sortOrder }
    }

    var availableFeaturedJourneys: [Journey] {
      featuredJourneys.filter { !subscribedJourneyIds.contains($0.id) }
    }
  }

  enum Action {
    case onAppear
    case becameActive  // Called when tab becomes active via programmatic navigation
    case refreshJourneys  // Passthrough — AppFeature listens and triggers .content(.refresh)
    /// Pushed by AppFeature when ContentFeature's journey fetch settles.
    case contentJourneysUpdated([Journey])
    /// Pushed by AppFeature when ContentFeature reports a journey-fetch failure.
    case contentJourneysFailed(String)
    case loadSubscribedIds
    case subscribedIdsLoaded(Set<Int>)
    case journeyTapped(Journey)
    case subscribeToggled(Journey)
    case subscriptionUpdated(journeyId: Int, isSubscribed: Bool)
    case detail(PresentationAction<JourneyDetailFeature.Action>)
    case dismissError
  }

  @Dependency(\.journeyService) var journeyService
  @Dependency(\.habitStorage) var habitStorage
  @Dependency(\.continuousClock) var clock

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // Content is owned by ContentFeature/AppFeature. Here we only need to
        // pull user-data (subscribed IDs) and show a loading hint until content
        // arrives via `.contentJourneysUpdated`.
        if state.journeys.isEmpty {
          state.isLoading = true
          state.errorMessage = nil
        }
        return .send(.loadSubscribedIds)

      case .becameActive:
        // Tab became active via programmatic navigation. Subscribed IDs may have
        // changed (user subscribed from another tab); journey list itself is
        // refreshed by AppFeature pushing `.contentJourneysUpdated` if needed.
        return .send(.loadSubscribedIds)

      case .refreshJourneys:
        // Passthrough — AppFeature observes this and triggers .content(.refresh).
        state.isLoading = true
        state.errorMessage = nil
        return .none

      case .contentJourneysUpdated(let journeys):
        journeyLogger.info("✅ contentJourneysUpdated: \(journeys.count, privacy: .public) journeys")
        state.isLoading = false
        state.errorMessage = nil
        state.journeys = journeys
        return .none

      case .contentJourneysFailed(let message):
        journeyLogger.error("❌ contentJourneysFailed: \(message, privacy: .public)")
        state.isLoading = false
        state.errorMessage = "Failed to load journeys: \(message)"
        return .none

      case .loadSubscribedIds:
        // Load from HabitStorage (shared with AdkharFeature)
        return .run { [habitStorage] send in
          do {
            let ids = try await habitStorage.getActiveJourneyIds()
            await send(.subscribedIdsLoaded(Set(ids)))
          } catch {
            journeyLogger.error("Failed to load subscribed IDs: \(error.localizedDescription, privacy: .public)")
            await send(.subscribedIdsLoaded([]))
          }
        }

      case .subscribedIdsLoaded(let ids):
        state.subscribedJourneyIds = ids
        return .none

      case .journeyTapped(let journey):
        let isSubscribed = state.subscribedJourneyIds.contains(journey.id)
        let activeCount = state.subscribedJourneyIds.count

        // Initialize with empty duas, will be loaded
        state.detail = JourneyDetailFeature.State(
          journeyWithDuas: JourneyWithDuas(journey: journey, duas: []),
          isSubscribed: isSubscribed,
          activeJourneysCount: activeCount,
          isLoading: true
        )

        // Load duas asynchronously
        return .run { [journeyService] send in
          do {
            let duas = try await journeyService.fetchJourneyDuas(journey.id)
            await send(.detail(.presented(.duasLoaded(duas))))
          } catch {
            // Handle error if needed
          }
        }

      case .subscribeToggled(let journey):
        let isCurrentlySubscribed = state.subscribedJourneyIds.contains(journey.id)
        let journeyId = journey.id
        if isCurrentlySubscribed {
          state.subscribedJourneyIds.remove(journey.id)
        } else {
          state.subscribedJourneyIds.insert(journey.id)
        }
        // Persist to HabitStorage (shared with AdkharFeature)
        return .run { [habitStorage] send in
          do {
            if isCurrentlySubscribed {
              try await habitStorage.removeJourney(journeyId)
              journeyLogger.info("Removed journey \(journeyId, privacy: .public) from subscriptions")
            } else {
              try await habitStorage.addJourney(journeyId)
              journeyLogger.info("Added journey \(journeyId, privacy: .public) to subscriptions")
            }
          } catch {
            journeyLogger.error("Failed to update subscription: \(error.localizedDescription, privacy: .public)")
          }
          await send(.subscriptionUpdated(journeyId: journeyId, isSubscribed: !isCurrentlySubscribed))
        }

      case .subscriptionUpdated:
        return .none

      case .detail(.presented(.subscribeToggled)):
        // Handle subscription toggle from detail view
        guard let detailState = state.detail else { return .none }
        let journey = detailState.journeyWithDuas.journey
        let journeyId = journey.id
        let wasSubscribed = detailState.isSubscribed

        if wasSubscribed {
          state.subscribedJourneyIds.remove(journey.id)
          let newCount = state.subscribedJourneyIds.count
          state.detail?.isSubscribed = false
          state.detail?.activeJourneysCount = newCount
        } else {
          state.subscribedJourneyIds.insert(journey.id)
          let newCount = state.subscribedJourneyIds.count
          state.detail?.isSubscribed = true
          state.detail?.activeJourneysCount = newCount
        }
        // Persist to HabitStorage (shared with AdkharFeature)
        return .run { [habitStorage] _ in
          do {
            if wasSubscribed {
              try await habitStorage.removeJourney(journeyId)
              journeyLogger.info("Removed journey \(journeyId, privacy: .public) from subscriptions (detail)")
            } else {
              try await habitStorage.addJourney(journeyId)
              journeyLogger.info("Added journey \(journeyId, privacy: .public) to subscriptions (detail)")
            }
          } catch {
            journeyLogger.error("Failed to update subscription from detail: \(error.localizedDescription, privacy: .public)")
          }
        }

      case .detail(.presented(.dismiss)):
        state.detail = nil
        return .none

      case .detail(.dismiss):
        return .none

      case .detail:
        return .none

      case .dismissError:
        state.errorMessage = nil
        return .none
      }
    }
    .ifLet(\.$detail, action: \.detail) {
      JourneyDetailFeature()
    }
  }

}

// MARK: - Habit Storage Dependency

extension HabitStorage: DependencyKey {
  public static let liveValue: HabitStorage = ServiceContainer.shared.habitStorage
  public static let testValue: HabitStorage = .shared
  public static let previewValue: HabitStorage = .shared
}

extension DependencyValues {
  var habitStorage: HabitStorage {
    get { self[HabitStorage.self] }
    set { self[HabitStorage.self] = newValue }
  }
}
