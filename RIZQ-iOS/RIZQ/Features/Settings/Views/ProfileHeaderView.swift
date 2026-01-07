import SwiftUI
import RIZQKit

// MARK: - Profile Header View
// Displays user avatar, name, email, and stats

struct ProfileHeaderView: View {
  let displayName: String
  let email: String
  let profileImageUrl: String?
  let level: Int
  let totalXp: Int
  let streak: Int
  let isEditing: Bool
  @Binding var editedName: String
  let isSaving: Bool
  let onEditTapped: () -> Void
  let onSaveTapped: () -> Void
  let onCancelTapped: () -> Void

  private var xpProgress: Double {
    let profile = UserProfile(
      id: "",
      userId: "",
      streak: streak,
      totalXp: totalXp,
      level: level
    )
    return profile.levelProgress
  }

  private var xpToNextLevel: Int {
    let profile = UserProfile(
      id: "",
      userId: "",
      streak: streak,
      totalXp: totalXp,
      level: level
    )
    return profile.xpToNextLevel
  }

  var body: some View {
    VStack(spacing: RIZQSpacing.lg) {
      // Avatar and Name Section
      HStack(spacing: RIZQSpacing.lg) {
        // Avatar with Level Badge
        avatarView

        // Name and Email
        VStack(alignment: .leading, spacing: RIZQSpacing.xs) {
          if isEditing {
            editNameView
          } else {
            nameDisplayView
          }

          // Email
          HStack(spacing: RIZQSpacing.xs) {
            Image(systemName: "envelope.fill")
              .font(.system(size: 12))
              .foregroundStyle(Color.rizqTextSecondary)

            Text(email)
              .font(.rizqSans(.subheadline))
              .foregroundStyle(Color.rizqTextSecondary)
          }
        }

        Spacer()
      }

      // Stats Grid
      statsGrid

      // XP Progress Bar
      xpProgressView
    }
    .padding(RIZQSpacing.lg)
    .background(Color.rizqCard)
    .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.islamic))
    .shadowSoft()
  }

  // MARK: - Avatar View

  private var avatarView: some View {
    ZStack(alignment: .bottomTrailing) {
      if let imageUrl = profileImageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          case .failure, .empty:
            avatarPlaceholder
          @unknown default:
            avatarPlaceholder
          }
        }
        .frame(width: 64, height: 64)
        .clipShape(Circle())
      } else {
        avatarPlaceholder
      }

      // Level Badge
      Text("\(level)")
        .font(.rizqMonoMedium(.caption2))
        .foregroundStyle(.white)
        .frame(width: 24, height: 24)
        .background(Color.rizqPrimary)
        .clipShape(Circle())
        .offset(x: 4, y: 4)
    }
  }

  private var avatarPlaceholder: some View {
    Circle()
      .fill(LinearGradient.rizqPrimaryGradient)
      .frame(width: 64, height: 64)
      .overlay {
        Text(displayName.prefix(1).uppercased())
          .font(.rizqDisplayBold(.title2))
          .foregroundStyle(.white)
      }
  }

  // MARK: - Name Views

  private var nameDisplayView: some View {
    HStack(spacing: RIZQSpacing.sm) {
      Text(displayName)
        .font(.rizqDisplaySemiBold(.title3))
        .foregroundStyle(Color.rizqText)

      Button(action: onEditTapped) {
        Image(systemName: "pencil")
          .font(.system(size: 14))
          .foregroundStyle(Color.rizqTextSecondary)
          .padding(6)
          .background(Color.rizqMuted.opacity(0.3))
          .clipShape(Circle())
      }
    }
  }

  private var editNameView: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      TextField("Display Name", text: $editedName)
        .font(.rizqSansSemiBold(.headline))
        .foregroundStyle(Color.rizqText)
        .padding(.horizontal, RIZQSpacing.md)
        .padding(.vertical, RIZQSpacing.sm)
        .background(Color.rizqBackground)
        .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
        .overlay {
          RoundedRectangle(cornerRadius: RIZQRadius.sm)
            .stroke(Color.rizqPrimary, lineWidth: 1)
        }

      HStack(spacing: RIZQSpacing.sm) {
        Button(action: onSaveTapped) {
          HStack(spacing: RIZQSpacing.xs) {
            if isSaving {
              ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(0.8)
            } else {
              Image(systemName: "checkmark")
                .font(.system(size: 12, weight: .semibold))
            }
            Text("Save")
              .font(.rizqSansSemiBold(.subheadline))
          }
          .foregroundStyle(.white)
          .padding(.horizontal, RIZQSpacing.md)
          .padding(.vertical, RIZQSpacing.sm)
          .background(Color.rizqPrimary)
          .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
        }
        .disabled(isSaving || editedName.trimmingCharacters(in: .whitespaces).isEmpty)
        .opacity(isSaving || editedName.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1)

        Button(action: onCancelTapped) {
          Image(systemName: "xmark")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Color.rizqTextSecondary)
            .padding(RIZQSpacing.sm)
            .background(Color.rizqMuted.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: RIZQRadius.sm))
        }
        .disabled(isSaving)
      }
    }
  }

  // MARK: - Stats Grid

  private var statsGrid: some View {
    HStack(spacing: RIZQSpacing.lg) {
      statItem(
        icon: "star.fill",
        value: "\(level)",
        label: "Level",
        color: Color.rizqPrimary
      )

      Divider()
        .frame(height: 40)

      statItem(
        icon: "trophy.fill",
        value: "\(totalXp)",
        label: "Total XP",
        color: Color.goldSoft
      )

      Divider()
        .frame(height: 40)

      statItem(
        icon: "flame.fill",
        value: "\(streak)",
        label: "Day Streak",
        color: Color.streakGlow
      )
    }
    .padding(.vertical, RIZQSpacing.sm)
  }

  private func statItem(
    icon: String,
    value: String,
    label: String,
    color: Color
  ) -> some View {
    VStack(spacing: RIZQSpacing.xs) {
      Circle()
        .fill(color.opacity(0.15))
        .frame(width: 40, height: 40)
        .overlay {
          Image(systemName: icon)
            .font(.system(size: 18))
            .foregroundStyle(color)
        }

      Text(value)
        .font(.rizqMono(.headline))
        .foregroundStyle(Color.rizqText)

      Text(label)
        .font(.rizqSans(.caption2))
        .foregroundStyle(Color.rizqTextSecondary)
    }
    .frame(maxWidth: .infinity)
  }

  // MARK: - XP Progress

  private var xpProgressView: some View {
    VStack(alignment: .leading, spacing: RIZQSpacing.sm) {
      HStack {
        Text("Level \(level) Progress")
          .font(.rizqSans(.subheadline))
          .foregroundStyle(Color.rizqTextSecondary)

        Spacer()

        Text("\(Int(xpProgress * 100))%")
          .font(.rizqMono(.subheadline))
          .foregroundStyle(Color.rizqText)
      }

      // Progress Bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.rizqMuted.opacity(0.3))
            .frame(height: 8)

          RoundedRectangle(cornerRadius: 4)
            .fill(LinearGradient.rizqPrimaryGradient)
            .frame(width: geometry.size.width * xpProgress, height: 8)
        }
      }
      .frame(height: 8)

      Text("\(xpToNextLevel) XP to Level \(level + 1)")
        .font(.rizqSans(.caption))
        .foregroundStyle(Color.rizqTextSecondary)
    }
  }
}

// MARK: - Preview

#Preview {
  ProfileHeaderView(
    displayName: "Omar",
    email: "omar@example.com",
    profileImageUrl: nil,
    level: 2,
    totalXp: 350,
    streak: 5,
    isEditing: false,
    editedName: .constant(""),
    isSaving: false,
    onEditTapped: {},
    onSaveTapped: {},
    onCancelTapped: {}
  )
  .padding()
  .background(Color.rizqBackground)
}
