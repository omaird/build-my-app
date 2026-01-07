import SwiftUI
import ComposableArchitecture
import RIZQKit

struct LibraryView: View {
  @Bindable var store: StoreOf<LibraryFeature>

  // Adaptive grid columns - 2 on iPhone, more on iPad
  private let columns = [
    GridItem(.flexible(), spacing: RIZQSpacing.lg),
    GridItem(.flexible(), spacing: RIZQSpacing.lg),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: RIZQSpacing.xl) {
          // Header
          headerSection

          // Search Bar
          SearchBarView(searchText: $store.searchText)

          // Category Filters
          CategoryFilterView(
            categories: store.categories,
            selectedCategory: store.selectedCategory,
            onCategorySelected: { category in
              store.send(.categorySelected(category))
            }
          )

          // Active Filter Indicator
          if let selectedCategory = store.selectedCategory {
            activeFilterIndicator(for: selectedCategory)
          }

          // Duas Grid
          duasGrid
        }
        .padding(.horizontal, RIZQSpacing.lg)
        .padding(.bottom, RIZQSpacing.huge) // Nav bar clearance
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
  }

  // MARK: - Header Section
  private var headerSection: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
      Text("Library")
        .font(.rizqDisplayBold(.largeTitle))
        .foregroundStyle(Color.rizqText)

      Text("Explore our collection of authentic duas")
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.top, RIZQSpacing.lg)
  }

  // MARK: - Active Filter Indicator
  private func activeFilterIndicator(for categorySlug: CategorySlug) -> some View {
    let category = CategoryDisplay.display(for: categorySlug)

    return HStack(spacing: RIZQSpacing.sm) {
      Text("Showing \(store.filteredDuas.count) duas in \(category.name)")
        .font(.rizqSans(.subheadline))
        .foregroundStyle(Color.rizqTextSecondary)

      Spacer()

      Button {
        store.send(.categorySelected(nil))
      } label: {
        Image(systemName: "xmark.circle.fill")
          .font(.system(size: 16))
          .foregroundStyle(Color.rizqPrimary)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, RIZQSpacing.md)
    .padding(.vertical, RIZQSpacing.sm)
    .background(Color.rizqPrimary.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
  }

  // MARK: - Duas Grid
  private var duasGrid: some View {
    Group {
      if store.isLoading {
        loadingState
      } else if store.filteredDuas.isEmpty {
        emptyState
      } else {
        LazyVGrid(columns: columns, spacing: RIZQSpacing.lg) {
          ForEach(store.filteredDuas) { dua in
            DuaCardView(
              dua: dua,
              onTap: {
                store.send(.duaTapped(dua))
              },
              onAddToAdkhar: {
                store.send(.addToAdkharTapped(dua))
              }
            )
          }
        }

        // Total count
        Text("\(store.filteredDuas.count) of \(store.duas.count) duas")
          .font(.rizqSans(.footnote))
          .foregroundStyle(Color.rizqMuted)
          .frame(maxWidth: .infinity)
          .padding(.top, RIZQSpacing.md)
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

  // MARK: - Empty State
  private var emptyState: some View {
    VStack(spacing: RIZQSpacing.lg) {
      Image(systemName: "book.closed")
        .font(.system(size: 48))
        .foregroundStyle(Color.rizqMuted)

      Text("No duas found")
        .font(.rizqSansSemiBold(.headline))
        .foregroundStyle(Color.rizqTextSecondary)

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

        Spacer()

        // Action Buttons
        VStack(spacing: RIZQSpacing.md) {
          Button {
            store.send(.confirmTapped)
          } label: {
            Text("Add to Daily Adkhar")
              .frame(maxWidth: .infinity)
              .rizqPrimaryButton()
          }

          Button {
            store.send(.cancelTapped)
          } label: {
            Text("Cancel")
              .font(.rizqSansMedium(.headline))
              .foregroundStyle(Color.rizqTextSecondary)
          }
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
  }
}

// MARK: - Preview
#Preview {
  LibraryView(
    store: Store(initialState: LibraryFeature.State(duas: Dua.demoData)) {
      LibraryFeature()
    }
  )
}
