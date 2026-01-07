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
  public let bestTime: TimeSlot?
  public let difficulty: DuaDifficulty
  public let estDurationSec: Int?
  public let rizqBenefit: String?
  public let context: String?
  public let propheticContext: String?
  public let xpValue: Int
  public let audioUrl: String?
  public let createdAt: Date
  public let updatedAt: Date

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
    bestTime: TimeSlot? = nil,
    difficulty: DuaDifficulty = .beginner,
    estDurationSec: Int? = nil,
    rizqBenefit: String? = nil,
    context: String? = nil,
    propheticContext: String? = nil,
    xpValue: Int = 10,
    audioUrl: String? = nil,
    createdAt: Date = Date(),
    updatedAt: Date = Date()
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
    self.context = context
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
    case context
    case propheticContext = "prophetic_context"
    case xpValue = "xp_value"
    case audioUrl = "audio_url"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
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
