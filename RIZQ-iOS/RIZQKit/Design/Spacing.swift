import SwiftUI

// MARK: - RIZQ Spacing System
// Consistent spacing values throughout the app

public enum RIZQSpacing {
  /// 4pt
  public static let xs: CGFloat = 4
  /// 8pt
  public static let sm: CGFloat = 8
  /// 12pt
  public static let md: CGFloat = 12
  /// 16pt
  public static let lg: CGFloat = 16
  /// 20pt
  public static let xl: CGFloat = 20
  /// 24pt
  public static let xxl: CGFloat = 24
  /// 32pt
  public static let xxxl: CGFloat = 32
  /// 48pt
  public static let huge: CGFloat = 48
}

// MARK: - Corner Radius
public enum RIZQRadius {
  /// 8pt - Small elements
  public static let sm: CGFloat = 8
  /// 12pt - Default (rounded-lg)
  public static let md: CGFloat = 12
  /// 16pt - Buttons (rounded-btn)
  public static let btn: CGFloat = 16
  /// 20pt - Cards (rounded-islamic)
  public static let islamic: CGFloat = 20
  /// 24pt - Large containers
  public static let lg: CGFloat = 24
  /// Full circle
  public static let full: CGFloat = 9999
}

// MARK: - Shadow Definitions
public extension View {
  /// Subtle elevation shadow
  func shadowSoft() -> some View {
    self.shadow(
      color: Color.black.opacity(0.08),
      radius: 8,
      x: 0,
      y: 4
    )
  }

  /// Card hover state shadow
  func shadowElevated() -> some View {
    self.shadow(
      color: Color.black.opacity(0.12),
      radius: 16,
      x: 0,
      y: 8
    )
  }

  /// Primary button glow
  func shadowGlowPrimary() -> some View {
    self.shadow(
      color: Color.sandWarm.opacity(0.4),
      radius: 12,
      x: 0,
      y: 4
    )
  }

  /// Streak badge glow
  func shadowGlowStreak() -> some View {
    self.shadow(
      color: Color.streakGlow.opacity(0.5),
      radius: 16,
      x: 0,
      y: 0
    )
  }
}

// MARK: - Standard View Modifiers
public extension View {
  /// Apply RIZQ card styling
  func rizqCard() -> some View {
    self
      .background(Color.rizqCard)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
      .shadowSoft()
  }

  /// Apply RIZQ primary button styling
  func rizqPrimaryButton() -> some View {
    self
      .font(.rizqSansSemiBold(.headline))
      .foregroundStyle(.white)
      .padding(.horizontal, RIZQSpacing.xl)
      .padding(.vertical, RIZQSpacing.md)
      .background(Color.rizqPrimary)
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
      .shadowGlowPrimary()
  }

  /// Apply RIZQ secondary button styling
  func rizqSecondaryButton() -> some View {
    self
      .font(.rizqSansMedium(.headline))
      .foregroundStyle(Color.rizqPrimary)
      .padding(.horizontal, RIZQSpacing.xl)
      .padding(.vertical, RIZQSpacing.md)
      .background(Color.rizqPrimary.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.btn))
  }

  /// Page background with Islamic pattern
  func rizqPageBackground() -> some View {
    self
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(Color.rizqBackground)
  }
}
