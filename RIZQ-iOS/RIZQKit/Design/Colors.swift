import SwiftUI

// MARK: - RIZQ Color Palette
// Translated from tailwind.config.ts - Warm Islamic aesthetic

public extension Color {
  // MARK: - Brand Colors
  static let rizqPrimary = sandWarm
  static let rizqAccent = mocha

  // MARK: - Sand Palette
  static let sandWarm = Color(hex: "D4A574")
  static let sandLight = Color(hex: "E6C79C")
  static let sandDeep = Color(hex: "A67C52")

  // MARK: - Mocha Palette
  static let mocha = Color(hex: "6B4423")
  static let mochaDeep = Color(hex: "2C2416")

  // MARK: - Cream Palette
  static let cream = Color(hex: "F5EFE7")
  static let creamWarm = Color(hex: "FFFCF7")

  // MARK: - Gold Palette
  static let goldSoft = Color(hex: "E6C79C")
  static let goldBright = Color(hex: "FFEBB3")

  // MARK: - Teal Palette
  static let tealMuted = Color(hex: "5B8A8A")
  static let tealSuccess = Color(hex: "6B9B7C")

  // MARK: - Semantic Colors
  static let rizqBackground = cream
  static let rizqCard = creamWarm
  static let rizqSurface = Color(hex: "F8F5F0")  // Surface for inputs/controls
  static let rizqText = mochaDeep
  static let rizqTextSecondary = Color(hex: "8B7355")
  static let rizqTextTertiary = Color(hex: "A69B8C")  // Lighter tertiary text
  static let rizqMuted = Color(hex: "C4B8A8")
  static let rizqBorder = Color(hex: "E5DFD5")

  // MARK: - Category Badge Colors
  static let badgeMorning = Color(hex: "F59E0B")  // Amber
  static let badgeEvening = Color(hex: "6366F1")  // Indigo
  static let badgeRizq = Color(hex: "10B981")     // Emerald
  static let badgeGratitude = Color(hex: "EC4899") // Pink

  // MARK: - Gamification Colors
  static let xpBar = sandWarm
  static let streakGlow = Color(hex: "F59E0B")
  static let levelBadge = mocha
}

// MARK: - Hex Initializer
public extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a, r, g, b: UInt64
    switch hex.count {
    case 3: // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6: // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8: // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (255, 0, 0, 0)
    }
    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  /// Returns hex string representation
  var hexString: String {
    guard let components = UIColor(self).cgColor.components else { return "000000" }
    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)
    return String(format: "%02X%02X%02X", r, g, b)
  }
}

// MARK: - Gradient Definitions
public extension LinearGradient {
  static let rizqPrimaryGradient = LinearGradient(
    colors: [.sandLight, .sandWarm],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let rizqCardGradient = LinearGradient(
    colors: [.creamWarm, .cream],
    startPoint: .top,
    endPoint: .bottom
  )

  static let streakGradient = LinearGradient(
    colors: [.goldBright, .goldSoft],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}
