import ComposableArchitecture
import Foundation
import RIZQKit
import os.log

private let journeyLogger = Logger(subsystem: "com.rizq.app", category: "Journeys")

@Reducer
struct JourneysFeature {
  @ObservableState
  struct State: Equatable {
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
    case journeysLoaded(Result<[Journey], Error>)
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
        let journeyCount = state.journeys.count
        journeyLogger.info("onAppear received, journeys.count: \(journeyCount, privacy: .public)")
        guard state.journeys.isEmpty else {
          journeyLogger.info("Journeys already loaded, skipping fetch")
          return .none
        }
        state.isLoading = true
        journeyLogger.info("Starting to fetch journeys...")
        return .merge(
          .run { [journeyService] send in
            do {
              let journeys = try await journeyService.fetchJourneys()
              await send(.journeysLoaded(.success(journeys)))
            } catch {
              await send(.journeysLoaded(.failure(error)))
            }
          },
          .send(.loadSubscribedIds)
        )

      case .becameActive:
        // Triggered when tab becomes active via programmatic navigation
        // Load journeys if not already loaded
        let journeyCount = state.journeys.count
        journeyLogger.info("becameActive received, journeys.count: \(journeyCount, privacy: .public)")
        guard state.journeys.isEmpty && !state.isLoading else {
          return .none
        }
        state.isLoading = true
        journeyLogger.info("Loading journeys on becameActive...")
        return .merge(
          .run { [journeyService] send in
            do {
              let journeys = try await journeyService.fetchJourneys()
              await send(.journeysLoaded(.success(journeys)))
            } catch {
              await send(.journeysLoaded(.failure(error)))
            }
          },
          .send(.loadSubscribedIds)
        )

      case .journeysLoaded(.success(let journeys)):
        journeyLogger.info("journeysLoaded success: \(journeys.count, privacy: .public) journeys")
        state.isLoading = false
        state.journeys = journeys
        return .none

      case .journeysLoaded(.failure(let error)):
        journeyLogger.error("journeysLoaded failure: \(error.localizedDescription, privacy: .public)")
        state.isLoading = false
        state.errorMessage = error.localizedDescription
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

      case .detail(.presented(.duaTapped)):
        // TODO: Navigate to dua practice
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

// MARK: - Journey Service Client

struct JourneyServiceClient: Sendable {
  var fetchJourneys: @Sendable () async throws -> [Journey]
  var fetchJourneyDuas: @Sendable (Int) async throws -> [JourneyDuaFull]
}

extension JourneyServiceClient: DependencyKey {
  static let liveValue: JourneyServiceClient = {
    // Use FirestoreContentService for content data (duas, journeys)
    // This replaces the deprecated neonService which returns MockNeonService
    let firestoreContentService = FirestoreContentService()

    return JourneyServiceClient(
      fetchJourneys: {
        journeyLogger.info("Fetching journeys from Firestore...")
        do {
          let journeys = try await firestoreContentService.fetchAllJourneys()
          journeyLogger.info("Fetched \(journeys.count, privacy: .public) journeys from Firestore")
          for journey in journeys {
            journeyLogger.info("  Journey: \(journey.name, privacy: .public) (id: \(journey.id, privacy: .public))")
          }
          return journeys
        } catch {
          journeyLogger.error("Error fetching journeys: \(error.localizedDescription, privacy: .public)")
          throw error
        }
      },
      fetchJourneyDuas: { journeyId in
        journeyLogger.info("Fetching duas for journey \(journeyId, privacy: .public) from Firestore...")
        do {
          // Fetch journey duas and all duas, then combine them
          let journeyDuas = try await firestoreContentService.fetchJourneyDuas(journeyId)
          let allDuas = try await firestoreContentService.fetchAllDuas()
          let duasCache = Dictionary(uniqueKeysWithValues: allDuas.map { ($0.id, $0) })

          let fullDuas = journeyDuas.compactMap { journeyDua -> JourneyDuaFull? in
            guard let dua = duasCache[journeyDua.duaId] else { return nil }
            return JourneyDuaFull(journeyDua: journeyDua, dua: dua)
          }

          journeyLogger.info("Fetched \(fullDuas.count, privacy: .public) duas for journey \(journeyId, privacy: .public)")
          return fullDuas
        } catch {
          journeyLogger.error("Error fetching journey duas: \(error.localizedDescription, privacy: .public)")
          throw error
        }
      }
    )
  }()

  static let testValue: JourneyServiceClient = JourneyServiceClient(
    fetchJourneys: { SampleData.journeys },
    fetchJourneyDuas: { journeyId in
      SampleData.journeyDuas.filter { $0.journeyDua.journeyId == journeyId }
    }
  )

  static let previewValue: JourneyServiceClient = testValue
}

extension DependencyValues {
  var journeyService: JourneyServiceClient {
    get { self[JourneyServiceClient.self] }
    set { self[JourneyServiceClient.self] = newValue }
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
