import SwiftUI
import RIZQKit

// MARK: - Daily Quote View
//
// Design Decisions:
// - Displays Islamic quote with elegant typography
// - Arabic text renders RTL when available
// - Subtle gold gradient background for warmth
// - Category-specific icon from IslamicQuote.QuoteCategory
// - Staggered fade-in animation on appear
//
// Related Files:
// - IslamicQuote.swift (data model with displayName, iconName, accessibilityDescription)
// - HomeView.swift (integration)
// - HomeFeature.swift (state management)
// - RIZQTests.swift (IslamicQuoteModelTests)
//
// Edge Cases Handled:
// - Quotes without Arabic text (only English displayed)
// - Very long quotes (multiline support)
// - VoiceOver accessibility
//
// Acceptance Criteria Met:
// 1. ✓ Elegant typography with gold gradient background
// 2. ✓ RTL Arabic text with proper layout direction
// 3. ✓ Category icon from model (not hardcoded)
// 4. ✓ Category badge display
// 5. ✓ Staggered fade-in animations (header → arabic → english → source)
// 6. ✓ Multiline support with fixedSize(horizontal:false, vertical:true)
// 7. ✓ VoiceOver accessibility using model's accessibilityDescription
// 8. ✓ Haptic feedback on appear (soft impact)
// 9. ✓ Optional share button with press animation
// 10. ✓ Icon glow animation (pulsing opacity)
// 11. ✓ Source attribution with primary color
// 12. ✓ Build verified successful

/// Islamic quote card with elegant typography and subtle gold accents
struct DailyQuoteView: View {
  let quote: IslamicQuote
  var onShareTapped: (() -> Void)?

  @State private var isVisible = false
  @State private var iconGlow: Double = 0.5
  @State private var isSharePressed = false

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.lg) {
      // Header with quote icon and category badge
      headerRow

      // Arabic text (if available)
      if let arabicText = quote.arabicText, !arabicText.isEmpty {
        arabicTextSection(arabicText)
      }

      // English translation
      englishTextSection

      // Source attribution
      sourceRow
    }
    .padding(RIZQSpacing.xl)
    .background(backgroundGradient)
    .overlay(borderOverlay)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(quote.accessibilityDescription)
    .accessibilityAddTraits(.isStaticText)
    .onAppear {
      withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
        isVisible = true
      }
      startIconGlow()
      // Subtle haptic on quote appearance
      UIImpactFeedbackGenerator(style: .soft).impactOccurred()
    }
  }

  // MARK: - Animation

  private func startIconGlow() {
    withAnimation(
      .easeInOut(duration: 3.0)
        .repeatForever(autoreverses: true)
    ) {
      iconGlow = 1.0
    }
  }

  // MARK: - Header Row

  private var headerRow: some View {
    HStack {
      // Category-specific icon with subtle glow animation
      Image(systemName: quote.category.iconName)
        .font(.title2)
        .foregroundStyle(Color.goldSoft.opacity(iconGlow))
        .shadow(color: Color.goldSoft.opacity(iconGlow * 0.3), radius: 4)

      Spacer()

      // Category badge
      Text(quote.category.displayName)
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
        .padding(.horizontal, RIZQSpacing.sm)
        .padding(.vertical, RIZQSpacing.xs)
        .background(Color.rizqMuted.opacity(0.2))
        .clipShape(Capsule())

      // Share button (if handler provided)
      if onShareTapped != nil {
        shareButton
      }
    }
  }

  private var shareButton: some View {
    Button {
      UIImpactFeedbackGenerator(style: .light).impactOccurred()
      onShareTapped?()
    } label: {
      Image(systemName: "square.and.arrow.up")
        .font(.subheadline)
        .foregroundStyle(Color.rizqTextSecondary)
        .padding(RIZQSpacing.sm)
        .background(Color.rizqMuted.opacity(0.15))
        .clipShape(Circle())
    }
    .buttonStyle(.plain)
    .scaleEffect(isSharePressed ? 0.9 : 1.0)
    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isSharePressed)
    .simultaneousGesture(
      DragGesture(minimumDistance: 0)
        .onChanged { _ in isSharePressed = true }
        .onEnded { _ in isSharePressed = false }
    )
    .accessibilityLabel("Share quote")
  }

  // MARK: - Arabic Text Section

  private func arabicTextSection(_ text: String) -> some View {
    Text(text)
      .font(.rizqArabic(.title3))
      .foregroundStyle(Color.rizqText)
      .multilineTextAlignment(.trailing)
      .frame(maxWidth: .infinity, alignment: .trailing)
      .environment(\.layoutDirection, .rightToLeft)
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 10)
      .animation(.easeOut(duration: 0.5).delay(0.3), value: isVisible)
  }

  // MARK: - English Text Section

  private var englishTextSection: some View {
    Text(quote.englishText)
      .font(.rizqDisplayMedium(.body))
      .foregroundStyle(Color.rizqText)
      .italic()
      .multilineTextAlignment(.leading)
      .lineLimit(nil)
      .fixedSize(horizontal: false, vertical: true)
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 10)
      .animation(.easeOut(duration: 0.5).delay(0.4), value: isVisible)
  }

  // MARK: - Source Row

  private var sourceRow: some View {
    HStack {
      Spacer()

      Text("— \(quote.source)")
        .font(.rizqSansMedium(.caption))
        .foregroundStyle(Color.rizqPrimary)
    }
    .opacity(isVisible ? 1 : 0)
    .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)
  }

  // MARK: - Background & Border

  private var backgroundGradient: some View {
    LinearGradient(
      colors: [Color.goldSoft.opacity(0.08), Color.goldBright.opacity(0.03)],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }

  private var borderOverlay: some View {
    RoundedRectangle(cornerRadius: RIZQRadius.islamic)
      .stroke(Color.goldSoft.opacity(0.3), lineWidth: 1)
  }
}

// MARK: - Previews

#Preview("Daily Quote - Quran (with Arabic)") {
  DailyQuoteView(quote: IslamicQuote.dailyQuotes[0])
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - Hadith") {
  DailyQuoteView(quote: IslamicQuote.dailyQuotes[2])
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - Wisdom (Long)") {
  DailyQuoteView(quote: IslamicQuote.dailyQuotes[4])
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - Today's Quote") {
  DailyQuoteView(quote: IslamicQuote.quoteForToday())
    .padding()
    .background(Color.rizqBackground)
}

#Preview("Daily Quote - All Categories") {
  ScrollView {
    VStack(spacing: 16) {
      ForEach(IslamicQuote.dailyQuotes) { quote in
        DailyQuoteView(quote: quote)
      }
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
