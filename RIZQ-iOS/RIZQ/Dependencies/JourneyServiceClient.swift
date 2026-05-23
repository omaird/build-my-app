import ComposableArchitecture
import Foundation
import RIZQKit

// MARK: - Journey Service Client

/// Per-journey detail fetch only. The all-journeys master list is owned by
/// `\.cachedContentClient` / `ContentFeature`; this client retains the
/// per-journey expansion (`fetchJourneyDuas`) used by JourneyDetailFeature
/// because it joins `JourneyDua` + `Dua` into the `JourneyDuaFull` view model.
struct JourneyServiceClient: Sendable {
  var fetchJourneyDuas: @Sendable (Int) async throws -> [JourneyDuaFull]
}

extension JourneyServiceClient: DependencyKey {
  static let liveValue: JourneyServiceClient = {
    let firestoreContentService = FirestoreContentService()

    return JourneyServiceClient(
      fetchJourneyDuas: { journeyId in
        let journeyDuas = try await firestoreContentService.fetchJourneyDuas(journeyId)
        let allDuas = try await firestoreContentService.fetchAllDuas()
        let duasCache = Dictionary(uniqueKeysWithValues: allDuas.map { ($0.id, $0) })

        return journeyDuas.compactMap { mapping in
          guard let dua = duasCache[mapping.duaId] else { return nil }
          return JourneyDuaFull(journeyDua: mapping, dua: dua)
        }
      }
    )
  }()

  static let testValue: JourneyServiceClient = JourneyServiceClient(
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
