import ComposableArchitecture
import RIZQKit

/// TCA dependency for haptic feedback
/// Allows injection for testing while providing real haptics in production
struct HapticClient: Sendable {
  var lightTap: @Sendable () -> Void
  var mediumTap: @Sendable () -> Void
  var heavyTap: @Sendable () -> Void
  var selection: @Sendable () -> Void
  var success: @Sendable () -> Void
  var warning: @Sendable () -> Void
  var error: @Sendable () -> Void
  var counterIncrement: @Sendable () -> Void
  var counterComplete: @Sendable () -> Void
  var habitComplete: @Sendable () -> Void
  var celebration: @Sendable () -> Void
  var streakMilestone: @Sendable () -> Void
  var levelUp: @Sendable () -> Void
  var buttonPress: @Sendable () -> Void
  var tabSwitch: @Sendable () -> Void
  var cardPress: @Sendable () -> Void
}

// MARK: - Dependency Key

extension HapticClient: DependencyKey {
  static let liveValue = HapticClient(
    lightTap: { HapticManager.shared.lightTap() },
    mediumTap: { HapticManager.shared.mediumTap() },
    heavyTap: { HapticManager.shared.heavyTap() },
    selection: { HapticManager.shared.selection() },
    success: { HapticManager.shared.success() },
    warning: { HapticManager.shared.warning() },
    error: { HapticManager.shared.error() },
    counterIncrement: { HapticManager.shared.counterIncrement() },
    counterComplete: { HapticManager.shared.counterComplete() },
    habitComplete: { HapticManager.shared.habitComplete() },
    celebration: { HapticManager.shared.celebration() },
    streakMilestone: { HapticManager.shared.streakMilestone() },
    levelUp: { HapticManager.shared.levelUp() },
    buttonPress: { HapticManager.shared.buttonPress() },
    tabSwitch: { HapticManager.shared.tabSwitch() },
    cardPress: { HapticManager.shared.cardPress() }
  )

  static let previewValue = HapticClient(
    lightTap: {},
    mediumTap: {},
    heavyTap: {},
    selection: {},
    success: {},
    warning: {},
    error: {},
    counterIncrement: {},
    counterComplete: {},
    habitComplete: {},
    celebration: {},
    streakMilestone: {},
    levelUp: {},
    buttonPress: {},
    tabSwitch: {},
    cardPress: {}
  )

  static let testValue = HapticClient(
    lightTap: {},
    mediumTap: {},
    heavyTap: {},
    selection: {},
    success: {},
    warning: {},
    error: {},
    counterIncrement: {},
    counterComplete: {},
    habitComplete: {},
    celebration: {},
    streakMilestone: {},
    levelUp: {},
    buttonPress: {},
    tabSwitch: {},
    cardPress: {}
  )
}

// MARK: - Dependency Values

extension DependencyValues {
  var haptics: HapticClient {
    get { self[HapticClient.self] }
    set { self[HapticClient.self] = newValue }
  }
}
