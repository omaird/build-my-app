import SwiftUI
import RIZQKit

/// Search bar with magnifying glass icon and clear button
struct SearchBarView: View {
  @Binding var searchText: String
  var placeholder: String = "Search duas..."

  @FocusState private var isFocused: Bool

  var body: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Search icon
      Image(systemName: "magnifyingglass")
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(isFocused ? Color.rizqPrimary : Color.rizqTextSecondary)

      // Text field
      TextField(placeholder, text: $searchText)
        .font(.rizqSans(.body))
        .foregroundStyle(Color.rizqText)
        .focused($isFocused)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)

      // Clear button
      if !searchText.isEmpty {
        Button {
          searchText = ""
        } label: {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 16))
            .foregroundStyle(Color.rizqMuted)
        }
        .buttonStyle(.plain)
        .transition(.scale.combined(with: .opacity))
      }
    }
    .padding(.horizontal, RIZQSpacing.lg)
    .padding(.vertical, RIZQSpacing.md)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
    .overlay(
      RoundedRectangle(cornerRadius: RIZQRadius.btn)
        .stroke(
          isFocused ? Color.rizqPrimary : Color.rizqBorder,
          lineWidth: isFocused ? 2 : 1
        )
    )
    .animation(.easeInOut(duration: 0.2), value: isFocused)
    .animation(.easeInOut(duration: 0.15), value: searchText.isEmpty)
  }
}

// MARK: - Preview
#Preview {
  VStack(spacing: 24) {
    SearchBarView(searchText: .constant(""))
    SearchBarView(searchText: .constant("Morning"))
    SearchBarView(searchText: .constant(""), placeholder: "Find something...")
  }
  .padding()
  .background(Color.rizqBackground)
}
