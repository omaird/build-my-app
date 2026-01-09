import Foundation

// MARK: - Enums

public enum DuaDifficulty: String, Codable, CaseIterable, Sendable {
  case beginner = "Beginner"
  case intermediate = "Intermediate"
  case advanced = "Advanced"
}

public enum TimeSlot: String, Codable, CaseIterable, Identifiable, Equatable, Sendable {
  case morning
  case anytime
  case evening

  public var id: String { rawValue }

  public var displayName: String {
    switch self {
    case .morning: return "Morning"
    case .anytime: return "Anytime"
    case .evening: return "Evening"
    }
  }

  public var icon: String {
    switch self {
    case .morning: return "sun.max.fill"
    case .anytime: return "clock.fill"
    case .evening: return "moon.fill"
    }
  }

  public var greeting: String {
    switch self {
    case .morning: return "Good morning"
    case .anytime: return "Assalamu Alaikum"
    case .evening: return "Good evening"
    }
  }
}

public enum CategorySlug: String, Codable, CaseIterable, Sendable {
  case morning
  case evening
  case rizq
  case gratitude
}

// MARK: - Category

public struct DuaCategory: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let name: String
  public let slug: CategorySlug
  public let description: String?

  public init(id: Int, name: String, slug: CategorySlug, description: String? = nil) {
    self.id = id
    self.name = name
    self.slug = slug
    self.description = description
  }

  /// Icon for the category based on slug
  public var icon: String {
    switch slug {
    case .morning: return "sun.max.fill"
    case .evening: return "moon.fill"
    case .rizq: return "sparkles"
    case .gratitude: return "heart.fill"
    }
  }
}

// MARK: - Collection

public struct DuaCollection: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let name: String
  public let slug: String
  public let description: String?
  public let isPremium: Bool

  public init(id: Int, name: String, slug: String, description: String? = nil, isPremium: Bool = false) {
    self.id = id
    self.name = name
    self.slug = slug
    self.description = description
    self.isPremium = isPremium
  }

  private enum CodingKeys: String, CodingKey {
    case id, name, slug, description
    case isPremium = "is_premium"
  }
}

// MARK: - Dua

public struct Dua: Codable, Identifiable, Equatable, Sendable {
  public let id: Int
  public let categoryId: Int?
  public let collectionId: Int?
  public let titleEn: String
  public let titleAr: String?
  public let arabicText: String
  public let transliteration: String?
  public let translationEn: String
  public let source: String?
  public let repetitions: Int
  public let bestTime: String?  // DB stores free text like "After Fajr, before sleep"
  public let difficulty: DuaDifficulty?  // Make optional since DB might have unexpected values
  public let estDurationSec: Int?
  public let rizqBenefit: String?
  public let propheticContext: String?
  public let xpValue: Int
  public let audioUrl: String?
  public let createdAt: Date?  // Make optional to handle parsing failures
  public let updatedAt: Date?  // Make optional to handle parsing failures

  public init(
    id: Int,
    categoryId: Int? = nil,
    collectionId: Int? = nil,
    titleEn: String,
    titleAr: String? = nil,
    arabicText: String,
    transliteration: String? = nil,
    translationEn: String,
    source: String? = nil,
    repetitions: Int = 1,
    bestTime: String? = nil,
    difficulty: DuaDifficulty? = .beginner,
    estDurationSec: Int? = nil,
    rizqBenefit: String? = nil,
    propheticContext: String? = nil,
    xpValue: Int = 10,
    audioUrl: String? = nil,
    createdAt: Date? = Date(),
    updatedAt: Date? = Date()
  ) {
    self.id = id
    self.categoryId = categoryId
    self.collectionId = collectionId
    self.titleEn = titleEn
    self.titleAr = titleAr
    self.arabicText = arabicText
    self.transliteration = transliteration
    self.translationEn = translationEn
    self.source = source
    self.repetitions = repetitions
    self.bestTime = bestTime
    self.difficulty = difficulty
    self.estDurationSec = estDurationSec
    self.rizqBenefit = rizqBenefit
    self.propheticContext = propheticContext
    self.xpValue = xpValue
    self.audioUrl = audioUrl
    self.createdAt = createdAt
    self.updatedAt = updatedAt
  }

  private enum CodingKeys: String, CodingKey {
    case id
    case categoryId = "category_id"
    case collectionId = "collection_id"
    case titleEn = "title_en"
    case titleAr = "title_ar"
    case arabicText = "arabic_text"
    case transliteration
    case translationEn = "translation_en"
    case source
    case repetitions
    case bestTime = "best_time"
    case difficulty
    case estDurationSec = "est_duration_sec"
    case rizqBenefit = "rizq_benefit"
    case propheticContext = "prophetic_context"
    case xpValue = "xp_value"
    case audioUrl = "audio_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
  }

  // Custom decoder to handle flexible date formats and optional enums
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int.self, forKey: .id)
    categoryId = try container.decodeIfPresent(Int.self, forKey: .categoryId)
    collectionId = try container.decodeIfPresent(Int.self, forKey: .collectionId)
    titleEn = try container.decode(String.self, forKey: .titleEn)
    titleAr = try container.decodeIfPresent(String.self, forKey: .titleAr)
    arabicText = try container.decode(String.self, forKey: .arabicText)
    transliteration = try container.decodeIfPresent(String.self, forKey: .transliteration)
    translationEn = try container.decode(String.self, forKey: .translationEn)
    source = try container.decodeIfPresent(String.self, forKey: .source)
    repetitions = try container.decodeIfPresent(Int.self, forKey: .repetitions) ?? 1
    bestTime = try container.decodeIfPresent(String.self, forKey: .bestTime)
    estDurationSec = try container.decodeIfPresent(Int.self, forKey: .estDurationSec)
    rizqBenefit = try container.decodeIfPresent(String.self, forKey: .rizqBenefit)
    propheticContext = try container.decodeIfPresent(String.self, forKey: .propheticContext)
    xpValue = try container.decodeIfPresent(Int.self, forKey: .xpValue) ?? 10
    audioUrl = try container.decodeIfPresent(String.self, forKey: .audioUrl)

    // Decode difficulty with fallback for unexpected values
    if let difficultyString = try container.decodeIfPresent(String.self, forKey: .difficulty) {
      difficulty = DuaDifficulty(rawValue: difficultyString)
    } else {
      difficulty = nil
    }

    // Decode dates with flexible parsing
    createdAt = Self.parseDate(try container.decodeIfPresent(String.self, forKey: .createdAt))
    updatedAt = Self.parseDate(try container.decodeIfPresent(String.self, forKey: .updatedAt))
  }

  /// Parse PostgreSQL timestamp formats
  private static func parseDate(_ string: String?) -> Date? {
    guard let string = string else { return nil }

    // Try various PostgreSQL timestamp formats
    let formatters: [DateFormatter] = {
      let formats = [
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSSXXXXX",  // 2024-01-15T10:30:00.123456+00:00
        "yyyy-MM-dd'T'HH:mm:ssXXXXX",          // 2024-01-15T10:30:00+00:00
        "yyyy-MM-dd'T'HH:mm:ss.SSSSSS",        // 2024-01-15T10:30:00.123456
        "yyyy-MM-dd'T'HH:mm:ss",               // 2024-01-15T10:30:00
        "yyyy-MM-dd HH:mm:ss.SSSSSSXXXXX",     // 2024-01-15 10:30:00.123456+00:00
        "yyyy-MM-dd HH:mm:ssXXXXX",            // 2024-01-15 10:30:00+00:00
        "yyyy-MM-dd HH:mm:ss.SSSSSS",          // 2024-01-15 10:30:00.123456
        "yyyy-MM-dd HH:mm:ss",                 // 2024-01-15 10:30:00
      ]
      return formats.map { format in
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
      }
    }()

    for formatter in formatters {
      if let date = formatter.date(from: string) {
        return date
      }
    }

    // Try ISO8601DateFormatter as fallback
    let iso8601 = ISO8601DateFormatter()
    iso8601.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let date = iso8601.date(from: string) {
      return date
    }

    iso8601.formatOptions = [.withInternetDateTime]
    return iso8601.date(from: string)
  }
}

// MARK: - Dua with Relations

public struct DuaWithCategory: Equatable, Sendable {
  public let dua: Dua
  public let category: DuaCategory?

  public init(dua: Dua, category: DuaCategory? = nil) {
    self.dua = dua
    self.category = category
  }
}

public struct DuaFull: Equatable, Sendable {
  public let dua: Dua
  public let category: DuaCategory?
  public let collection: DuaCollection?

  public init(dua: Dua, category: DuaCategory? = nil, collection: DuaCollection? = nil) {
    self.dua = dua
    self.category = category
    self.collection = collection
  }
}

// MARK: - Demo Data

extension DuaCategory {
  /// Demo data for previews and testing
  public static let demoData: [DuaCategory] = [
    DuaCategory(id: 1, name: "Morning", slug: .morning, description: "Duas for the morning to seek protection and provision."),
    DuaCategory(id: 2, name: "Evening", slug: .evening, description: "Duas for the evening and night."),
    DuaCategory(id: 3, name: "Rizq", slug: .rizq, description: "Duas specifically asking for wealth and provision."),
    DuaCategory(id: 4, name: "Gratitude", slug: .gratitude, description: "Duas of thankfulness and appreciation."),
  ]
}

extension Dua {
  /// Demo data for previews and testing
  public static let demoData: [Dua] = [
    Dua(
      id: 1,
      categoryId: 1,
      titleEn: "Morning Dhikr",
      titleAr: "أذكار الصباح",
      arabicText: "أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ",
      transliteration: "Asbahna wa asbahal mulku lillah",
      translationEn: "We have entered upon morning and the whole kingdom belongs to Allah",
      source: "Sahih Muslim",
      repetitions: 1,
      bestTime: "After Fajr",
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 2,
      categoryId: 1,
      titleEn: "Seeking Protection",
      arabicText: "أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ",
      transliteration: "A'udhu bikalimatillahit-tammati min sharri ma khalaq",
      translationEn: "I seek refuge in the perfect words of Allah from the evil of what He has created",
      source: "Sahih Muslim",
      repetitions: 3,
      difficulty: .beginner,
      xpValue: 15
    ),
    Dua(
      id: 3,
      categoryId: 3,
      titleEn: "Seeking Rizq",
      arabicText: "اللَّهُمَّ اكْفِنِي بِحَلَالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ",
      transliteration: "Allahumma akfini bihalalika 'an haramika wa aghnini bifadlika 'amman siwak",
      translationEn: "O Allah, suffice me with what is lawful against what is unlawful",
      source: "Tirmidhi",
      repetitions: 3,
      difficulty: .intermediate,
      xpValue: 20
    ),
    Dua(
      id: 4,
      categoryId: 4,
      titleEn: "Gratitude",
      arabicText: "الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ",
      transliteration: "Alhamdu lillahil-ladhi ahyana ba'da ma amatana wa ilayhin-nushur",
      translationEn: "All praise is for Allah who gave us life after having taken it from us",
      source: "Bukhari",
      repetitions: 1,
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 5,
      categoryId: 2,
      titleEn: "Evening Protection",
      arabicText: "أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ وَالْحَمْدُ لِلَّهِ",
      transliteration: "Amsayna wa amsal mulku lillahi wal hamdu lillah",
      translationEn: "We have entered upon evening and the whole kingdom belongs to Allah",
      source: "Abu Dawud",
      repetitions: 1,
      difficulty: .beginner,
      xpValue: 10
    ),
    Dua(
      id: 6,
      categoryId: 2,
      titleEn: "Ayatul Kursi",
      arabicText: "اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ",
      transliteration: "Allahu la ilaha illa huwal hayyul qayyum",
      translationEn: "Allah - there is no deity except Him, the Ever-Living, the Sustainer of existence",
      source: "Quran 2:255",
      repetitions: 1,
      difficulty: .intermediate,
      xpValue: 25
    ),
  ]
}
