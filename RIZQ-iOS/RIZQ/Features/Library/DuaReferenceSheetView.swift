import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Educational reference view for learning about a dua in the Library.
/// Unlike QuickPracticeSheet, this has no counter - it's for discovery, not practice.
struct DuaReferenceSheetView: View {
  @Bindable var store: StoreOf<DuaReferenceSheetFeature>

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          // Category badge + Title header
          headerSection

          // Arabic text card (prominent, centered)
          arabicTextCard

          // Pronunciation section (transliteration)
          if let transliteration = store.dua.transliteration {
            sectionView(title: "PRONUNCIATION") {
              Text(transliteration)
                .font(.rizqSans(.body))
                .foregroundStyle(Color.rizqText)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }

          // Meaning section (translation)
          sectionView(title: "MEANING") {
            Text(store.dua.translationEn)
              .font(.rizqSans(.body))
              .foregroundStyle(Color.rizqTextSecondary)
              .frame(maxWidth: .infinity, alignment: .leading)
          }

          // Why Recite This Dua? section (rizqBenefit)
          if let benefit = store.dua.rizqBenefit {
            sectionView(title: "WHY RECITE THIS DUA?") {
              Text(benefit)
                .font(.rizqSans(.body))
                .foregroundStyle(Color.rizqText)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
          }

          // Prophetic Tradition card (propheticContext)
          if let propheticContext = store.dua.propheticContext {
            propheticContextCard(propheticContext)
          }

          // Source card
          if let source = store.dua.source {
            sourceCard(source)
          }

          // Footer info: Difficulty + recitation count
          footerInfo

          Spacer().frame(height: 100)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
      }
      .background(Color.rizqCard)
      .safeAreaInset(edge: .bottom) {
        // Fixed CTA button at bottom
        ctaButton
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          categoryBadge
        }
        ToolbarItem(placement: .navigationBarTrailing) {
          closeButton
        }
      }
      .navigationBarTitleDisplayMode(.inline)
    }
    .sheet(item: $store.scope(state: \.addToAdkharSheet, action: \.addToAdkharSheet)) { childStore in
      AddToAdkharSheetView(store: childStore)
    }
  }

  // MARK: - Header Section

  private var headerSection: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(store.dua.titleEn)
        .font(.rizqDisplaySemiBold(.title2))
        .foregroundStyle(Color.rizqText)
        .frame(maxWidth: .infinity, alignment: .leading)

      // Best time hint (if available)
      if let bestTime = store.dua.bestTime {
        HStack(spacing: 6) {
          Image(systemName: bestTimeIcon(for: bestTime))
            .font(.system(size: 12))
          Text("Best recited: \(bestTime)")
            .font(.rizqSans(.caption))
        }
        .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .padding(.top, 8)
  }

  // MARK: - Category Badge

  private var categoryBadge: some View {
    let category = CategoryDisplay.display(for: categorySlug(for: store.dua.categoryId))

    return HStack(spacing: 4) {
      Text(category.emoji)
        .font(.system(size: 14))
      Text(category.name.uppercased())
        .font(.rizqSans(.caption2))
        .tracking(1)
    }
    .foregroundStyle(Color.rizqPrimary)
    .padding(.horizontal, 10)
    .padding(.vertical, 6)
    .background(
      Capsule()
        .fill(Color.rizqPrimary.opacity(0.1))
    )
  }

  // MARK: - Close Button

  private var closeButton: some View {
    Button {
      store.send(.closeTapped)
    } label: {
      ZStack {
        Circle()
          .fill(Color.rizqMuted.opacity(0.2))
          .frame(width: 32, height: 32)

        Image(systemName: "xmark")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .accessibilityLabel("Close")
  }

  // MARK: - Arabic Text Card

  private var arabicTextCard: some View {
    VStack(spacing: 0) {
      Text(store.dua.arabicText)
        .font(.rizqArabic(.title))
        .foregroundStyle(Color.rizqText)
        .multilineTextAlignment(.center)
        .lineSpacing(16)
        .padding(.vertical, 28)
        .padding(.horizontal, 20)
        .environment(\.layoutDirection, .rightToLeft)
    }
    .frame(maxWidth: .infinity)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .fill(Color.cream)
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.islamic)
        .stroke(Color.goldSoft.opacity(0.4), lineWidth: 1.5)
    )
  }

  // MARK: - Section View Helper

  private func sectionView<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(1)

      content()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  // MARK: - Prophetic Context Card

  private func propheticContextCard(_ context: String) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: "book.closed.fill")
          .font(.system(size: 12))
        Text("PROPHETIC TRADITION")
          .font(.rizqSans(.caption2))
          .tracking(1)
      }
      .foregroundStyle(Color.sandWarm)

      Text(context)
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqText)
        .italic()
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .fill(Color.goldSoft.opacity(0.15))
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .stroke(Color.goldSoft.opacity(0.3), lineWidth: 1)
    )
  }

  // MARK: - Source Card

  private func sourceCard(_ source: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(spacing: 6) {
        Image(systemName: "scroll.fill")
          .font(.system(size: 12))
        Text("SOURCE")
          .font(.rizqSans(.caption2))
          .tracking(1)
      }
      .foregroundStyle(Color.rizqPrimary)

      Text(source)
        .font(.rizqSansMedium(.body))
        .foregroundStyle(Color.rizqText)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .fill(Color.rizqPrimary.opacity(0.05))
    )
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.md)
        .stroke(Color.rizqPrimary.opacity(0.15), lineWidth: 1)
    )
  }

  // MARK: - Footer Info

  private var footerInfo: some View {
    HStack(spacing: 16) {
      // Difficulty indicator
      if let difficulty = store.dua.difficulty {
        HStack(spacing: 6) {
          Circle()
            .fill(difficultyColor(for: difficulty))
            .frame(width: 8, height: 8)
          Text(difficultyLabel(for: difficulty))
            .font(.rizqSans(.caption))
        }
        .foregroundStyle(Color.rizqTextSecondary)
      }

      // Separator dot
      if store.dua.difficulty != nil {
        Text("•")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqMuted)
      }

      // Recitation count (informational, not for practice)
      Text("\(store.dua.repetitions) recitation\(store.dua.repetitions == 1 ? "" : "s") per session")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)

      Spacer()
    }
    .padding(.top, 8)
  }

  // MARK: - CTA Button

  private var ctaButton: some View {
    VStack(spacing: 0) {
      Divider()

      Button {
        store.send(.addToAdkharTapped)
      } label: {
        HStack(spacing: 10) {
          if store.isAlreadyInAdkhar {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 18))
          } else {
            Image(systemName: "plus.circle.fill")
              .font(.system(size: 18))
          }

          Text(store.isAlreadyInAdkhar ? "Added to Daily Adkhar" : "Add to Daily Adkhar")
            .font(.rizqSansSemiBold(.headline))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .background(
          RoundedRectangle(cornerRadius: RIZQRadius.btn)
            .fill(store.isAlreadyInAdkhar ? Color.tealSuccess : Color.rizqPrimary)
        )
      }
      .disabled(store.isAlreadyInAdkhar)
      .padding(.horizontal, 24)
      .padding(.vertical, 16)
    }
    .background(Color.rizqCard)
  }

  // MARK: - Helpers

  private func categorySlug(for categoryId: Int?) -> CategorySlug? {
    switch categoryId {
    case 1: return .morning
    case 2: return .evening
    case 3: return .rizq
    case 4: return .gratitude
    default: return nil
    }
  }

  private func bestTimeIcon(for time: String) -> String {
    let lowercased = time.lowercased()
    if lowercased.contains("morning") { return "sun.max.fill" }
    if lowercased.contains("evening") { return "moon.fill" }
    return "clock.fill"
  }

  private func difficultyColor(for difficulty: DuaDifficulty) -> Color {
    switch difficulty {
    case .beginner: return Color.tealSuccess
    case .intermediate: return Color.sandWarm
    case .advanced: return Color.rizqPrimary
    }
  }

  private func difficultyLabel(for difficulty: DuaDifficulty) -> String {
    switch difficulty {
    case .beginner: return "Beginner-friendly"
    case .intermediate: return "Intermediate"
    case .advanced: return "Advanced"
    }
  }
}

// MARK: - Preview

#Preview {
  DuaReferenceSheetView(
    store: Store(
      initialState: DuaReferenceSheetFeature.State(
        dua: Dua(
          id: 1,
          categoryId: 3,
          titleEn: "Seeking Provision",
          arabicText: "اللَّهُمَّ اكْفِنِي بِحَلالِكَ عَنْ حَرَامِكَ وَأَغْنِنِي بِفَضْلِكَ عَمَّنْ سِوَاكَ",
          transliteration: "Allahumma-kfinee bihalaalika 'an haraamika wa 'aghninee bifadlika 'amman siwaaka",
          translationEn: "O Allah, suffice me with what is lawful against what is unlawful, and make me independent of all others besides You.",
          source: "Sahih al-Tirmidhi",
          repetitions: 1,
          bestTime: "Morning",
          difficulty: .beginner,
          rizqBenefit: "This dua helps establish trust in Allah for provision and protects against seeking unlawful means of sustenance.",
          propheticContext: "The Prophet (ﷺ) taught this dua to Ali (RA) when he came to him complaining about his debts. Ali reported that even if he had a debt as large as a mountain, Allah would help him pay it off.",
          xpValue: 10
        )
      )
    ) {
      DuaReferenceSheetFeature()
    }
  )
}
