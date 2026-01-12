import SwiftUI
import ComposableArchitecture
import RIZQKit

/// Admin view for managing journeys
struct AdminJourneysView: View {
  @Bindable var store: StoreOf<AdminJourneysFeature>

  var body: some View {
    List {
      ForEach(filteredJourneys) { journey in
        JourneyAdminRow(journey: journey) {
          store.send(.editJourneyTapped(journey))
        } onDelete: {
          store.send(.deleteJourneyTapped(journey))
        } onManageDuas: {
          store.send(.manageDuasTapped(journey))
        }
      }
    }
    .listStyle(.plain)
    .searchable(text: $store.searchQuery, prompt: "Search journeys...")
    .navigationTitle("Journeys")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.createJourneyTapped)
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
      } else if filteredJourneys.isEmpty {
        ContentUnavailableView(
          "No Journeys",
          systemImage: "map",
          description: Text(store.searchQuery.isEmpty ? "Add your first journey" : "No results found")
        )
      }
    }
    .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
      Button("OK") { store.send(.dismissError) }
    } message: {
      Text(store.errorMessage ?? "")
    }
    .alert("Delete Journey", isPresented: $store.isDeleteConfirmationPresented) {
      Button("Cancel", role: .cancel) { store.send(.cancelDelete) }
      Button("Delete", role: .destructive) { store.send(.confirmDelete) }
    } message: {
      Text("Are you sure you want to delete this journey? This cannot be undone.")
    }
    .sheet(isPresented: $store.isFormPresented) {
      JourneyFormSheet(store: store)
    }
    .sheet(isPresented: $store.isManagingDuas) {
      ManageDuasSheet(store: store)
    }
    .onAppear {
      store.send(.loadJourneys)
    }
  }

  private var filteredJourneys: [Journey] {
    guard !store.searchQuery.isEmpty else { return store.journeys }
    let query = store.searchQuery.lowercased()
    return store.journeys.filter {
      $0.name.lowercased().contains(query) ||
      ($0.description?.lowercased().contains(query) ?? false)
    }
  }
}

// MARK: - Journey Admin Row

private struct JourneyAdminRow: View {
  let journey: Journey
  let onEdit: () -> Void
  let onDelete: () -> Void
  let onManageDuas: () -> Void

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Use JourneyIconView to properly handle both emojis and image paths
      JourneyIconView(journey: journey, size: 44, showDecorations: false)

      VStack(alignment: .leading, spacing: 4) {
        HStack {
          Text(journey.name)
            .font(.rizqSans(.body))
            .foregroundStyle(Color.rizqText)

          if journey.isFeatured {
            Image(systemName: "star.fill")
              .font(.caption2)
              .foregroundStyle(Color.rizqPrimary)
          }

          if journey.isPremium {
            Image(systemName: "crown.fill")
              .font(.caption2)
              .foregroundStyle(Color.badgeMorning)
          }
        }

        if let desc = journey.description {
          Text(desc)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
            .lineLimit(1)
        }

        HStack(spacing: RIZQSpacing.sm) {
          Label("\(journey.dailyXp) XP", systemImage: "bolt.fill")
            .font(.rizqSans(.caption2))
            .foregroundStyle(Color.rizqPrimary)

          Label("\(journey.estimatedMinutes) min", systemImage: "clock")
            .font(.rizqSans(.caption2))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }

      Spacer()

      Menu {
        Button("Edit", systemImage: "pencil") { onEdit() }
        Button("Manage Duas", systemImage: "list.bullet") { onManageDuas() }
        Button("Delete", systemImage: "trash", role: .destructive) { onDelete() }
      } label: {
        Image(systemName: "ellipsis.circle")
          .foregroundStyle(Color.rizqTextSecondary)
      }
    }
    .padding(.vertical, 8)
  }
}

// MARK: - Journey Form Sheet

private struct JourneyFormSheet: View {
  @Bindable var store: StoreOf<AdminJourneysFeature>

  var body: some View {
    NavigationStack {
      Form {
        Section("Basic Info") {
          TextField("Name", text: $store.formInput.name)
          TextField("Slug", text: $store.formInput.slug)
          TextField("Emoji", text: $store.formInput.emoji)
          TextField("Description", text: Binding(
            get: { store.formInput.description ?? "" },
            set: { store.formInput.description = $0.isEmpty ? nil : $0 }
          ), axis: .vertical)
            .lineLimit(2...4)
        }

        Section("Details") {
          Stepper("Duration: \(store.formInput.estimatedMinutes) min", value: $store.formInput.estimatedMinutes, in: 1...120)
          Stepper("Daily XP: \(store.formInput.dailyXp)", value: $store.formInput.dailyXp, in: 0...500, step: 10)
          Stepper("Sort Order: \(store.formInput.sortOrder)", value: $store.formInput.sortOrder, in: 0...100)
        }

        Section("Flags") {
          Toggle("Premium", isOn: $store.formInput.isPremium)
          Toggle("Featured", isOn: $store.formInput.isFeatured)
        }
      }
      .navigationTitle(store.editingJourneyId == nil ? "New Journey" : "Edit Journey")
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

// MARK: - Manage Duas Sheet

private struct ManageDuasSheet: View {
  @Bindable var store: StoreOf<AdminJourneysFeature>
  @State private var selectedTimeSlot: TimeSlot = .morning
  @State private var duaSearchQuery = ""

  var body: some View {
    NavigationStack {
      List {
        currentDuasSection
        availableDuasSection
      }
      .searchable(text: $duaSearchQuery, prompt: "Search duas...")
      .navigationTitle(store.selectedJourney?.name ?? "Manage Duas")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Done") {
            store.send(.closeDuasManager)
          }
        }
      }
    }
  }

  // MARK: - Current Duas Section

  @ViewBuilder
  private var currentDuasSection: some View {
    Section {
      if store.journeyDuas.isEmpty {
        ContentUnavailableView(
          "No Duas Added",
          systemImage: "doc.text",
          description: Text("Add duas from the section below")
        )
      } else {
        ForEach(sortedJourneyDuas, id: \.duaId) { journeyDua in
          CurrentDuaRow(
            journeyDua: journeyDua,
            dua: duaForJourneyDua(journeyDua),
            onRemove: { store.send(.removeDuaFromJourney(journeyDua.duaId)) }
          )
        }
      }
    } header: {
      Text("Current Duas (\(store.journeyDuas.count))")
    }
  }

  // MARK: - Available Duas Section

  @ViewBuilder
  private var availableDuasSection: some View {
    Section {
      timeSlotPicker
      ForEach(filteredAvailableDuas) { dua in
        AvailableDuaRow(
          dua: dua,
          isInJourney: isDuaInJourney(dua.id),
          onAdd: { store.send(.addDuaToJourney(dua, selectedTimeSlot)) }
        )
      }
    } header: {
      Text("Available Duas")
    }
  }

  @ViewBuilder
  private var timeSlotPicker: some View {
    Picker("Time Slot", selection: $selectedTimeSlot) {
      ForEach(TimeSlot.allCases) { slot in
        Text(slot.displayName).tag(slot)
      }
    }
    .pickerStyle(.segmented)
    .listRowBackground(Color.clear)
    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
  }

  // MARK: - Helpers

  private var sortedJourneyDuas: [JourneyDua] {
    store.journeyDuas.sorted { $0.sortOrder < $1.sortOrder }
  }

  private func duaForJourneyDua(_ journeyDua: JourneyDua) -> Dua? {
    store.availableDuas.first { $0.id == journeyDua.duaId }
  }

  private var filteredAvailableDuas: [Dua] {
    guard !duaSearchQuery.isEmpty else { return store.availableDuas }
    let query = duaSearchQuery.lowercased()
    return store.availableDuas.filter { dua in
      dua.titleEn.lowercased().contains(query) ||
      dua.translationEn.lowercased().contains(query)
    }
  }

  private func isDuaInJourney(_ duaId: Int) -> Bool {
    store.journeyDuas.contains { $0.duaId == duaId }
  }
}

// MARK: - Current Dua Row

private struct CurrentDuaRow: View {
  let journeyDua: JourneyDua
  let dua: Dua?
  let onRemove: () -> Void

  var body: some View {
    if let dua = dua {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(dua.titleEn)
            .font(.rizqSans(.body))
            .foregroundStyle(Color.rizqText)

          HStack(spacing: RIZQSpacing.sm) {
            Label(journeyDua.timeSlot.displayName, systemImage: journeyDua.timeSlot.icon)
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqTextSecondary)

            Text("•")
              .foregroundStyle(Color.rizqTextSecondary)

            Text("\(dua.xpValue) XP")
              .font(.rizqSans(.caption))
              .foregroundStyle(Color.rizqPrimary)
          }
        }

        Spacer()

        Button(action: onRemove) {
          Image(systemName: "minus.circle.fill")
            .foregroundStyle(.red)
        }
      }
      .padding(.vertical, 4)
    }
  }
}

// MARK: - Available Dua Row

private struct AvailableDuaRow: View {
  let dua: Dua
  let isInJourney: Bool
  let onAdd: () -> Void

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(dua.titleEn)
          .font(.rizqSans(.body))
          .foregroundStyle(Color.rizqText)

        Text("\(dua.xpValue) XP")
          .font(.rizqSans(.caption))
          .foregroundStyle(Color.rizqPrimary)
      }

      Spacer()

      if isInJourney {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(Color.tealSuccess)
      } else {
        Button(action: onAdd) {
          Image(systemName: "plus.circle.fill")
            .foregroundStyle(Color.rizqPrimary)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  NavigationStack {
    AdminJourneysView(
      store: Store(initialState: AdminJourneysFeature.State()) {
        AdminJourneysFeature()
      }
    )
  }
}
