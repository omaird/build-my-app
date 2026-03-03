import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin view for managing collections
struct AdminCollectionsView: View {
  @Bindable var store: StoreOf<AdminCollectionsFeature>

  var body: some View {
    List {
      ForEach(store.filteredCollections) { collection in
        CollectionAdminRow(collection: collection) {
          store.send(.editCollectionTapped(collection))
        } onDelete: {
          store.send(.deleteCollectionTapped(collection))
        }
      }
    }
    .listStyle(.plain)
    .navigationTitle("Collections")
    .searchable(text: $store.searchQuery, prompt: "Search collections")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.createCollectionTapped)
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
      } else if store.collections.isEmpty {
        ContentUnavailableView(
          "No Collections",
          systemImage: "square.stack",
          description: Text("Add your first collection")
        )
      } else if store.filteredCollections.isEmpty {
        ContentUnavailableView.search(text: store.searchQuery)
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") { store.send(.dismissError) }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .alert("Delete Collection", isPresented: $store.isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelDelete) }
      Button("Delete", role: .destructive) { store.send(.confirmDelete) }
    } message: {
      Text("Are you sure you want to delete this collection? Duas in this collection will become uncategorized.")
    }
    .sheet(isPresented: $store.isFormPresented) {
      CollectionFormSheet(store: store)
    }
    .onAppear {
      store.send(.loadCollections)
    }
  }
}

// MARK: - Collection Admin Row

private struct CollectionAdminRow: View {
  let collection: DuaCollection
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      ZStack {
        Circle()
          .fill(collection.isPremium ? Color.badgeRizq.opacity(0.15) : Color.tealMuted.opacity(0.15))
          .frame(width: 44, height: 44)

        Image(systemName: collection.isPremium ? "crown.fill" : "square.stack.fill")
          .font(.title3)
          .foregroundStyle(collection.isPremium ? Color.badgeRizq : Color.tealMuted)
      }

      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Text(collection.name)
            .font(.rizqSans(.body))
            .foregroundStyle(Color.rizqText)

          if collection.isPremium {
            Text("PREMIUM")
              .font(.rizqMono(.caption2))
              .foregroundStyle(.white)
              .padding(.horizontal, 6)
              .padding(.vertical, 2)
              .background(Color.badgeRizq)
              .clipShape(Capsule())
          }
        }

        Text(collection.slug)
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
}

// MARK: - Collection Form Sheet

private struct CollectionFormSheet: View {
  @Bindable var store: StoreOf<AdminCollectionsFeature>

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Info") {
          TextField("Name", text: $store.formInput.name)
            .onChange(of: store.formInput.name) { _, newValue in
              if store.formMode == .create {
                store.formInput.slug = newValue
                  .lowercased()
                  .replacingOccurrences(of: " ", with: "-")
                  .replacingOccurrences(of: "[^a-z0-9-]", with: "", options: .regularExpression)
              }
            }

          TextField("Slug", text: $store.formInput.slug)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }

        Section("Settings") {
          Toggle("Premium", isOn: $store.formInput.isPremium)
        }

        if !store.formErrors.isEmpty {
          Section {
            ForEach(store.formErrors, id: \.self) { error in
              Text(error)
                .font(.rizqSans(.caption))
                .foregroundStyle(.red)
            }
          }
        }
      }
      .navigationTitle(store.editingCollectionId == nil ? "New Collection" : "Edit Collection")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { store.send(.cancelForm) }
        }
        ToolbarItem(placement: .confirmationAction) {
          if store.isSubmitting {
            ProgressView()
          } else {
            Button("Save") { store.send(.submitForm) }
              .disabled(!store.formInput.isValid)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    AdminCollectionsView(
      store: Store(initialState: AdminCollectionsFeature.State()) {
        AdminCollectionsFeature()
      }
    )
  }
}
