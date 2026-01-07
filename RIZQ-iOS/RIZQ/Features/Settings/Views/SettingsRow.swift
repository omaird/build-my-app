import SwiftUI
import RIZQKit

// MARK: - Settings Row Style

enum SettingsRowStyle {
  case navigation
  case toggle
  case destructive
  case destructiveNavigation
}

// MARK: - Settings Row
// Generic settings row with icon, label, and optional accessory

struct SettingsRow: View {
  let icon: String
  let iconColor: Color
  let title: String
  let subtitle: String?
  let style: SettingsRowStyle
  let isOn: Binding<Bool>?
  let isLoading: Bool
  let action: (() -> Void)?

  init(
    icon: String,
    iconColor: Color = .rizqPrimary,
    title: String,
    subtitle: String? = nil,
    style: SettingsRowStyle = .navigation,
    isOn: Binding<Bool>? = nil,
    isLoading: Bool = false,
    action: (() -> Void)? = nil
  ) {
    self.icon = icon
    self.iconColor = iconColor
    self.title = title
    self.subtitle = subtitle
    self.style = style
    self.isOn = isOn
    self.isLoading = isLoading
    self.action = action
  }

  private var textColor: Color {
    switch style {
    case .destructive, .destructiveNavigation:
      return .red
    default:
      return .rizqText
    }
  }

  private var effectiveIconColor: Color {
    switch style {
    case .destructive, .destructiveNavigation:
      return .red
    default:
      return iconColor
    }
  }

  var body: some View {
    Group {
      switch style {
      case .toggle:
        toggleContent
      case .navigation, .destructive, .destructiveNavigation:
        if let action = action {
          Button(action: action) {
            rowContent
          }
          .buttonStyle(.plain)
        } else {
          rowContent
        }
      }
    }
  }

  // MARK: - Row Content

  private var rowContent: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Icon
      iconView

      // Labels
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.rizqSans(.body))
          .foregroundStyle(textColor)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }

      Spacer()

      // Accessory
      accessoryView
    }
    .padding(.vertical, RIZQSpacing.sm)
    .contentShape(Rectangle())
  }

  private var toggleContent: some View {
    HStack(spacing: RIZQSpacing.md) {
      // Icon
      iconView

      // Label
      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.rizqSans(.body))
          .foregroundStyle(textColor)

        if let subtitle = subtitle {
          Text(subtitle)
            .font(.rizqSans(.caption))
            .foregroundStyle(Color.rizqTextSecondary)
        }
      }

      Spacer()

      // Toggle
      if let isOn = isOn {
        Toggle("", isOn: isOn)
          .labelsHidden()
          .tint(Color.rizqPrimary)
      }
    }
    .padding(.vertical, RIZQSpacing.sm)
  }

  // MARK: - Icon View

  private var iconView: some View {
    Image(systemName: icon)
      .font(.system(size: 18))
      .foregroundStyle(effectiveIconColor)
      .frame(width: 28, height: 28)
  }

  // MARK: - Accessory View

  @ViewBuilder
  private var accessoryView: some View {
    if isLoading {
      ProgressView()
        .progressViewStyle(CircularProgressViewStyle(tint: Color.rizqTextSecondary))
        .scaleEffect(0.8)
    } else {
      switch style {
      case .navigation, .destructiveNavigation:
        Image(systemName: "chevron.right")
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(Color.rizqTextSecondary)
      case .toggle, .destructive:
        EmptyView()
      }
    }
  }
}

// MARK: - Convenience Initializers

extension SettingsRow {
  /// Navigation row with action
  static func navigation(
    icon: String,
    iconColor: Color = .rizqPrimary,
    title: String,
    subtitle: String? = nil,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) -> SettingsRow {
    SettingsRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      style: .navigation,
      isLoading: isLoading,
      action: action
    )
  }

  /// Toggle row
  static func toggle(
    icon: String,
    iconColor: Color = .rizqPrimary,
    title: String,
    subtitle: String? = nil,
    isOn: Binding<Bool>
  ) -> SettingsRow {
    SettingsRow(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      style: .toggle,
      isOn: isOn
    )
  }

  /// Destructive row (no chevron)
  static func destructive(
    icon: String,
    title: String,
    subtitle: String? = nil,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) -> SettingsRow {
    SettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      style: .destructive,
      isLoading: isLoading,
      action: action
    )
  }

  /// Destructive navigation row (with chevron)
  static func destructiveNavigation(
    icon: String,
    title: String,
    subtitle: String? = nil,
    isLoading: Bool = false,
    action: @escaping () -> Void
  ) -> SettingsRow {
    SettingsRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      style: .destructiveNavigation,
      isLoading: isLoading,
      action: action
    )
  }
}

// MARK: - Settings Section
// Container for grouping settings rows

struct SettingsSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      Text(title.uppercased())
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
        .tracking(0.5)
        .padding(.horizontal, RIZQSpacing.xs)

      VStack(spacing: 0) {
        content()
      }
      .padding(.horizontal, RIZQSpacing.md)
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    }
  }
}

// MARK: - Preview

#Preview {
  ScrollView {
    VStack(spacing: RIZQSpacing.xl) {
      SettingsSection(title: "Appearance") {
        SettingsRow.toggle(
          icon: "moon.fill",
          title: "Dark Mode",
          isOn: .constant(false)
        )
        Divider()
        SettingsRow.toggle(
          icon: "bell.fill",
          title: "Notifications",
          subtitle: "Daily reminders for your habits",
          isOn: .constant(true)
        )
      }

      SettingsSection(title: "Account") {
        SettingsRow.navigation(
          icon: "person.fill",
          title: "Edit Profile",
          action: {}
        )
        Divider()
        SettingsRow.navigation(
          icon: "rectangle.portrait.and.arrow.right",
          iconColor: Color.rizqTextSecondary,
          title: "Sign Out",
          action: {}
        )
      }

      SettingsSection(title: "Danger Zone") {
        SettingsRow.destructive(
          icon: "trash.fill",
          title: "Reset Progress",
          subtitle: "This cannot be undone",
          action: {}
        )
      }
    }
    .padding()
  }
  .background(Color.rizqBackground)
}
