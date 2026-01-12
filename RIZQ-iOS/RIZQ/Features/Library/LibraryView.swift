import SwiftUI
import ComposableArchitecture
import RIZQKit

struct LibraryView: View {
  @Bindable var store: StoreOf<LibraryFeature>

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.lg) {
          // Header (matches React design)
          headerSection

          // Search Bar
          searchBar

          // Category Filter Pills (matches React emojis)
          categoryPills

          // Dua List (vertical, not grid - matches React)
          duaList
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.huge)
      }
      .rizqPageBackground()
      .navigationBarHidden(true)
    }
    .onAppear {
      store.send(.onAppear)
    }
    .sheet(
      item: $store.scope(state: \.addToAdkharSheet, action: \.addToAdkharSheet)
    ) { sheetStore in
      AddToAdkharSheetView(store: sheetStore)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
    .sheet(
      item: $store.scope(state: \.practiceSheet, action: \.practiceSheet)
    ) { sheetStore in
      PracticeSheetView(store: sheetStore)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
  }

  // MARK: - Header (matches React BookOpen icon + title)
  private var headerSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      HStack(spacing: RIZQSpacing.sm) {
        Image(systemName: "book.fill")
          .font(.system(size: 28))
          .foregroundStyle(Color.rizqPrimary)

        Text("Dua Library")
          .font(.rizqDisplayBold(.largeTitle))
          .foregroundStyle(Color.rizqText)
      }

      Text(store.isLoading ? "Loading..." : "\(store.allDuas.count) duas to practice")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, RIZQSpacing.lg)
  }

  // MARK: - Search Bar
  private var searchBar: some View {
    HStack(spacing: RIZQSpacing.sm) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(Color.rizqMuted)

      TextField("Search duas...", text: $store.searchText)
        .font(.rizqSans(.body))
    }
    .padding(RIZQSpacing.md)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.btn)
        .stroke(Color.rizqBorder, lineWidth: 1)
    )
  }

  // MARK: - Category Pills (matches React emojis)
  private var categoryPills: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: RIZQSpacing.sm) {
        ForEach(store.categories) { category in
          categoryPill(category)
        }
      }
      .padding(.horizontal, 1) // Prevent clipping
    }
  }

  private func categoryPill(_ category: CategoryDisplay) -> some View {
    let isSelected = store.selectedCategory == category.slug

    return Button {
      store.send(.categorySelected(category.slug))
    } label: {
      HStack(spacing: RIZQSpacing.xs) {
        Text(category.emoji)
          .font(.system(size: 16))
        Text(category.name)
          .font(.rizqSansMedium(.subheadline))
      }
      .padding(.horizontal, RIZQSpacing.md)
      .padding(.vertical, RIZQSpacing.sm)
      .background(isSelected ? Color.rizqPrimary : Color.rizqCard)
      .foregroundStyle(isSelected ? .white : Color.rizqText)
      .clipShape(Capsule())
      .overlay(
        Capsule()
          .stroke(isSelected ? Color.clear : Color.rizqBorder, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  // MARK: - Dua List (vertical layout, matches React)
  private var duaList: some View {
    Group {
      if store.isLoading {
        loadingState
      } else if let error = store.errorMessage {
        errorState(error)
      } else if store.filteredDuas.isEmpty {
        emptyState
      } else {
        LazyVStack(spacing: RIZQSpacing.md) {
          ForEach(Array(store.filteredDuas.enumerated()), id: \.element.id) { index, dua in
            DuaListCardView(
              dua: dua,
              isActive: store.activeHabitDuaIds.contains(dua.id),
              isCompleted: store.completedTodayDuaIds.contains(dua.id),
              onTap: { store.send(.duaTapped(dua)) },
              onAddToAdkhar: { store.send(.addToAdkharTapped(dua)) }
            )
            .modifier(StaggeredItemModifier(index: index))
          }
        }

        // Results count
        Text("\(store.filteredDuas.count) duas")
          .font(.rizqSans(.footnote))
          .foregroundStyle(Color.rizqMuted)
          .padding(.top, RIZQSpacing.sm)
      }
    }
  }

  // MARK: - Loading State
  private var loadingState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
        .scaleEffect(1.2)

      Text("Loading duas...")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.huge)
  }

  // MARK: - Error State
  private func errorState(_ message: String) -> some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 48))
        .foregroundStyle(Color.red.opacity(0.7))

      Text("Unable to load duas")
        .font(.rizqSansSemiBold(.headline))
        .foregroundStyle(Color.rizqText)

      Text(message)
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqMuted)
        .multilineTextAlignment(.center)

      Button {
        store.send(.retryTapped)
      } label: {
        HStack(spacing: RIZQSpacing.sm) {
          Image(systemName: "arrow.clockwise")
          Text("Retry")
        }
        .rizqPrimaryButton()
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.huge)
  }

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "book.closed")
        .font(.system(size: 48))
        .foregroundStyle(Color.rizqMuted)

      Text("No duas found")
        .font(.rizqSansSemiBold(.headline))
        .foregroundStyle(Color.rizqText)

      Text("Try adjusting your search or filters")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqMuted)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, RIZQSpacing.huge)
  }
}

// MARK: - Add to Adkhar Sheet View

struct AddToAdkharSheetView: View {
  let store: StoreOf<AddToAdkharSheetFeature>

  var body: some View {
    NavigationStack {
      VStack(spacing: RIZQSpacing.xxl) {
        // Dua Info
        VStack(spacing: RIZQSpacing.sm) {
          Text(store.dua.titleEn)
            .font(.rizqSansSemiBold(.title3))
            .foregroundStyle(Color.rizqText)

          Text(store.dua.arabicText)
            .font(.rizqArabic(.title3))
            .foregroundStyle(Color.rizqText)
            .multilineTextAlignment(.center)
            .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(.horizontal, RIZQSpacing.lg)

        // Time Slot Selection
        VStack(alignment: .leading, spacing: RIZQSpacing.md) {
          Text("Choose time slot")
            .font(.rizqSansMedium(.headline))
            .foregroundStyle(Color.rizqText)

          HStack(spacing: RIZQSpacing.md) {
            ForEach(TimeSlot.allCases) { timeSlot in
              timeSlotButton(timeSlot)
            }
          }
        }
        .padding(.horizontal, RIZQSpacing.lg)

        // Error Message
        if let errorMessage = store.errorMessage {
          Text(errorMessage)
            .font(.rizqSans(.caption))
            .foregroundStyle(.red)
            .multilineTextAlignment(.center)
            .padding(.horizontal, RIZQSpacing.lg)
        }

        Spacer()

        // Action Buttons
        VStack(spacing: RIZQSpacing.md) {
          Button {
            store.send(.confirmTapped)
          } label: {
            HStack(spacing: RIZQSpacing.sm) {
              if store.isSaving {
                ProgressView()
                  .progressViewStyle(CircularProgressViewStyle(tint: .white))
                  .scaleEffect(0.8)
              }
              Text(store.isSaving ? "Adding..." : "Add to Daily Adkhar")
            }
            .frame(maxWidth: .infinity)
            .rizqPrimaryButton()
          }
          .disabled(store.isSaving)

          Button {
            store.send(.cancelTapped)
          } label: {
            Text("Cancel")
              .font(.rizqSansMedium(.headline))
              .foregroundStyle(Color.rizqTextSecondary)
          }
          .disabled(store.isSaving)
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.xl)
      }
      .padding(.top, RIZQSpacing.xl)
      .navigationTitle("Add to Adkhar")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private func timeSlotButton(_ timeSlot: TimeSlot) -> some View {
    let isSelected = store.selectedTimeSlot == timeSlot

    return Button {
      store.send(.timeSlotSelected(timeSlot))
    } label: {
      VStack(spacing: RIZQSpacing.sm) {
        Image(systemName: timeSlot.icon)
          .font(.system(size: 24))

        Text(timeSlot.displayName)
          .font(.rizqSans(.caption))
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, RIZQSpacing.md)
      .foregroundStyle(isSelected ? .white : Color.rizqText)
      .background(isSelected ? Color.rizqPrimary : Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      .overlay(
        RoundedRectangle(cornerRadius: RIZQRadius.btn)
          .stroke(isSelected ? Color.clear : Color.rizqBorder, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
    .disabled(store.isSaving)
  }
}

// MARK: - Practice Sheet View

struct PracticeSheetView: View {
  let store: StoreOf<PracticeSheetFeature>

  var body: some View {
    NavigationStack {
      VStack(spacing: RIZQSpacing.xxl) {
        // Dua content
        ScrollView {
          VStack(spacing: RIZQSpacing.xl) {
            // Arabic text
            Text(store.dua.arabicText)
              .font(.rizqArabic(.title))
              .foregroundStyle(Color.rizqText)
              .multilineTextAlignment(.center)
              .environment(\.layoutDirection, .rightToLeft)
              .padding(.top, RIZQSpacing.lg)

            // Transliteration
            if let transliteration = store.dua.transliteration {
              Text(transliteration)
                .font(.rizqSans(.body))
                .foregroundStyle(Color.rizqTextSecondary)
                .italic()
                .multilineTextAlignment(.center)
            }

            // Translation
            Text(store.dua.translationEn)
              .font(.rizqSans(.body))
              .foregroundStyle(Color.rizqText)
              .multilineTextAlignment(.center)
          }
          .padding(.horizontal, RIZQSpacing.lg)
        }

        Spacer()

        // Counter section
        VStack(spacing: RIZQSpacing.lg) {
          // Progress ring
          ZStack {
            Circle()
              .stroke(Color.rizqMuted.opacity(0.3), lineWidth: 8)
              .frame(width: 120, height: 120)

            Circle()
              .trim(from: 0, to: store.progress)
              .stroke(
                store.isComplete ? Color.tealSuccess : Color.rizqPrimary,
                style: StrokeStyle(lineWidth: 8, lineCap: .round)
              )
              .frame(width: 120, height: 120)
              .rotationEffect(.degrees(-90))
              .animation(.easeOut(duration: 0.3), value: store.progress)

            VStack(spacing: 4) {
              Text("\(store.currentCount)")
                .font(.rizqMonoMedium(.largeTitle))
                .foregroundStyle(Color.rizqText)

              Text("of \(store.targetCount)")
                .font(.rizqSans(.caption))
                .foregroundStyle(Color.rizqTextSecondary)
            }
          }

          // Tap to count button
          Button {
            store.send(.incrementTapped)
          } label: {
            Text(store.isComplete ? "Complete!" : "Tap to count")
              .font(.rizqSansMedium(.headline))
              .foregroundStyle(.white)
              .frame(maxWidth: .infinity)
              .padding(.vertical, RIZQSpacing.md)
              .background(store.isComplete ? Color.tealSuccess : Color.rizqPrimary)
              .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
          }
          .disabled(store.isComplete)
          .padding(.horizontal, RIZQSpacing.lg)

          // Done button (when complete)
          if store.isComplete {
            Button {
              store.send(.completeTapped)
            } label: {
              HStack(spacing: RIZQSpacing.sm) {
                if store.isSaving {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqPrimary))
                    .scaleEffect(0.8)
                }
                Text(store.isSaving ? "Saving..." : "Done (+\(store.dua.xpValue) XP)")
              }
              .font(.rizqSansMedium(.headline))
              .foregroundStyle(Color.rizqPrimary)
            }
            .disabled(store.isSaving)
          }
        }
        .padding(.bottom, RIZQSpacing.xxl)
      }
      .rizqPageBackground()
      .navigationTitle(store.dua.titleEn)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            store.send(.closeTapped)
          } label: {
            Image(systemName: "xmark.circle.fill")
              .font(.title2)
              .foregroundStyle(Color.rizqMuted)
          }
        }
      }
    }
  }
}

// MARK: - Staggered Animation Modifier

/// Modifier for staggered entry animations (matches Framer Motion staggerChildren)
struct StaggeredItemModifier: ViewModifier {
  let index: Int
  @State private var isVisible: Bool = false

  private var delay: Double {
    0.05 * Double(min(index, 10))  // Cap delay to prevent too long waits
  }

  func body(content: Content) -> some View {
    content
      .opacity(isVisible ? 1 : 0)
      .offset(y: isVisible ? 0 : 15)
      .onAppear {
        withAnimation(
          .easeOut(duration: 0.3)
          .delay(delay)
        ) {
          isVisible = true
        }
      }
  }
}

// MARK: - Preview

#Preview {
  LibraryView(
    store: Store(initialState: LibraryFeature.State(
      duas: Dua.demoData,
      allDuas: Dua.demoData
    )) {
      LibraryFeature()
    }
  )
}

#Preview("Practice Sheet") {
  PracticeSheetView(
    store: Store(initialState: PracticeSheetFeature.State(
      dua: Dua.demoData[0],
      userId: "test-user"
    )) {
      PracticeSheetFeature()
    }
  )
}
