import WidgetKit
import SwiftUI
import RIZQKit

// MARK: - Design Tokens (Widget-specific, matching main app)
private enum WidgetColors {
  static let background = Color(hex: "F5EFE7")    // Warm cream
  static let cardBg = Color(hex: "FFFCF7")        // Warm white
  static let primary = Color(hex: "D4A574")       // Warm sand
  static let accent = Color(hex: "6B4423")        // Deep mocha
  static let streakGlow = Color(hex: "E6A23C")    // Streak gold
  static let goldSoft = Color(hex: "E6C79C")      // Soft gold
  static let textPrimary = Color(hex: "2C2416")   // Deep text
  static let textSecondary = Color(hex: "8B7355") // Muted text
  static let success = Color(hex: "6B9B7C")       // Teal success
}

// MARK: - Daily Progress Entry
struct DailyProgressEntry: TimelineEntry {
  let date: Date
  let completedCount: Int
  let totalCount: Int
  let streak: Int
  let currentXp: Int
  let xpToNextLevel: Int
  let level: Int

  var progress: Double {
    guard totalCount > 0 else { return 0 }
    return Double(completedCount) / Double(totalCount)
  }

  static var placeholder: DailyProgressEntry {
    DailyProgressEntry(
      date: Date(),
      completedCount: 4,
      totalCount: 7,
      streak: 12,
      currentXp: 450,
      xpToNextLevel: 600,
      level: 5
    )
  }
}

// MARK: - Daily Progress Provider
struct DailyProgressProvider: TimelineProvider {
  func placeholder(in context: Context) -> DailyProgressEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (DailyProgressEntry) -> Void) {
    let entry = createEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<DailyProgressEntry>) -> Void) {
    let entry = createEntry()

    // Refresh at the start of each hour
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func createEntry() -> DailyProgressEntry {
    let data = WidgetDataManager.shared.getDailyProgressData()

    // If no data has been set yet (lastUpdated is nil), use placeholder
    if data.lastUpdated == nil {
      return .placeholder
    }

    return DailyProgressEntry(
      date: Date(),
      completedCount: data.completedCount,
      totalCount: data.totalCount,
      streak: data.streak,
      currentXp: data.currentXp,
      xpToNextLevel: data.xpToNextLevel,
      level: data.level
    )
  }
}

// MARK: - Daily Progress Widget View
struct DailyProgressWidgetView: View {
  var entry: DailyProgressEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall:
      smallWidget
    case .systemMedium:
      mediumWidget
    case .accessoryCircular:
      circularAccessoryWidget
    case .accessoryRectangular:
      rectangularAccessoryWidget
    default:
      smallWidget
    }
  }

  // MARK: - Small Widget
  private var smallWidget: some View {
    VStack(spacing: 12) {
      // Header with streak
      HStack {
        Image(systemName: "flame.fill")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(WidgetColors.streakGlow)
        Text("\(entry.streak)")
          .font(.system(size: 14, weight: .bold, design: .rounded))
          .foregroundStyle(WidgetColors.textPrimary)
        Spacer()
        Text("Level \(entry.level)")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(WidgetColors.textSecondary)
      }

      Spacer()

      // Progress circle
      ZStack {
        Circle()
          .stroke(WidgetColors.primary.opacity(0.2), lineWidth: 6)

        Circle()
          .trim(from: 0, to: entry.progress)
          .stroke(
            WidgetColors.primary,
            style: StrokeStyle(lineWidth: 6, lineCap: .round)
          )
          .rotationEffect(.degrees(-90))

        VStack(spacing: 2) {
          Text("\(entry.completedCount)")
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundStyle(WidgetColors.textPrimary)
          Text("of \(entry.totalCount)")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(WidgetColors.textSecondary)
        }
      }
      .frame(width: 80, height: 80)

      Spacer()

      // Label
      Text("Today's Adkhar")
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(WidgetColors.textSecondary)
    }
    .padding(16)
    .containerBackground(for: .widget) {
      WidgetColors.background
    }
  }

  // MARK: - Medium Widget
  private var mediumWidget: some View {
    HStack(spacing: 16) {
      // Left: Progress section
      VStack(alignment: .leading, spacing: 12) {
        // Title
        Text("Today's Progress")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(WidgetColors.textSecondary)

        // Count
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(entry.completedCount)")
            .font(.system(size: 36, weight: .bold, design: .rounded))
            .foregroundStyle(WidgetColors.textPrimary)
          Text("/ \(entry.totalCount)")
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(WidgetColors.textSecondary)
        }

        // Progress bar
        GeometryReader { geometry in
          ZStack(alignment: .leading) {
            Capsule()
              .fill(WidgetColors.primary.opacity(0.2))

            Capsule()
              .fill(
                LinearGradient(
                  colors: [WidgetColors.primary, WidgetColors.goldSoft],
                  startPoint: .leading,
                  endPoint: .trailing
                )
              )
              .frame(width: geometry.size.width * entry.progress)
          }
        }
        .frame(height: 8)

        Spacer()
      }

      // Divider
      Rectangle()
        .fill(WidgetColors.primary.opacity(0.2))
        .frame(width: 1)
        .padding(.vertical, 8)

      // Right: Stats section
      VStack(spacing: 16) {
        // Streak
        VStack(spacing: 4) {
          HStack(spacing: 4) {
            Image(systemName: "flame.fill")
              .font(.system(size: 16))
              .foregroundStyle(WidgetColors.streakGlow)
            Text("\(entry.streak)")
              .font(.system(size: 22, weight: .bold, design: .rounded))
              .foregroundStyle(WidgetColors.textPrimary)
          }
          Text("day streak")
            .font(.system(size: 10, weight: .medium))
            .foregroundStyle(WidgetColors.textSecondary)
        }

        // Level badge
        VStack(spacing: 4) {
          HStack(spacing: 4) {
            Image(systemName: "star.fill")
              .font(.system(size: 14))
              .foregroundStyle(WidgetColors.accent)
            Text("Lvl \(entry.level)")
              .font(.system(size: 16, weight: .bold, design: .rounded))
              .foregroundStyle(WidgetColors.textPrimary)
          }
          Text("\(entry.currentXp)/\(entry.xpToNextLevel) XP")
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(WidgetColors.textSecondary)
        }
      }
      .frame(width: 80)
    }
    .padding(16)
    .containerBackground(for: .widget) {
      WidgetColors.background
    }
  }

  // MARK: - Lock Screen Circular
  private var circularAccessoryWidget: some View {
    Gauge(value: entry.progress) {
      Image(systemName: "book.fill")
    } currentValueLabel: {
      Text("\(entry.completedCount)")
        .font(.system(size: 14, weight: .bold))
    }
    .gaugeStyle(.accessoryCircular)
  }

  // MARK: - Lock Screen Rectangular
  private var rectangularAccessoryWidget: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Image(systemName: "book.fill")
        Text("Today's Adkhar")
          .font(.headline)
        Spacer()
        Image(systemName: "flame.fill")
        Text("\(entry.streak)")
      }

      ProgressView(value: entry.progress)

      Text("\(entry.completedCount) of \(entry.totalCount) completed")
        .font(.caption)
    }
  }
}

// MARK: - Streak Entry
struct StreakEntry: TimelineEntry {
  let date: Date
  let streak: Int
  let bestStreak: Int
  let totalDuas: Int

  static var placeholder: StreakEntry {
    StreakEntry(date: Date(), streak: 12, bestStreak: 45, totalDuas: 342)
  }
}

// MARK: - Streak Provider
struct StreakProvider: TimelineProvider {
  func placeholder(in context: Context) -> StreakEntry {
    .placeholder
  }

  func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
    let entry = createEntry()
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
    let entry = createEntry()
    let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
    let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
    completion(timeline)
  }

  private func createEntry() -> StreakEntry {
    let data = WidgetDataManager.shared.getStreakData()

    return StreakEntry(
      date: Date(),
      streak: data.streak > 0 ? data.streak : 12, // Use placeholder if no data
      bestStreak: data.bestStreak > 0 ? data.bestStreak : 45,
      totalDuas: data.totalDuasCompleted > 0 ? data.totalDuasCompleted : 342
    )
  }
}

// MARK: - Streak Widget View
struct StreakWidgetView: View {
  var entry: StreakEntry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall:
      smallStreakWidget
    case .accessoryCircular:
      circularStreakWidget
    default:
      smallStreakWidget
    }
  }

  private var smallStreakWidget: some View {
    VStack(spacing: 8) {
      Spacer()

      // Flame icon with glow effect
      ZStack {
        // Glow
        Image(systemName: "flame.fill")
          .font(.system(size: 44))
          .foregroundStyle(WidgetColors.streakGlow.opacity(0.3))
          .blur(radius: 8)

        // Main flame
        Image(systemName: "flame.fill")
          .font(.system(size: 44))
          .foregroundStyle(
            LinearGradient(
              colors: [WidgetColors.streakGlow, Color.orange],
              startPoint: .top,
              endPoint: .bottom
            )
          )
      }

      // Streak count
      Text("\(entry.streak)")
        .font(.system(size: 32, weight: .bold, design: .rounded))
        .foregroundStyle(WidgetColors.textPrimary)

      Text("day streak")
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(WidgetColors.textSecondary)

      Spacer()

      // Best streak indicator
      HStack(spacing: 4) {
        Image(systemName: "trophy.fill")
          .font(.system(size: 10))
          .foregroundStyle(WidgetColors.goldSoft)
        Text("Best: \(entry.bestStreak)")
          .font(.system(size: 10, weight: .medium))
          .foregroundStyle(WidgetColors.textSecondary)
      }
    }
    .padding(16)
    .containerBackground(for: .widget) {
      WidgetColors.background
    }
  }

  private var circularStreakWidget: some View {
    ZStack {
      AccessoryWidgetBackground()
      VStack(spacing: 2) {
        Image(systemName: "flame.fill")
          .font(.system(size: 14))
        Text("\(entry.streak)")
          .font(.system(size: 18, weight: .bold))
      }
    }
  }
}

// MARK: - Widget Configurations
@main
struct RIZQWidgetBundle: WidgetBundle {
  var body: some Widget {
    DailyProgressWidget()
    StreakWidget()
  }
}

struct DailyProgressWidget: Widget {
  let kind: String = "DailyProgressWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: DailyProgressProvider()) { entry in
      DailyProgressWidgetView(entry: entry)
    }
    .configurationDisplayName("Daily Adkhar")
    .description("Track your daily dua practice progress.")
    .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular])
  }
}

struct StreakWidget: Widget {
  let kind: String = "StreakWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: StreakProvider()) { entry in
      StreakWidgetView(entry: entry)
    }
    .configurationDisplayName("Streak")
    .description("Keep track of your dua practice streak.")
    .supportedFamilies([.systemSmall, .accessoryCircular])
  }
}

// MARK: - Color Extension
extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let r, g, b: UInt64
    (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: 1
    )
  }
}

// MARK: - Previews
#Preview("Daily Progress - Small", as: .systemSmall) {
  DailyProgressWidget()
} timeline: {
  DailyProgressEntry.placeholder
}

#Preview("Daily Progress - Medium", as: .systemMedium) {
  DailyProgressWidget()
} timeline: {
  DailyProgressEntry.placeholder
}

#Preview("Streak - Small", as: .systemSmall) {
  StreakWidget()
} timeline: {
  StreakEntry.placeholder
}
