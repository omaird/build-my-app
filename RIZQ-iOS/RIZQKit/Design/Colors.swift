import SwiftUI

// MARK: - RIZQ Color Palette
// Translated from tailwind.config.ts - Warm Islamic aesthetic
// Dark mode support via Asset Catalog colors

public extension Color {
  // MARK: - Brand Colors (Adaptive - brighten in dark mode)
  static let rizqPrimary = Color("rizqPrimaryAdaptive", bundle: .main)
  static let rizqAccent = mocha

  // MARK: - Sand Palette (Static - for explicit light colors)
  static let sandWarm = Color(hex: "D4A574")
  static let sandLight = Color(hex: "E6C79C")
  static let sandDeep = Color(hex: "A67C52")

  // MARK: - Sand Palette (Dark mode brightened)
  static let sandWarmDark = Color(hex: "E6B886")
  static let sandLightDark = Color(hex: "F0C896")

  // MARK: - Mocha Palette (Static)
  static let mocha = Color(hex: "6B4423")
  static let mochaDeep = Color(hex: "2C2416")

  // MARK: - Cream Palette (Static - for explicit light colors)
  static let cream = Color(hex: "F5EFE7")
  static let creamWarm = Color(hex: "FFFCF7")

  // MARK: - Gold Palette (Static)
  static let goldSoft = Color(hex: "E6C79C")
  static let goldBright = Color(hex: "FFEBB3")

  // MARK: - Gold Palette (Dark mode brightened)
  static let goldSoftDark = Color(hex: "F0C896")
  static let goldBrightDark = Color(hex: "FFE5A0")

  // MARK: - Teal Palette (Static)
  static let tealMuted = Color(hex: "5B8A8A")
  static let tealSuccess = Color(hex: "6B9B7C")

  // MARK: - Semantic Colors (Adaptive via Asset Catalog)
  static let rizqBackground = Color("rizqBackground", bundle: .main)
  static let rizqCard = Color("rizqCard", bundle: .main)
  static let rizqSurface = Color("rizqSurface", bundle: .main)
  static let rizqText = Color("rizqText", bundle: .main)
  static let rizqTextSecondary = Color("rizqTextSecondary", bundle: .main)
  static let rizqTextTertiary = Color("rizqTextTertiary", bundle: .main)
  static let rizqMuted = Color("rizqMuted", bundle: .main)
  static let rizqBorder = Color("rizqBorder", bundle: .main)

  // MARK: - Category Badge Colors (Adaptive - brighten in dark mode)
  static let badgeMorning = Color("badgeMorningAdaptive", bundle: .main)
  static let badgeEvening = Color("badgeEveningAdaptive", bundle: .main)
  static let badgeRizq = Color("badgeRizqAdaptive", bundle: .main)
  static let badgeGratitude = Color("badgeGratitudeAdaptive", bundle: .main)

  // MARK: - Gamification Colors (Adaptive)
  static let xpBar = Color("rizqPrimaryAdaptive", bundle: .main)
  static let streakGlow = Color("badgeMorningAdaptive", bundle: .main)
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

// MARK: - Gradient Colors (Adaptive via Asset Catalog)
public extension Color {
  static let gradientCardStart = Color("gradientCardStart", bundle: .main)
  static let gradientCardEnd = Color("gradientCardEnd", bundle: .main)
  static let gradientPrimaryStart = Color("gradientPrimaryStart", bundle: .main)
  static let gradientPrimaryEnd = Color("gradientPrimaryEnd", bundle: .main)
  static let gradientStreakStart = Color("gradientStreakStart", bundle: .main)
  static let gradientStreakEnd = Color("gradientStreakEnd", bundle: .main)
}

// MARK: - Gradient Definitions (Adaptive)
public extension LinearGradient {
  static let rizqPrimaryGradient = LinearGradient(
    colors: [Color.gradientPrimaryStart, Color.gradientPrimaryEnd],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )

  static let rizqCardGradient = LinearGradient(
    colors: [Color.gradientCardStart, Color.gradientCardEnd],
    startPoint: .top,
    endPoint: .bottom
  )

  static let streakGradient = LinearGradient(
    colors: [Color.gradientStreakStart, Color.gradientStreakEnd],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
  )
}
