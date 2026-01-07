import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin view for managing categories
struct AdminCategoriesView: View {
  @Bindable var store: StoreOf<AdminCategoriesFeature>

  var body: some View {
    List {
      ForEach(store.categories) { category in
        CategoryAdminRow(category: category) {
          store.send(.editCategoryTapped(category))
        } onDelete: {
          store.send(.deleteCategoryTapped(category))
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Categories")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.createCategoryTapped)
        } label: {
          Image(systemName: "plus.circle.fill")
            .font(.title2)
        }
      }
    }
    .rizqPageBackground()
    .overlay {
      if store.isLoading {
        ProgressView()
      } else if store.categories.isEmpty {
        ContentUnavailableView(
          "No Categories",
          systemImage: "folder",
          description: Text("Add your first category")
        )
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") { store.send(.dismissError) }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .alert("Delete Category", isPresented: $store.isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelDelete) }
      Button("Delete", role: .destructive) { store.send(.confirmDelete) }
    } message: {
      Text("Are you sure you want to delete this category? Duas in this category will become uncategorized.")
    }
    .sheet(isPresented: $store.isFormPresented) {
      CategoryFormSheet(store: store)
    }
    .onAppear {
      store.send(.loadCategories)
    }
  }
}

// MARK: - Category Admin Row

private struct CategoryAdminRow: View {
  let category: DuaCategory
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      ZStack {
        Circle()
          .fill(categoryColor.opacity(0.15))
          .frame(width: 44, height: 44)

        Image(systemName: category.icon)
          .font(.title3)
          .foregroundStyle(categoryColor)
      }

      VStack(alignment: .leading, spacing: 4) {
        Text(category.name)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)

        if let desc = category.description {
          Text(desc)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .lineLimit(1)
        }

        Text(category.slug.rawValue)
          .font(.rizqMono(.caption2))
          .foregroundStyle(Color.rizqTextTertiary)
      }

      Spacer()

      Menu {
        Button("Edit", systemImage: "pencil") { onEdit() }
        Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
      } label: {
        Image(systemName: "ellipsis.circle")
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .padding(.vertical, 8)
  }

  private var categoryColor: Color {
    switch category.slug {
    case .morning: return .badgeMorning
    case .evening: return .badgeEvening
    case .rizq: return .badgeRizq
    case .gratitude: return .badgeGratitude
    }
  }
}

// MARK: - Category Form Sheet

private struct CategoryFormSheet: View {
  @Bindable var store: StoreOf<AdminCategoriesFeature>

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Info") {
          TextField("Name", text: $store.formInput.name)

          Picker("Slug", selection: $store.formInput.slug) {
            ForEach(CategorySlug.allCases, id: \.self) { slug in
              Text(slug.rawValue.capitalized).tag(slug)
            }
          }

          TextField("Description", text: Binding(
            get: { store.formInput.description ?? "" },
            set: { store.formInput.description = $0.isEmpty ? nil : $0 }
          ), axis: .vertical)
            .lineLimit(2...4)
        }
      }
      .navigationTitle(store.editingCategoryId == nil ? "New Category" : "Edit Category")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { store.send(.cancelForm) }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") { store.send(.submitForm) }
            .disabled(!store.formInput.isValid)
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    AdminCategoriesView(
      store: Store(initialState: AdminCategoriesFeature.State()) {
        AdminCategoriesFeature()
      }
    )
  }
}
