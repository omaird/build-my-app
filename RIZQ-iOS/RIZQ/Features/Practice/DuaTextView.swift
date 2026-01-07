import SwiftUI
import RIZQKit

/// Displays dua text with Arabic, transliteration, and translation
struct DuaTextView: View {
  let arabicText: String
  let transliteration: String?
  let translation: String
  let showTransliteration: Bool

  var body: some View {
    VStack(spacing: RIZQSpacing.lg) {
      // Arabic Text
      arabicTextView

      // Divider
      islamicDivider

      // Transliteration (if visible)
      if showTransliteration, let transliteration = transliteration {
        transliterationView(transliteration)
      }

      // Translation
      translationView
    }
  }

  // MARK: - Arabic Text

  private var arabicTextView: some View {
    Text(arabicText)
      .font(.custom("Amiri-Regular", size: 28))
      .foregroundStyle(Color.rizqText)
      .multilineTextAlignment(.center)
      .lineSpacing(12)
      .environment(\.layoutDirection, .rightToLeft)
      .frame(maxWidth: .infinity)
      .padding(.horizontal, RIZQSpacing.sm)
  }

  // MARK: - Islamic Divider

  private var islamicDivider: some View {
    HStack(spacing: RIZQSpacing.md) {
      Rectangle()
        .fill(Color.rizqMuted.opacity(0.3))
        .frame(height: 1)

      Text("\u{2726}") // Four-pointed star
        .font(.system(size: 12))
        .foregroundStyle(Color.rizqPrimary.opacity(0.5))

      Rectangle()
        .fill(Color.rizqMuted.opacity(0.3))
        .frame(height: 1)
    }
    .padding(.horizontal, RIZQSpacing.xxl)
  }

  // MARK: - Transliteration

  private func transliterationView(_ text: String) -> some View {
    Text(text)
      .font(.rizqSans(.subheadline))
      .italic()
      .foregroundStyle(Color.rizqTextSecondary)
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .transition(.asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.95)),
        removal: .opacity.combined(with: .scale(scale: 0.95))
      ))
  }

  // MARK: - Translation

  private var translationView: some View {
    Text(translation)
      .font(.rizqSans(.body))
      .foregroundStyle(Color.rizqText.opacity(0.85))
      .multilineTextAlignment(.center)
      .lineSpacing(4)
      .frame(maxWidth: .infinity)
  }
}

// MARK: - Previews

#Preview("Dua Text View") {
  ScrollView {
    DuaTextView(
      arabicText: "بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ",
      transliteration: "Bismillahir Rahmanir Raheem",
      translation: "In the name of Allah, the Most Gracious, the Most Merciful",
      showTransliteration: true
    )
    .padding()
    .rizqCard()
    .padding()
  }
  .rizqPageBackground()
}

#Preview("Without Transliteration") {
  ScrollView {
    DuaTextView(
      arabicText: "الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ",
      transliteration: "Alhamdulillahi Rabbil Aalameen",
      translation: "All praise is due to Allah, Lord of all the worlds",
      showTransliteration: false
    )
    .padding()
    .rizqCard()
    .padding()
  }
  .rizqPageBackground()
}
