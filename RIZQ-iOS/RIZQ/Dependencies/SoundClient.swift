import ComposableArchitecture
import RIZQKit

/// TCA dependency for UI sound effects.
/// Mirrors the structure of `HapticClient` so tests can no-op sounds easily.
///
/// NOTE: Using manual struct registration instead of @DependencyClient macro per CLAUDE.md.
struct SoundClient: Sendable {
  /// Plays the tasbih bead click. Fire on every counter increment.
  var beadTap: @Sendable () -> Void

  /// Plays the soft completion chime. Fire when a habit is fully completed.
  var completion: @Sendable () -> Void

  /// Pre-warm players so the first `play` has no decode latency.
  /// Call from `.onAppear` of screens that will play sounds.
  var prepare: @Sendable () -> Void
}

// MARK: - Dependency Key

extension SoundClient: DependencyKey {
  static let liveValue = SoundClient(
    beadTap: { SoundPlayer.shared.play(.beadTap) },
    completion: { SoundPlayer.shared.play(.completion) },
    prepare: { SoundPlayer.shared.prepare() }
  )

  static let previewValue = SoundClient(
    beadTap: {},
    completion: {},
    prepare: {}
  )

  static let testValue = SoundClient(
    beadTap: {},
    completion: {},
    prepare: {}
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var sound: SoundClient {
    get { self[SoundClient.self] }
    set { self[SoundClient.self] = newValue }
  }
}
