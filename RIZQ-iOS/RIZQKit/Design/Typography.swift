import SwiftUI
import UIKit

// MARK: - RIZQ Typography
// Translated from tailwind.config.ts font stack

public extension Font {
  // MARK: - Display Font (Headings)
  // Playfair Display - Luxury serif for headings
  static func rizqDisplay(_ style: Font.TextStyle) -> Font {
    .custom("PlayfairDisplay-Regular", size: style.defaultSize, relativeTo: style)
  }

  static func rizqDisplayMedium(_ style: Font.TextStyle) -> Font {
    .custom("PlayfairDisplay-Medium", size: style.defaultSize, relativeTo: style)
  }

  static func rizqDisplaySemiBold(_ style: Font.TextStyle) -> Font {
    .custom("PlayfairDisplay-SemiBold", size: style.defaultSize, relativeTo: style)
  }

  static func rizqDisplayBold(_ style: Font.TextStyle) -> Font {
    .custom("PlayfairDisplay-Bold", size: style.defaultSize, relativeTo: style)
  }

  // MARK: - Sans Font (Body Text)
  // Crimson Pro - Elegant serif for body text
  static func rizqSans(_ style: Font.TextStyle) -> Font {
    .custom("CrimsonPro-Regular", size: style.defaultSize, relativeTo: style)
  }

  static func rizqSansMedium(_ style: Font.TextStyle) -> Font {
    .custom("CrimsonPro-Medium", size: style.defaultSize, relativeTo: style)
  }

  static func rizqSansSemiBold(_ style: Font.TextStyle) -> Font {
    .custom("CrimsonPro-SemiBold", size: style.defaultSize, relativeTo: style)
  }

  static func rizqSansBold(_ style: Font.TextStyle) -> Font {
    .custom("CrimsonPro-Bold", size: style.defaultSize, relativeTo: style)
  }

  // MARK: - Arabic Font
  // Amiri Quran - Quranic Arabic typeface optimized for religious text
  // See: https://fonts.google.com/specimen/Amiri+Quran
  static func rizqArabic(_ style: Font.TextStyle) -> Font {
    // Arabic text needs larger size for readability
    .custom("AmiriQuran-Regular", size: style.defaultSize * 1.3, relativeTo: style)
  }

  // Fallback to Amiri Bold for bold Arabic (Amiri Quran only has Regular weight)
  static func rizqArabicBold(_ style: Font.TextStyle) -> Font {
    .custom("Amiri-Bold", size: style.defaultSize * 1.3, relativeTo: style)
  }

  // MARK: - Mono Font (Numbers, Counters)
  // JetBrains Mono - Monospace for numbers and code
  static func rizqMono(_ style: Font.TextStyle) -> Font {
    .custom("JetBrainsMono-Regular", size: style.defaultSize, relativeTo: style)
  }

  static func rizqMonoMedium(_ style: Font.TextStyle) -> Font {
    .custom("JetBrainsMono-Medium", size: style.defaultSize, relativeTo: style)
  }
}

// MARK: - TextStyle Size Mapping
public extension Font.TextStyle {
  var defaultSize: CGFloat {
    switch self {
    case .largeTitle: return 34
    case .title: return 28
    case .title2: return 22
    case .title3: return 20
    case .headline: return 17
    case .subheadline: return 15
    case .body: return 17
    case .callout: return 16
    case .footnote: return 13
    case .caption: return 12
    case .caption2: return 11
    @unknown default: return 17
    }
  }

  var uiKit: UIFont.TextStyle {
    switch self {
    case .largeTitle: return .largeTitle
    case .title: return .title1
    case .title2: return .title2
    case .title3: return .title3
    case .headline: return .headline
    case .subheadline: return .subheadline
    case .body: return .body
    case .callout: return .callout
    case .footnote: return .footnote
    case .caption: return .caption1
    case .caption2: return .caption2
    @unknown default: return .body
    }
  }
}

// MARK: - Text Modifiers
public extension View {
  /// Apply RIZQ display typography
  func rizqDisplayStyle(_ style: Font.TextStyle = .title) -> some View {
    self
      .font(.rizqDisplay(style))
      .foregroundStyle(Color.rizqText)
  }

  /// Apply RIZQ body typography
  func rizqBodyStyle(_ style: Font.TextStyle = .body) -> some View {
    self
      .font(.rizqSans(style))
      .foregroundStyle(Color.rizqText)
  }

  /// Apply RIZQ Arabic typography
  func rizqArabicStyle(_ style: Font.TextStyle = .title) -> some View {
    self
      .font(.rizqArabic(style))
      .foregroundStyle(Color.rizqText)
      .environment(\.layoutDirection, .rightToLeft)
      .lineSpacing(12)
  }

  /// Apply RIZQ mono typography (for numbers)
  func rizqMonoStyle(_ style: Font.TextStyle = .body) -> some View {
    self
      .font(.rizqMono(style))
      .foregroundStyle(Color.rizqText)
  }
}
