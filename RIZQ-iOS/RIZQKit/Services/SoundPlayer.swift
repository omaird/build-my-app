import AVFoundation
import Foundation
import os.log

private let logger = Logger(subsystem: "com.rizq.app", category: "SoundPlayer")

/// Plays short UI sound effects (counter tap, completion chime).
///
/// Design notes:
/// - Audio session category is `.ambient`, so sounds mix with other audio
///   (e.g., Quran recitation playing in another app) and **respect the silent
///   switch** — important for an Islamic app where users often have the phone
///   on silent during salah.
/// - Each sound owns a small pool of `AVAudioPlayer` instances so rapid
///   repeated taps can overlap without clipping each other off.
/// - The on/off toggle is consulted from `UserDefaults` on every play so that
///   changes from Settings take effect immediately without restarting the app.
public final class SoundPlayer: @unchecked Sendable {
  public static let shared = SoundPlayer()

  /// UserDefaults key matched by `SettingsFeature`'s toggle.
  public static let soundEffectsEnabledKey = "soundEffectsEnabled"

  public enum Effect: String {
    case beadTap = "bead_tap"
    case completion = "completion_chime"

    fileprivate var poolSize: Int {
      switch self {
      case .beadTap: return 4      // rapid taps can overlap
      case .completion: return 1   // one-shot
      }
    }
  }

  private struct Pool {
    var players: [AVAudioPlayer]
    var cursor: Int = 0
  }

  private let queue = DispatchQueue(label: "com.rizq.app.soundplayer", qos: .userInitiated)
  private var pools: [Effect: Pool] = [:]
  private var sessionConfigured = false

  private init() {}

  /// Pre-load and warm the audio engine. Safe to call repeatedly.
  /// Call from a view's `onAppear` on screens that will play sounds.
  public func prepare() {
    queue.async { [weak self] in
      guard let self else { return }
      self.configureSessionIfNeeded()
      for effect in [Effect.beadTap, Effect.completion] where self.pools[effect] == nil {
        self.pools[effect] = self.makePool(for: effect)
      }
    }
  }

  /// Play a sound effect. No-op if disabled in settings or asset is missing.
  public func play(_ effect: Effect) {
    guard isEnabled() else { return }
    queue.async { [weak self] in
      guard let self else { return }
      self.configureSessionIfNeeded()

      if self.pools[effect] == nil {
        self.pools[effect] = self.makePool(for: effect)
      }
      guard var pool = self.pools[effect], !pool.players.isEmpty else { return }

      let player = pool.players[pool.cursor]
      pool.cursor = (pool.cursor + 1) % pool.players.count
      self.pools[effect] = pool

      player.currentTime = 0
      player.play()
    }
  }

  // MARK: - Internals

  private func isEnabled() -> Bool {
    let defaults = UserDefaults.standard
    // Default ON when the key has never been set.
    if defaults.object(forKey: Self.soundEffectsEnabledKey) == nil { return true }
    return defaults.bool(forKey: Self.soundEffectsEnabledKey)
  }

  private func configureSessionIfNeeded() {
    guard !sessionConfigured else { return }
    #if os(iOS) || os(tvOS) || os(watchOS)
    let session = AVAudioSession.sharedInstance()
    do {
      try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
      try session.setActive(true, options: [])
    } catch {
      logger.error("AVAudioSession config failed: \(error.localizedDescription, privacy: .public)")
    }
    #endif
    sessionConfigured = true
  }

  private func makePool(for effect: Effect) -> Pool {
    guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "caf", subdirectory: "Sounds")
            ?? Bundle.main.url(forResource: effect.rawValue, withExtension: "caf")
    else {
      logger.error("Sound asset missing: \(effect.rawValue, privacy: .public).caf")
      return Pool(players: [])
    }

    var players: [AVAudioPlayer] = []
    for _ in 0..<effect.poolSize {
      do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
        player.volume = 1.0
        players.append(player)
      } catch {
        logger.error("AVAudioPlayer init failed for \(effect.rawValue, privacy: .public): \(error.localizedDescription, privacy: .public)")
      }
    }
    return Pool(players: players)
  }
}
