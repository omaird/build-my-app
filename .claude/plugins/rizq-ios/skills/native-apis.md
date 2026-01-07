---
name: native-apis
description: "iOS native API patterns: Haptic feedback, WidgetKit, ShareSheet, App Intents (Siri), and Push Notifications"
---

# Native iOS APIs

This skill provides patterns for integrating iOS-native features that enhance the RIZQ app beyond web capabilities.

---

## Haptic Feedback

### UIFeedbackGenerator Types

```swift
import UIKit

// MARK: - Haptic Manager
final class HapticManager {
  static let shared = HapticManager()

  private let impactLight = UIImpactFeedbackGenerator(style: .light)
  private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
  private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
  private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
  private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
  private let notification = UINotificationFeedbackGenerator()
  private let selection = UISelectionFeedbackGenerator()

  private init() {
    // Prepare generators for lower latency
    prepareAll()
  }

  func prepareAll() {
    impactLight.prepare()
    impactMedium.prepare()
    impactHeavy.prepare()
    notification.prepare()
    selection.prepare()
  }

  // MARK: - Impact Feedback

  func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1.0) {
    let generator: UIImpactFeedbackGenerator
    switch style {
    case .light: generator = impactLight
    case .medium: generator = impactMedium
    case .heavy: generator = impactHeavy
    case .soft: generator = impactSoft
    case .rigid: generator = impactRigid
    @unknown default: generator = impactMedium
    }
    generator.impactOccurred(intensity: intensity)
  }

  // MARK: - Notification Feedback

  func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
    notification.notificationOccurred(type)
  }

  // MARK: - Selection Feedback

  func selection() {
    selection.selectionChanged()
  }

  // MARK: - RIZQ Custom Patterns

  /// Tap feedback for buttons
  func tap() {
    impact(.light)
  }

  /// Success feedback for completing a dua
  func success() {
    notification(.success)
  }

  /// Celebration feedback for XP earned
  func celebration() {
    // Double tap pattern
    impact(.medium)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      self.impact(.heavy)
    }
  }

  /// Counter increment feedback
  func counter() {
    impact(.soft, intensity: 0.5)
  }

  /// Streak milestone feedback
  func streakMilestone() {
    notification(.success)
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
      self.impact(.heavy)
    }
  }

  /// Error feedback
  func error() {
    notification(.error)
  }

  /// Warning feedback
  func warning() {
    notification(.warning)
  }
}
```

### SwiftUI Integration

```swift
import SwiftUI

// MARK: - Haptic View Modifier
struct HapticModifier: ViewModifier {
  let type: HapticType
  @AppStorage("haptics_enabled") private var hapticsEnabled = true

  enum HapticType {
    case tap
    case success
    case error
    case selection
    case counter
    case celebration
  }

  func body(content: Content) -> some View {
    content
      .simultaneousGesture(TapGesture().onEnded {
        guard hapticsEnabled else { return }
        performHaptic()
      })
  }

  private func performHaptic() {
    switch type {
    case .tap: HapticManager.shared.tap()
    case .success: HapticManager.shared.success()
    case .error: HapticManager.shared.error()
    case .selection: HapticManager.shared.selection()
    case .counter: HapticManager.shared.counter()
    case .celebration: HapticManager.shared.celebration()
    }
  }
}

extension View {
  func haptic(_ type: HapticModifier.HapticType) -> some View {
    modifier(HapticModifier(type: type))
  }
}

// MARK: - Usage
struct DuaCounterButton: View {
  @State private var count = 0
  let targetCount: Int

  var body: some View {
    Button {
      count += 1
      if count >= targetCount {
        HapticManager.shared.success()
      } else {
        HapticManager.shared.counter()
      }
    } label: {
      Text("\(count) / \(targetCount)")
    }
    .haptic(.tap)
  }
}
```

### Sensory Feedback (iOS 17+)

```swift
import SwiftUI

// MARK: - Modern Sensory Feedback
struct ModernHapticView: View {
  @State private var isCompleted = false

  var body: some View {
    Button("Complete") {
      isCompleted = true
    }
    .sensoryFeedback(.success, trigger: isCompleted)
  }
}

// MARK: - Custom Sensory Patterns
extension SensoryFeedback {
  static let duaComplete = SensoryFeedback.impact(weight: .medium, intensity: 0.8)
  static let xpEarned = SensoryFeedback.impact(weight: .heavy, intensity: 1.0)
  static let counterTap = SensoryFeedback.impact(weight: .light, intensity: 0.5)
}
```

---

## WidgetKit

### Widget Configuration

```swift
import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct RIZQWidgetEntry: TimelineEntry {
  let date: Date
  let streak: Int
  let todaysProgress: Int
  let totalHabits: Int
  let nextDua: String?
}

// MARK: - Timeline Provider
struct RIZQWidgetProvider: TimelineProvider {
  func placeholder(in context: Context) -> RIZQWidgetEntry {
    RIZQWidgetEntry(
      date: Date(),
      streak: 7,
      todaysProgress: 3,
      totalHabits: 5,
      nextDua: "Morning Remembrance"
    )
  }

  func getSnapshot(in context: Context, completion: @escaping (RIZQWidgetEntry) -> Void) {
    let entry = RIZQWidgetEntry(
      date: Date(),
      streak: loadStreak(),
      todaysProgress: loadTodaysProgress(),
      totalHabits: loadTotalHabits(),
      nextDua: loadNextDua()
    )
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<RIZQWidgetEntry>) -> Void) {
    let entry = RIZQWidgetEntry(
      date: Date(),
      streak: loadStreak(),
      todaysProgress: loadTodaysProgress(),
      totalHabits: loadTotalHabits(),
      nextDua: loadNextDua()
    )

    // Refresh at next hour
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  // MARK: - Data Loading (from App Group)

  private func loadStreak() -> Int {
    let defaults = UserDefaults(suiteName: "group.com.rizq.app")
    return defaults?.integer(forKey: "streak") ?? 0
  }

  private func loadTodaysProgress() -> Int {
    let defaults = UserDefaults(suiteName: "group.com.rizq.app")
    return defaults?.integer(forKey: "todays_progress") ?? 0
  }

  private func loadTotalHabits() -> Int {
    let defaults = UserDefaults(suiteName: "group.com.rizq.app")
    return defaults?.integer(forKey: "total_habits") ?? 0
  }

  private func loadNextDua() -> String? {
    let defaults = UserDefaults(suiteName: "group.com.rizq.app")
    return defaults?.string(forKey: "next_dua")
  }
}
```

### Widget Views

```swift
// MARK: - Small Widget
struct RIZQWidgetSmall: View {
  let entry: RIZQWidgetEntry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Streak
      HStack(spacing: 4) {
        Image(systemName: "flame.fill")
          .foregroundStyle(.orange)
        Text("\(entry.streak)")
          .font(.system(.title2, design: .rounded, weight: .bold))
      }

      Spacer()

      // Progress
      VStack(alignment: .leading, spacing: 4) {
        Text("Today")
          .font(.caption)
          .foregroundStyle(.secondary)

        ProgressView(value: Double(entry.todaysProgress), total: Double(max(entry.totalHabits, 1)))
          .tint(.rizqPrimary)

        Text("\(entry.todaysProgress)/\(entry.totalHabits) completed")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .containerBackground(.background, for: .widget)
  }
}

// MARK: - Medium Widget
struct RIZQWidgetMedium: View {
  let entry: RIZQWidgetEntry

  var body: some View {
    HStack(spacing: 16) {
      // Left: Streak
      VStack(spacing: 4) {
        Image(systemName: "flame.fill")
          .font(.largeTitle)
          .foregroundStyle(.orange)

        Text("\(entry.streak)")
          .font(.system(.title, design: .rounded, weight: .bold))

        Text("day streak")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity)

      Divider()

      // Right: Next dua
      VStack(alignment: .leading, spacing: 8) {
        Text("Up Next")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let nextDua = entry.nextDua {
          Text(nextDua)
            .font(.headline)
            .lineLimit(2)
        } else {
          Text("All done for now!")
            .font(.headline)
            .foregroundStyle(.green)
        }

        Spacer()

        // Progress bar
        VStack(alignment: .leading, spacing: 2) {
          ProgressView(value: Double(entry.todaysProgress), total: Double(max(entry.totalHabits, 1)))
            .tint(.rizqPrimary)

          Text("\(entry.todaysProgress)/\(entry.totalHabits)")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding()
    .containerBackground(.background, for: .widget)
  }
}

// MARK: - Widget Bundle
@main
struct RIZQWidgetBundle: WidgetBundle {
  var body: some Widget {
    RIZQWidget()
    RIZQLockScreenWidget()
  }
}

struct RIZQWidget: Widget {
  let kind = "RIZQWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RIZQWidgetProvider()) { entry in
      RIZQWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("RIZQ Progress")
    .description("Track your daily dua practice")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

struct RIZQWidgetEntryView: View {
  @Environment(\.widgetFamily) var family
  let entry: RIZQWidgetEntry

  var body: some View {
    switch family {
    case .systemSmall:
      RIZQWidgetSmall(entry: entry)
    case .systemMedium:
      RIZQWidgetMedium(entry: entry)
    default:
      RIZQWidgetSmall(entry: entry)
    }
  }
}
```

### Lock Screen Widget (iOS 16+)

```swift
// MARK: - Lock Screen Widget
struct RIZQLockScreenWidget: Widget {
  let kind = "RIZQLockScreenWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RIZQWidgetProvider()) { entry in
      RIZQLockScreenView(entry: entry)
    }
    .configurationDisplayName("RIZQ Streak")
    .description("Your current streak")
    .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
  }
}

struct RIZQLockScreenView: View {
  @Environment(\.widgetFamily) var family
  let entry: RIZQWidgetEntry

  var body: some View {
    switch family {
    case .accessoryCircular:
      Gauge(value: Double(entry.todaysProgress), in: 0...Double(max(entry.totalHabits, 1))) {
        Image(systemName: "flame.fill")
      } currentValueLabel: {
        Text("\(entry.streak)")
      }
      .gaugeStyle(.accessoryCircular)

    case .accessoryRectangular:
      VStack(alignment: .leading) {
        HStack {
          Image(systemName: "flame.fill")
          Text("\(entry.streak) day streak")
        }
        .font(.headline)

        Text("\(entry.todaysProgress)/\(entry.totalHabits) today")
          .font(.caption)
      }

    case .accessoryInline:
      Label("\(entry.streak) day streak", systemImage: "flame.fill")

    default:
      Text("\(entry.streak)")
    }
  }
}
```

### Update Widget from App

```swift
import WidgetKit

// MARK: - Widget Data Manager
@MainActor
final class WidgetDataManager {
  static let shared = WidgetDataManager()

  private let defaults = UserDefaults(suiteName: "group.com.rizq.app")

  private init() {}

  func updateStreak(_ streak: Int) {
    defaults?.set(streak, forKey: "streak")
    reloadWidgets()
  }

  func updateProgress(completed: Int, total: Int) {
    defaults?.set(completed, forKey: "todays_progress")
    defaults?.set(total, forKey: "total_habits")
    reloadWidgets()
  }

  func updateNextDua(_ dua: String?) {
    defaults?.set(dua, forKey: "next_dua")
    reloadWidgets()
  }

  private func reloadWidgets() {
    WidgetCenter.shared.reloadAllTimelines()
  }
}

// MARK: - Usage in App
extension HabitStorageManager {
  func markHabitComplete(_ habitId: String) async throws {
    // ... existing completion logic ...

    // Update widget
    let completed = todaysCompletions.count
    let total = try await getTodaysHabits().count
    await WidgetDataManager.shared.updateProgress(completed: completed, total: total)
  }
}
```

---

## ShareSheet (UIActivityViewController)

### Share Manager

```swift
import UIKit
import SwiftUI

// MARK: - Share Manager
@MainActor
final class ShareManager {
  static let shared = ShareManager()

  private init() {}

  // MARK: - Share Dua

  func shareDua(_ dua: Dua) {
    let text = """
    📿 \(dua.title)

    \(dua.arabicText)

    \(dua.transliteration)

    "\(dua.translation)"

    \(dua.source ?? "")

    Shared from RIZQ - Islamic Dua Practice
    """

    share(items: [text])
  }

  // MARK: - Share Progress

  func shareProgress(streak: Int, level: Int, totalXP: Int) {
    let text = """
    🔥 My RIZQ Progress

    🌟 Level \(level)
    ⚡ \(totalXP) XP earned
    🔥 \(streak) day streak

    Join me in building a daily dua practice!

    #RIZQ #IslamicApp #DuaPractice
    """

    share(items: [text])
  }

  // MARK: - Share Achievement

  func shareAchievement(title: String, description: String) {
    let text = """
    🏆 Achievement Unlocked!

    \(title)
    \(description)

    Earned in RIZQ - Islamic Dua Practice
    """

    share(items: [text])
  }

  // MARK: - Share App

  func shareApp() {
    let text = "I'm using RIZQ to build a daily dua practice. Check it out!"
    let url = URL(string: "https://apps.apple.com/app/rizq/id123456789")!

    share(items: [text, url])
  }

  // MARK: - Generic Share

  func share(items: [Any], excludedTypes: [UIActivity.ActivityType] = []) {
    let activityVC = UIActivityViewController(
      activityItems: items,
      applicationActivities: nil
    )
    activityVC.excludedActivityTypes = excludedTypes

    // Present
    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let rootVC = windowScene.windows.first?.rootViewController {
      // Handle iPad popover
      if let popover = activityVC.popoverPresentationController {
        popover.sourceView = rootVC.view
        popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
        popover.permittedArrowDirections = []
      }

      rootVC.present(activityVC, animated: true)
    }
  }
}
```

### SwiftUI ShareLink (iOS 16+)

```swift
import SwiftUI

// MARK: - Share Button
struct DuaShareButton: View {
  let dua: Dua

  var body: some View {
    ShareLink(
      item: shareText,
      subject: Text(dua.title),
      message: Text("Check out this beautiful dua")
    ) {
      Label("Share", systemImage: "square.and.arrow.up")
    }
  }

  private var shareText: String {
    """
    📿 \(dua.title)

    \(dua.arabicText)

    \(dua.transliteration)

    "\(dua.translation)"
    """
  }
}

// MARK: - Custom Transferable
struct ShareableDua: Transferable {
  let dua: Dua

  static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation { shareable in
      shareable.formattedText
    }
  }

  var formattedText: String {
    """
    📿 \(dua.title)

    \(dua.arabicText)

    \(dua.transliteration)

    "\(dua.translation)"

    Shared from RIZQ
    """
  }
}

// MARK: - Usage with Transferable
struct DuaDetailView: View {
  let dua: Dua

  var body: some View {
    VStack {
      // ... dua content ...

      ShareLink(item: ShareableDua(dua: dua)) {
        Label("Share Dua", systemImage: "square.and.arrow.up")
      }
      .buttonStyle(.borderedProminent)
    }
  }
}
```

---

## App Intents (Siri Shortcuts)

### Basic App Intent

```swift
import AppIntents

// MARK: - Practice Dua Intent
struct PracticeDuaIntent: AppIntent {
  static var title: LocalizedStringResource = "Practice a Dua"
  static var description = IntentDescription("Open RIZQ to practice a specific dua")

  @Parameter(title: "Dua Name")
  var duaName: String?

  static var openAppWhenRun: Bool = true

  func perform() async throws -> some IntentResult {
    // This will open the app
    // The app can read the intent parameters to navigate
    return .result()
  }
}

// MARK: - Check Streak Intent
struct CheckStreakIntent: AppIntent {
  static var title: LocalizedStringResource = "Check My Streak"
  static var description = IntentDescription("Check your current RIZQ streak")

  static var openAppWhenRun: Bool = false

  func perform() async throws -> some IntentResult & ReturnsValue<Int> & ProvidesDialog {
    let streak = UserDefaults(suiteName: "group.com.rizq.app")?.integer(forKey: "streak") ?? 0

    return .result(
      value: streak,
      dialog: "Your current streak is \(streak) days. Keep it up!"
    )
  }
}

// MARK: - Log Dua Intent
struct LogDuaCompletionIntent: AppIntent {
  static var title: LocalizedStringResource = "Log Dua Completion"
  static var description = IntentDescription("Log that you completed a dua")

  @Parameter(title: "Dua")
  var dua: DuaEntity

  func perform() async throws -> some IntentResult & ProvidesDialog {
    // Log completion
    // In real app, this would update SwiftData

    return .result(dialog: "Logged \(dua.name) as complete. MashAllah!")
  }
}
```

### App Entity for Intents

```swift
import AppIntents

// MARK: - Dua Entity
struct DuaEntity: AppEntity {
  var id: Int
  var name: String

  static var defaultQuery = DuaEntityQuery()

  static var typeDisplayRepresentation: TypeDisplayRepresentation {
    TypeDisplayRepresentation(name: "Dua")
  }

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

// MARK: - Dua Entity Query
struct DuaEntityQuery: EntityQuery {
  func entities(for identifiers: [Int]) async throws -> [DuaEntity] {
    // Fetch from database
    // Simplified for example
    return identifiers.map { DuaEntity(id: $0, name: "Dua \($0)") }
  }

  func suggestedEntities() async throws -> [DuaEntity] {
    // Return commonly used duas
    return [
      DuaEntity(id: 1, name: "Morning Remembrance"),
      DuaEntity(id: 2, name: "Evening Remembrance"),
      DuaEntity(id: 3, name: "Before Sleep")
    ]
  }
}
```

### App Shortcuts Provider

```swift
import AppIntents

// MARK: - Shortcuts Provider
struct RIZQShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: PracticeDuaIntent(),
      phrases: [
        "Practice a dua in \(.applicationName)",
        "Open \(.applicationName) to practice",
        "Start dua practice in \(.applicationName)"
      ],
      shortTitle: "Practice Dua",
      systemImageName: "hands.sparkles"
    )

    AppShortcut(
      intent: CheckStreakIntent(),
      phrases: [
        "Check my \(.applicationName) streak",
        "What's my streak in \(.applicationName)",
        "How many days streak in \(.applicationName)"
      ],
      shortTitle: "Check Streak",
      systemImageName: "flame"
    )
  }
}
```

### Siri Tips

```swift
import SwiftUI
import AppIntents

// MARK: - Siri Tip View
struct SiriTipView: View {
  var body: some View {
    SiriTipView(intent: PracticeDuaIntent())
      .siriTipViewStyle(.automatic)
  }
}

// MARK: - Donate Intent (for Suggestions)
func donateIntent() {
  let intent = PracticeDuaIntent()
  intent.duaName = "Morning Remembrance"

  Task {
    try? await intent.donate()
  }
}
```

---

## Push Notifications

### Notification Manager

```swift
import UserNotifications

// MARK: - Notification Manager
@MainActor
final class NotificationManager: NSObject, ObservableObject {
  static let shared = NotificationManager()

  @Published var isAuthorized = false
  @Published var pendingNotifications: [UNNotificationRequest] = []

  private override init() {
    super.init()
    UNUserNotificationCenter.current().delegate = self
  }

  // MARK: - Authorization

  func requestAuthorization() async -> Bool {
    do {
      let granted = try await UNUserNotificationCenter.current().requestAuthorization(
        options: [.alert, .badge, .sound]
      )
      await MainActor.run {
        isAuthorized = granted
      }
      return granted
    } catch {
      return false
    }
  }

  func checkAuthorizationStatus() async {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    await MainActor.run {
      isAuthorized = settings.authorizationStatus == .authorized
    }
  }

  // MARK: - Schedule Notifications

  func scheduleMorningReminder(at time: DateComponents) async throws {
    let content = UNMutableNotificationContent()
    content.title = "Morning Adhkar ☀️"
    content.body = "Start your day with morning remembrance"
    content.sound = .default
    content.badge = 1

    let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
    let request = UNNotificationRequest(
      identifier: "morning_reminder",
      content: content,
      trigger: trigger
    )

    try await UNUserNotificationCenter.current().add(request)
  }

  func scheduleEveningReminder(at time: DateComponents) async throws {
    let content = UNMutableNotificationContent()
    content.title = "Evening Adhkar 🌙"
    content.body = "Wind down with evening remembrance"
    content.sound = .default
    content.badge = 1

    let trigger = UNCalendarNotificationTrigger(dateMatching: time, repeats: true)
    let request = UNNotificationRequest(
      identifier: "evening_reminder",
      content: content,
      trigger: trigger
    )

    try await UNUserNotificationCenter.current().add(request)
  }

  func scheduleStreakReminder() async throws {
    // Send if user hasn't opened app by 8 PM
    let content = UNMutableNotificationContent()
    content.title = "Don't break your streak! 🔥"
    content.body = "Complete your daily duas to keep your streak going"
    content.sound = .default

    var dateComponents = DateComponents()
    dateComponents.hour = 20
    dateComponents.minute = 0

    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
    let request = UNNotificationRequest(
      identifier: "streak_reminder",
      content: content,
      trigger: trigger
    )

    try await UNUserNotificationCenter.current().add(request)
  }

  // MARK: - Cancel Notifications

  func cancelNotification(_ identifier: String) {
    UNUserNotificationCenter.current().removePendingNotificationRequests(
      withIdentifiers: [identifier]
    )
  }

  func cancelAllNotifications() {
    UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
  }

  // MARK: - Fetch Pending

  func fetchPendingNotifications() async {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    await MainActor.run {
      pendingNotifications = requests
    }
  }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification
  ) async -> UNNotificationPresentationOptions {
    // Show notification even when app is foreground
    return [.banner, .sound, .badge]
  }

  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse
  ) async {
    // Handle notification tap
    let identifier = response.notification.request.identifier

    switch identifier {
    case "morning_reminder":
      // Navigate to morning adhkar
      NotificationCenter.default.post(
        name: .navigateToMorningAdhkar,
        object: nil
      )
    case "evening_reminder":
      // Navigate to evening adhkar
      NotificationCenter.default.post(
        name: .navigateToEveningAdhkar,
        object: nil
      )
    default:
      break
    }
  }
}

// MARK: - Notification Names
extension Notification.Name {
  static let navigateToMorningAdhkar = Notification.Name("navigateToMorningAdhkar")
  static let navigateToEveningAdhkar = Notification.Name("navigateToEveningAdhkar")
}
```

### Local Notification Settings View

```swift
import SwiftUI

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
  @StateObject private var manager = NotificationManager.shared
  @AppStorage("morning_reminder_enabled") private var morningEnabled = false
  @AppStorage("evening_reminder_enabled") private var eveningEnabled = false
  @AppStorage("streak_reminder_enabled") private var streakEnabled = true

  @State private var morningTime = DateComponents(hour: 6, minute: 0)
  @State private var eveningTime = DateComponents(hour: 20, minute: 0)

  var body: some View {
    Form {
      Section {
        if !manager.isAuthorized {
          Button("Enable Notifications") {
            Task {
              _ = await manager.requestAuthorization()
            }
          }
        }
      }

      Section("Daily Reminders") {
        Toggle("Morning Adhkar", isOn: $morningEnabled)
          .onChange(of: morningEnabled) { _, newValue in
            Task {
              if newValue {
                try? await manager.scheduleMorningReminder(at: morningTime)
              } else {
                manager.cancelNotification("morning_reminder")
              }
            }
          }

        if morningEnabled {
          DatePicker(
            "Time",
            selection: Binding(
              get: { Calendar.current.date(from: morningTime) ?? Date() },
              set: { morningTime = Calendar.current.dateComponents([.hour, .minute], from: $0) }
            ),
            displayedComponents: .hourAndMinute
          )
        }

        Toggle("Evening Adhkar", isOn: $eveningEnabled)
          .onChange(of: eveningEnabled) { _, newValue in
            Task {
              if newValue {
                try? await manager.scheduleEveningReminder(at: eveningTime)
              } else {
                manager.cancelNotification("evening_reminder")
              }
            }
          }

        if eveningEnabled {
          DatePicker(
            "Time",
            selection: Binding(
              get: { Calendar.current.date(from: eveningTime) ?? Date() },
              set: { eveningTime = Calendar.current.dateComponents([.hour, .minute], from: $0) }
            ),
            displayedComponents: .hourAndMinute
          )
        }
      }

      Section("Streak Protection") {
        Toggle("Streak Reminder", isOn: $streakEnabled)
          .onChange(of: streakEnabled) { _, newValue in
            Task {
              if newValue {
                try? await manager.scheduleStreakReminder()
              } else {
                manager.cancelNotification("streak_reminder")
              }
            }
          }

        if streakEnabled {
          Text("Reminds you at 8 PM if you haven't practiced today")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle("Notifications")
    .task {
      await manager.checkAuthorizationStatus()
    }
  }
}
```

---

## Live Activities (iOS 16.1+)

### Live Activity for Practice Session

```swift
import ActivityKit
import WidgetKit

// MARK: - Practice Session Attributes
struct PracticeSessionAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var currentDua: String
    var progress: Int
    var total: Int
    var xpEarned: Int
  }

  var journeyName: String
  var startTime: Date
}

// MARK: - Live Activity Widget
struct PracticeSessionLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: PracticeSessionAttributes.self) { context in
      // Lock screen / banner UI
      HStack {
        VStack(alignment: .leading) {
          Text(context.attributes.journeyName)
            .font(.headline)

          Text(context.state.currentDua)
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack {
          Text("\(context.state.progress)/\(context.state.total)")
            .font(.title2.bold())

          Text("+\(context.state.xpEarned) XP")
            .font(.caption)
            .foregroundStyle(.green)
        }
      }
      .padding()
    } dynamicIsland: { context in
      DynamicIsland {
        // Expanded
        DynamicIslandExpandedRegion(.leading) {
          Image(systemName: "hands.sparkles")
        }

        DynamicIslandExpandedRegion(.trailing) {
          Text("\(context.state.progress)/\(context.state.total)")
        }

        DynamicIslandExpandedRegion(.center) {
          Text(context.state.currentDua)
            .lineLimit(1)
        }

        DynamicIslandExpandedRegion(.bottom) {
          ProgressView(value: Double(context.state.progress), total: Double(context.state.total))
        }
      } compactLeading: {
        Image(systemName: "hands.sparkles")
      } compactTrailing: {
        Text("\(context.state.progress)/\(context.state.total)")
      } minimal: {
        Image(systemName: "hands.sparkles")
      }
    }
  }
}

// MARK: - Live Activity Manager
@MainActor
final class LiveActivityManager {
  static let shared = LiveActivityManager()

  private var currentActivity: Activity<PracticeSessionAttributes>?

  func startPracticeSession(journeyName: String, totalDuas: Int) async throws {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

    let attributes = PracticeSessionAttributes(
      journeyName: journeyName,
      startTime: Date()
    )

    let initialState = PracticeSessionAttributes.ContentState(
      currentDua: "Starting...",
      progress: 0,
      total: totalDuas,
      xpEarned: 0
    )

    currentActivity = try Activity.request(
      attributes: attributes,
      content: .init(state: initialState, staleDate: nil)
    )
  }

  func updateProgress(currentDua: String, progress: Int, xpEarned: Int) async {
    guard let activity = currentActivity else { return }

    let state = PracticeSessionAttributes.ContentState(
      currentDua: currentDua,
      progress: progress,
      total: activity.content.state.total,
      xpEarned: xpEarned
    )

    await activity.update(using: state)
  }

  func endSession() async {
    guard let activity = currentActivity else { return }

    let finalState = activity.content.state
    await activity.end(using: finalState, dismissalPolicy: .after(.now + 5))
    currentActivity = nil
  }
}
```

---

## TCA Integration Summary

### Native APIs Dependency

```swift
import ComposableArchitecture

// MARK: - Haptics Dependency
struct HapticsClientKey: DependencyKey {
  static let liveValue = HapticManager.shared
  static let testValue = HapticManager.shared // Could mock for tests
}

extension DependencyValues {
  var haptics: HapticManager {
    get { self[HapticsClientKey.self] }
    set { self[HapticsClientKey.self] = newValue }
  }
}

// MARK: - Usage in Reducer
@Reducer
struct DuaPracticeFeature {
  @Dependency(\.haptics) var haptics

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .counterTapped:
        state.count += 1
        return .run { _ in
          haptics.counter()
        }

      case .duaCompleted:
        return .run { _ in
          haptics.success()
        }

      // ...
      }
    }
  }
}
```
