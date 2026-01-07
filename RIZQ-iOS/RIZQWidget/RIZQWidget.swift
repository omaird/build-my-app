import WidgetKit
import SwiftUI

// MARK: - Widget Entry
struct HabitEntry: TimelineEntry {
  let date: Date
  let completedCount: Int
  let totalCount: Int
  let streak: Int
}

// MARK: - Widget Provider
struct HabitProvider: TimelineProvider {
  func placeholder(in context: Context) -> HabitEntry {
    HabitEntry(date: Date(), completedCount: 3, totalCount: 5, streak: 7)
  }

  func getSnapshot(in context: Context, completion: @escaping (HabitEntry) -> Void) {
    let entry = HabitEntry(date: Date(), completedCount: 3, totalCount: 5, streak: 7)
    completion(entry)
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<HabitEntry>) -> Void) {
    // TODO: Load actual habit data from App Group
    let entry = HabitEntry(date: Date(), completedCount: 3, totalCount: 5, streak: 7)
    let timeline = Timeline(entries: [entry], policy: .atEnd)
    completion(timeline)
  }
}

// MARK: - Widget View
struct RIZQWidgetEntryView: View {
  var entry: HabitProvider.Entry
  @Environment(\.widgetFamily) var family

  var body: some View {
    switch family {
    case .systemSmall:
      smallWidget
    case .systemMedium:
      mediumWidget
    default:
      smallWidget
    }
  }

  private var smallWidget: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: "flame.fill")
          .foregroundStyle(.orange)
        Text("\(entry.streak)")
          .font(.headline)
          .fontWeight(.bold)
      }

      Text("\(entry.completedCount)/\(entry.totalCount)")
        .font(.title2)
        .fontWeight(.semibold)

      Text("Today's Adkhar")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .containerBackground(for: .widget) {
      Color(hex: "F5EFE7")
    }
  }

  private var mediumWidget: some View {
    HStack {
      VStack(alignment: .leading, spacing: 8) {
        Text("Today's Progress")
          .font(.headline)

        Text("\(entry.completedCount) of \(entry.totalCount)")
          .font(.title)
          .fontWeight(.bold)

        progressBar
      }

      Spacer()

      VStack {
        Image(systemName: "flame.fill")
          .font(.title)
          .foregroundStyle(.orange)
        Text("\(entry.streak) days")
          .font(.caption)
      }
    }
    .padding()
    .containerBackground(for: .widget) {
      Color(hex: "F5EFE7")
    }
  }

  private var progressBar: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Capsule()
          .fill(Color.gray.opacity(0.3))

        Capsule()
          .fill(Color(hex: "D4A574"))
          .frame(width: geometry.size.width * CGFloat(entry.completedCount) / CGFloat(max(entry.totalCount, 1)))
      }
    }
    .frame(height: 8)
  }
}

// MARK: - Widget Configuration
@main
struct RIZQWidgets: Widget {
  let kind: String = "RIZQWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: HabitProvider()) { entry in
      RIZQWidgetEntryView(entry: entry)
    }
    .configurationDisplayName("Daily Adkhar")
    .description("Track your daily dua practice progress.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Color Extension for Widget
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

#Preview(as: .systemSmall) {
  RIZQWidgets()
} timeline: {
  HabitEntry(date: .now, completedCount: 3, totalCount: 5, streak: 7)
}
