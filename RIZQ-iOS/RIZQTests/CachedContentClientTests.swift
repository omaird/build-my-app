import ComposableArchitecture
import XCTest
@testable import RIZQ
@testable import RIZQKit

@MainActor
final class CachedContentClientTests: XCTestCase {
  override func setUp() {
    super.setUp()
    // Clear UserDefaults cache keys to isolate each test
    let defaults = UserDefaults.standard
    ["cached_duas", "cached_journeys", "cached_categories"].forEach {
      defaults.removeObject(forKey: $0)
    }
  }

  override func tearDown() {
    let defaults = UserDefaults.standard
    ["cached_duas", "cached_journeys", "cached_categories"].forEach {
      defaults.removeObject(forKey: $0)
    }
    super.tearDown()
  }

  // MARK: - Helpers

  /// Build a `Dua` with whole-second timestamps so ISO8601 round-trips preserve `Equatable`.
  private func makeStableDua() -> Dua {
    // Whole-second epoch avoids fractional-second drift in ISO8601 round-trips.
    let date = Date(timeIntervalSince1970: 1_700_000_000)
    return Dua(
      id: 42,
      categoryId: 1,
      titleEn: "Test Dua",
      arabicText: "اختبار",
      translationEn: "Test",
      repetitions: 3,
      xpValue: 15,
      createdAt: date,
      updatedAt: date
    )
  }

  // MARK: - fetchAllDuas

  func testNetworkSuccessReturnsAndCachesResult() async throws {
    let mockDuas = [makeStableDua()]
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { mockDuas }
    let cached = CachedContentClient(wrapping: underlying)

    let result = try await cached.fetchAllDuas()
    XCTAssertEqual(result, mockDuas)

    // Verify cache populated with a non-empty payload under the expected key.
    let raw = UserDefaults.standard.data(forKey: "cached_duas")
    XCTAssertNotNil(raw)
    XCTAssertGreaterThan(raw?.count ?? 0, 0)
  }

  func testNetworkFailureReturnsCachedResult() async throws {
    let mockDuas = [makeStableDua()]

    // Pre-populate cache by driving a successful fetch through the wrapper itself,
    // so the cache uses the wrapper's own encoder/decoder pairing.
    var seedingUnderlying = FirestoreContentClient.testValue
    seedingUnderlying.fetchAllDuas = { mockDuas }
    _ = try await CachedContentClient(wrapping: seedingUnderlying).fetchAllDuas()

    struct NetErr: Error {}
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { throw NetErr() }
    let cached = CachedContentClient(wrapping: underlying)

    let result = try await cached.fetchAllDuas()
    XCTAssertEqual(result, mockDuas)
  }

  func testNetworkFailureWithEmptyCacheRethrows() async {
    struct NetErr: Error, Equatable {}
    var underlying = FirestoreContentClient.testValue
    underlying.fetchAllDuas = { throw NetErr() }
    let cached = CachedContentClient(wrapping: underlying)

    do {
      _ = try await cached.fetchAllDuas()
      XCTFail("Expected rethrow when both network and cache are empty")
    } catch is NetErr {
      // Expected — the original network error surfaces so callers can show
      // a real error state instead of an unexplained empty list.
    } catch {
      XCTFail("Expected NetErr, got \(error)")
    }
  }
}
