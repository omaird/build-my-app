import Foundation

// MARK: - Islamic Quote Model
//
// Design Decisions:
// - Uses day-of-year rotation for consistent daily quotes
// - Arabic text is optional since not all hadith/wisdom quotes have it
// - Category determines display styling and iconography
// - quote(for:) is testable; quoteForToday() is convenience wrapper
//
// Future Enhancements:
// - Fetch quotes from Firestore for expandable collection
// - User favorites/saved quotes
// - Share functionality
//
// Related Files:
// - DailyQuoteView.swift (UI component)
// - HomeView.swift (integration)
// - RIZQTests.swift (unit tests)

/// Represents an inspirational Islamic quote for daily motivation.
/// Quotes rotate daily based on the day of the year.
public struct IslamicQuote: Codable, Identifiable, Equatable, Sendable {
  public let id: String
  public let arabicText: String?
  public let englishText: String
  public let source: String
  public let category: QuoteCategory

  public enum QuoteCategory: String, Codable, CaseIterable, Sendable {
    case quran
    case hadith
    case wisdom

    /// Human-readable display name
    public var displayName: String {
      switch self {
      case .quran: return "Quran"
      case .hadith: return "Hadith"
      case .wisdom: return "Wisdom"
      }
    }

    /// SF Symbol icon name for the category
    public var iconName: String {
      switch self {
      case .quran: return "book.fill"
      case .hadith: return "quote.opening"
      case .wisdom: return "lightbulb.fill"
      }
    }
  }

  public init(
    id: String,
    arabicText: String? = nil,
    englishText: String,
    source: String,
    category: QuoteCategory
  ) {
    self.id = id
    self.arabicText = arabicText
    self.englishText = englishText
    self.source = source
    self.category = category
  }
}

// MARK: - Daily Quotes Collection

public extension IslamicQuote {
  /// Collection of daily quotes that rotate throughout the year
  static let dailyQuotes: [IslamicQuote] = [
    IslamicQuote(
      id: "q1",
      arabicText: "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا",
      englishText: "For indeed, with hardship comes ease.",
      source: "Quran 94:5",
      category: .quran
    ),
    IslamicQuote(
      id: "q2",
      arabicText: "وَاذْكُر رَّبَّكَ كَثِيرًا",
      englishText: "And remember your Lord much.",
      source: "Quran 3:41",
      category: .quran
    ),
    IslamicQuote(
      id: "q3",
      englishText: "The best among you are those who have the best manners and character.",
      source: "Sahih Bukhari",
      category: .hadith
    ),
    IslamicQuote(
      id: "q4",
      arabicText: "مَن لَزِمَ الاستغفارَ جعل اللهُ له من كلِّ همٍّ فرجًا",
      englishText: "Whoever remains constant in seeking forgiveness, Allah will grant them relief from every worry.",
      source: "Abu Dawud",
      category: .hadith
    ),
    IslamicQuote(
      id: "q5",
      englishText: "Take benefit of five before five: your youth before your old age, your health before your sickness, your wealth before your poverty, your free time before your preoccupation, and your life before your death.",
      source: "Sahih Hadith",
      category: .wisdom
    ),
    IslamicQuote(
      id: "q6",
      arabicText: "الدُّعَاءُ هُوَ الْعِبَادَةُ",
      englishText: "Dua is the essence of worship.",
      source: "Tirmidhi",
      category: .hadith
    ),
    IslamicQuote(
      id: "q7",
      englishText: "Be in this world as if you were a stranger or a traveler along a path.",
      source: "Sahih Bukhari",
      category: .wisdom
    )
  ]

  /// Get quote for a specific date (deterministic, testable)
  /// Uses day-of-year to rotate through quotes collection.
  static func quote(for date: Date, calendar: Calendar = .current) -> IslamicQuote {
    let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
    let index = (dayOfYear - 1) % dailyQuotes.count
    return dailyQuotes[index]
  }

  /// Get quote for today (convenience wrapper)
  /// Returns the same quote for the entire day, changing at midnight.
  /// Note: For testable code, prefer quote(for:) with injected date.
  static func quoteForToday() -> IslamicQuote {
    quote(for: Date())
  }

  /// Check if quote has Arabic text available
  var hasArabicText: Bool {
    arabicText != nil && !(arabicText?.isEmpty ?? true)
  }

  /// VoiceOver accessibility description
  var accessibilityDescription: String {
    var desc = "\(category.displayName) quote: \(englishText)"
    desc += " Source: \(source)."
    if hasArabicText {
      desc += " Arabic text available."
    }
    return desc
  }
}
