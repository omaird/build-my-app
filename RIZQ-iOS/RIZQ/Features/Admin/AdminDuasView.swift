import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin view for managing duas
struct AdminDuasView: View {
  @Bindable var store: StoreOf<AdminDuasFeature>

  var body: some View {
    List {
      ForEach(filteredDuas) { dua in
        DuaAdminRow(dua: dua) {
          store.send(.editDuaTapped(dua))
        } onDelete: {
          store.send(.deleteDuaTapped(dua))
        }
      }
    }
    .listStyle(.plain)
    .searchable(text: $store.searchQuery, prompt: "Search duas...")
    .navigationTitle("Duas")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.createDuaTapped)
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
      } else if filteredDuas.isEmpty {
        ContentUnavailableView(
          "No Duas",
          systemImage: "book",
          description: Text(store.searchQuery.isEmpty ? "Add your first dua" : "No results found")
        )
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") { store.send(.dismissError) }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .alert("Delete Dua", isPresented: $store.isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelDelete) }
      Button("Delete", role: .destructive) { store.send(.confirmDelete) }
    } message: {
      Text("Are you sure you want to delete this dua? This cannot be undone.")
    }
    .sheet(isPresented: $store.isFormPresented) {
      DuaFormSheet(store: store)
    }
    .onAppear {
      store.send(.loadDuas)
    }
  }

  private var filteredDuas: [Dua] {
    guard !store.searchQuery.isEmpty else { return store.duas }
    let query = store.searchQuery.lowercased()
    return store.duas.filter {
      $0.titleEn.lowercased().contains(query) ||
      $0.arabicText.contains(query)
    }
  }
}

// MARK: - Dua Admin Row

private struct DuaAdminRow: View {
  let dua: Dua
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      VStack(alignment: .leading, spacing: 4) {
        Text(dua.titleEn)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)

        Text(dua.arabicText.prefix(50) + "...")
          .font(.rizqArabic(.caption))
          .foregroundStyle(Color.rizqTextSecondary)
          .lineLimit(1)

        HStack(spacing: RIZQSpacing.sm) {
          Label("\(dua.xpValue) XP", systemImage: "star.fill")
            .font(.rizqSans(.caption2))
            .foregroundStyle(Color.rizqPrimary)

          if let time = dua.bestTime {
            Label(time, systemImage: bestTimeIcon(for: time))
              .font(.rizqSans(.caption2))
              .foregroundStyle(bestTimeColor(for: time))
          }
        }
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

  // MARK: - Best Time Helpers

  private func bestTimeIcon(for time: String) -> String {
    let lowercased = time.lowercased()
    if lowercased.contains("morning") || lowercased.contains("fajr") {
      return "sun.max.fill"
    } else if lowercased.contains("evening") || lowercased.contains("maghrib") || lowercased.contains("sleep") {
      return "moon.fill"
    } else {
      return "clock.fill"
    }
  }

  private func bestTimeColor(for time: String) -> Color {
    let lowercased = time.lowercased()
    if lowercased.contains("morning") || lowercased.contains("fajr") {
      return .badgeMorning
    } else if lowercased.contains("evening") || lowercased.contains("maghrib") || lowercased.contains("sleep") {
      return .badgeEvening
    } else {
      return .badgeRizq
    }
  }
}

// MARK: - Dua Form Sheet

private struct DuaFormSheet: View {
  @Bindable var store: StoreOf<AdminDuasFeature>

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Info") {
          TextField("Title (English)", text: $store.formInput.titleEn)
          TextField("Arabic Text", text: $store.formInput.arabicText)
            .environment(\.layoutDirection, .rightToLeft)
          TextField("Transliteration", text: Binding(
            get: { store.formInput.transliteration ?? "" },
            set: { store.formInput.transliteration = $0.isEmpty ? nil : $0 }
          ))
          TextField("Translation", text: $store.formInput.translationEn)
        }

        Section("Details") {
          Stepper("Repetitions: \(store.formInput.repetitions)", value: $store.formInput.repetitions, in: 1...100)
          Stepper("XP Value: \(store.formInput.xpValue)", value: $store.formInput.xpValue, in: 1...100)

          Picker("Best Time", selection: $store.formInput.bestTime) {
            Text("Any time").tag(Optional<TimeSlot>.none)
            ForEach(TimeSlot.allCases, id: \.self) { slot in
              Text(slot.displayName).tag(Optional(slot))
            }
          }

          Picker("Difficulty", selection: $store.formInput.difficulty) {
            ForEach(DuaDifficulty.allCases, id: \.self) { diff in
              Text(diff.rawValue.capitalized).tag(diff)
            }
          }
        }

        Section("Source") {
          TextField("Source", text: Binding(
            get: { store.formInput.source ?? "" },
            set: { store.formInput.source = $0.isEmpty ? nil : $0 }
          ))
        }
      }
      .navigationTitle(store.editingDuaId == nil ? "New Dua" : "Edit Dua")
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
    AdminDuasView(
      store: Store(initialState: AdminDuasFeature.State()) {
        AdminDuasFeature()
      }
    )
  }
}
