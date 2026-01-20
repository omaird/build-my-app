import UIKit
import CoreHaptics
import os.log

private let logger = Logger(subsystem: "com.rizq.app", category: "HapticManager")

/// Manages haptic feedback throughout the app
/// Provides both UIKit impact/notification feedback and CoreHaptics for custom patterns
public final class HapticManager: @unchecked Sendable {
  public static let shared = HapticManager()

  private var engine: CHHapticEngine?
  private let supportsHaptics: Bool

  private init() {
    supportsHaptics = CHHapticEngine.capabilitiesForHardware().supportsHaptics

    if supportsHaptics {
      prepareHapticEngine()
    }
  }

  // MARK: - Engine Setup

  private func prepareHapticEngine() {
    do {
      engine = try CHHapticEngine()
      engine?.resetHandler = { [weak self] in
        do {
          try self?.engine?.start()
        } catch {
          logger.error("Failed to restart haptic engine: \(error.localizedDescription, privacy: .public)")
        }
      }
      engine?.stoppedHandler = { reason in
        logger.debug("Haptic engine stopped: \(String(describing: reason), privacy: .public)")
      }
      try engine?.start()
    } catch {
      logger.error("Failed to create haptic engine: \(error.localizedDescription, privacy: .public)")
    }
  }

  // MARK: - Simple Haptics (UIKit)

  /// Light tap - for subtle interactions
  public func lightTap() {
    let generator = UIImpactFeedbackGenerator(style: .light)
    generator.prepare()
    generator.impactOccurred()
  }

  /// Medium tap - for button presses
  public func mediumTap() {
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.prepare()
    generator.impactOccurred()
  }

  /// Heavy tap - for significant actions
  public func heavyTap() {
    let generator = UIImpactFeedbackGenerator(style: .heavy)
    generator.prepare()
    generator.impactOccurred()
  }

  /// Soft tap - gentle feedback
  public func softTap() {
    let generator = UIImpactFeedbackGenerator(style: .soft)
    generator.prepare()
    generator.impactOccurred()
  }

  /// Rigid tap - firm feedback
  public func rigidTap() {
    let generator = UIImpactFeedbackGenerator(style: .rigid)
    generator.prepare()
    generator.impactOccurred()
  }

  /// Selection changed - for picker/scroll selections
  public func selection() {
    let generator = UISelectionFeedbackGenerator()
    generator.prepare()
    generator.selectionChanged()
  }

  /// Success notification
  public func success() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.success)
  }

  /// Warning notification
  public func warning() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.warning)
  }

  /// Error notification
  public func error() {
    let generator = UINotificationFeedbackGenerator()
    generator.prepare()
    generator.notificationOccurred(.error)
  }

  // MARK: - App-Specific Haptics

  /// Counter increment - satisfying tap for repetition counting
  public func counterIncrement() {
    mediumTap()
  }

  /// Counter complete - celebratory pattern when reaching target
  public func counterComplete() {
    guard supportsHaptics, let engine = engine else {
      success()
      return
    }

    do {
      // Create a celebratory haptic pattern
      let events: [CHHapticEvent] = [
        // Initial success burst
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
          ],
          relativeTime: 0
        ),
        // Rising confirmation
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
          ],
          relativeTime: 0.1
        ),
        // Final flourish
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
          ],
          relativeTime: 0.2
        )
      ]

      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      // Fallback to simple success
      success()
    }
  }

  /// Habit completion - satisfying check-off feeling
  public func habitComplete() {
    guard supportsHaptics, let engine = engine else {
      success()
      return
    }

    do {
      let events: [CHHapticEvent] = [
        // Soft preparation
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
          ],
          relativeTime: 0
        ),
        // Satisfying confirmation
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
          ],
          relativeTime: 0.08
        )
      ]

      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      success()
    }
  }

  /// Celebration - for major accomplishments (level up, streak milestone)
  public func celebration() {
    guard supportsHaptics, let engine = engine else {
      success()
      return
    }

    do {
      var events: [CHHapticEvent] = []

      // Build up
      for i in 0..<3 {
        events.append(
          CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
              CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i + 1) * 0.3),
              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            ],
            relativeTime: TimeInterval(i) * 0.1
          )
        )
      }

      // Climax burst
      events.append(
        CHHapticEvent(
          eventType: .hapticContinuous,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
          ],
          relativeTime: 0.3,
          duration: 0.2
        )
      )

      // Trailing sparkles
      for i in 0..<4 {
        events.append(
          CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
              CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4 - Float(i) * 0.08),
              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.9)
            ],
            relativeTime: 0.5 + TimeInterval(i) * 0.08
          )
        )
      }

      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      success()
    }
  }

  /// Streak milestone - special pattern for streak achievements
  public func streakMilestone() {
    guard supportsHaptics, let engine = engine else {
      success()
      return
    }

    do {
      var events: [CHHapticEvent] = []

      // Ascending pattern (like flames rising)
      for i in 0..<5 {
        let intensity = 0.4 + Float(i) * 0.15
        events.append(
          CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
              CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
            ],
            relativeTime: TimeInterval(i) * 0.06
          )
        )
      }

      // Peak
      events.append(
        CHHapticEvent(
          eventType: .hapticTransient,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
          ],
          relativeTime: 0.35
        )
      )

      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      success()
    }
  }

  /// Level up - epic achievement feeling
  public func levelUp() {
    guard supportsHaptics, let engine = engine else {
      success()
      return
    }

    do {
      var events: [CHHapticEvent] = []

      // Dramatic build
      for i in 0..<6 {
        events.append(
          CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
              CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i + 1) * 0.15),
              CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3 + Float(i) * 0.1)
            ],
            relativeTime: TimeInterval(i) * 0.08
          )
        )
      }

      // Epic burst
      events.append(
        CHHapticEvent(
          eventType: .hapticContinuous,
          parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
          ],
          relativeTime: 0.5,
          duration: 0.3
        )
      )

      // Shimmer fade
      for i in 0..<3 {
        events.append(
          CHHapticEvent(
            eventType: .hapticTransient,
            parameters: [
              CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.6 - Float(i) * 0.15),
              CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            ],
            relativeTime: 0.85 + TimeInterval(i) * 0.1
          )
        )
      }

      let pattern = try CHHapticPattern(events: events, parameters: [])
      let player = try engine.makePlayer(with: pattern)
      try player.start(atTime: 0)
    } catch {
      success()
    }
  }

  /// Button press - standard button feedback
  public func buttonPress() {
    lightTap()
  }

  /// Tab switch - navigation feedback
  public func tabSwitch() {
    selection()
  }

  /// Card press - feedback for card interactions
  public func cardPress() {
    softTap()
  }

  /// Swipe action - feedback for swipe gestures
  public func swipeAction() {
    mediumTap()
  }
}

// MARK: - SwiftUI View Extension

import SwiftUI

extension View {
  /// Adds haptic feedback on tap
  func hapticOnTap(_ type: HapticType = .light) -> some View {
    simultaneousGesture(
      TapGesture()
        .onEnded { _ in
          type.trigger()
        }
    )
  }
}

/// Haptic feedback types for SwiftUI modifier
public enum HapticType {
  case light
  case medium
  case heavy
  case soft
  case rigid
  case selection
  case success
  case warning
  case error
  case counterIncrement
  case counterComplete
  case habitComplete
  case celebration
  case streakMilestone
  case levelUp

  func trigger() {
    let haptics = HapticManager.shared
    switch self {
    case .light: haptics.lightTap()
    case .medium: haptics.mediumTap()
    case .heavy: haptics.heavyTap()
    case .soft: haptics.softTap()
    case .rigid: haptics.rigidTap()
    case .selection: haptics.selection()
    case .success: haptics.success()
    case .warning: haptics.warning()
    case .error: haptics.error()
    case .counterIncrement: haptics.counterIncrement()
    case .counterComplete: haptics.counterComplete()
    case .habitComplete: haptics.habitComplete()
    case .celebration: haptics.celebration()
    case .streakMilestone: haptics.streakMilestone()
    case .levelUp: haptics.levelUp()
    }
  }
}
